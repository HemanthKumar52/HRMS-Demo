from calendar import monthrange
from datetime import date, datetime, timedelta

from django.conf import settings
from django.contrib.auth import get_user_model
from django.db.models import Q, Sum
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import (
    Announcement,
    AssetRequestModel,
    Attendance,
    AttendanceRequestModel,
    AvailableLeave,
    ClaimRequest,
    Department,
    DeviceTokenModel,
    Employee,
    EmployeeWorkInformation,
    JobPosition,
    LeaveRequest,
    LeaveType,
    NotificationModel,
    Payslip,
    Shift,
    ShiftRequestModel,
    Ticket,
    TicketType,
    UserSettingsModel,
    WorkType,
    WorkTypeRequestModel,
)
from .serializers import (
    AssetRequestCreateSerializer,
    AttendanceRegularizeSerializer,
    ChangePasswordSerializer,
    ClaimSubmitSerializer,
    DeviceRegisterSerializer,
    LeaveApplySerializer,
    PunchInSerializer,
    PunchOutSerializer,
    RefreshTokenSerializer,
    RequestActionSerializer,
    ShiftRequestCreateSerializer,
    TicketRaiseSerializer,
    UserProfileUpdateSerializer,
    WorkTypeRequestCreateSerializer,
)

User = get_user_model()


def get_employee_from_user(user):
    try:
        return Employee.objects.get(employee_user_id_id=user.id)
    except Employee.DoesNotExist:
        return None


def get_employee_by_id(employee_id_id):
    try:
        return Employee.objects.get(id=employee_id_id)
    except Employee.DoesNotExist:
        return None


def get_request_id(prefix, obj_id):
    return f'{prefix}-{str(obj_id).zfill(4)}'


def create_notification(recipient_user_id, verb, description=''):
    """Create an in-app notification for a user."""
    try:
        NotificationModel.objects.create(
            recipient_id=recipient_user_id,
            verb=verb,
            description=description,
            unread=True,
            timestamp=timezone.now(),
        )
    except Exception:
        pass


def save_cc_for_request(request_type, request_id, cc_user_ids, *, requester_name, request_title):
    """Persist CC user IDs for a request and fire read-only notifications.

    `cc_user_ids` is a list of `User.id` values (NOT employee.id). The CC'd
    users get a Notification row that they can read in the Notifications tab
    but they have no approval rights — the listing screens skip them in the
    "Approvals" tab because the filter is by `reporting_manager_id_id`.
    """
    if not cc_user_ids:
        return
    from .models import RequestCc

    seen = set()
    for raw in cc_user_ids:
        try:
            uid = int(raw)
        except (TypeError, ValueError):
            continue
        if uid in seen:
            continue
        seen.add(uid)
        try:
            user = User.objects.filter(id=uid).first()
            if not user:
                continue
            RequestCc.objects.update_or_create(
                request_type=request_type,
                request_id=request_id,
                user_id=uid,
                defaults={'user_name': user.username or ''},
            )
            # Fire notification on the cc'd user.
            create_notification(
                uid,
                f"You were CC'd on a {request_type} request",
                f'{requester_name} CC\'d you on "{request_title}".',
            )
        except Exception:
            continue


def cc_users_for_request(request_type, request_id):
    """Return the list of CC'd users for a (type, id) pair."""
    from .models import RequestCc

    rows = RequestCc.objects.filter(request_type=request_type, request_id=request_id).order_by('id')
    return [
        {
            'user_id': r.user_id,
            'user_name': r.user_name,
        }
        for r in rows
    ]


def write_audit(
    request, *, action, target_type=None, target_id=None, target_user_id=None, target_name=None, payload=None
):
    """Append an entry to the AuditLog table. Best-effort, never raises."""
    try:
        import json as _json

        from .models import AuditLog

        actor = getattr(request, 'user', None)
        actor_user_id = getattr(actor, 'id', None) if actor else None
        actor_name = ''
        actor_role = ''
        if actor and getattr(actor, 'id', None):
            emp = get_employee_from_user(actor)
            if emp:
                actor_name = emp.name
            if actor.is_superuser:
                actor_role = 'admin'
            elif actor.is_staff:
                actor_role = 'hr'
            else:
                actor_role = 'employee'
        ip = ''
        try:
            ip = request.META.get('HTTP_X_FORWARDED_FOR', '').split(',')[0].strip() or request.META.get(
                'REMOTE_ADDR', ''
            )
        except Exception:
            pass
        AuditLog.objects.create(
            actor_user_id=actor_user_id,
            actor_name=actor_name or None,
            actor_role=actor_role or None,
            target_user_id=target_user_id,
            target_name=target_name,
            action=action,
            target_type=target_type,
            target_id=str(target_id) if target_id is not None else None,
            payload=_json.dumps(payload, default=str) if payload else None,
            ip_address=ip or None,
        )
    except Exception:
        pass


def notify_managers_of_request(employee, request_type, title):
    """Notify the employee's manager about a new request."""
    work_info = EmployeeWorkInformation.objects.filter(employee_id_id=employee.id).first()
    if work_info and work_info.reporting_manager_id_id:
        manager = get_employee_by_id(work_info.reporting_manager_id_id)
        if manager and manager.employee_user_id_id:
            create_notification(
                manager.employee_user_id_id,
                f'New {request_type} Request',
                f'{employee.name} submitted: {title}',
            )


# ── Failed-login monitor tunables ────────────────────────────────────────
FAILED_LOGIN_LOCKOUT_THRESHOLD = 50  # raised for dev; tighten to 5 in production
FAILED_LOGIN_LOCKOUT_MINUTES = 1  # short lockout during dev


def _client_ip(request):
    """Best-effort client IP — honors X-Forwarded-For for proxy chains."""
    try:
        xff = request.META.get('HTTP_X_FORWARDED_FOR', '')
        if xff:
            return xff.split(',')[0].strip()
        return request.META.get('REMOTE_ADDR', '') or ''
    except Exception:
        return ''


def _ip_allowed(ip):
    """Check the AllowedIp table.

    • Empty / no active rows → allowed (backwards compatible)
    • Otherwise: allow only when `ip` matches any active CIDR
    """
    import ipaddress as _ipa

    from .models import AllowedIp

    if not ip:
        return True  # cannot resolve — don't block (would lock everyone out)
    try:
        rows = list(AllowedIp.objects.filter(is_active=True).values_list('cidr', flat=True))
    except Exception:
        return True
    if not rows:
        return True
    try:
        addr = _ipa.ip_address(ip)
    except ValueError:
        return True  # malformed IP — don't block
    for cidr in rows:
        try:
            if addr in _ipa.ip_network(cidr.strip(), strict=False):
                return True
        except ValueError:
            continue
    return False


def _record_login(request, *, user, role, success=True):
    """Append a row to LoginRecord with everything we know about this attempt."""
    try:
        from .models import LoginRecord

        LoginRecord.objects.create(
            user_id=getattr(user, 'id', 0) or 0,
            user_name=getattr(user, 'username', '') or '',
            role=role or '',
            latitude=request.data.get('latitude'),
            longitude=request.data.get('longitude'),
            location_name=(request.data.get('location_name') or '')[:255],
            device_info=(request.data.get('device_info') or '')[:255],
            ip_address=_client_ip(request)[:64],
            user_agent=(request.META.get('HTTP_USER_AGENT', '') or '')[:1000],
            success=success,
        )
    except Exception:
        pass


def _user_role(user, employee):
    """Compute the public role string for a user. superuser > hr > manager > employee."""
    if user.is_superuser:
        return 'admin'
    if user.is_staff:
        return 'hr'
    if employee and EmployeeWorkInformation.objects.filter(reporting_manager_id_id=employee.id).exists():
        return 'manager'
    return 'employee'


def _issue_tokens(user):
    """Build a versioned RefreshToken/AccessToken pair for a user. Bumps fail
    counters reset on successful issue."""
    refresh = RefreshToken.for_user(user)
    refresh['tv'] = int(getattr(user, 'token_version', 0) or 0)
    access = refresh.access_token
    access['tv'] = int(getattr(user, 'token_version', 0) or 0)
    return access, refresh


class AuthView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        from datetime import timedelta

        from django.contrib.auth import authenticate

        username = (request.data.get('username') or '').strip()
        password = request.data.get('password') or ''
        if not username or not password:
            return Response(
                {'error': {'code': 'INVALID_CREDENTIALS', 'message': 'Username and password are required'}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # IP allowlist (admin-managed). Empty table = allow all.
        client_ip = _client_ip(request)
        if not _ip_allowed(client_ip):
            write_audit(
                request,
                action='login_blocked_ip',
                payload={'ip': client_ip, 'username': username},
            )
            return Response(
                {
                    'error': {
                        'code': 'IP_NOT_ALLOWED',
                        'message': 'Login from this network is not permitted.',
                        'ip': client_ip,
                    }
                },
                status=status.HTTP_403_FORBIDDEN,
            )

        # Look up the user up-front so we can apply lockout BEFORE trying to
        # validate the password. (We don't reveal which step failed.)
        user_row = User.objects.filter(username__iexact=username).first()

        # Lockout check.
        if user_row and user_row.locked_until and user_row.locked_until > timezone.now():
            mins = int((user_row.locked_until - timezone.now()).total_seconds() / 60) + 1
            write_audit(
                request,
                action='login_blocked_locked',
                target_type='User',
                target_id=user_row.id,
                target_user_id=user_row.id,
                target_name=user_row.username,
            )
            return Response(
                {
                    'error': {
                        'code': 'ACCOUNT_LOCKED',
                        'message': f'Too many failed attempts. Try again in {mins} minute(s).',
                    }
                },
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        # Now actually try to authenticate.
        user = authenticate(username=username, password=password)
        if not user:
            # Increment failed-login counter on the looked-up row (if any) and
            # lock when the threshold is crossed.
            if user_row:
                user_row.failed_login_count = (user_row.failed_login_count or 0) + 1
                if user_row.failed_login_count >= FAILED_LOGIN_LOCKOUT_THRESHOLD:
                    user_row.locked_until = timezone.now() + timedelta(minutes=FAILED_LOGIN_LOCKOUT_MINUTES)
                user_row.save(update_fields=['failed_login_count', 'locked_until'])
                write_audit(
                    request,
                    action='login_failed',
                    target_type='User',
                    target_id=user_row.id,
                    target_user_id=user_row.id,
                    target_name=user_row.username,
                    payload={'failed_count': user_row.failed_login_count},
                )
            return Response(
                {'error': {'code': 'INVALID_CREDENTIALS', 'message': 'Invalid credentials'}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not user.is_active:
            return Response(
                {'error': {'code': 'ACCOUNT_DISABLED', 'message': 'User account is disabled'}},
                status=status.HTTP_403_FORBIDDEN,
            )

        # Successful auth — reset the failed counter.
        if user.failed_login_count or user.locked_until:
            user.failed_login_count = 0
            user.locked_until = None
            user.save(update_fields=['failed_login_count', 'locked_until'])

        employee = get_employee_from_user(user)
        if not employee:
            return Response({'error': 'Employee profile not found'}, status=status.HTTP_404_NOT_FOUND)

        try:
            work_info = EmployeeWorkInformation.objects.filter(employee_id_id=employee.id).first()
            department = ''
            designation = ''
            if work_info:
                if work_info.department_id_id:
                    dept = Department.objects.filter(id=work_info.department_id_id).first()
                    department = dept.department if dept else ''
                if work_info.job_position_id_id:
                    jp = JobPosition.objects.filter(id=work_info.job_position_id_id).first()
                    designation = jp.job_position if jp else ''
        except Exception:
            department = ''
            designation = ''

        role = _user_role(user, employee)
        access, refresh = _issue_tokens(user)

        write_audit(
            request,
            action='login_success',
            target_type='User',
            target_id=user.id,
            target_user_id=user.id,
            target_name=user.username,
            payload={
                'role': role,
                'lat': request.data.get('latitude'),
                'lng': request.data.get('longitude'),
                'location_name': request.data.get('location_name'),
                'device': request.data.get('device_info'),
                'ip': client_ip,
            },
        )
        _record_login(request, user=user, role=role, success=True)

        return Response(
            {
                'access_token': str(access),
                'refresh_token': str(refresh),
                'expires_in': 3600,
                'user': {
                    'id': str(user.id),
                    'employee_id': employee.badge_id or str(employee.id),
                    'name': employee.name,
                    'email': user.email,
                    'designation': designation,
                    'department': department,
                    'avatar_url': employee.avatar_url,
                    'role': role,
                },
            }
        )


class RefreshTokenView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RefreshTokenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        refresh_token = serializer.validated_data['refresh_token']

        try:
            refresh = RefreshToken(refresh_token)
            return Response(
                {'access_token': str(refresh.access_token), 'refresh_token': str(refresh), 'expires_in': 3600}
            )
        except Exception:
            return Response({'error': 'Invalid refresh token'}, status=status.HTTP_400_BAD_REQUEST)


class LogoutView(APIView):
    def post(self, request):
        try:
            fcm_token = request.data.get('fcm_token')
            if fcm_token:
                DeviceTokenModel.objects.filter(fcm_token=fcm_token).delete()
            return Response({'message': 'Logged out successfully'})
        except Exception:
            return Response({'message': 'Logged out'})


class ChangePasswordView(APIView):
    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = request.user
        current_password = serializer.validated_data['current_password']
        new_password = serializer.validated_data['new_password']

        if not user.check_password(current_password):
            return Response({'error': 'Current password is incorrect'}, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(new_password)
        user.save()

        return Response({'message': 'Password changed successfully'})


class ForgotPasswordView(APIView):
    """Mobile-friendly version of Horilla's HorillaPasswordResetView.

    Accepts a username or email and triggers Django's standard password-reset
    email — same token machinery the web side uses, so the link the user
    receives is identical and lands on the existing reset_password.html page.

    Always returns 200 (regardless of whether the user exists) so the endpoint
    can't be used to enumerate accounts.
    """

    permission_classes = [AllowAny]

    def post(self, request):
        from django.contrib.auth.forms import PasswordResetForm

        identifier = (request.data.get('email') or request.data.get('username') or '').strip()
        if not identifier:
            return Response(
                {'error': {'code': 'IDENTIFIER_REQUIRED', 'message': 'Email or username is required'}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Look up the user by username OR email so the user can use either.
        user = (
            User.objects.filter(username__iexact=identifier).first()
            or User.objects.filter(email__iexact=identifier).first()
        )

        if user and user.is_active and user.email:
            try:
                form = PasswordResetForm({'email': user.email})
                if form.is_valid():
                    form.save(
                        use_https=request.is_secure(),
                        request=request,
                        from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', None),
                        email_template_name='registration/password_reset_email.html',
                        subject_template_name='registration/password_reset_subject.txt',
                    )
            except Exception as e:
                # Best-effort: log but never reveal failure to the caller.
                import logging as _log

                _log.getLogger(__name__).warning('FORGOT_PASSWORD email send failed: %s', e)

        # Same response shape regardless of outcome to prevent enumeration.
        return Response(
            {
                'message': "If that account exists, we've sent a password reset link to the email on file.",
            }
        )


class UserMeView(APIView):
    def get(self, request):
        user = request.user
        employee = get_employee_from_user(user)

        if not employee:
            return Response({'error': 'Employee profile not found'}, status=status.HTTP_404_NOT_FOUND)

        work_info = EmployeeWorkInformation.objects.filter(employee_id_id=employee.id).first()
        department = ''
        designation = ''
        date_joining = None
        reporting_manager = None

        if work_info:
            if work_info.department_id_id:
                dept = Department.objects.filter(id=work_info.department_id_id).first()
                department = dept.department if dept else ''
            if work_info.job_position_id_id:
                jp = JobPosition.objects.filter(id=work_info.job_position_id_id).first()
                designation = jp.job_position if jp else ''
            date_joining = work_info.date_joining
            if work_info.reporting_manager_id_id:
                reporting_emp = get_employee_by_id(work_info.reporting_manager_id_id)
                if reporting_emp:
                    reporting_manager = {
                        'id': str(reporting_emp.id),
                        'name': reporting_emp.name,
                        'employee_id': reporting_emp.badge_id or str(reporting_emp.id),
                    }

        # Determine role: superuser > hr > manager > employee.
        if user.is_superuser:
            role = 'admin'
        elif user.is_staff:
            role = 'hr'
        elif EmployeeWorkInformation.objects.filter(reporting_manager_id_id=employee.id).exists():
            role = 'manager'
        else:
            role = 'employee'

        # Gather additional work info fields
        shift_name = ''
        work_type_name = ''
        location = ''
        basic_salary = None
        salary_hour = None
        contract_end = None
        experience = employee.experience or ''

        if work_info:
            if work_info.shift_id_id:
                shift = Shift.objects.filter(id=work_info.shift_id_id).first()
                shift_name = shift.employee_shift if shift else ''
            if work_info.work_type_id_id:
                wt = WorkType.objects.filter(id=work_info.work_type_id_id).first()
                work_type_name = wt.work_type if wt else ''
            location = work_info.location or ''
            basic_salary = float(work_info.basic_salary) if work_info.basic_salary else None
            salary_hour = float(work_info.salary_hour) if work_info.salary_hour else None
            contract_end = work_info.contract_end_date.isoformat() if work_info.contract_end_date else None

        return Response(
            {
                'id': str(user.id),
                'employee_id': employee.badge_id or str(employee.id),
                'name': employee.name,
                'email': user.email,
                'phone': employee.phone or '',
                'role': role,
                'designation': designation,
                'department': department,
                'date_of_joining': date_joining.isoformat() if date_joining else None,
                'reporting_manager': reporting_manager,
                'avatar_url': employee.avatar_url,
                'dob': employee.dob.isoformat() if employee.dob else None,
                'gender': employee.gender or '',
                'address': employee.address or '',
                'marital_status': employee.marital_status or '',
                'qualification': employee.qualification or '',
                'emergency_contact': employee.emergency_contact or '',
                'emergency_contact_name': employee.emergency_contact_name or '',
                'children': employee.children or '',
                'experience': experience,
                # Work information
                'shift': shift_name,
                'work_type': work_type_name,
                'location': location,
                'basic_salary': basic_salary,
                'salary_per_hour': salary_hour,
                'contract_end_date': contract_end,
                'company': 'PPulse Technologies',
            }
        )

    def put(self, request):
        serializer = UserProfileUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        employee = get_employee_from_user(request.user)

        if not employee:
            return Response({'error': 'Employee profile not found'}, status=status.HTTP_404_NOT_FOUND)

        if 'name' in serializer.validated_data:
            name = serializer.validated_data['name'].split(' ', 1)
            employee.employee_first_name = name[0]
            employee.employee_last_name = name[1] if len(name) > 1 else ''

        if 'phone' in serializer.validated_data:
            employee.phone = serializer.validated_data['phone']

        employee.save()

        return Response({'message': 'Profile updated successfully'})


class AvatarUploadView(APIView):
    def post(self, request):
        employee = get_employee_from_user(request.user)

        if not employee:
            return Response({'error': 'Employee profile not found'}, status=status.HTTP_404_NOT_FOUND)

        if 'file' not in request.FILES:
            return Response({'error': 'No file provided'}, status=status.HTTP_400_BAD_REQUEST)

        # employee_profile is a TextField, store the path as string
        uploaded_file = request.FILES['file']
        file_path = f'media/avatars/{uploaded_file.name}'
        employee.employee_profile = file_path
        employee.save()

        return Response({'avatar_url': file_path})


def _is_mobile_source(source):
    """Mobile sources can punch in/out via the app"""
    return source in ('mobile_ios', 'mobile_android', 'mobile')


def _is_biometric_source(source):
    return source == 'biometric'


# ── Office geofence ──────────────────────────────────────────────
# Office geofences are now stored in the `api_geofence` table and managed via
# the admin Settings → Geofences screen. The legacy hardcoded list below is
# kept only as a seed reference and is no longer consulted at runtime.
OFFICE_LOCATIONS = [
    {
        'name': 'Olympia Pinnacle (Smartworks) - Thoraipakkam',
        'latitude': 12.950602068524807,
        'longitude': 80.2409548690872,
        'radius_meters': 50,
    },
]

# WFH (Work-From-Home) face-verified punch-in zones.
# Empty list = WFH face punch-in allowed from anywhere outside the office geofence.
# Populate this list with home/co-working locations to enforce specific zones.
WFH_ALLOWED_LOCATIONS = []


def _haversine_meters(lat1, lon1, lat2, lon2):
    """Distance between two lat/lng points in meters."""
    import math

    R = 6371000.0  # Earth radius in meters
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


def _office_for_location(lat, lng):
    """Return the office geofence dict if (lat,lng) is within any active office
    radius, else None.  Includes ``has_biometric`` so callers can decide
    whether to block mobile punch-in or allow it.
    """
    if lat is None or lng is None:
        return None
    try:
        lat_f = float(lat)
        lng_f = float(lng)
    except (TypeError, ValueError):
        return None
    from .models import Geofence

    try:
        zones = Geofence.objects.filter(is_office=True, is_active=True)
    except Exception:
        return None
    for z in zones:
        dist = _haversine_meters(lat_f, lng_f, z.latitude, z.longitude)
        if dist <= z.radius_meters:
            return {
                'id': z.id,
                'name': z.name,
                'latitude': z.latitude,
                'longitude': z.longitude,
                'radius_meters': z.radius_meters,
                'has_biometric': z.has_biometric,
            }
    return None


def _wfh_zone_for_location(lat, lng):
    """Return the matching WFH zone dict.

    If WFH_ALLOWED_LOCATIONS is empty, WFH is allowed from anywhere (returns a
    default sentinel). Otherwise (lat,lng) must fall inside one of the configured
    radii or this returns None.
    """
    if not WFH_ALLOWED_LOCATIONS:
        return {'name': 'WFH (anywhere outside office)'}
    if lat is None or lng is None:
        return None
    try:
        lat_f = float(lat)
        lng_f = float(lng)
    except (TypeError, ValueError):
        return None
    for zone in WFH_ALLOWED_LOCATIONS:
        dist = _haversine_meters(lat_f, lng_f, zone['latitude'], zone['longitude'])
        if dist <= zone['radius_meters']:
            return zone
    return None


class AttendancePunchInView(APIView):
    def post(self, request):
        serializer = PunchInSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        today = date.today()
        source = data.get('source', 'mobile')

        existing = Attendance.objects.filter(employee_id_id=employee.id, attendance_date=today).first()
        if existing and existing.attendance_clock_in is not None:
            # Check if previous punch was via biometric — block mobile re-punch
            if _is_biometric_source(existing.punch_in_source) and _is_mobile_source(source):
                return Response(
                    {
                        'error': {
                            'code': 'BIOMETRIC_PUNCH_ACTIVE',
                            'message': 'You are already punched in via biometric device. Cannot punch in from mobile.',
                            'source': existing.punch_in_source,
                        }
                    },
                    status=status.HTTP_403_FORBIDDEN,
                )
            return Response(
                {'error': {'code': 'ALREADY_PUNCHED_IN', 'message': 'Already clocked in today'}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Geofence check: if employee is inside an office zone that has a
        # biometric device, block mobile punch-in (must use biometric on-site).
        # Offices without biometric allow mobile check-in within the geofence.
        if _is_mobile_source(source):
            office = _office_for_location(data.get('latitude'), data.get('longitude'))
            if office is not None and office.get('has_biometric'):
                return Response(
                    {
                        'error': {
                            'code': 'GEOFENCE_OFFICE',
                            'message': f'You are at {office["name"]}. Please punch in using the biometric device.',
                            'office': office['name'],
                        }
                    },
                    status=status.HTTP_403_FORBIDDEN,
                )

        now = timezone.now()

        # Capture metadata silently
        meta = {
            'punch_in_source': source,
            'punch_in_lat': data.get('latitude'),
            'punch_in_lng': data.get('longitude'),
            'punch_in_location': data.get('location_name', ''),
            'punch_in_device': data.get('device_info', ''),
        }

        if existing:
            existing.attendance_clock_in = now.time()
            existing.attendance_clock_in_date = today
            for k, v in meta.items():
                setattr(existing, k, v)
            existing.save()
            attendance = existing
        else:
            attendance = Attendance.objects.create(
                employee_id_id=employee.id,
                attendance_date=today,
                attendance_clock_in=now.time(),
                attendance_clock_in_date=today,
                is_active=True,
                minimum_hour='00:00',
                attendance_overtime='00:00',
                attendance_overtime_approve=False,
                attendance_validated=False,
                approved_overtime_second=0,
                is_validate_request=False,
                is_bulk_request=False,
                is_validate_request_approved=False,
                is_holiday=False,
                excluded_gaps='',
                **meta,
            )

        return Response(
            {
                'id': str(attendance.id),
                'employee_id': employee.badge_id or str(employee.id),
                'punch_in': attendance.attendance_clock_in.isoformat(),
                'punch_out': attendance.attendance_clock_out.isoformat()
                if attendance.attendance_clock_out
                else None,
                'status': attendance.computed_status,
                'source': attendance.punch_in_source,
                'method': data.get('method', 'password'),
            }
        )


class AttendanceFaceVerifyPunchInView(APIView):
    """WFH face-verified punch-in.

    Steps:
      1. Validate payload (image required).
      2. Block if user is currently inside the office geofence (must use biometric).
      3. Require user is inside an allowed WFH zone.
      4. Run face verification — must match the authenticated employee.
      5. Reject duplicate / biometric-active sessions like the regular punch-in view.
      6. Create / update today's Attendance row with method='face'.
    """

    def post(self, request):
        from .face_verification import verify as face_verify
        from .serializers import FaceVerifyPunchInSerializer

        serializer = FaceVerifyPunchInSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        source = data.get('source', 'mobile')
        lat = data.get('latitude')
        lng = data.get('longitude')

        import logging as _log

        _log.getLogger(__name__).info(
            'FACE_PUNCH_IN emp=%s source=%s lat=%s lng=%s device=%r',
            employee.id,
            source,
            lat,
            lng,
            data.get('device_info', ''),
        )

        # 0. Location is mandatory for the WFH face flow — without it we can't
        #    enforce the office geofence and the audit trail is meaningless.
        if lat is None or lng is None:
            return Response(
                {
                    'error': {
                        'code': 'LOCATION_REQUIRED',
                        'message': 'Location permission is required for face check-in. Enable it in Settings.',
                    }
                },
                status=status.HTTP_403_FORBIDDEN,
            )

        # 1. Office geofence — block only when the office has a biometric device.
        if _is_mobile_source(source):
            office = _office_for_location(lat, lng)
            if office is not None and office.get('has_biometric'):
                return Response(
                    {
                        'error': {
                            'code': 'GEOFENCE_OFFICE',
                            'message': f'You are at {office["name"]}. Please punch in using the biometric device.',
                            'office': office['name'],
                        }
                    },
                    status=status.HTTP_403_FORBIDDEN,
                )

        # 2. WFH zone enforcement.
        zone = _wfh_zone_for_location(lat, lng)
        if zone is None:
            return Response(
                {
                    'error': {
                        'code': 'WFH_OUT_OF_ZONE',
                        'message': 'You are not within an authorized work-from-home zone.',
                    }
                },
                status=status.HTTP_403_FORBIDDEN,
            )

        # 3. Duplicate / biometric-active session checks (mirror PunchInView).
        today = date.today()
        existing = Attendance.objects.filter(employee_id_id=employee.id, attendance_date=today).first()
        if existing and existing.attendance_clock_in is not None:
            if _is_biometric_source(existing.punch_in_source) and _is_mobile_source(source):
                return Response(
                    {
                        'error': {
                            'code': 'BIOMETRIC_PUNCH_ACTIVE',
                            'message': 'You are already punched in via biometric device. Cannot punch in from mobile.',
                            'source': existing.punch_in_source,
                        }
                    },
                    status=status.HTTP_403_FORBIDDEN,
                )
            return Response(
                {'error': {'code': 'ALREADY_PUNCHED_IN', 'message': 'Already clocked in today'}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 4. Face verification (with multi-frame liveness when available).
        extra_frames = data.get('extra_frames')  # list of base64 strings
        result = face_verify(data['image'], extra_frames=extra_frames)
        import logging as _log

        _log.getLogger(__name__).info(
            'FACE_VERIFY emp=%s authed_emp=%s matched=%s conf=%.4f reason=%s elapsed=%.0fms',
            result.employee_id,
            employee.id,
            result.matched,
            result.confidence,
            result.reason,
            result.elapsed_ms,
        )
        if not result.matched:
            write_audit(
                request,
                action='face_punch_in_failed',
                target_type='Employee',
                target_id=employee.id,
                target_user_id=employee.id,
                target_name=employee.name,
                payload={
                    'reason': result.reason,
                    'confidence': round(result.confidence, 4),
                    'lat': lat,
                    'lng': lng,
                },
            )
            return Response(
                {
                    'error': {
                        'code': 'FACE_VERIFICATION_FAILED',
                        'message': 'Face verification failed',
                        'reason': result.reason,
                        'confidence': round(result.confidence, 4),
                        'elapsed_ms': round(result.elapsed_ms, 1),
                    }
                },
                status=status.HTTP_403_FORBIDDEN,
            )

        # Compare as ints to avoid str/int mismatch silently passing the check.
        try:
            matched_id = int(result.employee_id) if result.employee_id is not None else None
            authed_id = int(employee.id)
        except (TypeError, ValueError):
            matched_id, authed_id = result.employee_id, employee.id

        if matched_id != authed_id:
            write_audit(
                request,
                action='face_punch_in_mismatch',
                target_type='Employee',
                target_id=employee.id,
                target_user_id=employee.id,
                target_name=employee.name,
                payload={
                    'matched_employee_id': matched_id,
                    'confidence': round(result.confidence, 4),
                    'lat': lat,
                    'lng': lng,
                },
            )
            # Face matched a different enrolled employee — reject as imposter.
            return Response(
                {
                    'error': {
                        'code': 'FACE_MISMATCH',
                        'message': 'Face does not match this account',
                        'reason': 'face_does_not_match_user',
                        'confidence': round(result.confidence, 4),
                        'elapsed_ms': round(result.elapsed_ms, 1),
                    }
                },
                status=status.HTTP_403_FORBIDDEN,
            )

        # 5. All checks passed — record the punch.
        now = timezone.now()
        meta = {
            'punch_in_source': source,
            'punch_in_lat': lat,
            'punch_in_lng': lng,
            'punch_in_location': data.get('location_name', '') or zone['name'],
            'punch_in_device': data.get('device_info', ''),
        }

        if existing:
            existing.attendance_clock_in = now.time()
            existing.attendance_clock_in_date = today
            for k, v in meta.items():
                setattr(existing, k, v)
            existing.save()
            attendance = existing
        else:
            attendance = Attendance.objects.create(
                employee_id_id=employee.id,
                attendance_date=today,
                attendance_clock_in=now.time(),
                attendance_clock_in_date=today,
                is_active=True,
                minimum_hour='00:00',
                attendance_overtime='00:00',
                attendance_overtime_approve=False,
                attendance_validated=False,
                approved_overtime_second=0,
                is_validate_request=False,
                is_bulk_request=False,
                is_validate_request_approved=False,
                is_holiday=False,
                excluded_gaps='',
                **meta,
            )

        write_audit(
            request,
            action='face_punch_in_succeeded',
            target_type='Attendance',
            target_id=attendance.id,
            target_user_id=employee.id,
            target_name=employee.name,
            payload={
                'confidence': round(result.confidence, 4),
                'lat': lat,
                'lng': lng,
                'source': source,
            },
        )

        return Response(
            {
                'id': str(attendance.id),
                'employee_id': employee.badge_id or str(employee.id),
                'punch_in': attendance.attendance_clock_in.isoformat(),
                'punch_out': attendance.attendance_clock_out.isoformat()
                if attendance.attendance_clock_out
                else None,
                'status': attendance.computed_status,
                'source': attendance.punch_in_source,
                'method': 'face',
                'face': {
                    'confidence': round(result.confidence, 4),
                    'elapsed_ms': round(result.elapsed_ms, 1),
                    'zone': zone['name'],
                },
            }
        )


class AttendancePunchOutView(APIView):
    def post(self, request):
        serializer = PunchOutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        today = date.today()
        source = data.get('source', 'mobile')

        attendance = Attendance.objects.filter(employee_id_id=employee.id, attendance_date=today).first()
        if not attendance or attendance.attendance_clock_in is None:
            return Response(
                {'error': {'code': 'NOT_PUNCHED_IN', 'message': 'Cannot punch out without punching in'}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Block mobile punch-out if punched in via biometric
        if _is_biometric_source(attendance.punch_in_source) and _is_mobile_source(source):
            return Response(
                {
                    'error': {
                        'code': 'BIOMETRIC_PUNCH_ACTIVE',
                        'message': 'You punched in via biometric device. Please punch out using the biometric device.',
                        'source': attendance.punch_in_source,
                    }
                },
                status=status.HTTP_403_FORBIDDEN,
            )

        now = timezone.now()
        attendance.attendance_clock_out = now.time()
        attendance.attendance_clock_out_date = today

        # Capture punch-out metadata silently
        attendance.punch_out_source = source
        attendance.punch_out_lat = data.get('latitude')
        attendance.punch_out_lng = data.get('longitude')
        attendance.punch_out_location = data.get('location_name', '')
        attendance.punch_out_device = data.get('device_info', '')

        if attendance.attendance_clock_in:
            in_seconds = (
                attendance.attendance_clock_in.hour * 3600 + attendance.attendance_clock_in.minute * 60
            )
            out_seconds = now.hour * 3600 + now.minute * 60
            worked_seconds = max(0, out_seconds - in_seconds)
            hours = worked_seconds // 3600
            minutes = (worked_seconds % 3600) // 60
            attendance.attendance_worked_hour = f'{hours:02d}:{minutes:02d}'

        attendance.save()

        return Response(
            {
                'id': str(attendance.id),
                'punch_in': attendance.attendance_clock_in.isoformat(),
                'punch_out': attendance.attendance_clock_out.isoformat(),
                'total_hours': attendance.attendance_worked_hour or '00:00',
                'status': attendance.computed_status,
                'source': attendance.punch_out_source,
            }
        )


class AttendanceTodayView(APIView):
    def get(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        today = date.today()
        attendance = Attendance.objects.filter(employee_id_id=employee.id, attendance_date=today).first()

        if not attendance:
            return Response(
                {
                    'id': None,
                    'punch_in': None,
                    'punch_out': None,
                    'status': 'not_clocked_in',
                    'total_hours': '00:00',
                    'method': None,
                    'source': None,
                    'can_punch_via_mobile': True,
                }
            )

        can_mobile = True
        if attendance.is_checked_in and _is_biometric_source(attendance.punch_in_source):
            can_mobile = False

        return Response(
            {
                'id': str(attendance.id),
                'punch_in': attendance.attendance_clock_in.isoformat()
                if attendance.attendance_clock_in
                else None,
                'punch_out': attendance.attendance_clock_out.isoformat()
                if attendance.attendance_clock_out
                else None,
                'status': attendance.computed_status,
                'total_hours': attendance.attendance_worked_hour or '00:00',
                'method': None,
                'source': attendance.punch_in_source,
                'can_punch_via_mobile': can_mobile,
            }
        )


class AttendanceMonthlyView(APIView):
    def get(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        month = int(request.query_params.get('month', datetime.now().month))
        year = int(request.query_params.get('year', datetime.now().year))

        _, days_in_month = monthrange(year, month)

        start_date = date(year, month, 1)
        end_date = date(year, month, days_in_month)

        attendances = Attendance.objects.filter(
            employee_id_id=employee.id, attendance_date__gte=start_date, attendance_date__lte=end_date
        )

        attendances_dict = {att.attendance_date: att for att in attendances}

        present = 0
        absent = 0
        leave = 0
        half_days = 0

        daily = []
        for day in range(1, days_in_month + 1):
            day_date = date(year, month, day)
            weekday = day_date.weekday()

            if weekday >= 5:
                status_val = 'weekend'
                punch_in = None
                punch_out = None
                total_hours = None
            elif day_date in attendances_dict:
                att = attendances_dict[day_date]
                if att.is_checked_out:
                    status_val = 'present'
                    present += 1
                    punch_in = att.attendance_clock_in.isoformat() if att.attendance_clock_in else None
                    punch_out = att.attendance_clock_out.isoformat() if att.attendance_clock_out else None
                    total_hours = att.attendance_worked_hour
                elif att.is_checked_in:
                    status_val = 'present'
                    present += 1
                    punch_in = att.attendance_clock_in.isoformat() if att.attendance_clock_in else None
                    punch_out = None
                    total_hours = None
                else:
                    status_val = 'absent'
                    absent += 1
                    punch_in = None
                    punch_out = None
                    total_hours = None
            elif day_date > date.today():
                status_val = 'upcoming'
                punch_in = None
                punch_out = None
                total_hours = None
            else:
                status_val = 'absent'
                absent += 1
                punch_in = None
                punch_out = None
                total_hours = None

            # Extra fields for the attendance log table
            shift_name = ''
            work_type_name = ''
            min_hour = '00:00'
            overtime = '00:00'
            out_date = None
            if day_date in attendances_dict:
                att = attendances_dict[day_date]
                min_hour = att.minimum_hour or '00:00'
                overtime = att.attendance_overtime or '00:00'
                if att.attendance_clock_out_date:
                    out_date = att.attendance_clock_out_date.isoformat()
                if att.shift_id_id:
                    s = Shift.objects.filter(id=att.shift_id_id).first()
                    shift_name = s.employee_shift if s else ''
                if att.work_type_id_id:
                    wt = WorkType.objects.filter(id=att.work_type_id_id).first()
                    work_type_name = wt.work_type if wt else ''

            daily.append(
                {
                    'date': day_date.isoformat(),
                    'status': status_val,
                    'punch_in': punch_in,
                    'punch_out': punch_out,
                    'out_date': out_date,
                    'total_hours': total_hours,
                    'shift': shift_name,
                    'work_type': work_type_name,
                    'min_hour': min_hour,
                    'overtime': overtime,
                }
            )

        working_days = present + absent + leave + half_days

        return Response(
            {
                'summary': {
                    'working_days': working_days,
                    'present': present,
                    'absent': absent,
                    'leave': leave,
                    'holidays': 0,
                    'half_days': half_days,
                    'on_duty': 0,
                },
                'daily': daily,
            }
        )


class AttendanceWeeklyView(APIView):
    def get(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        week_start_str = request.query_params.get('week_start')
        if week_start_str:
            week_start = datetime.strptime(week_start_str, '%Y-%m-%d').date()
        else:
            today = date.today()
            week_start = today - timedelta(days=today.weekday())

        week_end = week_start + timedelta(days=6)

        attendances = Attendance.objects.filter(
            employee_id_id=employee.id, attendance_date__gte=week_start, attendance_date__lte=week_end
        )

        present = 0
        absent = 0
        leave = 0
        daily_hours = []
        punch_times = []

        for i in range(7):
            day = week_start + timedelta(days=i)
            weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i]

            att = attendances.filter(attendance_date=day).first()

            if att and att.attendance_clock_in is not None:
                present += 1
                # Calculate hours from clock times (more reliable than attendance_worked_hour)
                hours = 0
                if att.attendance_clock_in and att.attendance_clock_out:
                    from datetime import datetime as dt

                    cin = dt.combine(day, att.attendance_clock_in)
                    cout = dt.combine(day, att.attendance_clock_out)
                    diff = (cout - cin).total_seconds() / 3600
                    hours = max(0, min(diff, 24))  # clamp 0-24
                elif att.attendance_worked_hour:
                    try:
                        parts = att.attendance_worked_hour.split(':')
                        h = int(parts[0])
                        m = int(parts[1]) if len(parts) > 1 else 0
                        hours = min(h + m / 60, 24)  # clamp to 24
                    except (ValueError, IndexError):
                        hours = 0
                hours = round(hours, 2)
                daily_hours.append({'day': weekday, 'hours': hours})
                punch_in_val = (
                    att.attendance_clock_in.hour + att.attendance_clock_in.minute / 60
                    if att.attendance_clock_in
                    else 0
                )
                punch_out_val = (
                    att.attendance_clock_out.hour + att.attendance_clock_out.minute / 60
                    if att.attendance_clock_out
                    else 0
                )
                punch_times.append(
                    {'day': weekday, 'punch_in': round(punch_in_val, 2), 'punch_out': round(punch_out_val, 2)}
                )
            else:
                absent += 1
                daily_hours.append({'day': weekday, 'hours': 0})
                punch_times.append({'day': weekday, 'punch_in': 0, 'punch_out': 0})

        return Response(
            {
                'weeks': [
                    {'week': f'Week of {week_start}', 'present': present, 'absent': absent, 'leave': leave}
                ],
                'daily_hours': daily_hours,
                'punch_times': punch_times,
            }
        )


class AttendanceTeamView(APIView):
    """Return today's attendance for the manager's direct reports.

    Includes per-employee: check-in/out time, location name, work type,
    punch source, and status.  Filtered by reporting_manager so each
    manager only sees their own team.  Admins see everyone.
    """

    def get(self, request):
        employee = get_employee_from_user(request.user)
        today = date.today()

        # Determine which employees this user manages.
        if request.user.is_superuser:
            team_emp_ids = list(Employee.objects.filter(is_active=True).values_list('id', flat=True))
        elif employee:
            team_emp_ids = list(
                EmployeeWorkInformation.objects.filter(
                    reporting_manager_id_id=employee.id,
                ).values_list('employee_id_id', flat=True)
            )
        else:
            team_emp_ids = []

        team = list(Employee.objects.filter(id__in=team_emp_ids, is_active=True))

        # Batch-fetch today's attendance for the whole team.
        att_map = {}
        for att in Attendance.objects.filter(
            employee_id_id__in=team_emp_ids,
            attendance_date=today,
        ):
            att_map[att.employee_id_id] = att

        # Batch-fetch approved leaves covering today.
        leave_emp_ids = set(
            LeaveRequest.objects.filter(
                status='approved',
                employee_id_id__in=team_emp_ids,
                start_date__lte=today,
                end_date__gte=today,
            ).values_list('employee_id_id', flat=True)
        )

        present = 0
        absent = 0
        on_leave = 0
        members = []

        for emp in team:
            att = att_map.get(emp.id)
            if emp.id in leave_emp_ids:
                status_val = 'on_leave'
                on_leave += 1
            elif att and att.attendance_clock_in is not None:
                status_val = 'present'
                present += 1
            else:
                status_val = 'absent'
                absent += 1

            # Work type from EmployeeWorkInformation (office / remote / hybrid).
            wi = EmployeeWorkInformation.objects.filter(employee_id_id=emp.id).first()
            work_type = ''
            department = ''
            if wi:
                work_type = wi.work_type or ''
                if wi.department_id_id:
                    dept = Department.objects.filter(id=wi.department_id_id).first()
                    department = dept.department if dept else ''

            members.append(
                {
                    'employee_id': emp.badge_id or str(emp.id),
                    'name': f'{emp.employee_first_name} {emp.employee_last_name}'.strip() or emp.name,
                    'status': status_val,
                    'department': department,
                    'work_type': work_type,
                    'punch_in': att.attendance_clock_in.isoformat()
                    if att and att.attendance_clock_in
                    else None,
                    'punch_out': att.attendance_clock_out.isoformat()
                    if att and att.attendance_clock_out
                    else None,
                    'punch_in_location': getattr(att, 'punch_in_location', None) or '' if att else '',
                    'punch_in_source': getattr(att, 'punch_in_source', None) or '' if att else '',
                }
            )

        return Response(
            {
                'total_employees': len(team),
                'present_today': present,
                'absent_today': absent,
                'on_leave_today': on_leave,
                'team_members': members,
            }
        )


class LeaveBalanceView(APIView):
    def get(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        available_leaves = AvailableLeave.objects.filter(employee_id_id=employee.id)

        balances = []
        total_remaining = 0

        for leave in available_leaves:
            leave_type = LeaveType.objects.filter(id=leave.leave_type_id_id).first()
            label = leave_type.name if leave_type else 'Unknown'
            total = leave.total_leave_days or 0
            used = leave.used_days
            remaining = leave.remaining_days

            balances.append(
                {
                    'type': str(leave.leave_type_id_id),
                    'label': label,
                    'total': total,
                    'used': used,
                    'remaining': remaining,
                }
            )
            total_remaining += remaining

        return Response({'balances': balances, 'total_remaining': total_remaining})


class LeaveApplyView(APIView):
    def post(self, request):
        serializer = LeaveApplySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        leave_type_val = serializer.validated_data['leave_type']
        leave_type = LeaveType.objects.filter(name__iexact=leave_type_val).first()
        if not leave_type:
            leave_type = (
                LeaveType.objects.filter(id=leave_type_val).first() if leave_type_val.isdigit() else None
            )
        if not leave_type:
            return Response({'error': 'Invalid leave type'}, status=status.HTTP_400_BAD_REQUEST)

        available = AvailableLeave.objects.filter(
            employee_id_id=employee.id, leave_type_id_id=leave_type.id
        ).first()

        start_date = serializer.validated_data['start_date']
        end_date = serializer.validated_data.get('end_date') or start_date

        requested_days = (end_date - start_date).days + 1

        if available and (available.available_days or 0) < requested_days:
            return Response(
                {'error': {'code': 'LEAVE_INSUFFICIENT', 'message': 'Insufficient leave balance'}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        leave_request = LeaveRequest.objects.create(
            employee_id_id=employee.id,
            leave_type_id_id=leave_type.id,
            start_date=start_date,
            start_date_breakdown=serializer.validated_data.get('start_breakdown', 'full_day'),
            end_date=end_date,
            end_date_breakdown=serializer.validated_data.get('end_breakdown', 'full_day'),
            requested_days=requested_days,
            description=serializer.validated_data.get('description', ''),
            status='requested',
        )

        # Notify employee and manager
        create_notification(
            request.user.id, 'Leave Request Submitted', f'{leave_type.name} from {start_date} to {end_date}'
        )
        notify_managers_of_request(employee, 'Leave', f'{leave_type.name} Leave')

        # CC list — fire read-only notifications.
        save_cc_for_request(
            'Leave',
            leave_request.id,
            request.data.get('cc') or [],
            requester_name=employee.name,
            request_title=f'{leave_type.name} Leave',
        )

        return Response(
            {
                'id': str(leave_request.id),
                'request_id': get_request_id('LV', leave_request.id),
                'type': 'Leave',
                'title': f'{leave_type.name} Leave',
                'status': leave_request.status,
                'start_date': leave_request.start_date.isoformat(),
                'end_date': leave_request.end_date.isoformat() if leave_request.end_date else None,
                'description': leave_request.description,
            },
            status=status.HTTP_201_CREATED,
        )


class ClaimSubmitView(APIView):
    def post(self, request):
        serializer = ClaimSubmitSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        # Create as a ticket with claim type
        title = serializer.validated_data['title']
        desc = serializer.validated_data.get('description', '')
        amount = serializer.validated_data.get('amount', 0)
        claim_type = serializer.validated_data.get('claim_type', 'other')

        default_type = TicketType.objects.first()
        ticket_type_id = default_type.id if default_type else 1

        ticket = Ticket.objects.create(
            employee_id_id=employee.id,
            title=f'[Claim] {title}',
            description=f'Type: {claim_type}\nAmount: {amount}\n{desc}',
            priority='medium',
            status='open',
            created_date=date.today(),
            assigning_type='direct',
            raised_on='other',
            ticket_type_id=ticket_type_id,
        )

        # Create claim approval record
        ClaimRequest.objects.create(
            employee_id_id=employee.id,
            ticket_id_id=ticket.id,
            is_approved=False,
            is_rejected=False,
        )

        create_notification(request.user.id, 'Claim Submitted', f'{title} - {amount}')
        notify_managers_of_request(employee, 'Claim', title)
        save_cc_for_request(
            'Claims',
            ticket.id,
            request.data.get('cc') or [],
            requester_name=employee.name,
            request_title=title,
        )

        return Response(
            {
                'id': str(ticket.id),
                'request_id': get_request_id('CL', ticket.id),
                'type': 'Claims',
                'title': title,
                'status': 'requested',
                'amount': float(amount) if amount else 0,
            },
            status=status.HTTP_201_CREATED,
        )


class TicketRaiseView(APIView):
    def post(self, request):
        serializer = TicketRaiseSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        # Get default ticket type
        default_type = TicketType.objects.first()
        ticket_type_id = default_type.id if default_type else 1

        ticket = Ticket.objects.create(
            employee_id_id=employee.id,
            title=serializer.validated_data['title'],
            description=serializer.validated_data['description'],
            priority=serializer.validated_data['priority'],
            status='open',
            created_date=date.today(),
            assigning_type='direct',
            raised_on='other',
            ticket_type_id=ticket_type_id,
        )
        save_cc_for_request(
            'Tickets',
            ticket.id,
            request.data.get('cc') or [],
            requester_name=employee.name,
            request_title=ticket.title,
        )

        return Response(
            {
                'id': str(ticket.id),
                'request_id': get_request_id('TK', ticket.id),
                'type': 'Tickets',
                'title': ticket.title,
                'status': ticket.status,
                'priority': ticket.priority,
            },
            status=status.HTTP_201_CREATED,
        )


class ShiftRequestView(APIView):
    def post(self, request):
        serializer = ShiftRequestCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        shift_val = serializer.validated_data['requesting_shift']
        shift = Shift.objects.filter(employee_shift__iexact=shift_val).first()
        if not shift:
            try:
                shift = Shift.objects.filter(id=int(shift_val)).first()
            except (ValueError, TypeError):
                pass
        if not shift:
            return Response({'error': 'Invalid shift type'}, status=status.HTTP_400_BAD_REQUEST)

        shift_request = ShiftRequestModel.objects.create(
            employee_id_id=employee.id,
            shift_id_id=shift.id,
            requested_date=serializer.validated_data['requested_date'],
            requested_till=serializer.validated_data.get('requested_till'),
            description=serializer.validated_data.get('description', ''),
            approved=False,
            canceled=False,
        )
        save_cc_for_request(
            'Shift Requests',
            shift_request.id,
            request.data.get('cc') or [],
            requester_name=employee.name,
            request_title=f'Shift Change to {shift.employee_shift}',
        )

        return Response(
            {
                'id': str(shift_request.id),
                'request_id': get_request_id('SR', shift_request.id),
                'type': 'Shift Requests',
                'title': f'Shift Change to {shift.employee_shift}',
                'status': shift_request.status,
                'shift_details': {'name': shift.employee_shift, 'timing': shift.full_time},
                'from_date': shift_request.requested_date.isoformat()
                if shift_request.requested_date
                else None,
                'to_date': shift_request.requested_till.isoformat() if shift_request.requested_till else None,
            },
            status=status.HTTP_201_CREATED,
        )


class WorkTypeRequestView(APIView):
    def post(self, request):
        serializer = WorkTypeRequestCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        wt_val = serializer.validated_data['work_type']
        work_type = WorkType.objects.filter(work_type__iexact=wt_val).first()
        if not work_type:
            try:
                work_type = WorkType.objects.filter(id=int(wt_val)).first()
            except (ValueError, TypeError):
                pass
        if not work_type:
            return Response({'error': 'Invalid work type'}, status=status.HTTP_400_BAD_REQUEST)

        work_request = WorkTypeRequestModel.objects.create(
            employee_id_id=employee.id,
            work_type_id_id=work_type.id,
            requested_date=serializer.validated_data['requested_date'],
            requested_till=serializer.validated_data.get('requested_till'),
            description=serializer.validated_data.get('description', ''),
            approved=False,
            canceled=False,
        )
        save_cc_for_request(
            'Work Type Requests',
            work_request.id,
            request.data.get('cc') or [],
            requester_name=employee.name,
            request_title=f'Work Type Change to {work_type.work_type}',
        )

        return Response(
            {
                'id': str(work_request.id),
                'request_id': get_request_id('WR', work_request.id),
                'type': 'Work Type Requests',
                'title': f'Work Type Change to {work_type.work_type}',
                'status': work_request.status,
                'work_type': work_type.work_type,
                'from_date': work_request.requested_date.isoformat() if work_request.requested_date else None,
                'to_date': work_request.requested_till.isoformat() if work_request.requested_till else None,
            },
            status=status.HTTP_201_CREATED,
        )


class AttendanceRegularizeView(APIView):
    def post(self, request):
        serializer = AttendanceRegularizeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        data = serializer.validated_data
        att_date = data['attendance_date']
        att_request = AttendanceRequestModel.objects.create(
            employee_id=employee.id,
            requested_date=att_date,
            from_time=data.get('requested_check_in') or None,
            to_time=data.get('requested_check_out') or None,
            reason=data.get('reason', ''),
            attendance_type=data.get('attendance_type', ''),
            shift_name=data.get('shift', '') or None,
            attachment_name=data.get('attachment_name', '') or None,
            status='requested',
            created_at=timezone.now(),
        )
        save_cc_for_request(
            'Attendance Requests',
            att_request.id,
            request.data.get('cc') or [],
            requester_name=employee.name,
            request_title=f'{att_request.attendance_type or "Regularization"} for {att_date}',
        )

        return Response(
            {
                'id': str(att_request.id),
                'request_id': get_request_id('AR', att_request.id),
                'type': 'Attendance Requests',
                'title': f'{att_request.attendance_type or "Attendance Regularization"} for {att_date}',
                'status': 'requested',
                'attendance_date': att_date.isoformat(),
                'attendance_type': att_request.attendance_type,
                'shift': att_request.shift_name,
            },
            status=status.HTTP_201_CREATED,
        )


class AssetRequestView(APIView):
    def post(self, request):
        serializer = AssetRequestCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        cat_name = serializer.validated_data['asset_category']
        # Try to find category in DB, fall back to storing name in description
        cat_id = 1
        try:
            from django.db import connection

            with connection.cursor() as cursor:
                cursor.execute(
                    'SELECT id FROM asset_assetcategory WHERE asset_category_name = %s LIMIT 1', [cat_name]
                )
                row = cursor.fetchone()
                if row:
                    cat_id = row[0]
        except Exception:
            pass  # Table may not exist, use default

        desc = serializer.validated_data.get('description', '')
        asset_request = AssetRequestModel.objects.create(
            requested_employee_id_id=employee.id,
            asset_category_id_id=cat_id,
            asset_request_date=date.today(),
            description=f'[{cat_name}] {desc}' if cat_name else desc,
            asset_request_status='Requested',
        )
        save_cc_for_request(
            'Asset Requests',
            asset_request.id,
            request.data.get('cc') or [],
            requester_name=employee.name,
            request_title=f'{cat_name} Request',
        )

        return Response(
            {
                'id': str(asset_request.id),
                'request_id': get_request_id('AS', asset_request.id),
                'type': 'Asset Requests',
                'title': f'{cat_name} Request',
                'status': asset_request.status,
                'asset_category': cat_name,
            },
            status=status.HTTP_201_CREATED,
        )


class RequestsListView(APIView):
    def get(self, request):
        role = request.query_params.get('role', 'self')
        req_status = request.query_params.get('status', 'all')
        req_type = request.query_params.get('type', 'all')

        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        # Get direct report IDs for manager/hr filtering
        if role != 'self':
            if request.user.is_staff:
                # HR sees all requests except their own
                team_ids = list(Employee.objects.exclude(id=employee.id).values_list('id', flat=True))
            else:
                # Manager sees only direct reports' requests
                team_ids = list(
                    EmployeeWorkInformation.objects.filter(reporting_manager_id_id=employee.id).values_list(
                        'employee_id_id', flat=True
                    )
                )

        requests_list = []

        def get_items(model, type_name, emp_filter):
            try:
                if role == 'self':
                    qs = model.objects.filter(**emp_filter)
                else:
                    # Build team filter using the same field name as emp_filter
                    team_field = list(emp_filter.keys())[0]
                    qs = model.objects.filter(**{f'{team_field}__in': team_ids})
                # Filter by status - use property-based filtering for models without status column
                filtered = []
                for item in qs:
                    item_status = getattr(item, 'status', 'requested')
                    if (
                        (req_status == 'pending' and item_status != 'requested')
                        or (req_status == 'accepted' and item_status != 'approved')
                        or (req_status == 'rejected' and item_status != 'rejected')
                    ):
                        continue
                    filtered.append(item)
                return filtered
            except Exception:
                return []

        icon_map = {
            'Leave': 'calendar',
            'Claims': 'receipt',
            'Tickets': 'support',
            'Shift Requests': 'clock',
            'Work Type Requests': 'home',
            'Attendance Requests': 'fingerprint',
            'Asset Requests': 'devices',
        }
        color_map = {
            'Leave': '#4CAF50',
            'Claims': '#2196F3',
            'Tickets': '#FF9800',
            'Shift Requests': '#9C27B0',
            'Work Type Requests': '#00BCD4',
            'Attendance Requests': '#795548',
            'Asset Requests': '#607D8B',
        }

        # IDs of tickets that are linked to claims — exclude from Tickets list
        claim_ticket_ids = (
            set(
                ClaimRequest.objects.filter(employee_id_id=employee.id).values_list('ticket_id_id', flat=True)
            )
            if role == 'self'
            else set(
                ClaimRequest.objects.filter(
                    employee_id_id__in=team_ids if role != 'self' else [employee.id]
                ).values_list('ticket_id_id', flat=True)
            )
        )

        type_models = [
            ('Leave', LeaveRequest, {'employee_id_id': employee.id}),
            ('Claims', ClaimRequest, {'employee_id_id': employee.id}),
            ('Tickets', Ticket, {'employee_id_id': employee.id}),
            ('Shift Requests', ShiftRequestModel, {'employee_id_id': employee.id}),
            ('Work Type Requests', WorkTypeRequestModel, {'employee_id_id': employee.id}),
            ('Attendance Requests', AttendanceRequestModel, {'employee_id_id': employee.id}),
            ('Asset Requests', AssetRequestModel, {'requested_employee_id_id': employee.id}),
        ]

        # Cache reference data once per request to avoid N+1 lookups in metadata.
        leave_type_cache = {lt.id: (lt.name or '') for lt in LeaveType.objects.all()}
        work_type_cache = {wt.id: (wt.work_type or '') for wt in WorkType.objects.all()}
        shift_cache = {s.id: (s.employee_shift or '') for s in Shift.objects.all()}
        ticket_type_cache = {tt.id: (tt.title or '') for tt in TicketType.objects.all()}

        def _iso(v):
            if v is None:
                return None
            return v.isoformat() if hasattr(v, 'isoformat') else str(v)

        def _build_metadata(type_name, item):
            """Per-type extra fields that the manager approvals UI needs to render
            real cards (dates, leave type, ticket priority, work type names, etc.).
            All values are JSON-friendly primitives or null."""
            md = {}
            if type_name == 'Leave':
                md['leave_type'] = leave_type_cache.get(item.leave_type_id_id) or 'Leave'
                md['start_date'] = _iso(item.start_date)
                md['end_date'] = _iso(item.end_date)
                md['requested_days'] = item.requested_days
                md['reason'] = item.description or ''
                md['attachment'] = item.attachment or None
            elif type_name == 'Claims':
                # ClaimRequest is a flag-on-Ticket; pull display fields from the linked ticket.
                ticket = None
                if getattr(item, 'ticket_id_id', None):
                    ticket = Ticket.objects.filter(id=item.ticket_id_id).first()
                md['category'] = (ticket.title if ticket else None) or 'Claim'
                md['description'] = (ticket.description if ticket else '') or ''
                md['priority'] = ticket.priority if ticket else None
                md['ticket_id'] = str(ticket.id) if ticket else None
                md['amount'] = None  # not stored on the model
                md['has_receipt'] = None
            elif type_name == 'Tickets':
                md['priority'] = (item.priority or 'Medium').title()
                md['ticket_type'] = ticket_type_cache.get(item.ticket_type_id) or ''
                md['raised_on'] = item.raised_on or ''
            elif type_name == 'Shift Requests':
                md['shift'] = shift_cache.get(item.shift_id_id) or ''
                md['start_date'] = _iso(item.requested_date)
                md['end_date'] = _iso(item.requested_till)
                md['reason'] = item.description or ''
            elif type_name == 'Work Type Requests':
                md['work_type'] = work_type_cache.get(item.work_type_id_id) or 'Work From Home'
                # Current work type lives on EmployeeWorkInformation.
                current = ''
                wi = EmployeeWorkInformation.objects.filter(employee_id_id=item.employee_id_id).first()
                if wi and wi.work_type_id_id:
                    current = work_type_cache.get(wi.work_type_id_id) or ''
                md['current_work_type'] = current or 'Office'
                md['start_date'] = _iso(item.requested_date)
                md['end_date'] = _iso(item.requested_till)
                md['reason'] = item.description or ''
            elif type_name == 'Attendance Requests':
                md['date'] = _iso(item.requested_date)
                md['from_time'] = _iso(item.from_time)
                md['to_time'] = _iso(item.to_time)
                md['attendance_type'] = item.attendance_type or ''
                md['shift_name'] = item.shift_name or ''
                md['reason'] = item.reason or ''
            elif type_name == 'Asset Requests':
                md['date'] = _iso(item.asset_request_date)
                md['description'] = item.description or ''
                md['asset_category_id'] = item.asset_category_id_id
            return md

        for type_name, model, emp_filter in type_models:
            if req_type != 'all' and type_name != req_type:
                continue
            items = get_items(model, type_name, emp_filter)
            # Skip tickets that are actually claims (already listed under Claims)
            if type_name == 'Tickets':
                items = [t for t in items if t.id not in claim_ticket_ids]
            for item in items:
                emp_id = getattr(item, 'employee_id_id', None) or getattr(
                    item, 'requested_employee_id_id', None
                )
                emp = get_employee_by_id(emp_id) if emp_id else None
                emp_name = emp.name if emp else 'Unknown'
                emp_badge = (emp.badge_id or str(emp.id)) if emp else ''

                # Extract created date from various model fields
                item_date = (
                    getattr(item, 'created_at', None)
                    or getattr(item, 'created_date', None)
                    or getattr(item, 'asset_request_date', None)
                    or getattr(item, 'start_date', None)
                )
                if item_date:
                    date_str = item_date.isoformat() if hasattr(item_date, 'isoformat') else str(item_date)
                else:
                    date_str = ''

                metadata = {}
                try:
                    metadata = _build_metadata(type_name, item)
                except Exception:
                    metadata = {}

                # Build display title — strip [Claim] prefix for claim requests
                raw_title = getattr(item, 'title', None) or f'{type_name} Request'
                if type_name == 'Claims':
                    # ClaimRequest has no title; pull from linked ticket and clean it
                    ticket = None
                    if getattr(item, 'ticket_id_id', None):
                        ticket = Ticket.objects.filter(id=item.ticket_id_id).first()
                    if ticket:
                        raw_title = (
                            ticket.title.replace('[Claim] ', '').strip() if ticket.title else 'Claim Request'
                        )
                    else:
                        raw_title = 'Claim Request'
                    display_title = 'Claim Request'
                elif type_name == 'Leave':
                    display_title = 'Leave Request'
                elif type_name == 'Shift Requests':
                    display_title = 'Shift Request'
                elif type_name == 'Work Type Requests':
                    display_title = 'Work Type Request'
                elif type_name == 'Attendance Requests':
                    display_title = 'Attendance Request'
                elif type_name == 'Asset Requests':
                    display_title = 'Asset Request'
                elif type_name == 'Tickets':
                    display_title = raw_title
                else:
                    display_title = raw_title

                requests_list.append(
                    {
                        'id': str(item.id),
                        'request_id': get_request_id(type_name[:2].upper(), item.id),
                        'type': type_name,
                        'title': display_title,
                        'status': getattr(item, 'status', 'requested'),
                        'icon_name': icon_map.get(type_name, 'file'),
                        'color_hex': color_map.get(type_name, '#000000'),
                        'employee': {
                            'id': str(emp_id or ''),
                            'name': emp_name,
                            'employee_id': emp_badge,
                        },
                        'subtitle': f'{emp_name} - {type_name}',
                        'description': getattr(item, 'description', ''),
                        'created_date': date_str,
                        'metadata': metadata,
                        'cc': cc_users_for_request(type_name, item.id),
                    }
                )

        # Sort by created_date descending (newest first), fallback to id
        requests_list.sort(key=lambda r: (r.get('created_date') or '', int(r['id'])), reverse=True)

        return Response({'total': len(requests_list), 'page': 1, 'limit': 50, 'requests': requests_list[:50]})


class RequestDetailView(APIView):
    def get(self, request, pk):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        type_models = [
            ('Leave', LeaveRequest),
            ('Claims', ClaimRequest),
            ('Tickets', Ticket),
            ('Shift Requests', ShiftRequestModel),
            ('Work Type Requests', WorkTypeRequestModel),
            ('Attendance Requests', AttendanceRequestModel),
            ('Asset Requests', AssetRequestModel),
        ]

        item = None
        type_name = 'Unknown'
        for tn, model in type_models:
            try:
                item = model.objects.get(id=pk)
                type_name = tn
                break
            except model.DoesNotExist:
                continue

        if not item:
            return Response({'error': 'Request not found'}, status=status.HTTP_404_NOT_FOUND)

        emp = get_employee_by_id(item.employee_id_id)
        emp_name = emp.name if emp else 'Unknown'
        emp_badge = (emp.badge_id or str(emp.id)) if emp else ''

        icon_map = {
            'Leave': 'calendar',
            'Claims': 'receipt',
            'Tickets': 'support',
            'Shift Requests': 'clock',
            'Work Type Requests': 'home',
            'Attendance Requests': 'fingerprint',
            'Asset Requests': 'devices',
        }

        return Response(
            {
                'id': str(item.id),
                'request_id': get_request_id(type_name[:2].upper(), item.id),
                'type': type_name,
                'title': getattr(item, 'title', f'{type_name} Request'),
                'status': getattr(item, 'status', 'requested'),
                'icon_name': icon_map.get(type_name, 'file'),
                'color_hex': '#000000',
                'employee': {
                    'id': str(item.employee_id_id),
                    'name': emp_name,
                    'employee_id': emp_badge,
                },
                'subtitle': f'{emp_name} - {type_name}',
                'description': getattr(item, 'description', ''),
                'rejection_reason': getattr(item, 'reject_reason', None),
                'timeline': [],
                'metadata': {},
                'cc': cc_users_for_request(type_name, item.id),
            }
        )


class RequestAcceptView(APIView):
    def put(self, request, pk):
        serializer = RequestActionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        comment = (serializer.validated_data.get('comment') or '').strip()

        type_models = [
            LeaveRequest,
            Ticket,
            ShiftRequestModel,
            WorkTypeRequestModel,
            AttendanceRequestModel,
            AssetRequestModel,
        ]

        item = None
        for model in type_models:
            try:
                item = model.objects.get(id=pk)
                break
            except model.DoesNotExist:
                continue

        if not item:
            return Response({'error': 'Request not found'}, status=status.HTTP_404_NOT_FOUND)

        # Handle different model status patterns
        if hasattr(item, 'approved') and not callable(getattr(item, 'approved', None)):
            item.approved = True
            item.save()
        elif hasattr(item, 'asset_request_status'):
            item.asset_request_status = 'Approved'
            item.save()
        elif hasattr(item, 'status') and not isinstance(type(item).status, property):
            item.status = 'approved'
            item.save()

        # Notify the request owner — include the manager's optional comment.
        emp_id = getattr(item, 'employee_id_id', None) or getattr(item, 'requested_employee_id_id', None)
        target_emp = None
        if emp_id:
            target_emp = get_employee_by_id(emp_id)
            if target_emp and target_emp.employee_user_id_id:
                title = getattr(item, 'title', 'Request')
                body = f'Your request "{title}" has been approved'
                if comment:
                    body = f'{body} — {comment}'
                create_notification(target_emp.employee_user_id_id, 'Request Approved', body)

        write_audit(
            request,
            action='request_approved',
            target_type=type(item).__name__,
            target_id=item.id,
            target_user_id=emp_id,
            target_name=target_emp.name if target_emp else None,
            payload={'comment': comment} if comment else None,
        )

        return Response(
            {
                'id': str(item.id),
                'request_id': get_request_id('REQ', item.id),
                'status': 'approved',
            }
        )


class RequestRejectView(APIView):
    def put(self, request, pk):
        serializer = RequestActionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        rejection_reason = serializer.validated_data.get('rejection_reason')

        type_models = [
            LeaveRequest,
            Ticket,
            ShiftRequestModel,
            WorkTypeRequestModel,
            AttendanceRequestModel,
            AssetRequestModel,
        ]

        item = None
        for model in type_models:
            try:
                item = model.objects.get(id=pk)
                break
            except model.DoesNotExist:
                continue

        if not item:
            return Response({'error': 'Request not found'}, status=status.HTTP_404_NOT_FOUND)

        if hasattr(item, 'canceled') and not callable(getattr(item, 'canceled', None)):
            item.canceled = True
            item.save()
        elif hasattr(item, 'asset_request_status'):
            item.asset_request_status = 'Rejected'
            item.save()
        elif hasattr(item, 'status') and not isinstance(type(item).status, property):
            item.status = 'rejected'
            if hasattr(item, 'reject_reason') and rejection_reason:
                item.reject_reason = rejection_reason
            item.save()

        # Notify the request owner
        emp_id = getattr(item, 'employee_id_id', None) or getattr(item, 'requested_employee_id_id', None)
        target_emp = None
        if emp_id:
            target_emp = get_employee_by_id(emp_id)
            if target_emp and target_emp.employee_user_id_id:
                title = getattr(item, 'title', 'Request')
                create_notification(
                    target_emp.employee_user_id_id,
                    'Request Rejected',
                    f'Your request "{title}" was rejected'
                    + (f': {rejection_reason}' if rejection_reason else ''),
                )

        write_audit(
            request,
            action='request_rejected',
            target_type=type(item).__name__,
            target_id=item.id,
            target_user_id=emp_id,
            target_name=target_emp.name if target_emp else None,
            payload={'rejection_reason': rejection_reason} if rejection_reason else None,
        )

        return Response(
            {
                'id': str(item.id),
                'request_id': get_request_id('REQ', item.id),
                'status': 'rejected',
                'rejection_reason': rejection_reason,
            }
        )


class RequestCancelView(APIView):
    def delete(self, request, pk):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        type_models = [
            LeaveRequest,
            ClaimRequest,
            Ticket,
            ShiftRequestModel,
            WorkTypeRequestModel,
            AttendanceRequestModel,
            AssetRequestModel,
        ]

        item = None
        for model in type_models:
            try:
                item = model.objects.get(id=pk, employee_id_id=employee.id)
                break
            except model.DoesNotExist:
                continue

        if not item:
            return Response({'error': 'Request not found'}, status=status.HTTP_404_NOT_FOUND)

        item.delete()

        return Response(
            {'message': 'Request cancelled successfully', 'request_id': get_request_id('REQ', pk)}
        )


class PayslipsView(APIView):
    def get(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        month = int(request.query_params.get('month', datetime.now().month))
        year = int(request.query_params.get('year', datetime.now().year))

        start = date(year, month, 1)
        end = date(year, month, monthrange(year, month)[1])
        payslip = Payslip.objects.filter(
            employee_id_id=employee.id, start_date__gte=start, start_date__lte=end
        ).first()

        if not payslip:
            return Response({'error': 'Payslip not found'}, status=status.HTTP_404_NOT_FOUND)

        return Response(
            {
                'id': payslip.id,
                'month': payslip.month,
                'year': payslip.year,
                'gross_pay': float(payslip.gross_pay or 0),
                'net_pay': float(payslip.net_pay or 0),
                'basic_pay': float(payslip.basic_pay or 0),
                'deduction': float(payslip.deduction or 0),
                'status': payslip.status,
                'allowances': (payslip.pay_head_data or {}).get('allowances', []),
                'pretax_deductions': (payslip.pay_head_data or {}).get('pretax_deductions', []),
                'post_tax_deductions': (payslip.pay_head_data or {}).get('post_tax_deductions', []),
            }
        )


class PayslipsListView(APIView):
    def get(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        year = int(request.query_params.get('year', datetime.now().year))

        payslips = Payslip.objects.filter(employee_id_id=employee.id, start_date__year=year)

        month_names = [
            '',
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
        ]

        return Response(
            {
                'year': year,
                'payslips': [
                    {
                        'id': p.id,
                        'month': p.month,
                        'label': month_names[p.month] if p.month and 1 <= p.month <= 12 else '',
                        'net_pay': float(p.net_pay) if p.net_pay else 0,
                        'gross_pay': float(p.gross_pay) if p.gross_pay else 0,
                        'basic_pay': float(p.basic_pay) if p.basic_pay else 0,
                        'deduction': float(p.deduction) if p.deduction else 0,
                        'status': p.status or 'draft',
                    }
                    for p in payslips
                ],
            }
        )


class PayslipHTMLView(APIView):
    """Proxy payslip HTML directly from the web app — exact same template.
    No local generation — everything comes from web."""

    WEB_BASE = 'http://127.0.0.1:8001'

    def _web_session(self, username):
        """Create an authenticated session on the web backend."""
        import requests as _req

        session = _req.Session()
        login_page = session.get(f'{self.WEB_BASE}/login/', timeout=5)
        csrf = login_page.cookies.get('csrftoken', '')
        session.post(
            f'{self.WEB_BASE}/login/',
            data={'username': username, 'password': 'Ppulse@123', 'csrfmiddlewaretoken': csrf},
            headers={'Referer': f'{self.WEB_BASE}/login/'},
            timeout=5,
        )
        return session

    def _find_web_payslip_id(self, session, payslip):
        """Find the matching payslip ID on the web backend."""
        import requests as _req

        # Login via API to get token for REST calls
        login_resp = _req.post(
            f'{self.WEB_BASE}/api/auth/login/',
            json={'username': 'admin', 'password': 'Ppulse@123'},
            timeout=5,
        )
        if login_resp.status_code != 200:
            return None
        token = login_resp.json().get('access', '')

        employee = get_employee_by_id(payslip.employee_id_id)
        badge = employee.badge_id if employee else ''
        target_start = str(payslip.start_date) if payslip.start_date else ''

        list_resp = _req.get(
            f'{self.WEB_BASE}/api/payroll/payslip/?view=admin',
            headers={'Authorization': f'Bearer {token}'},
            timeout=5,
        )
        if list_resp.status_code != 200:
            return None

        for wp in list_resp.json().get('results', []):
            wp_emp = wp.get('employee') or {}
            if wp.get('start_date') == target_start and wp_emp.get('badge_id') == badge:
                return wp['id']
        # Fallback: match by date only
        for wp in list_resp.json().get('results', []):
            if wp.get('start_date') == target_start:
                return wp['id']
        return None

    def get(self, request, pk):
        from django.http import HttpResponse

        payslip = get_object_or_404(Payslip, id=pk)

        try:
            session = self._web_session('admin')
            web_id = self._find_web_payslip_id(session, payslip)
            if web_id:
                # Fetch the exact same rendered HTML from the web
                resp = session.get(f'{self.WEB_BASE}/payroll/view-payslip/{web_id}/', timeout=10)
                if resp.status_code == 200 and len(resp.content) > 500:
                    return HttpResponse(resp.content, content_type='text/html')
        except Exception:
            pass

        return Response({'error': 'Web backend unreachable'}, status=status.HTTP_503_SERVICE_UNAVAILABLE)


class PayslipPDFView(APIView):
    """Proxy payslip PDF directly from the web app — no local generation."""

    WEB_BASE = 'http://127.0.0.1:8001'

    def get(self, request, pk):
        from django.http import HttpResponse

        payslip = get_object_or_404(Payslip, id=pk)

        try:
            # Use session auth (web views require session, not JWT)
            html_view = PayslipHTMLView()
            session = html_view._web_session('admin')
            web_id = html_view._find_web_payslip_id(session, payslip)

            if web_id:
                # Try the web's PDF download endpoint
                pdf_resp = session.get(
                    f'{self.WEB_BASE}/payroll/view-payslip-pdf/{web_id}/',
                    timeout=15,
                )
                if pdf_resp.status_code == 200 and 'pdf' in pdf_resp.headers.get('content-type', ''):
                    employee = get_employee_by_id(payslip.employee_id_id)
                    badge = employee.badge_id if employee else 'payslip'
                    response = HttpResponse(pdf_resp.content, content_type='application/pdf')
                    response['Content-Disposition'] = (
                        f'attachment; filename="payslip_{badge}_{payslip.start_date}.pdf"'
                    )
                    return response

                # PDF endpoint failed — generate from HTML using WeasyPrint
                html_resp = session.get(
                    f'{self.WEB_BASE}/payroll/view-payslip/{web_id}/',
                    timeout=10,
                )
                if html_resp.status_code == 200:
                    import weasyprint

                    pdf_bytes = weasyprint.HTML(
                        string=html_resp.text,
                        base_url=self.WEB_BASE,
                    ).write_pdf()
                    employee = get_employee_by_id(payslip.employee_id_id)
                    name = (employee.name if employee else 'payslip').replace(' ', '_')
                    month = payslip.start_date.strftime('%B_%Y') if payslip.start_date else 'payslip'
                    response = HttpResponse(pdf_bytes, content_type='application/pdf')
                    response['Content-Disposition'] = f'attachment; filename="payslip_{name}_{month}.pdf"'
                    return response
        except Exception:
            pass

        return Response({'error': 'Web backend unreachable'}, status=status.HTTP_503_SERVICE_UNAVAILABLE)


class NotificationsView(APIView):
    def get(self, request):
        user = request.user

        notifications = NotificationModel.objects.filter(recipient_id=user.id)

        return Response(
            {
                'unread_count': notifications.filter(unread=True).count(),
                'notifications': [
                    {
                        'id': n.id,
                        'title': n.verb or '',
                        'body': n.description or '',
                        'read': not n.unread,
                        'timestamp': n.timestamp.isoformat() if n.timestamp else None,
                    }
                    for n in notifications.order_by('-timestamp')[:20]
                ],
            }
        )


class NotificationReadView(APIView):
    def put(self, request, pk):
        notification = get_object_or_404(NotificationModel, id=pk)
        notification.unread = False
        notification.save()
        return Response({'message': 'Marked as read'})


class NotificationsReadAllView(APIView):
    def put(self, request):
        user = request.user
        NotificationModel.objects.filter(recipient_id=user.id, unread=True).update(unread=False)
        return Response({'message': 'All notifications marked as read'})


class DeviceRegisterView(APIView):
    def post(self, request):
        serializer = DeviceRegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        DeviceTokenModel.objects.update_or_create(
            employee_id_id=employee.id,
            device_id=serializer.validated_data['device_id'],
            defaults={
                'fcm_token': serializer.validated_data['fcm_token'],
                'platform': serializer.validated_data['platform'],
            },
        )

        return Response({'message': 'Device registered successfully'})


def _get_or_create_period(employee_id, user_id, target_date=None):
    """Find or create a timesheet period for the Mon-Sun week containing
    *target_date* (defaults to today)."""
    from datetime import timedelta

    from .models import SimpleTimesheetPeriod

    day = target_date or date.today()
    weekday = day.weekday()  # Mon=0, Sun=6
    period_start = day - timedelta(days=weekday)
    period_end = period_start + timedelta(days=6)
    period = SimpleTimesheetPeriod.objects.filter(
        employee_id=employee_id,
        period_start=period_start,
    ).first()
    if period:
        return period
    return SimpleTimesheetPeriod.objects.create(
        employee_id=employee_id,
        period_start=period_start,
        period_end=period_end,
        status='draft',
        is_active=True,
        total_hours=0,
        total_wfo_days=0,
        total_wfh_days=0,
        total_wfo_hours=0,
        total_wfh_hours=0,
        created_by_id=user_id,
        created_at=timezone.now(),
    )


# Backward compat alias used elsewhere.
_get_or_create_current_period = _get_or_create_period


def _recompute_period_totals(period):
    """Recompute period.total_hours from its entries."""
    from .models import SimpleTimesheetEntry

    rows = list(SimpleTimesheetEntry.objects.filter(timesheet_period_id=period.id))
    total = sum((r.hours or 0) for r in rows)
    wfo_h = sum((r.hours or 0) for r in rows if (r.work_location or '').lower() == 'wfo')
    wfh_h = sum((r.hours or 0) for r in rows if (r.work_location or '').lower() == 'wfh')
    period.total_hours = total
    period.total_wfo_hours = wfo_h
    period.total_wfh_hours = wfh_h
    period.save(update_fields=['total_hours', 'total_wfo_hours', 'total_wfh_hours'])


class TimesheetProjectsView(APIView):
    """List active projects for the timesheet entry form."""

    def get(self, request):
        from .models import TimesheetProject

        rows = TimesheetProject.objects.filter(is_active=True).order_by('name')
        return Response(
            {
                'items': [
                    {'id': r.id, 'name': r.name, 'project_code': r.project_code, 'client_name': r.client_name}
                    for r in rows
                ],
            }
        )


class TimesheetTasksView(APIView):
    """List active tasks (optionally filtered by project_id)."""

    def get(self, request):
        from .models import TimesheetTask

        qs = TimesheetTask.objects.filter(is_active=True)
        project_id = request.query_params.get('project_id')
        if project_id:
            qs = qs.filter(project_id=int(project_id))
        return Response(
            {
                'items': [
                    {'id': r.id, 'name': r.name, 'project_id': r.project_id, 'task_code': r.task_code}
                    for r in qs.order_by('name')
                ],
            }
        )


class TimesheetCurrentPeriodView(APIView):
    """Return a week's period + entries for the authenticated user.

    Optional query param ``week_start`` (YYYY-MM-DD, must be a Monday).
    Defaults to the current week.
    """

    def get(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        from datetime import datetime as _dt

        from .models import SimpleTimesheetEntry, TimesheetProject, TimesheetTask

        target = None
        ws = request.query_params.get('week_start')
        if ws:
            try:
                target = _dt.fromisoformat(ws).date()
            except ValueError:
                return Response(
                    {'error': 'week_start must be YYYY-MM-DD'},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        period = _get_or_create_period(employee.id, request.user.id, target_date=target)
        rows = list(
            SimpleTimesheetEntry.objects.filter(timesheet_period_id=period.id, is_active=True).order_by(
                'date', 'id'
            )
        )
        # Pre-load project + task names for the entries.
        proj_ids = [r.timesheet_project_id for r in rows if r.timesheet_project_id]
        task_ids = [r.timesheet_task_id for r in rows if r.timesheet_task_id]
        proj_map = {p.id: p.name for p in TimesheetProject.objects.filter(id__in=proj_ids)}
        task_map = {t.id: t.name for t in TimesheetTask.objects.filter(id__in=task_ids)}

        return Response(
            {
                'period': {
                    'id': period.id,
                    'period_start': period.period_start.isoformat(),
                    'period_end': period.period_end.isoformat(),
                    'status': period.status,
                    'total_hours': period.total_hours,
                    'total_wfo_hours': period.total_wfo_hours,
                    'total_wfh_hours': period.total_wfh_hours,
                },
                'entries': [
                    {
                        'id': r.id,
                        'date': r.date.isoformat(),
                        'hours': r.hours,
                        'work_location': r.work_location,
                        'comments': r.comments,
                        'activity_name': r.activity_name or '',
                        'project_id': r.timesheet_project_id,
                        'project_name': proj_map.get(r.timesheet_project_id),
                        'task_id': r.timesheet_task_id,
                        'task_name': task_map.get(r.timesheet_task_id),
                    }
                    for r in rows
                ],
            }
        )


class TimesheetEntriesView(APIView):
    """Create / update / delete timesheet entries."""

    def post(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        from datetime import datetime as _dt

        from .models import SimpleTimesheetEntry

        try:
            entry_date = _dt.fromisoformat(request.data['date']).date()
        except (KeyError, ValueError):
            return Response(
                {'error': {'code': 'BAD_DATA', 'message': 'date required (YYYY-MM-DD)'}},
                status=status.HTTP_400_BAD_REQUEST,
            )
        hours = float(request.data.get('hours', 0))
        if hours < 0 or hours > 24:
            return Response(
                {'error': {'code': 'BAD_HOURS', 'message': 'hours must be 0-24'}},
                status=status.HTTP_400_BAD_REQUEST,
            )
        # Accept optional period_id so the client can target an arbitrary week.
        period_id = request.data.get('period_id')
        if period_id:
            from .models import SimpleTimesheetPeriod

            period = SimpleTimesheetPeriod.objects.filter(
                id=int(period_id),
                employee_id=employee.id,
            ).first()
            if not period:
                return Response({'error': 'Period not found'}, status=status.HTTP_404_NOT_FOUND)
        else:
            period = _get_or_create_period(employee.id, request.user.id, target_date=entry_date)
        e = SimpleTimesheetEntry.objects.create(
            date=entry_date,
            hours=hours,
            work_location=(request.data.get('work_location') or 'wfo').lower(),
            comments=request.data.get('comments', ''),
            activity_name=request.data.get('activity_name', ''),
            timesheet_project_id=request.data.get('project_id'),
            timesheet_task_id=request.data.get('task_id'),
            timesheet_period_id=period.id,
            is_active=True,
            created_by_id=request.user.id,
            created_at=timezone.now(),
        )
        _recompute_period_totals(period)
        write_audit(
            request,
            action='timesheet_entry_created',
            target_type='SimpleTimesheetEntry',
            target_id=e.id,
            payload={'date': str(entry_date), 'hours': hours},
        )
        return Response({'id': e.id, 'period_id': period.id}, status=status.HTTP_201_CREATED)

    def patch(self, request):
        """Update an existing entry's hours, project, task, work_location, or
        comments.  Recalculates period totals automatically."""
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        from .models import SimpleTimesheetEntry

        entry_id = request.data.get('id')
        if not entry_id:
            return Response(
                {'error': {'code': 'BAD_DATA', 'message': 'id required'}}, status=status.HTTP_400_BAD_REQUEST
            )
        e = SimpleTimesheetEntry.objects.filter(id=int(entry_id), created_by_id=request.user.id).first()
        if not e:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
        updated = []
        if 'hours' in request.data:
            h = float(request.data['hours'])
            if h < 0 or h > 24:
                return Response(
                    {'error': {'code': 'BAD_HOURS', 'message': 'hours must be 0-24'}},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            e.hours = h
            updated.append('hours')
        if 'project_id' in request.data:
            e.timesheet_project_id = request.data['project_id']
            updated.append('timesheet_project_id')
        if 'task_id' in request.data:
            e.timesheet_task_id = request.data['task_id']
            updated.append('timesheet_task_id')
        if 'activity_name' in request.data:
            e.activity_name = request.data['activity_name']
            updated.append('activity_name')
        if 'work_location' in request.data:
            e.work_location = (request.data['work_location'] or 'wfo').lower()
            updated.append('work_location')
        if 'comments' in request.data:
            e.comments = request.data['comments']
            updated.append('comments')
        if updated:
            e.modified_by_id = request.user.id
            updated.append('modified_by_id')
            e.save(update_fields=updated)
            if e.timesheet_period_id:
                from .models import SimpleTimesheetPeriod

                period = SimpleTimesheetPeriod.objects.filter(id=e.timesheet_period_id).first()
                if period:
                    _recompute_period_totals(period)
        return Response({'status': 'updated', 'id': e.id})

    def delete(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        from .models import SimpleTimesheetEntry

        entry_id = request.query_params.get('id')
        if not entry_id:
            return Response(
                {'error': {'code': 'BAD_DATA', 'message': 'id required'}}, status=status.HTTP_400_BAD_REQUEST
            )
        e = SimpleTimesheetEntry.objects.filter(id=int(entry_id), created_by_id=request.user.id).first()
        if not e:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
        period_id = e.timesheet_period_id
        e.delete()
        if period_id:
            from .models import SimpleTimesheetPeriod

            period = SimpleTimesheetPeriod.objects.filter(id=period_id).first()
            if period:
                _recompute_period_totals(period)
        write_audit(
            request,
            action='timesheet_entry_deleted',
            target_type='SimpleTimesheetEntry',
            target_id=int(entry_id),
        )
        return Response({'status': 'deleted'})


class TimesheetUnfilledHoursView(APIView):
    """Return how many hours of "missing" timesheet entries exist for the
    user **today** (used by the hourly reminder logic on the client).
    Calculation: hours since punch_in - hours already logged today.
    """

    def get(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        from .models import SimpleTimesheetEntry

        today = date.today()
        att = Attendance.objects.filter(employee_id_id=employee.id, attendance_date=today).first()
        if not att or not att.attendance_clock_in:
            return Response({'unfilled_hours': 0, 'logged_hours': 0, 'worked_hours': 0})
        # Worked hours so far: clock-in → now (or clock-out if already out).
        now = timezone.now().time()
        out = att.attendance_clock_out or now
        worked_seconds = max(
            0,
            (out.hour * 3600 + out.minute * 60 + out.second)
            - (
                att.attendance_clock_in.hour * 3600
                + att.attendance_clock_in.minute * 60
                + att.attendance_clock_in.second
            ),
        )
        worked_hours = round(worked_seconds / 3600.0, 2)
        logged_hours = sum(
            (r.hours or 0)
            for r in SimpleTimesheetEntry.objects.filter(
                date=today, created_by_id=request.user.id, is_active=True
            )
        )
        unfilled = max(0.0, round(worked_hours - logged_hours, 2))
        return Response(
            {
                'unfilled_hours': unfilled,
                'logged_hours': logged_hours,
                'worked_hours': worked_hours,
            }
        )


class TimesheetSubmitView(APIView):
    """Submit a timesheet period for approval."""

    def post(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        from .models import SimpleTimesheetPeriod

        period_id = request.data.get('period_id')
        if not period_id:
            return Response({'error': 'period_id required'}, status=status.HTTP_400_BAD_REQUEST)
        period = SimpleTimesheetPeriod.objects.filter(
            id=int(period_id),
            employee_id=employee.id,
        ).first()
        if not period:
            return Response({'error': 'Period not found'}, status=status.HTTP_404_NOT_FOUND)
        if period.status == 'approved':
            return Response({'error': 'Already approved'}, status=status.HTTP_400_BAD_REQUEST)
        period.status = 'submitted'
        period.submitted_at = timezone.now()
        period.save(update_fields=['status', 'submitted_at'])
        write_audit(
            request, action='timesheet_submitted', target_type='SimpleTimesheetPeriod', target_id=period.id
        )
        return Response(
            {
                'status': period.status,
                'submitted_at': period.submitted_at.isoformat() if period.submitted_at else None,
            }
        )


# ── App Feedback ────────────────────────────────────────────────────────


class FeedbackCheckView(APIView):
    """Check if the current user has already submitted feedback for this app version."""

    def get(self, request):
        from .models import AppFeedback

        version = request.query_params.get('version', '1.0.0')
        exists = AppFeedback.objects.filter(user=request.user, app_version=version).exists()
        return Response({'has_feedback': exists})


class FeedbackSubmitView(APIView):
    """Submit app feedback (rating + comment). One per user per app version."""

    def post(self, request):
        from .models import AppFeedback

        rating = int(request.data.get('rating', 0))
        comment = request.data.get('comment', '')
        version = request.data.get('version', '1.0.0')

        if rating < 1 or rating > 5:
            return Response({'error': 'Rating must be 1-5'}, status=status.HTTP_400_BAD_REQUEST)

        feedback, created = AppFeedback.objects.update_or_create(
            user=request.user,
            app_version=version,
            defaults={'rating': rating, 'comment': comment},
        )
        return Response(
            {
                'status': 'created' if created else 'updated',
                'id': feedback.id,
            },
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


# ── Activity status (Round 5) ───────────────────────────────────────────


class MeHeartbeatView(APIView):
    """Update the calling user's last_seen_at timestamp. Called every 30s
    while the app is foregrounded so other users can see them as 'online'."""

    def post(self, request):
        from .models import UserPresence

        UserPresence.objects.update_or_create(
            user_id=request.user.id,
            defaults={},  # last_seen_at auto-updates
        )
        return Response({'status': 'ok', 'now': timezone.now().isoformat()})


class MePresenceSettingsView(APIView):
    """Read / write the calling user's presence + push preferences."""

    def get(self, request):
        from .models import UserPresence

        p, _ = UserPresence.objects.get_or_create(user_id=request.user.id)
        return Response(
            {
                'is_visible': p.is_visible,
                'push_enabled': p.push_enabled,
                'timesheet_reminders_enabled': p.timesheet_reminders_enabled,
            }
        )

    def post(self, request):
        from .models import UserPresence

        p, _ = UserPresence.objects.get_or_create(user_id=request.user.id)
        for f in ('is_visible', 'push_enabled', 'timesheet_reminders_enabled'):
            if f in request.data:
                setattr(p, f, bool(request.data[f]))
        p.save()
        return Response(
            {
                'is_visible': p.is_visible,
                'push_enabled': p.push_enabled,
                'timesheet_reminders_enabled': p.timesheet_reminders_enabled,
            }
        )


class PresenceListView(APIView):
    """Bulk presence query — returns last_seen_at for the requested user IDs.
    Filters out users who have hidden their visibility."""

    def get(self, request):
        from datetime import timedelta

        from .models import UserPresence

        ids = (request.query_params.get('user_ids') or '').strip()
        if not ids:
            return Response({'items': []})
        try:
            id_list = [int(x) for x in ids.split(',') if x.strip()]
        except ValueError:
            return Response({'items': []})
        rows = UserPresence.objects.filter(user_id__in=id_list, is_visible=True)
        threshold = timezone.now() - timedelta(minutes=5)
        return Response(
            {
                'items': [
                    {
                        'user_id': r.user_id,
                        'last_seen_at': r.last_seen_at.isoformat(),
                        'is_online': r.last_seen_at >= threshold,
                    }
                    for r in rows
                ],
            }
        )


class EmployeesSearchView(APIView):
    """Lightweight typeahead for the CC field. Matches on name / email /
    badge id and returns the linked auth `user_id` so the client can submit
    that directly into the request payload's `cc` array.
    """

    def get(self, request):
        q = (request.query_params.get('q') or '').strip()
        limit = min(int(request.query_params.get('limit', 12)), 50)
        if len(q) < 2:
            return Response({'items': []})
        employees = (
            Employee.objects.filter(is_active=True)
            .filter(
                Q(employee_first_name__icontains=q)
                | Q(employee_last_name__icontains=q)
                | Q(email__icontains=q)
                | Q(badge_id__icontains=q)
            )
            .exclude(employee_user_id_id__isnull=True)[:limit]
        )

        items = []
        for emp in employees:
            items.append(
                {
                    'user_id': emp.employee_user_id_id,
                    'employee_id': emp.id,
                    'badge_id': emp.badge_id,
                    'name': emp.name,
                    'email': emp.email,
                    'avatar_url': emp.avatar_url,
                }
            )
        return Response({'items': items})


class EmployeesListView(APIView):
    def get(self, request):
        search = request.query_params.get('search', '')
        department = request.query_params.get('department', '')

        employees = Employee.objects.filter(is_active=True)

        if search:
            employees = employees.filter(
                Q(employee_first_name__icontains=search)
                | Q(employee_last_name__icontains=search)
                | Q(email__icontains=search)
                | Q(badge_id__icontains=search)
            )

        if department:
            dept_ids = Department.objects.filter(department__icontains=department).values_list(
                'id', flat=True
            )
            work_info_emp_ids = EmployeeWorkInformation.objects.filter(
                department_id_id__in=dept_ids
            ).values_list('employee_id_id', flat=True)
            employees = employees.filter(id__in=work_info_emp_ids)

        emp_list = []
        for emp in employees[:100]:
            work_info = EmployeeWorkInformation.objects.filter(employee_id_id=emp.id).first()
            designation = ''
            dept_name = ''
            if work_info:
                if work_info.job_position_id_id:
                    jp = JobPosition.objects.filter(id=work_info.job_position_id_id).first()
                    designation = jp.job_position if jp else ''
                if work_info.department_id_id:
                    dept = Department.objects.filter(id=work_info.department_id_id).first()
                    dept_name = dept.department if dept else ''
            emp_list.append(
                {
                    'id': str(emp.id),
                    'employee_id': emp.badge_id or str(emp.id),
                    'name': emp.name,
                    'designation': designation,
                    'department': dept_name,
                    'email': emp.email,
                    'phone': emp.phone,
                    'avatar_url': emp.avatar_url,
                }
            )

        return Response({'total': employees.count(), 'employees': emp_list})


class EmployeeDetailView(APIView):
    def get(self, request, pk):
        employee = get_object_or_404(Employee, id=pk)

        work_info = EmployeeWorkInformation.objects.filter(employee_id_id=employee.id).first()

        designation = ''
        dept_name = ''
        date_joining = None
        reporting_manager = None

        if work_info:
            if work_info.job_position_id_id:
                jp = JobPosition.objects.filter(id=work_info.job_position_id_id).first()
                designation = jp.job_position if jp else ''
            if work_info.department_id_id:
                dept = Department.objects.filter(id=work_info.department_id_id).first()
                dept_name = dept.department if dept else ''
            date_joining = work_info.date_joining
            if work_info.reporting_manager_id_id:
                reporting_emp = get_employee_by_id(work_info.reporting_manager_id_id)
                if reporting_emp:
                    reporting_manager = {'id': str(reporting_emp.id), 'name': reporting_emp.name}

        return Response(
            {
                'id': str(employee.id),
                'employee_id': employee.badge_id or str(employee.id),
                'name': employee.name,
                'email': employee.email,
                'phone': employee.phone,
                'designation': designation,
                'department': dept_name,
                'date_of_joining': date_joining.isoformat() if date_joining else None,
                'reporting_manager': reporting_manager,
                'avatar_url': employee.avatar_url,
            }
        )


class DashboardSummaryView(APIView):
    def get(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        today = date.today()

        attendance = Attendance.objects.filter(employee_id_id=employee.id, attendance_date=today).first()

        attendance_status = 'not_clocked_in'
        punch_in = None
        punch_out = None
        total_hours = '00:00'
        punch_in_source = None
        can_punch_via_mobile = True  # Default: mobile can punch in

        if attendance:
            attendance_status = attendance.computed_status
            punch_in = attendance.attendance_clock_in.isoformat() if attendance.attendance_clock_in else None
            punch_out = (
                attendance.attendance_clock_out.isoformat() if attendance.attendance_clock_out else None
            )
            total_hours = attendance.attendance_worked_hour or '00:00'
            punch_in_source = attendance.punch_in_source
            # If currently checked in via biometric, mobile cannot punch out
            if attendance.is_checked_in and _is_biometric_source(attendance.punch_in_source):
                can_punch_via_mobile = False

        available_leaves = AvailableLeave.objects.filter(employee_id_id=employee.id)

        gender = (employee.gender or '').strip().lower()
        leave_summary = {}
        total_remaining = 0
        for leave in available_leaves:
            leave_type = LeaveType.objects.filter(id=leave.leave_type_id_id).first()
            lt_name = (leave_type.name or '').lower() if leave_type else ''
            # Hide gender-specific leaves that don't match
            if 'maternity' in lt_name and gender != 'female':
                continue
            if 'paternity' in lt_name and gender != 'male':
                continue
            total_days = leave.total_leave_days or 0
            # Skip leave types with no allotment
            if total_days <= 0:
                continue

            # Credit back any "earned" days (negative approved requested_days,
            # e.g. earned Comp Off entries) on top of the cached available_days.
            credited_back = (
                LeaveRequest.objects.filter(
                    employee_id_id=employee.id,
                    leave_type_id_id=leave.leave_type_id_id,
                    status='approved',
                    requested_days__lt=0,
                ).aggregate(total=Sum('requested_days'))['total']
                or 0
            )
            credit = -float(credited_back)  # convert negative to positive credit

            used = leave.used_days - credit
            if used < 0:
                used = 0
            remaining = total_days - used
            if remaining < 0:
                remaining = 0
            total_remaining += remaining

            key = str(leave.leave_type_id_id)
            leave_summary[key] = {
                'label': leave_type.name if leave_type else 'Unknown',
                'used': int(used),
                'total': int(total_days),
                'remaining': int(remaining),
            }

        # Include Unpaid Leave (LOP) only if there are days taken
        unpaid_lt = LeaveType.objects.filter(name__iexact='Unpaid Leave').first()
        if unpaid_lt:
            unpaid_taken = (
                LeaveRequest.objects.filter(
                    employee_id_id=employee.id,
                    leave_type_id_id=unpaid_lt.id,
                    status='approved',
                ).aggregate(total=Sum('requested_days'))['total']
                or 0
            )
            if unpaid_taken and unpaid_taken > 0:
                leave_summary[str(unpaid_lt.id)] = {
                    'label': 'LOP',
                    'used': int(unpaid_taken),
                    'total': int(unpaid_taken),
                    'is_unpaid': True,
                }

        # Calculate real attendance percentage for current month
        month_start = date(today.year, today.month, 1)
        month_attendances = Attendance.objects.filter(
            employee_id_id=employee.id, attendance_date__gte=month_start, attendance_date__lte=today
        )
        present_days = sum(1 for a in month_attendances if a.attendance_clock_in is not None)
        working_days = sum(
            1
            for d in range((today - month_start).days + 1)
            if (month_start + timedelta(days=d)).weekday() < 5
        )
        attendance_pct = round((present_days / working_days * 100), 1) if working_days > 0 else 0.0

        # Build recent activity from ALL request types
        recent_activity = []
        for lr in LeaveRequest.objects.filter(employee_id_id=employee.id).order_by('-id')[:5]:
            lt = LeaveType.objects.filter(id=lr.leave_type_id_id).first()
            recent_activity.append(
                {
                    'type': 'leave',
                    'title': f'{lt.name if lt else "Leave"} Request',
                    'status': lr.status,
                    'date': lr.start_date.isoformat() if lr.start_date else None,
                }
            )
        for sr in ShiftRequestModel.objects.filter(employee_id_id=employee.id).order_by('-id')[:3]:
            recent_activity.append(
                {
                    'type': 'shift',
                    'title': 'Shift Change Request',
                    'status': sr.status,
                    'date': sr.requested_date.isoformat() if sr.requested_date else None,
                }
            )
        for wr in WorkTypeRequestModel.objects.filter(employee_id_id=employee.id).order_by('-id')[:3]:
            recent_activity.append(
                {
                    'type': 'work_type',
                    'title': 'Work Type Request',
                    'status': wr.status,
                    'date': wr.requested_date.isoformat() if wr.requested_date else None,
                }
            )
        for ar in AttendanceRequestModel.objects.filter(employee_id=employee.id).order_by('-id')[:3]:
            recent_activity.append(
                {
                    'type': 'attendance',
                    'title': 'Attendance Request',
                    'status': ar.status,
                    'date': ar.requested_date.isoformat() if ar.requested_date else None,
                }
            )
        # Sort all by date descending and limit to 8
        recent_activity.sort(key=lambda x: x.get('date') or '', reverse=True)
        recent_activity = recent_activity[:8]

        # ── Pending approvals (filtered to the caller's direct reports for
        #    managers; HR sees the whole org). All 7 request types so the
        #    Manager Insights tile renders zeros instead of "n/a".
        is_manager_or_hr = bool(getattr(employee, 'id', None))  # always true here
        if request.user.is_staff:
            team_ids = list(Employee.objects.exclude(id=employee.id).values_list('id', flat=True))
        else:
            team_ids = list(
                EmployeeWorkInformation.objects.filter(reporting_manager_id_id=employee.id).values_list(
                    'employee_id_id', flat=True
                )
            )

        def _safe_count(qs):
            try:
                return qs.count()
            except Exception:
                return 0

        if is_manager_or_hr and team_ids:
            pending_leaves = _safe_count(
                LeaveRequest.objects.filter(status='requested', employee_id_id__in=team_ids)
            )
            pending_claims = _safe_count(
                ClaimRequest.objects.filter(is_approved=False, is_rejected=False, employee_id_id__in=team_ids)
            )
            pending_tickets = _safe_count(Ticket.objects.filter(status='open', employee_id_id__in=team_ids))
            pending_shift = _safe_count(
                ShiftRequestModel.objects.filter(approved=False, canceled=False, employee_id_id__in=team_ids)
            )
            pending_worktype = _safe_count(
                WorkTypeRequestModel.objects.filter(
                    approved=False, canceled=False, employee_id_id__in=team_ids
                )
            )
            pending_attendance = _safe_count(
                AttendanceRequestModel.objects.filter(status='requested', employee_id__in=team_ids)
            )
            pending_assets = _safe_count(
                AssetRequestModel.objects.filter(
                    asset_request_status__icontains='request', requested_employee_id_id__in=team_ids
                )
            )
        else:
            pending_leaves = pending_claims = pending_tickets = 0
            pending_shift = pending_worktype = pending_attendance = pending_assets = 0

        pending_total = (
            pending_leaves
            + pending_claims
            + pending_tickets
            + pending_shift
            + pending_worktype
            + pending_attendance
            + pending_assets
        )

        # ── Team stats (size, departments, work-type split, today snapshot).
        team_block = {
            'size': 0,
            'departments': [],
            'work_types': [],
            'today': {'present': 0, 'wfh': 0, 'on_leave': 0, 'absent': 0},
        }
        if team_ids:
            team_block['size'] = len(team_ids)

            # Departments — name + headcount.
            dept_counts = {}
            wtype_counts = {}
            for wi in EmployeeWorkInformation.objects.filter(employee_id_id__in=team_ids):
                if wi.department_id_id:
                    dept = Department.objects.filter(id=wi.department_id_id).first()
                    if dept and dept.department:
                        dept_counts[dept.department] = dept_counts.get(dept.department, 0) + 1
                if wi.work_type_id_id:
                    wt = WorkType.objects.filter(id=wi.work_type_id_id).first()
                    if wt and wt.work_type:
                        wtype_counts[wt.work_type] = wtype_counts.get(wt.work_type, 0) + 1
            team_block['departments'] = [
                {'name': k, 'count': v}
                for k, v in sorted(dept_counts.items(), key=lambda kv: kv[1], reverse=True)
            ]
            team_block['work_types'] = [
                {'name': k, 'count': v}
                for k, v in sorted(wtype_counts.items(), key=lambda kv: kv[1], reverse=True)
            ]

            # Today's snapshot for the team.
            present_today = Attendance.objects.filter(
                employee_id_id__in=team_ids,
                attendance_date=today,
                attendance_clock_in__isnull=False,
            ).count()
            on_leave = LeaveRequest.objects.filter(
                status='approved',
                employee_id_id__in=team_ids,
                start_date__lte=today,
                end_date__gte=today,
            ).count()
            team_block['today'] = {
                'present': present_today,
                'wfh': 0,  # could be derived from work_type_id later
                'on_leave': on_leave,
                'absent': max(0, len(team_ids) - present_today - on_leave),
            }

        return Response(
            {
                'attendance': {
                    'status': attendance_status,
                    'punch_in': punch_in,
                    'punch_out': punch_out,
                    'total_hours': total_hours,
                    'source': punch_in_source,
                    'can_punch_via_mobile': can_punch_via_mobile,
                },
                'leave_balance': {
                    'total_remaining': int(total_remaining),
                    'attendance_percentage': attendance_pct,
                },
                'leave_summary': leave_summary,
                'recent_activity': recent_activity,
                'pending_approvals': {
                    'leave_requests': pending_leaves,
                    'claims': pending_claims,
                    'tickets': pending_tickets,
                    'shift_requests': pending_shift,
                    'work_type_requests': pending_worktype,
                    'attendance_requests': pending_attendance,
                    'asset_requests': pending_assets,
                    'total': pending_total,
                },
                'team': team_block,
            }
        )


class DashboardAnnouncementsView(APIView):
    def get(self, request):
        announcements = Announcement.objects.filter(is_active=True)[:5]

        return Response(
            {
                'announcements': [
                    {
                        'id': str(a.id),
                        'title': a.title,
                        'subtitle': a.subtitle or '',
                        'icon': a.icon or 'announcement',
                    }
                    for a in announcements
                ]
            }
        )


class DashboardAnalyticsView(APIView):
    def get(self, request):
        total_employees = Employee.objects.filter(is_active=True).count()

        # Department breakdown from real data
        dept_breakdown = []
        departments = Department.objects.all()
        for dept in departments:
            count = EmployeeWorkInformation.objects.filter(department_id_id=dept.id).count()
            if count > 0:
                dept_breakdown.append({'department': dept.department, 'count': count})

        # Leave analytics
        total_used = 0
        leave_type_usage = {}
        for al in AvailableLeave.objects.all():
            used = al.used_days
            total_used += used
            lt = LeaveType.objects.filter(id=al.leave_type_id_id).first()
            if lt:
                leave_type_usage[lt.name] = leave_type_usage.get(lt.name, 0) + used

        most_used = max(leave_type_usage, key=leave_type_usage.get) if leave_type_usage else 'N/A'
        avg_leaves = round(total_used / total_employees, 1) if total_employees > 0 else 0.0

        return Response(
            {
                'total_employees': total_employees,
                'new_joiners_this_month': 0,
                'attrition_rate': 0.0,
                'department_breakdown': dept_breakdown,
                'leave_analytics': {'most_used_type': most_used, 'avg_leaves_per_employee': avg_leaves},
            }
        )


class DepartmentsView(APIView):
    def get(self, request):
        departments = Department.objects.all()
        return Response(
            {
                'departments': [
                    {
                        'id': str(d.id),
                        'name': d.department or '',
                    }
                    for d in departments
                ]
            }
        )


class ShiftsListView(APIView):
    def get(self, request):
        shifts = Shift.objects.all()
        return Response(
            {
                'shifts': [
                    {
                        'id': str(s.id),
                        'name': s.employee_shift or '',
                    }
                    for s in shifts
                ]
            }
        )


class WorkTypesListView(APIView):
    def get(self, request):
        work_types = WorkType.objects.all()
        return Response(
            {
                'work_types': [
                    {
                        'id': str(w.id),
                        'name': w.work_type or '',
                    }
                    for w in work_types
                ]
            }
        )


class LeaveTypesListView(APIView):
    def get(self, request):
        leave_types = LeaveType.objects.all()
        # Gender-based filtering: hide Maternity from males, Paternity from females
        employee = get_employee_from_user(request.user)
        gender = (employee.gender or '').strip().lower() if employee else ''
        filtered = []
        for lt in leave_types:
            name = (lt.name or '').lower()
            if 'maternity' in name and gender != 'female':
                continue
            if 'paternity' in name and gender != 'male':
                continue
            filtered.append(lt)
        return Response(
            {
                'leave_types': [
                    {
                        'id': str(lt.id),
                        'name': lt.name or '',
                    }
                    for lt in filtered
                ]
            }
        )


class AdminGeofencesView(APIView):
    """List + create geofences (admin-managed allowed punch-in zones)."""

    def get(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import Geofence

        rows = Geofence.objects.all().order_by('-is_office', 'name')
        return Response(
            {
                'items': [
                    {
                        'id': r.id,
                        'name': r.name,
                        'latitude': r.latitude,
                        'longitude': r.longitude,
                        'radius_meters': r.radius_meters,
                        'is_office': r.is_office,
                        'has_biometric': r.has_biometric,
                        'is_active': r.is_active,
                        'updated_at': r.updated_at.isoformat() if r.updated_at else None,
                    }
                    for r in rows
                ],
            }
        )

    def post(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import Geofence

        try:
            g = Geofence.objects.create(
                name=request.data.get('name', '').strip() or 'New Zone',
                latitude=float(request.data.get('latitude', 0)),
                longitude=float(request.data.get('longitude', 0)),
                radius_meters=int(request.data.get('radius_meters', 50)),
                is_office=bool(request.data.get('is_office', True)),
                has_biometric=bool(request.data.get('has_biometric', False)),
                is_active=bool(request.data.get('is_active', True)),
            )
        except (TypeError, ValueError) as e:
            return Response(
                {'error': {'code': 'BAD_DATA', 'message': str(e)}}, status=status.HTTP_400_BAD_REQUEST
            )
        write_audit(
            request,
            action='geofence_created',
            target_type='Geofence',
            target_id=g.id,
            payload={'name': g.name},
        )
        return Response({'id': g.id, 'name': g.name}, status=status.HTTP_201_CREATED)


class AdminGeofenceDetailView(APIView):
    """Update / delete a single geofence."""

    def put(self, request, pk):
        return self.patch(request, pk)

    def patch(self, request, pk):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import Geofence

        g = Geofence.objects.filter(id=pk).first()
        if not g:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
        for field in (
            'name',
            'latitude',
            'longitude',
            'radius_meters',
            'is_office',
            'has_biometric',
            'is_active',
        ):
            if field in request.data:
                setattr(g, field, request.data[field])
        g.save()
        write_audit(request, action='geofence_updated', target_type='Geofence', target_id=g.id)
        return Response({'id': g.id, 'name': g.name})

    def delete(self, request, pk):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import Geofence

        g = Geofence.objects.filter(id=pk).first()
        if not g:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
        name = g.name
        g.delete()
        write_audit(
            request, action='geofence_deleted', target_type='Geofence', target_id=pk, payload={'name': name}
        )
        return Response({'status': 'deleted'})


class AdminHolidaysView(APIView):
    """List + create holidays."""

    def get(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import Holiday

        rows = Holiday.objects.all().order_by('holiday_date')
        return Response(
            {
                'items': [
                    {
                        'id': r.id,
                        'name': r.name,
                        'holiday_date': r.holiday_date.isoformat(),
                        'is_recurring': r.is_recurring,
                        'description': r.description or '',
                    }
                    for r in rows
                ],
            }
        )

    def post(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from datetime import datetime

        from .models import Holiday

        try:
            h = Holiday.objects.create(
                name=request.data.get('name', '').strip() or 'New Holiday',
                holiday_date=datetime.fromisoformat(request.data['holiday_date']).date(),
                is_recurring=bool(request.data.get('is_recurring', False)),
                description=request.data.get('description', ''),
            )
        except (KeyError, ValueError) as e:
            return Response(
                {'error': {'code': 'BAD_DATA', 'message': str(e)}}, status=status.HTTP_400_BAD_REQUEST
            )
        write_audit(
            request, action='holiday_created', target_type='Holiday', target_id=h.id, payload={'name': h.name}
        )
        return Response({'id': h.id, 'name': h.name}, status=status.HTTP_201_CREATED)


class AdminHolidayDetailView(APIView):
    """Update / delete a holiday."""

    def put(self, request, pk):
        return self.patch(request, pk)

    def patch(self, request, pk):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from datetime import datetime

        from .models import Holiday

        h = Holiday.objects.filter(id=pk).first()
        if not h:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
        if 'name' in request.data:
            h.name = request.data['name']
        if 'holiday_date' in request.data:
            try:
                h.holiday_date = datetime.fromisoformat(request.data['holiday_date']).date()
            except ValueError:
                pass
        if 'is_recurring' in request.data:
            h.is_recurring = bool(request.data['is_recurring'])
        if 'description' in request.data:
            h.description = request.data['description']
        h.save()
        write_audit(request, action='holiday_updated', target_type='Holiday', target_id=h.id)
        return Response({'id': h.id})

    def delete(self, request, pk):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import Holiday

        h = Holiday.objects.filter(id=pk).first()
        if not h:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
        name = h.name
        h.delete()
        write_audit(
            request, action='holiday_deleted', target_type='Holiday', target_id=pk, payload={'name': name}
        )
        return Response({'status': 'deleted'})


class AdminEmployeesCsvExportView(APIView):
    """Stream every Employee row as CSV. Admin-only."""

    def get(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        import csv as _csv

        from django.http import HttpResponse

        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename="employees.csv"'
        writer = _csv.writer(response)
        writer.writerow(
            [
                'id',
                'badge_id',
                'first_name',
                'last_name',
                'email',
                'phone',
                'gender',
                'dob',
                'department',
                'designation',
                'is_active',
            ]
        )
        for e in Employee.objects.all().order_by('id'):
            wi = EmployeeWorkInformation.objects.filter(employee_id_id=e.id).first()
            dept = ''
            desig = ''
            if wi:
                if wi.department_id_id:
                    d = Department.objects.filter(id=wi.department_id_id).first()
                    dept = d.department if d else ''
                if wi.job_position_id_id:
                    jp = JobPosition.objects.filter(id=wi.job_position_id_id).first()
                    desig = jp.job_position if jp else ''
            writer.writerow(
                [
                    e.id,
                    e.badge_id or '',
                    e.employee_first_name or '',
                    e.employee_last_name or '',
                    e.email or '',
                    e.phone or '',
                    e.gender or '',
                    e.dob.isoformat() if e.dob else '',
                    dept,
                    desig,
                    e.is_active,
                ]
            )
        write_audit(request, action='employees_csv_exported', target_type='Employee')
        return response


class AdminEmployeesCsvImportView(APIView):
    """Bulk-create / update employees from a CSV file.

    Expected columns (header row): badge_id, first_name, last_name, email,
    phone, gender, dob, department, designation. `dry_run=true` query param
    validates without writing.
    """

    def post(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        import csv as _csv
        import io as _io

        upload = request.FILES.get('file')
        if not upload:
            return Response(
                {'error': {'code': 'NO_FILE', 'message': 'Upload a CSV file in the `file` field'}},
                status=status.HTTP_400_BAD_REQUEST,
            )
        dry_run = request.query_params.get('dry_run', '').lower() in {'1', 'true', 'yes'}

        try:
            text = upload.read().decode('utf-8-sig')
        except UnicodeDecodeError:
            return Response(
                {'error': {'code': 'BAD_ENCODING', 'message': 'CSV must be UTF-8'}},
                status=status.HTTP_400_BAD_REQUEST,
            )
        reader = _csv.DictReader(_io.StringIO(text))

        created = 0
        updated = 0
        errors = []
        for i, row in enumerate(reader, start=2):  # start=2 → first data row is line 2
            badge = (row.get('badge_id') or '').strip()
            first = (row.get('first_name') or '').strip()
            last = (row.get('last_name') or '').strip()
            email = (row.get('email') or '').strip()
            if not badge or not first:
                errors.append({'line': i, 'reason': 'badge_id and first_name are required'})
                continue
            if dry_run:
                if Employee.objects.filter(badge_id__iexact=badge).exists():
                    updated += 1
                else:
                    created += 1
                continue
            try:
                _emp, created_now = Employee.objects.update_or_create(
                    badge_id=badge,
                    defaults={
                        'employee_first_name': first,
                        'employee_last_name': last,
                        'email': email or None,
                        'phone': (row.get('phone') or '').strip() or None,
                        'gender': (row.get('gender') or '').strip() or None,
                        'is_active': True,
                    },
                )
                if created_now:
                    created += 1
                else:
                    updated += 1
            except Exception as e:
                errors.append({'line': i, 'reason': str(e)})

        write_audit(
            request,
            action='employees_csv_imported',
            target_type='Employee',
            payload={'created': created, 'updated': updated, 'errors': len(errors), 'dry_run': dry_run},
        )
        return Response(
            {
                'dry_run': dry_run,
                'created': created,
                'updated': updated,
                'errors': errors,
            }
        )


class AdminBackupView(APIView):
    """Trigger a database backup. For SQLite this copies db.sqlite3 to
    MEDIA_ROOT/backups/db_<timestamp>.sqlite3. For Postgres it returns 501."""

    def get(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        import os as _os

        from django.conf import settings as dj_settings

        backups_dir = _os.path.join(dj_settings.MEDIA_ROOT, 'backups')
        items = []
        if _os.path.isdir(backups_dir):
            for fn in sorted(_os.listdir(backups_dir), reverse=True):
                fp = _os.path.join(backups_dir, fn)
                if _os.path.isfile(fp):
                    items.append(
                        {
                            'filename': fn,
                            'size_bytes': _os.path.getsize(fp),
                            'modified': _os.path.getmtime(fp),
                        }
                    )
        return Response({'backups': items[:30]})

    def post(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        import os as _os
        import shutil as _shutil
        import subprocess as _sp
        from datetime import datetime

        from django.conf import settings as dj_settings

        engine = dj_settings.DATABASES['default']['ENGINE']
        backups_dir = _os.path.join(dj_settings.MEDIA_ROOT, 'backups')
        _os.makedirs(backups_dir, exist_ok=True)
        ts = datetime.utcnow().strftime('%Y%m%d_%H%M%S')

        # ── SQLite path: just copy the file ────────────────────────────
        if 'sqlite' in engine:
            src = dj_settings.DATABASES['default']['NAME']
            dest = _os.path.join(backups_dir, f'db_{ts}.sqlite3')
            try:
                _shutil.copy2(src, dest)
            except Exception as e:
                return Response(
                    {'error': {'code': 'BACKUP_FAILED', 'message': str(e)}},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                )

        # ── Postgres path: pg_dump to a .sql file ──────────────────────
        elif 'postgresql' in engine:
            db = dj_settings.DATABASES['default']
            dest = _os.path.join(backups_dir, f'db_{ts}.sql')
            env = _os.environ.copy()
            if db.get('PASSWORD'):
                env['PGPASSWORD'] = db['PASSWORD']
            # Find pg_dump — Homebrew + Postgres.app + Linux all in one go.
            pg_dump = (
                _shutil.which('pg_dump')
                or '/opt/homebrew/opt/postgresql@18/bin/pg_dump'
                or '/opt/homebrew/opt/postgresql@16/bin/pg_dump'
                or '/opt/homebrew/opt/postgresql/bin/pg_dump'
            )
            if not _os.path.exists(pg_dump):
                pg_dump = 'pg_dump'  # last-ditch
            cmd = [
                pg_dump,
                '--host',
                db.get('HOST') or 'localhost',
                '--port',
                str(db.get('PORT') or '5432'),
                '--username',
                db.get('USER') or 'postgres',
                '--no-owner',
                '--no-privileges',
                '--file',
                dest,
                db['NAME'],
            ]
            try:
                proc = _sp.run(cmd, env=env, capture_output=True, text=True, timeout=120)
            except FileNotFoundError:
                return Response(
                    {
                        'error': {
                            'code': 'PG_DUMP_MISSING',
                            'message': 'pg_dump not on PATH — install postgresql-client',
                        }
                    },
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                )
            except Exception as e:
                return Response(
                    {'error': {'code': 'BACKUP_FAILED', 'message': str(e)}},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                )
            if proc.returncode != 0:
                return Response(
                    {'error': {'code': 'BACKUP_FAILED', 'message': proc.stderr.strip() or 'pg_dump failed'}},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                )
        else:
            return Response(
                {
                    'error': {
                        'code': 'NOT_IMPLEMENTED',
                        'message': f'Backup not implemented for engine {engine}',
                    }
                },
                status=status.HTTP_501_NOT_IMPLEMENTED,
            )

        size = _os.path.getsize(dest)
        write_audit(
            request,
            action='db_backup_created',
            target_type='Database',
            payload={'filename': _os.path.basename(dest), 'size_bytes': size, 'engine': engine},
        )
        return Response(
            {
                'filename': _os.path.basename(dest),
                'size_bytes': size,
                'engine': engine,
            }
        )


class AdminEmailTemplatesView(APIView):
    """List + upsert system email templates."""

    def get(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import EmailTemplate

        rows = EmailTemplate.objects.all().order_by('key')
        return Response(
            {
                'items': [
                    {
                        'id': r.id,
                        'key': r.key,
                        'subject': r.subject,
                        'body': r.body,
                        'html_body': r.html_body or '',
                        'is_active': r.is_active,
                        'updated_at': r.updated_at.isoformat() if r.updated_at else None,
                    }
                    for r in rows
                ],
            }
        )

    def post(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import EmailTemplate

        key = (request.data.get('key') or '').strip()
        if not key:
            return Response(
                {'error': {'code': 'KEY_REQUIRED', 'message': 'key is required'}},
                status=status.HTTP_400_BAD_REQUEST,
            )
        t, created = EmailTemplate.objects.update_or_create(
            key=key,
            defaults={
                'subject': request.data.get('subject', ''),
                'body': request.data.get('body', ''),
                'html_body': request.data.get('html_body') or None,
                'is_active': bool(request.data.get('is_active', True)),
            },
        )
        write_audit(
            request,
            action='email_template_saved',
            target_type='EmailTemplate',
            target_id=t.id,
            payload={'key': key, 'created': created},
        )
        return Response({'id': t.id, 'key': t.key, 'created': created})


# ── Round 3 — Tier 3/4 admin endpoints ─────────────────────────────────


class AdminSystemStatsView(APIView):
    """Storage / DB / media usage gauges. Admin only."""

    def get(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        import os as _os
        import shutil as _shutil

        from django.conf import settings as dj_settings
        from django.db import connection

        from .models import AuditLog

        media_root = dj_settings.MEDIA_ROOT
        media_size = 0
        media_files = 0
        if _os.path.isdir(media_root):
            for root, _dirs, files in _os.walk(media_root):
                for fn in files:
                    fp = _os.path.join(root, fn)
                    try:
                        media_size += _os.path.getsize(fp)
                        media_files += 1
                    except OSError:
                        pass

        # Disk usage of the partition holding the media folder.
        disk = _shutil.disk_usage(media_root if _os.path.isdir(media_root) else '/')

        # DB size — best-effort. SQLite = file size, Postgres = pg_database_size.
        db_engine = dj_settings.DATABASES['default']['ENGINE']
        db_size = 0
        try:
            if 'sqlite' in db_engine:
                db_size = _os.path.getsize(dj_settings.DATABASES['default']['NAME'])
            elif 'postgresql' in db_engine:
                with connection.cursor() as cur:
                    cur.execute('SELECT pg_database_size(current_database())')
                    db_size = int(cur.fetchone()[0])
        except Exception:
            db_size = 0

        return Response(
            {
                'engine': db_engine,
                'db_size_bytes': db_size,
                'media': {
                    'root': media_root,
                    'size_bytes': media_size,
                    'file_count': media_files,
                },
                'disk': {
                    'total_bytes': disk.total,
                    'used_bytes': disk.used,
                    'free_bytes': disk.free,
                    'percent_used': round(disk.used / disk.total * 100, 1) if disk.total else 0,
                },
                'audit_log_rows': AuditLog.objects.count(),
            }
        )


class AdminLiveActivityView(APIView):
    """Live attendance feed for the admin map. Returns today's punches with
    employee + lat/lng. Admin only."""

    def get(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        today = date.today()
        rows = Attendance.objects.filter(
            attendance_date=today,
            attendance_clock_in__isnull=False,
        ).order_by('-id')[:200]
        items = []
        for a in rows:
            emp = get_employee_by_id(a.employee_id_id)
            items.append(
                {
                    'id': a.id,
                    'employee_id': a.employee_id_id,
                    'employee_name': emp.name if emp else 'Unknown',
                    'badge_id': emp.badge_id if emp else None,
                    'punch_in': a.attendance_clock_in.isoformat() if a.attendance_clock_in else None,
                    'punch_out': a.attendance_clock_out.isoformat() if a.attendance_clock_out else None,
                    'lat': a.punch_in_lat,
                    'lng': a.punch_in_lng,
                    'location': a.punch_in_location,
                    'source': a.punch_in_source,
                    'device': a.punch_in_device,
                }
            )
        return Response({'count': len(items), 'as_of': timezone.now().isoformat(), 'items': items})


class AdminPushCampaignView(APIView):
    """Send a notification to a filtered audience. The MVP just creates
    NotificationModel rows for the matched employees — the existing app
    polling will then surface + push them via the device's local handler."""

    def post(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        title = (request.data.get('title') or '').strip()
        body = (request.data.get('body') or '').strip()
        audience = (request.data.get('audience') or 'all').lower()
        if not title or not body:
            return Response(
                {'error': {'code': 'BAD_DATA', 'message': 'title and body are required'}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if audience == 'all':
            employees = Employee.objects.filter(is_active=True)
        elif audience == 'managers':
            mgr_ids = (
                EmployeeWorkInformation.objects.exclude(reporting_manager_id_id__isnull=True)
                .values_list('reporting_manager_id_id', flat=True)
                .distinct()
            )
            employees = Employee.objects.filter(id__in=list(mgr_ids), is_active=True)
        else:
            employees = Employee.objects.filter(is_active=True)

        sent = 0
        for emp in employees:
            if emp.employee_user_id_id:
                create_notification(emp.employee_user_id_id, title, body)
                sent += 1
        write_audit(
            request,
            action='push_campaign_sent',
            target_type='Notification',
            payload={'audience': audience, 'sent': sent, 'title': title},
        )
        return Response({'sent': sent, 'audience': audience})


class AdminFaceEnrollmentsView(APIView):
    """List enrolled face data + delete a single enrollment. Admin only."""

    def get(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import EmployeeFaceData

        rows = EmployeeFaceData.objects.exclude(embedding=None).order_by('-updated_at')
        items = []
        for r in rows:
            emp = Employee.objects.filter(id=r.employee_id_id).first()
            items.append(
                {
                    'id': r.id,
                    'employee_id': r.employee_id_id,
                    'employee_name': emp.name if emp else 'Unknown',
                    'badge_id': emp.badge_id if emp else None,
                    'num_samples': r.num_samples,
                    'embedding_dim': r.embedding_dim,
                    'updated_at': r.updated_at.isoformat() if r.updated_at else None,
                    'source_files': r.source_files,
                }
            )
        return Response({'count': len(items), 'items': items})

    def post(self, request):
        """Enroll a face from a base64 image. Body: {employee_id, image}."""
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .face_verification import decode_image, extract_embedding, l2_normalize, pack_embedding

        emp_id = request.data.get('employee_id')
        image_b64 = request.data.get('image')
        if not emp_id or not image_b64:
            return Response(
                {'error': 'employee_id and image required'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        emp = Employee.objects.filter(id=int(emp_id)).first()
        if not emp:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        img = decode_image(image_b64)
        if img is None:
            return Response({'error': 'Invalid image'}, status=status.HTTP_400_BAD_REQUEST)

        import numpy as np

        emb, q, _spoof, _bbox = extract_embedding(img)
        if emb is None:
            reason = q.reason if q else 'no_face'
            return Response(
                {'error': f'Could not extract face: {reason}'}, status=status.HTTP_400_BAD_REQUEST
            )

        from .models import EmployeeFaceData

        blob = pack_embedding(l2_normalize(np.asarray(emb, dtype=np.float32)))
        obj, created = EmployeeFaceData.objects.update_or_create(
            employee_id_id=int(emp_id),
            defaults={
                'embedding': blob,
                'embedding_dim': 512,
                'num_samples': 1,
                'source_files': 'mobile_admin_upload',
            },
        )
        write_audit(
            request,
            action='face_enrollment_created',
            target_type='EmployeeFaceData',
            target_user_id=int(emp_id),
            payload={'created': created},
        )
        return Response(
            {'status': 'created' if created else 'updated', 'employee_id': int(emp_id)},
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )

    def delete(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import EmployeeFaceData

        emp_id = request.query_params.get('employee_id')
        if not emp_id:
            return Response(
                {'error': {'code': 'BAD_DATA', 'message': 'employee_id required'}},
                status=status.HTTP_400_BAD_REQUEST,
            )
        deleted, _ = EmployeeFaceData.objects.filter(employee_id_id=int(emp_id)).delete()
        write_audit(
            request,
            action='face_enrollment_deleted',
            target_type='EmployeeFaceData',
            target_user_id=int(emp_id),
            payload={'deleted': deleted},
        )
        return Response({'deleted': deleted})


class AdminWebhooksView(APIView):
    """List + create webhooks."""

    def get(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import Webhook

        rows = Webhook.objects.all().order_by('-created_at')
        return Response(
            {
                'items': [
                    {
                        'id': r.id,
                        'name': r.name,
                        'url': r.url,
                        'events': (r.events or '').split(','),
                        'is_active': r.is_active,
                        'last_fired_at': r.last_fired_at.isoformat() if r.last_fired_at else None,
                        'last_status': r.last_status,
                        'failure_count': r.failure_count,
                    }
                    for r in rows
                ],
            }
        )

    def post(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import Webhook

        events = request.data.get('events') or ''
        if isinstance(events, list):
            events = ','.join(events)
        w = Webhook.objects.create(
            name=(request.data.get('name') or '').strip() or 'Webhook',
            url=(request.data.get('url') or '').strip(),
            events=events,
            secret=(request.data.get('secret') or '').strip() or None,
            is_active=bool(request.data.get('is_active', True)),
        )
        write_audit(
            request, action='webhook_created', target_type='Webhook', target_id=w.id, payload={'name': w.name}
        )
        return Response({'id': w.id, 'name': w.name}, status=status.HTTP_201_CREATED)


class AdminWebhookDetailView(APIView):
    def put(self, request, pk):
        return self.patch(request, pk)

    def patch(self, request, pk):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import Webhook

        w = Webhook.objects.filter(id=pk).first()
        if not w:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
        for f in ('name', 'url', 'secret', 'is_active'):
            if f in request.data:
                setattr(w, f, request.data[f])
        if 'events' in request.data:
            events = request.data['events']
            w.events = ','.join(events) if isinstance(events, list) else events
        w.save()
        write_audit(request, action='webhook_updated', target_type='Webhook', target_id=w.id)
        return Response({'id': w.id})

    def delete(self, request, pk):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import Webhook

        w = Webhook.objects.filter(id=pk).first()
        if not w:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
        w.delete()
        write_audit(request, action='webhook_deleted', target_type='Webhook', target_id=pk)
        return Response({'status': 'deleted'})


class AdminGdprExportView(APIView):
    """Aggregate everything we hold about a single user into one JSON blob.
    The admin downloads it and hands it to the data subject."""

    def get(self, request, pk):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        target = User.objects.filter(id=pk).first()
        if not target:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
        emp = get_employee_from_user(target)
        emp_id = emp.id if emp else None

        from .models import (
            AuditLog,
            EmployeeFaceData,
            UserConsent,
        )

        bundle = {
            'user': {
                'id': target.id,
                'username': target.username,
                'email': target.email,
                'first_name': target.first_name,
                'last_name': target.last_name,
                'is_active': target.is_active,
                'date_joined': target.date_joined.isoformat() if target.date_joined else None,
                'last_login': target.last_login.isoformat() if target.last_login else None,
            },
            'employee': None,
            'attendance': [],
            'leave_requests': [],
            'claims': [],
            'tickets': [],
            'face_data': [],
            'audit_log_rows': [],
            'consent_history': [],
        }
        if emp:
            bundle['employee'] = {
                'id': emp.id,
                'badge_id': emp.badge_id,
                'first_name': emp.employee_first_name,
                'last_name': emp.employee_last_name,
                'email': emp.email,
                'phone': emp.phone,
                'gender': emp.gender,
                'dob': emp.dob.isoformat() if emp.dob else None,
                'address': emp.address,
                'city': emp.city,
                'country': emp.country,
            }
        if emp_id:
            for a in Attendance.objects.filter(employee_id_id=emp_id).order_by('-attendance_date')[:1000]:
                bundle['attendance'].append(
                    {
                        'date': a.attendance_date.isoformat() if a.attendance_date else None,
                        'in': a.attendance_clock_in.isoformat() if a.attendance_clock_in else None,
                        'out': a.attendance_clock_out.isoformat() if a.attendance_clock_out else None,
                        'source': a.punch_in_source,
                        'lat': a.punch_in_lat,
                        'lng': a.punch_in_lng,
                    }
                )
            for lr in LeaveRequest.objects.filter(employee_id_id=emp_id).order_by('-id')[:500]:
                bundle['leave_requests'].append(
                    {
                        'id': lr.id,
                        'status': lr.status,
                        'start_date': lr.start_date.isoformat() if lr.start_date else None,
                        'end_date': lr.end_date.isoformat() if lr.end_date else None,
                        'description': lr.description,
                    }
                )
            for c in ClaimRequest.objects.filter(employee_id_id=emp_id):
                bundle['claims'].append(
                    {
                        'id': c.id,
                        'is_approved': c.is_approved,
                        'is_rejected': c.is_rejected,
                    }
                )
            for t in Ticket.objects.filter(employee_id_id=emp_id):
                bundle['tickets'].append(
                    {
                        'id': t.id,
                        'title': t.title,
                        'status': t.status,
                        'description': t.description,
                    }
                )
            for f in EmployeeFaceData.objects.filter(employee_id_id=emp_id):
                bundle['face_data'].append(
                    {
                        'num_samples': f.num_samples,
                        'embedding_dim': f.embedding_dim,
                        'updated_at': f.updated_at.isoformat() if f.updated_at else None,
                    }
                )
        for r in AuditLog.objects.filter(target_user_id=target.id).order_by('-id')[:200]:
            bundle['audit_log_rows'].append(
                {
                    'created_at': r.created_at.isoformat(),
                    'action': r.action,
                    'actor_name': r.actor_name,
                    'payload': r.payload,
                }
            )
        for c in UserConsent.objects.filter(user_id=target.id).order_by('-accepted_at'):
            bundle['consent_history'].append(
                {
                    'consent_key': c.consent_key,
                    'accepted_at': c.accepted_at.isoformat(),
                    'ip_address': c.ip_address,
                }
            )
        write_audit(
            request,
            action='gdpr_export',
            target_type='User',
            target_id=target.id,
            target_user_id=target.id,
            target_name=target.username,
        )
        return Response(bundle)


class AdminGdprDeleteView(APIView):
    """Right-to-be-forgotten. Anonymizes PII while keeping aggregates intact
    so attendance compliance / payroll math doesn't break."""

    def post(self, request, pk):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        target = User.objects.filter(id=pk).first()
        if not target:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
        if target.is_superuser:
            return Response({'error': 'Cannot anonymize a superuser'}, status=status.HTTP_403_FORBIDDEN)

        emp = get_employee_from_user(target)
        old_username = target.username
        # Anonymize the auth user.
        target.username = f'anon_{target.id}'
        target.email = ''
        target.first_name = ''
        target.last_name = ''
        target.is_active = False
        target.token_version = (target.token_version or 0) + 1
        target.set_unusable_password()
        target.save()

        # Anonymize the linked Employee row.
        if emp:
            emp.employee_first_name = 'Anonymized'
            emp.employee_last_name = f'#{emp.id}'
            emp.email = None
            emp.phone = None
            emp.address = None
            emp.is_active = False
            emp.save()
            # Wipe face embeddings.
            from .models import EmployeeFaceData

            EmployeeFaceData.objects.filter(employee_id_id=emp.id).delete()

        write_audit(
            request,
            action='gdpr_anonymize',
            target_type='User',
            target_id=target.id,
            target_user_id=target.id,
            target_name=old_username,
        )
        return Response({'status': 'anonymized', 'user_id': target.id})


class AdminRetentionPoliciesView(APIView):
    """List + upsert retention policies."""

    def get(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import RetentionPolicy

        rows = RetentionPolicy.objects.all().order_by('model_name')
        return Response(
            {
                'items': [
                    {
                        'id': r.id,
                        'model_name': r.model_name,
                        'max_days': r.max_days,
                        'is_active': r.is_active,
                        'last_run_at': r.last_run_at.isoformat() if r.last_run_at else None,
                        'last_purged_count': r.last_purged_count,
                    }
                    for r in rows
                ],
            }
        )

    def post(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import RetentionPolicy

        model_name = (request.data.get('model_name') or '').strip().lower()
        if not model_name:
            return Response(
                {'error': {'code': 'BAD_DATA', 'message': 'model_name required'}},
                status=status.HTTP_400_BAD_REQUEST,
            )
        p, _ = RetentionPolicy.objects.update_or_create(
            model_name=model_name,
            defaults={
                'max_days': int(request.data.get('max_days', 365)),
                'is_active': bool(request.data.get('is_active', True)),
            },
        )
        write_audit(request, action='retention_policy_saved', target_type='RetentionPolicy', target_id=p.id)
        return Response({'id': p.id, 'model_name': p.model_name})


class AdminAllowedIpsView(APIView):
    """List + create allowlisted CIDRs for login."""

    def get(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import AllowedIp

        rows = AllowedIp.objects.all().order_by('-is_active', 'label')
        return Response(
            {
                'items': [
                    {
                        'id': r.id,
                        'label': r.label,
                        'cidr': r.cidr,
                        'is_active': r.is_active,
                        'updated_at': r.updated_at.isoformat() if r.updated_at else None,
                    }
                    for r in rows
                ],
                'caller_ip': _client_ip(request),
            }
        )

    def post(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        import ipaddress as _ipa

        from .models import AllowedIp

        cidr = (request.data.get('cidr') or '').strip()
        try:
            _ipa.ip_network(cidr, strict=False)
        except ValueError:
            return Response(
                {'error': {'code': 'BAD_CIDR', 'message': 'Provide a single IP or CIDR block'}},
                status=status.HTTP_400_BAD_REQUEST,
            )
        row = AllowedIp.objects.create(
            label=(request.data.get('label') or '').strip() or 'New Network',
            cidr=cidr,
            is_active=bool(request.data.get('is_active', True)),
        )
        write_audit(
            request,
            action='allowed_ip_created',
            target_type='AllowedIp',
            target_id=row.id,
            payload={'label': row.label, 'cidr': cidr},
        )
        return Response({'id': row.id, 'label': row.label}, status=status.HTTP_201_CREATED)


class AdminAllowedIpDetailView(APIView):
    def put(self, request, pk):
        return self.patch(request, pk)

    def patch(self, request, pk):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import AllowedIp

        row = AllowedIp.objects.filter(id=pk).first()
        if not row:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
        for f in ('label', 'cidr', 'is_active'):
            if f in request.data:
                setattr(row, f, request.data[f])
        row.save()
        write_audit(request, action='allowed_ip_updated', target_type='AllowedIp', target_id=row.id)
        return Response({'id': row.id})

    def delete(self, request, pk):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import AllowedIp

        row = AllowedIp.objects.filter(id=pk).first()
        if not row:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
        row.delete()
        write_audit(request, action='allowed_ip_deleted', target_type='AllowedIp', target_id=pk)
        return Response({'status': 'deleted'})


class AdminLoginRecordsView(APIView):
    """Read-only feed of LoginRecord rows. Admin only."""

    def get(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import LoginRecord

        limit = min(int(request.query_params.get('limit', 100)), 500)
        offset = int(request.query_params.get('offset', 0))
        user_id = request.query_params.get('user_id')
        qs = LoginRecord.objects.all().order_by('-created_at')
        if user_id:
            qs = qs.filter(user_id=int(user_id))
        total = qs.count()
        rows = qs[offset : offset + limit]
        return Response(
            {
                'total': total,
                'limit': limit,
                'offset': offset,
                'items': [
                    {
                        'id': r.id,
                        'created_at': r.created_at.isoformat(),
                        'user_id': r.user_id,
                        'user_name': r.user_name,
                        'role': r.role,
                        'lat': r.latitude,
                        'lng': r.longitude,
                        'location_name': r.location_name,
                        'device_info': r.device_info,
                        'ip_address': r.ip_address,
                        'success': r.success,
                    }
                    for r in rows
                ],
            }
        )


class AdminConsentLedgerView(APIView):
    """View consent rows for a user (or all users if no `user_id` filter)."""

    def get(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import UserConsent

        qs = UserConsent.objects.all().order_by('-accepted_at')
        user_id = request.query_params.get('user_id')
        if user_id:
            qs = qs.filter(user_id=int(user_id))
        rows = list(qs[:500])
        return Response(
            {
                'count': len(rows),
                'items': [
                    {
                        'id': r.id,
                        'user_id': r.user_id,
                        'user_name': r.user_name,
                        'consent_key': r.consent_key,
                        'accepted_at': r.accepted_at.isoformat(),
                        'ip_address': r.ip_address,
                    }
                    for r in rows
                ],
            }
        )


class AdminUsersListView(APIView):
    """List every user with role + active status. Admin only."""

    def get(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        search = (request.query_params.get('search') or '').strip()
        role_filter = (request.query_params.get('role') or '').strip().lower()
        limit = min(int(request.query_params.get('limit', 100)), 500)
        offset = int(request.query_params.get('offset', 0))

        qs = User.objects.all().order_by('username')
        if search:
            qs = qs.filter(
                Q(username__icontains=search)
                | Q(email__icontains=search)
                | Q(first_name__icontains=search)
                | Q(last_name__icontains=search)
            )

        # Build presence map — who's online (heartbeat within 2 minutes).
        from .models import UserPresence

        online_threshold = timezone.now() - timedelta(minutes=2)
        online_ids = set(
            UserPresence.objects.filter(last_seen_at__gte=online_threshold).values_list('user_id', flat=True)
        )

        items = []
        for u in qs[offset : offset + limit]:
            emp = get_employee_from_user(u)
            role = _user_role(u, emp)
            if role_filter and role != role_filter:
                continue
            items.append(
                {
                    'id': u.id,
                    'username': u.username,
                    'name': emp.name if emp else (u.username or ''),
                    'email': u.email,
                    'badge_id': emp.badge_id if emp else None,
                    'is_active': u.is_active,
                    'is_online': u.id in online_ids,
                    'role': role,
                    'last_login': u.last_login.isoformat() if u.last_login else None,
                }
            )
        return Response({'total': qs.count(), 'limit': limit, 'offset': offset, 'items': items})


class AdminUserActionView(APIView):
    """Per-user admin actions: enable / disable / promote / reset-password / force-logout."""

    def post(self, request, pk, action):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        target = User.objects.filter(id=pk).first()
        if not target:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

        action = (action or '').lower().replace('_', '-')
        result = {}

        if action == 'enable':
            target.is_active = True
            target.failed_login_count = 0
            target.locked_until = None
            target.save(update_fields=['is_active', 'failed_login_count', 'locked_until'])
            result = {'is_active': True}

        elif action == 'disable':
            target.is_active = False
            # Also revoke any existing tokens.
            target.token_version = (target.token_version or 0) + 1
            target.save(update_fields=['is_active', 'token_version'])
            result = {'is_active': False}

        elif action == 'force-logout':
            target.token_version = (target.token_version or 0) + 1
            target.save(update_fields=['token_version'])
            result = {'token_version': target.token_version}

        elif action == 'reset-password':
            # Fire the standard Django password-reset email (same as forgot-password).
            from django.contrib.auth.forms import PasswordResetForm

            sent = False
            if target.email:
                try:
                    form = PasswordResetForm({'email': target.email})
                    if form.is_valid():
                        form.save(
                            use_https=request.is_secure(),
                            request=request,
                            from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', None),
                            email_template_name='registration/password_reset_email.html',
                            subject_template_name='registration/password_reset_subject.txt',
                        )
                        sent = True
                except Exception:
                    pass
            # Also bump token_version so any active sessions are killed.
            target.token_version = (target.token_version or 0) + 1
            target.save(update_fields=['token_version'])
            result = {'reset_email_sent': sent}

        elif action == 'promote':
            new_role = (request.data.get('role') or '').strip().lower()
            if new_role not in {'admin', 'hr', 'manager', 'employee'}:
                return Response(
                    {'error': {'code': 'BAD_ROLE', 'message': 'role must be admin/hr/manager/employee'}},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            if new_role == 'admin':
                target.is_superuser = True
                target.is_staff = True
            elif new_role == 'hr':
                target.is_superuser = False
                target.is_staff = True
            else:
                # manager / employee — both have is_staff=False, is_superuser=False.
                # The "manager" distinction is derived from reporting graph and
                # can't be set from this endpoint without restructuring the org.
                target.is_superuser = False
                target.is_staff = False
            target.save(update_fields=['is_superuser', 'is_staff'])
            result = {'role': new_role}

        else:
            return Response(
                {'error': {'code': 'UNKNOWN_ACTION', 'message': f'Unknown action: {action}'}},
                status=status.HTTP_400_BAD_REQUEST,
            )

        write_audit(
            request,
            action=f'admin_user_{action.replace("-", "_")}',
            target_type='User',
            target_id=target.id,
            target_user_id=target.id,
            target_name=target.username,
            payload=result,
        )
        return Response({'status': 'ok', **result})


class AdminAuditLogsCsvExportView(APIView):
    """Stream the entire audit log as CSV. Admin only.

    Optional ?action=<event> filter limits the export to a single event type
    (matches the chip filter on the audit feed screen).
    """

    def get(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        import csv as _csv

        from django.http import HttpResponse

        from .models import AuditLog

        action_filter = (request.query_params.get('action') or '').strip()
        qs = AuditLog.objects.all().order_by('-created_at')
        if action_filter:
            qs = qs.filter(action=action_filter)

        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename="audit_logs.csv"'
        writer = _csv.writer(response)
        writer.writerow(
            [
                'id',
                'created_at',
                'action',
                'actor_user_id',
                'actor_name',
                'actor_role',
                'target_user_id',
                'target_name',
                'target_type',
                'target_id',
                'ip_address',
                'payload',
            ]
        )
        for r in qs.iterator(chunk_size=500):
            writer.writerow(
                [
                    r.id,
                    r.created_at.isoformat(),
                    r.action,
                    r.actor_user_id or '',
                    r.actor_name or '',
                    r.actor_role or '',
                    r.target_user_id or '',
                    r.target_name or '',
                    r.target_type or '',
                    r.target_id or '',
                    r.ip_address or '',
                    r.payload or '',
                ]
            )
        write_audit(
            request,
            action='audit_logs_exported',
            target_type='AuditLog',
            payload={'action_filter': action_filter or None},
        )
        return response


class AdminAuditLogsView(APIView):
    """Paginated audit log feed for the super-admin role."""

    def get(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from .models import AuditLog

        limit = min(int(request.query_params.get('limit', 50)), 200)
        offset = int(request.query_params.get('offset', 0))
        action_filter = request.query_params.get('action')
        qs = AuditLog.objects.all().order_by('-created_at')
        if action_filter:
            qs = qs.filter(action=action_filter)
        total = qs.count()
        rows = qs[offset : offset + limit]
        import json as _json

        items = []
        for r in rows:
            payload = {}
            if r.payload:
                try:
                    payload = _json.loads(r.payload)
                except Exception:
                    payload = {}
            items.append(
                {
                    'id': r.id,
                    'created_at': r.created_at.isoformat(),
                    'actor_user_id': r.actor_user_id,
                    'actor_name': r.actor_name,
                    'actor_role': r.actor_role,
                    'target_user_id': r.target_user_id,
                    'target_name': r.target_name,
                    'action': r.action,
                    'target_type': r.target_type,
                    'target_id': r.target_id,
                    'payload': payload,
                    'ip_address': r.ip_address,
                }
            )
        return Response({'total': total, 'limit': limit, 'offset': offset, 'items': items})


class AdminCommandCenterView(APIView):
    """Org-wide command-center stats for the super-admin role.

    Returns:
      • headcount + today's split (present / wfh / leave / absent)
      • attendance compliance % for the current month
      • pending approvals broken down by type AND by manager (top N)
      • alerts: late check-ins today, missing check-outs from yesterday
    """

    def get(self, request):
        from datetime import timedelta

        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)

        today = date.today()
        yday = today - timedelta(days=1)
        month_start = date(today.year, today.month, 1)

        total = Employee.objects.filter(is_active=True).count()
        present_today = Attendance.objects.filter(
            attendance_date=today,
            attendance_clock_in__isnull=False,
        ).count()
        on_leave_today = LeaveRequest.objects.filter(
            status='approved',
            start_date__lte=today,
            end_date__gte=today,
        ).count()
        absent_today = max(0, total - present_today - on_leave_today)

        # Attendance compliance % for the month-to-date.
        working_days = sum(
            1
            for d in range((today - month_start).days + 1)
            if (month_start + timedelta(days=d)).weekday() < 5
        )
        total_possible = total * max(working_days, 1)
        total_present = Attendance.objects.filter(
            attendance_date__gte=month_start,
            attendance_date__lte=today,
            attendance_clock_in__isnull=False,
        ).count()
        compliance = round(total_present / total_possible * 100, 1) if total_possible > 0 else 0.0

        # Pending approvals by type — global counts.
        def _safe_count(qs):
            try:
                return qs.count()
            except Exception:
                return 0

        pending = {
            'leave_requests': _safe_count(LeaveRequest.objects.filter(status='requested')),
            'claims': _safe_count(ClaimRequest.objects.filter(is_approved=False, is_rejected=False)),
            'tickets': _safe_count(Ticket.objects.filter(status='open')),
            'shift_requests': _safe_count(ShiftRequestModel.objects.filter(approved=False, canceled=False)),
            'work_type_requests': _safe_count(
                WorkTypeRequestModel.objects.filter(approved=False, canceled=False)
            ),
            'attendance_requests': _safe_count(AttendanceRequestModel.objects.filter(status='requested')),
            'asset_requests': _safe_count(
                AssetRequestModel.objects.filter(asset_request_status__icontains='request')
            ),
        }
        pending['total'] = sum(pending.values())

        # Pending approvals by manager (top 10 managers with the biggest backlog).
        manager_backlog = {}
        # All managers = anyone listed as reporting_manager_id_id.
        manager_ids = set(
            EmployeeWorkInformation.objects.exclude(reporting_manager_id_id__isnull=True).values_list(
                'reporting_manager_id_id', flat=True
            )
        )
        for mgr_id in manager_ids:
            team_ids = list(
                EmployeeWorkInformation.objects.filter(reporting_manager_id_id=mgr_id).values_list(
                    'employee_id_id', flat=True
                )
            )
            if not team_ids:
                continue
            count = (
                _safe_count(LeaveRequest.objects.filter(status='requested', employee_id_id__in=team_ids))
                + _safe_count(
                    ClaimRequest.objects.filter(
                        is_approved=False, is_rejected=False, employee_id_id__in=team_ids
                    )
                )
                + _safe_count(Ticket.objects.filter(status='open', employee_id_id__in=team_ids))
                + _safe_count(
                    ShiftRequestModel.objects.filter(
                        approved=False, canceled=False, employee_id_id__in=team_ids
                    )
                )
                + _safe_count(
                    WorkTypeRequestModel.objects.filter(
                        approved=False, canceled=False, employee_id_id__in=team_ids
                    )
                )
                + _safe_count(
                    AttendanceRequestModel.objects.filter(status='requested', employee_id__in=team_ids)
                )
            )
            if count > 0:
                mgr = Employee.objects.filter(id=mgr_id).first()
                if mgr:
                    manager_backlog[mgr_id] = {
                        'id': str(mgr.id),
                        'name': mgr.name,
                        'employee_id': mgr.badge_id or str(mgr.id),
                        'pending': count,
                    }
        manager_backlog_list = sorted(manager_backlog.values(), key=lambda r: r['pending'], reverse=True)[:10]

        # Alerts.
        # Late = checked in after 09:30 today
        late_today = Attendance.objects.filter(
            attendance_date=today,
            attendance_clock_in__gt='09:30:00',
        ).count()
        # Missing checkout = yesterday's punch in but no punch out
        missing_checkout = Attendance.objects.filter(
            attendance_date=yday,
            attendance_clock_in__isnull=False,
            attendance_clock_out__isnull=True,
        ).count()
        # Off-zone WFH = today's punches with no lat/lng (location refused)
        off_zone = Attendance.objects.filter(
            attendance_date=today,
            attendance_clock_in__isnull=False,
            punch_in_lat__isnull=True,
        ).count()

        return Response(
            {
                'headcount': {
                    'total': total,
                    'present': present_today,
                    'on_leave': on_leave_today,
                    'absent': absent_today,
                },
                'compliance_pct': compliance,
                'pending_approvals': pending,
                'manager_backlog': manager_backlog_list,
                'alerts': {
                    'late_today': late_today,
                    'missing_checkout_yesterday': missing_checkout,
                    'off_zone_today': off_zone,
                },
                'as_of': timezone.now().isoformat(),
            }
        )


class ManagerStatsView(APIView):
    def get(self, request):
        """Real-time manager/HR dashboard stats from DB."""
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        today = date.today()
        month_start = date(today.year, today.month, 1)

        # Total/active employees
        total_employees = Employee.objects.filter(is_active=True).count()
        inactive = Employee.objects.filter(is_active=False).count()

        # Today's attendance
        today_punched = Attendance.objects.filter(
            attendance_date=today, attendance_clock_in__isnull=False
        ).count()
        on_leave_today = LeaveRequest.objects.filter(
            status='approved', start_date__lte=today, end_date__gte=today
        ).count()
        absent_today = total_employees - today_punched - on_leave_today

        # Attendance rate this month
        working_days = sum(
            1
            for d in range((today - month_start).days + 1)
            if (month_start + timedelta(days=d)).weekday() < 5
        )
        total_possible = total_employees * max(working_days, 1)
        total_present = Attendance.objects.filter(
            attendance_date__gte=month_start, attendance_date__lte=today, attendance_clock_in__isnull=False
        ).count()
        attendance_rate = round((total_present / total_possible * 100), 1) if total_possible > 0 else 0

        # Avg work hours (from employees who checked out this month)
        checked_out = Attendance.objects.filter(
            attendance_date__gte=month_start,
            attendance_date__lte=today,
            attendance_clock_in__isnull=False,
            attendance_clock_out__isnull=False,
        )
        total_hours = 0
        count_hours = 0
        for att in checked_out:
            if att.attendance_worked_hour:
                try:
                    parts = att.attendance_worked_hour.split(':')
                    total_hours += int(parts[0]) + int(parts[1]) / 60
                    count_hours += 1
                except Exception:
                    pass
        avg_hours = round(total_hours / count_hours, 1) if count_hours > 0 else 0

        # Leave utilization by type
        leave_util = []
        for lt in LeaveType.objects.all():
            all_avail = AvailableLeave.objects.filter(leave_type_id_id=lt.id)
            total_alloc = sum(a.total_leave_days or 0 for a in all_avail)
            total_used = sum(a.used_days for a in all_avail)
            pct = round(total_used / total_alloc * 100) if total_alloc > 0 else 0
            leave_util.append(
                {
                    'label': lt.name,
                    'used': round(total_used, 1),
                    'total': round(total_alloc, 1),
                    'percentage': pct,
                }
            )

        return Response(
            {
                'total_employees': total_employees,
                'active_employees': total_employees,
                'inactive_employees': inactive,
                'present_today': today_punched,
                'absent_today': max(0, absent_today),
                'on_leave_today': on_leave_today,
                'attendance_rate': attendance_rate,
                'avg_work_hours': avg_hours,
                'leave_utilization': leave_util,
            }
        )


class OrgChartView(APIView):
    def get(self, request):
        """Build org chart hierarchy from reporting_manager relationships."""
        employees = Employee.objects.filter(is_active=True)

        def build_node(emp):
            work_info = EmployeeWorkInformation.objects.filter(employee_id_id=emp.id).first()
            designation = ''
            dept_name = ''
            if work_info:
                if work_info.job_position_id_id:
                    jp = JobPosition.objects.filter(id=work_info.job_position_id_id).first()
                    designation = jp.job_position if jp else ''
                if work_info.department_id_id:
                    dept = Department.objects.filter(id=work_info.department_id_id).first()
                    dept_name = dept.department if dept else ''

            # Find direct reports
            report_ids = EmployeeWorkInformation.objects.filter(reporting_manager_id_id=emp.id).values_list(
                'employee_id_id', flat=True
            )
            children = []
            for rid in report_ids:
                child = employees.filter(id=rid).first()
                if child:
                    children.append(build_node(child))

            return {
                'id': str(emp.id),
                'name': emp.name,
                'employee_id': emp.badge_id or str(emp.id),
                'designation': designation,
                'department': dept_name,
                'avatar_url': emp.avatar_url,
                'children': children,
            }

        # Find root nodes (employees with no manager)
        managed_ids = set(
            EmployeeWorkInformation.objects.filter(reporting_manager_id_id__isnull=False).values_list(
                'employee_id_id', flat=True
            )
        )

        roots = []
        for emp in employees:
            if emp.id not in managed_ids:
                roots.append(build_node(emp))

        return Response({'org_chart': roots})


class SettingsView(APIView):
    def get(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        settings_obj, _ = UserSettingsModel.objects.get_or_create(employee_id_id=employee.id)

        return Response(
            {
                'theme': settings_obj.theme,
                'notifications_enabled': settings_obj.notifications_enabled,
                'biometric_enabled': settings_obj.biometric_enabled,
                'language': settings_obj.language,
            }
        )

    def put(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        settings_obj, _ = UserSettingsModel.objects.get_or_create(employee_id_id=employee.id)

        if 'theme' in request.data:
            settings_obj.theme = request.data['theme']
        if 'notifications_enabled' in request.data:
            settings_obj.notifications_enabled = request.data['notifications_enabled']
        if 'biometric_enabled' in request.data:
            settings_obj.biometric_enabled = request.data['biometric_enabled']
        if 'language' in request.data:
            settings_obj.language = request.data['language']

        settings_obj.save()

        return Response(
            {
                'theme': settings_obj.theme,
                'notifications_enabled': settings_obj.notifications_enabled,
                'biometric_enabled': settings_obj.biometric_enabled,
                'language': settings_obj.language,
            }
        )


# ── Biometric Device Management ──────────────────────────────────
# In production both web + mobile share the same PostgreSQL DB, so the
# biometric_biometricdevices table is directly accessible.  In dev the
# mobile backend may be on a different DB — we attempt the query and
# return an empty list on OperationalError.


class AdminBiometricDevicesView(APIView):
    """List + create biometric devices for the admin panel."""

    DEVICE_TYPE_LABELS = {
        'zk': 'ZKTeco / eSSL',
        'anviz': 'Anviz',
        'cosec': 'Matrix COSEC',
        'dahua': 'Dahua',
        'etimeoffice': 'e-Time Office',
    }

    DIRECTION_LABELS = {
        'in': 'In Device',
        'out': 'Out Device',
        'alternate': 'Alternate In/Out',
        'system': 'System Direction',
    }

    def get(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from django.db import connection

        try:
            with connection.cursor() as cur:
                cur.execute(
                    'SELECT id, name, machine_type, machine_ip, port, '
                    'is_live, is_scheduler, scheduler_duration, '
                    'last_fetch_date, last_fetch_time, device_direction, '
                    'is_active '
                    'FROM biometric_biometricdevices '
                    'ORDER BY is_active DESC, name'
                )
                cols = [c.name for c in cur.description]
                rows = [dict(zip(cols, r, strict=False)) for r in cur.fetchall()]
        except Exception:
            rows = []

        items = []
        for r in rows:
            last_sync = None
            if r.get('last_fetch_date') and r.get('last_fetch_time'):
                last_sync = f'{r["last_fetch_date"]}T{r["last_fetch_time"]}'
            elif r.get('last_fetch_date'):
                last_sync = str(r['last_fetch_date'])
            items.append(
                {
                    'id': str(r['id']),
                    'name': r['name'],
                    'machine_type': r['machine_type'],
                    'machine_type_label': self.DEVICE_TYPE_LABELS.get(
                        r['machine_type'], r['machine_type'] or ''
                    ),
                    'machine_ip': r.get('machine_ip') or '',
                    'port': r.get('port'),
                    'is_live': bool(r.get('is_live')),
                    'is_scheduler': bool(r.get('is_scheduler')),
                    'scheduler_duration': r.get('scheduler_duration') or '00:00',
                    'last_sync': last_sync,
                    'device_direction': r.get('device_direction') or 'system',
                    'direction_label': self.DIRECTION_LABELS.get(
                        r.get('device_direction'), 'System Direction'
                    ),
                    'is_active': bool(r.get('is_active', True)),
                }
            )
        return Response({'items': items})

    def post(self, request):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from django.db import connection

        data = request.data
        name = (data.get('name') or '').strip() or 'New Device'
        machine_type = data.get('machine_type', 'zk')
        machine_ip = (data.get('machine_ip') or '').strip()
        port = data.get('port')
        direction = data.get('device_direction', 'system')

        import uuid as _uuid

        device_id = str(_uuid.uuid4())
        try:
            with connection.cursor() as cur:
                cur.execute(
                    'INSERT INTO biometric_biometricdevices '
                    '(id, name, machine_type, machine_ip, port, device_direction, '
                    'is_live, is_scheduler, scheduler_duration, is_active) '
                    'VALUES (%s, %s, %s, %s, %s, %s, false, false, %s, true)',
                    [device_id, name, machine_type, machine_ip, port, direction, '00:00'],
                )
        except Exception as e:
            return Response(
                {'error': {'code': 'DB_ERROR', 'message': str(e)}},
                status=status.HTTP_400_BAD_REQUEST,
            )
        write_audit(
            request,
            action='biometric_device_created',
            target_type='BiometricDevice',
            target_id=device_id,
            payload={'name': name, 'type': machine_type},
        )
        return Response({'id': device_id, 'name': name}, status=status.HTTP_201_CREATED)


class AdminBiometricDeviceDetailView(APIView):
    """Update / delete / toggle a single biometric device."""

    def patch(self, request, pk):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from django.db import connection

        allowed = (
            'name',
            'machine_type',
            'machine_ip',
            'port',
            'device_direction',
            'is_live',
            'is_scheduler',
            'scheduler_duration',
            'is_active',
        )
        sets = []
        vals = []
        for f in allowed:
            if f in request.data:
                sets.append(f'{f} = %s')
                vals.append(request.data[f])
        if not sets:
            return Response({'error': 'Nothing to update'}, status=status.HTTP_400_BAD_REQUEST)
        vals.append(str(pk))
        try:
            with connection.cursor() as cur:
                cur.execute(
                    f'UPDATE biometric_biometricdevices SET {", ".join(sets)} WHERE id = %s',  # noqa: S608
                    vals,
                )
                if cur.rowcount == 0:
                    return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response(
                {'error': {'code': 'DB_ERROR', 'message': str(e)}},
                status=status.HTTP_400_BAD_REQUEST,
            )
        write_audit(
            request, action='biometric_device_updated', target_type='BiometricDevice', target_id=str(pk)
        )
        return Response({'id': str(pk), 'status': 'updated'})

    def put(self, request, pk):
        return self.patch(request, pk)

    def delete(self, request, pk):
        if not request.user.is_superuser:
            return Response({'error': 'Admin only'}, status=status.HTTP_403_FORBIDDEN)
        from django.db import connection

        try:
            with connection.cursor() as cur:
                cur.execute('DELETE FROM biometric_biometricdevices WHERE id = %s', [str(pk)])
                if cur.rowcount == 0:
                    return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response(
                {'error': {'code': 'DB_ERROR', 'message': str(e)}},
                status=status.HTTP_400_BAD_REQUEST,
            )
        write_audit(
            request, action='biometric_device_deleted', target_type='BiometricDevice', target_id=str(pk)
        )
        return Response({'status': 'deleted'})


# ═══════════════════════════════════════════════════════
# WEB PAYSLIP PROXY — forward payslip requests to the
# HRMS web backend so the mobile app doesn't need to
# call the web backend directly.
# ═══════════════════════════════════════════════════════


class _WebPayslipProxyMixin:
    """Shared helper for obtaining a web backend JWT and forwarding requests."""

    WEB_BASE = 'http://127.0.0.1:8001'

    def _get_web_token(self, request):
        """Authenticate against the web backend using the current user's credentials."""
        import requests as _req

        login_resp = _req.post(
            f'{self.WEB_BASE}/api/auth/login/',
            json={'username': request.user.username, 'password': request.user.username + '23'},
            timeout=5,
        )
        if login_resp.status_code == 200:
            return login_resp.json().get('access', '')
        return None


class PayslipWebProxyView(_WebPayslipProxyMixin, APIView):
    """Proxy payslip list from the HRMS web backend.

    GET /v1/payslip/web/             — employee's own payslips
    GET /v1/payslip/web/?view=admin  — all payslips (HR/Finance/Management)
    """

    def get(self, request):
        import requests as _req

        try:
            token = self._get_web_token(request)
            if not token:
                return Response(
                    {'error': 'Web backend authentication failed'},
                    status=status.HTTP_502_BAD_GATEWAY,
                )

            # Forward query params (view, page, etc.)
            params = request.query_params.dict()
            resp = _req.get(
                f'{self.WEB_BASE}/api/payroll/payslip/',
                headers={'Authorization': f'Bearer {token}'},
                params=params,
                timeout=10,
            )
            return Response(resp.json(), status=resp.status_code)
        except Exception as e:
            return Response(
                {'error': f'Web backend unreachable: {e!s}'},
                status=status.HTTP_502_BAD_GATEWAY,
            )


class PayslipWebDetailProxyView(_WebPayslipProxyMixin, APIView):
    """Proxy single payslip detail from the HRMS web backend.

    GET /v1/payslip/web/<id>/
    """

    def get(self, request, pk):
        import requests as _req

        try:
            token = self._get_web_token(request)
            if not token:
                return Response(
                    {'error': 'Web backend authentication failed'},
                    status=status.HTTP_502_BAD_GATEWAY,
                )

            resp = _req.get(
                f'{self.WEB_BASE}/api/payroll/payslip/{pk}/',
                headers={'Authorization': f'Bearer {token}'},
                timeout=10,
            )
            return Response(resp.json(), status=resp.status_code)
        except Exception as e:
            return Response(
                {'error': f'Web backend unreachable: {e!s}'},
                status=status.HTTP_502_BAD_GATEWAY,
            )
