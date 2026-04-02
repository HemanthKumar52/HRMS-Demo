from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.db.models import Q
from datetime import datetime, date, timedelta
from calendar import monthrange

from .models import (
    Employee, Department, JobPosition, EmployeeWorkInformation,
    Shift, WorkType, Attendance, LeaveType, AvailableLeave, LeaveRequest,
    ClaimRequest, Ticket, TicketType, ShiftRequestModel, WorkTypeRequestModel,
    AttendanceRequestModel, AssetRequestModel,
    Payslip, NotificationModel, Announcement, DeviceTokenModel, UserSettingsModel
)
from .serializers import (
    PayslipSerializer, NotificationSerializer,
    LoginSerializer, RefreshTokenSerializer, ChangePasswordSerializer,
    UserProfileUpdateSerializer, PunchInSerializer, PunchOutSerializer,
    LeaveApplySerializer, ClaimSubmitSerializer, TicketRaiseSerializer,
    ShiftRequestCreateSerializer, WorkTypeRequestCreateSerializer,
    AttendanceRegularizeSerializer, AssetRequestCreateSerializer,
    RequestActionSerializer, DeviceRegisterSerializer
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
    return f"{prefix}-{str(obj_id).zfill(4)}"


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


def notify_managers_of_request(employee, request_type, title):
    """Notify the employee's manager about a new request."""
    work_info = EmployeeWorkInformation.objects.filter(employee_id_id=employee.id).first()
    if work_info and work_info.reporting_manager_id_id:
        manager = get_employee_by_id(work_info.reporting_manager_id_id)
        if manager and manager.employee_user_id_id:
            create_notification(
                manager.employee_user_id_id,
                f'New {request_type} Request',
                f'{employee.name} submitted: {title}'
            )


class AuthView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data['user']

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

        # Determine role
        if user.is_staff:
            role = 'hr'
        elif EmployeeWorkInformation.objects.filter(reporting_manager_id_id=employee.id).exists():
            role = 'manager'
        else:
            role = 'employee'

        refresh = RefreshToken.for_user(user)

        return Response({
            'access_token': str(refresh.access_token),
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
                'role': role
            }
        })


class RefreshTokenView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RefreshTokenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        refresh_token = serializer.validated_data['refresh_token']

        try:
            refresh = RefreshToken(refresh_token)
            return Response({
                'access_token': str(refresh.access_token),
                'refresh_token': str(refresh),
                'expires_in': 3600
            })
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
                        'employee_id': reporting_emp.badge_id or str(reporting_emp.id)
                    }

        # Determine role: hr if is_staff, manager if has direct reports, else employee
        if user.is_staff:
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

        return Response({
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
        })

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
        file_path = f"media/avatars/{uploaded_file.name}"
        employee.employee_profile = file_path
        employee.save()

        return Response({
            'avatar_url': file_path
        })


class AttendancePunchInView(APIView):
    def post(self, request):
        serializer = PunchInSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        today = date.today()

        existing = Attendance.objects.filter(employee_id_id=employee.id, attendance_date=today).first()
        if existing and existing.attendance_clock_in is not None:
            return Response({'error': {'code': 'ALREADY_PUNCHED_IN', 'message': 'Already clocked in today'}},
                           status=status.HTTP_400_BAD_REQUEST)

        now = timezone.now()

        if existing:
            existing.attendance_clock_in = now.time()
            existing.attendance_clock_in_date = today
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
            )

        return Response({
            'id': str(attendance.id),
            'employee_id': employee.badge_id or str(employee.id),
            'punch_in': attendance.attendance_clock_in.isoformat(),
            'punch_out': attendance.attendance_clock_out.isoformat() if attendance.attendance_clock_out else None,
            'status': attendance.computed_status,
            'method': request.data.get('method', 'password')
        })


class AttendancePunchOutView(APIView):
    def post(self, request):
        serializer = PunchOutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        today = date.today()

        attendance = Attendance.objects.filter(employee_id_id=employee.id, attendance_date=today).first()
        if not attendance or attendance.attendance_clock_in is None:
            return Response({'error': {'code': 'NOT_PUNCHED_IN', 'message': 'Cannot punch out without punching in'}},
                           status=status.HTTP_400_BAD_REQUEST)

        now = timezone.now()
        attendance.attendance_clock_out = now.time()
        attendance.attendance_clock_out_date = today

        if attendance.attendance_clock_in:
            in_seconds = attendance.attendance_clock_in.hour * 3600 + attendance.attendance_clock_in.minute * 60
            out_seconds = now.hour * 3600 + now.minute * 60
            worked_seconds = max(0, out_seconds - in_seconds)
            hours = worked_seconds // 3600
            minutes = (worked_seconds % 3600) // 60
            attendance.attendance_worked_hour = f"{hours:02d}:{minutes:02d}"

        attendance.save()

        return Response({
            'id': str(attendance.id),
            'punch_in': attendance.attendance_clock_in.isoformat(),
            'punch_out': attendance.attendance_clock_out.isoformat(),
            'total_hours': attendance.attendance_worked_hour or '00:00',
            'status': attendance.computed_status
        })


class AttendanceTodayView(APIView):
    def get(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        today = date.today()
        attendance = Attendance.objects.filter(employee_id_id=employee.id, attendance_date=today).first()

        if not attendance:
            return Response({
                'id': None,
                'punch_in': None,
                'punch_out': None,
                'status': 'not_clocked_in',
                'total_hours': '00:00',
                'method': None
            })

        return Response({
            'id': str(attendance.id),
            'punch_in': attendance.attendance_clock_in.isoformat() if attendance.attendance_clock_in else None,
            'punch_out': attendance.attendance_clock_out.isoformat() if attendance.attendance_clock_out else None,
            'status': attendance.computed_status,
            'total_hours': attendance.attendance_worked_hour or '00:00',
            'method': None
        })


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
            employee_id_id=employee.id,
            attendance_date__gte=start_date,
            attendance_date__lte=end_date
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

            daily.append({
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
            })

        working_days = present + absent + leave + half_days

        return Response({
            'summary': {
                'working_days': working_days,
                'present': present,
                'absent': absent,
                'leave': leave,
                'holidays': 0,
                'half_days': half_days,
                'on_duty': 0
            },
            'daily': daily
        })


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
            employee_id_id=employee.id,
            attendance_date__gte=week_start,
            attendance_date__lte=week_end
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
                punch_in_val = att.attendance_clock_in.hour + att.attendance_clock_in.minute / 60 if att.attendance_clock_in else 0
                punch_out_val = att.attendance_clock_out.hour + att.attendance_clock_out.minute / 60 if att.attendance_clock_out else 0
                punch_times.append({
                    'day': weekday,
                    'punch_in': round(punch_in_val, 2),
                    'punch_out': round(punch_out_val, 2)
                })
            else:
                absent += 1
                daily_hours.append({'day': weekday, 'hours': 0})
                punch_times.append({'day': weekday, 'punch_in': 0, 'punch_out': 0})

        return Response({
            'weeks': [{
                'week': f"Week of {week_start}",
                'present': present,
                'absent': absent,
                'leave': leave
            }],
            'daily_hours': daily_hours,
            'punch_times': punch_times
        })


class AttendanceTeamView(APIView):
    def get(self, request):
        month = int(request.query_params.get('month', datetime.now().month))
        year = int(request.query_params.get('year', datetime.now().year))

        employees = Employee.objects.filter(is_active=True)
        today = date.today()

        present_today = 0
        absent_today = 0
        on_leave_today = 0

        team_members = []

        for emp in employees[:50]:
            attendance = Attendance.objects.filter(employee_id_id=emp.id, attendance_date=today).first()

            if attendance and attendance.attendance_clock_in is not None:
                status_val = 'present'
                present_today += 1
            else:
                status_val = 'absent'
                absent_today += 1

            team_members.append({
                'employee_id': emp.badge_id or str(emp.id),
                'name': emp.name,
                'status': status_val,
                'punch_in': attendance.attendance_clock_in.isoformat() if attendance and attendance.attendance_clock_in else None
            })

        return Response({
            'total_employees': employees.count(),
            'present_today': present_today,
            'absent_today': absent_today,
            'on_leave_today': on_leave_today,
            'team_members': team_members
        })


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

            balances.append({
                'type': str(leave.leave_type_id_id),
                'label': label,
                'total': total,
                'used': used,
                'remaining': remaining
            })
            total_remaining += remaining

        return Response({
            'balances': balances,
            'total_remaining': total_remaining
        })


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
            leave_type = LeaveType.objects.filter(id=leave_type_val).first() if leave_type_val.isdigit() else None
        if not leave_type:
            return Response({'error': 'Invalid leave type'}, status=status.HTTP_400_BAD_REQUEST)

        available = AvailableLeave.objects.filter(employee_id_id=employee.id, leave_type_id_id=leave_type.id).first()

        start_date = serializer.validated_data['start_date']
        end_date = serializer.validated_data.get('end_date') or start_date

        requested_days = (end_date - start_date).days + 1

        if available and (available.available_days or 0) < requested_days:
            return Response({'error': {'code': 'LEAVE_INSUFFICIENT', 'message': 'Insufficient leave balance'}},
                           status=status.HTTP_400_BAD_REQUEST)

        leave_request = LeaveRequest.objects.create(
            employee_id_id=employee.id,
            leave_type_id_id=leave_type.id,
            start_date=start_date,
            start_date_breakdown=serializer.validated_data.get('start_breakdown', 'full_day'),
            end_date=end_date,
            end_date_breakdown=serializer.validated_data.get('end_breakdown', 'full_day'),
            requested_days=requested_days,
            description=serializer.validated_data.get('description', ''),
            status='requested'
        )

        # Notify employee and manager
        create_notification(request.user.id, 'Leave Request Submitted',
                          f'{leave_type.name} from {start_date} to {end_date}')
        notify_managers_of_request(employee, 'Leave', f'{leave_type.name} Leave')

        return Response({
            'id': str(leave_request.id),
            'request_id': get_request_id('LV', leave_request.id),
            'type': 'Leave',
            'title': f"{leave_type.name} Leave",
            'status': leave_request.status,
            'start_date': leave_request.start_date.isoformat(),
            'end_date': leave_request.end_date.isoformat() if leave_request.end_date else None,
            'description': leave_request.description
        }, status=status.HTTP_201_CREATED)


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
            title=f"[Claim] {title}",
            description=f"Type: {claim_type}\nAmount: {amount}\n{desc}",
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

        return Response({
            'id': str(ticket.id),
            'request_id': get_request_id('CL', ticket.id),
            'type': 'Claims',
            'title': title,
            'status': 'requested',
            'amount': float(amount) if amount else 0,
        }, status=status.HTTP_201_CREATED)


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

        return Response({
            'id': str(ticket.id),
            'request_id': get_request_id('TK', ticket.id),
            'type': 'Tickets',
            'title': ticket.title,
            'status': ticket.status,
            'priority': ticket.priority,
        }, status=status.HTTP_201_CREATED)


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

        return Response({
            'id': str(shift_request.id),
            'request_id': get_request_id('SR', shift_request.id),
            'type': 'Shift Requests',
            'title': f"Shift Change to {shift.employee_shift}",
            'status': shift_request.status,
            'shift_details': {
                'name': shift.employee_shift,
                'timing': shift.full_time
            },
            'from_date': shift_request.requested_date.isoformat() if shift_request.requested_date else None,
            'to_date': shift_request.requested_till.isoformat() if shift_request.requested_till else None,
        }, status=status.HTTP_201_CREATED)


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

        return Response({
            'id': str(work_request.id),
            'request_id': get_request_id('WR', work_request.id),
            'type': 'Work Type Requests',
            'title': f"Work Type Change to {work_type.work_type}",
            'status': work_request.status,
            'work_type': work_type.work_type,
            'from_date': work_request.requested_date.isoformat() if work_request.requested_date else None,
            'to_date': work_request.requested_till.isoformat() if work_request.requested_till else None,
        }, status=status.HTTP_201_CREATED)


class AttendanceRegularizeView(APIView):
    def post(self, request):
        serializer = AttendanceRegularizeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        att_date = serializer.validated_data['attendance_date']
        att_request = AttendanceRequestModel.objects.create(
            employee_id=employee.id,
            requested_date=att_date,
            from_time='09:00',
            to_time='18:00',
            reason=serializer.validated_data.get('description', ''),
            status='requested',
            created_at=timezone.now(),
        )

        return Response({
            'id': str(att_request.id),
            'request_id': get_request_id('AR', att_request.id),
            'type': 'Attendance Requests',
            'title': f"Attendance Regularization for {att_date}",
            'status': 'requested',
            'attendance_date': att_date.isoformat(),
        }, status=status.HTTP_201_CREATED)


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
                cursor.execute("SELECT id FROM asset_assetcategory WHERE asset_category_name = %s LIMIT 1", [cat_name])
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
            description=f"[{cat_name}] {desc}" if cat_name else desc,
            asset_request_status='Requested',
        )

        return Response({
            'id': str(asset_request.id),
            'request_id': get_request_id('AS', asset_request.id),
            'type': 'Asset Requests',
            'title': f"{cat_name} Request",
            'status': asset_request.status,
            'asset_category': cat_name,
        }, status=status.HTTP_201_CREATED)


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
                    EmployeeWorkInformation.objects.filter(
                        reporting_manager_id_id=employee.id
                    ).values_list('employee_id_id', flat=True)
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
                    if req_status == 'pending' and item_status != 'requested':
                        continue
                    elif req_status == 'accepted' and item_status != 'approved':
                        continue
                    elif req_status == 'rejected' and item_status != 'rejected':
                        continue
                    filtered.append(item)
                return filtered
            except Exception:
                return []

        icon_map = {
            'Leave': 'calendar', 'Claims': 'receipt', 'Tickets': 'support',
            'Shift Requests': 'clock', 'Work Type Requests': 'home',
            'Attendance Requests': 'fingerprint', 'Asset Requests': 'devices'
        }
        color_map = {
            'Leave': '#4CAF50', 'Claims': '#2196F3', 'Tickets': '#FF9800',
            'Shift Requests': '#9C27B0', 'Work Type Requests': '#00BCD4',
            'Attendance Requests': '#795548', 'Asset Requests': '#607D8B'
        }

        type_models = [
            ('Leave', LeaveRequest, {'employee_id_id': employee.id}),
            ('Claims', ClaimRequest, {'employee_id_id': employee.id}),
            ('Tickets', Ticket, {'employee_id_id': employee.id}),
            ('Shift Requests', ShiftRequestModel, {'employee_id_id': employee.id}),
            ('Work Type Requests', WorkTypeRequestModel, {'employee_id_id': employee.id}),
            ('Attendance Requests', AttendanceRequestModel, {'employee_id_id': employee.id}),
            ('Asset Requests', AssetRequestModel, {'requested_employee_id_id': employee.id}),
        ]

        for type_name, model, emp_filter in type_models:
            if req_type != 'all' and type_name != req_type:
                continue
            items = get_items(model, type_name, emp_filter)
            for item in items:
                emp_id = getattr(item, 'employee_id_id', None) or getattr(item, 'requested_employee_id_id', None)
                emp = get_employee_by_id(emp_id) if emp_id else None
                emp_name = emp.name if emp else 'Unknown'
                emp_badge = (emp.badge_id or str(emp.id)) if emp else ''

                # Extract created date from various model fields
                item_date = (
                    getattr(item, 'created_at', None) or
                    getattr(item, 'created_date', None) or
                    getattr(item, 'asset_request_date', None) or
                    getattr(item, 'start_date', None)
                )
                if item_date:
                    date_str = item_date.isoformat() if hasattr(item_date, 'isoformat') else str(item_date)
                else:
                    date_str = ''

                requests_list.append({
                    'id': str(item.id),
                    'request_id': get_request_id(type_name[:2].upper(), item.id),
                    'type': type_name,
                    'title': getattr(item, 'title', f"{type_name} Request"),
                    'status': getattr(item, 'status', 'requested'),
                    'icon_name': icon_map.get(type_name, 'file'),
                    'color_hex': color_map.get(type_name, '#000000'),
                    'employee': {
                        'id': str(emp_id or ''),
                        'name': emp_name,
                        'employee_id': emp_badge,
                    },
                    'subtitle': f"{emp_name} - {type_name}",
                    'description': getattr(item, 'description', ''),
                    'created_date': date_str,
                })

        # Sort by created_date descending (newest first), fallback to id
        requests_list.sort(key=lambda r: (r.get('created_date') or '', int(r['id'])), reverse=True)

        return Response({
            'total': len(requests_list),
            'page': 1,
            'limit': 50,
            'requests': requests_list[:50]
        })


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
            'Leave': 'calendar', 'Claims': 'receipt', 'Tickets': 'support',
            'Shift Requests': 'clock', 'Work Type Requests': 'home',
            'Attendance Requests': 'fingerprint', 'Asset Requests': 'devices'
        }

        return Response({
            'id': str(item.id),
            'request_id': get_request_id(type_name[:2].upper(), item.id),
            'type': type_name,
            'title': getattr(item, 'title', f"{type_name} Request"),
            'status': getattr(item, 'status', 'requested'),
            'icon_name': icon_map.get(type_name, 'file'),
            'color_hex': '#000000',
            'employee': {
                'id': str(item.employee_id_id),
                'name': emp_name,
                'employee_id': emp_badge,
            },
            'subtitle': f"{emp_name} - {type_name}",
            'description': getattr(item, 'description', ''),
            'rejection_reason': getattr(item, 'reject_reason', None),
            'timeline': [],
            'metadata': {}
        })


class RequestAcceptView(APIView):
    def put(self, request, pk):
        serializer = RequestActionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        type_models = [LeaveRequest, Ticket, ShiftRequestModel,
                       WorkTypeRequestModel, AttendanceRequestModel, AssetRequestModel]

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

        # Notify the request owner
        emp_id = getattr(item, 'employee_id_id', None) or getattr(item, 'requested_employee_id_id', None)
        if emp_id:
            emp = get_employee_by_id(emp_id)
            if emp and emp.employee_user_id_id:
                title = getattr(item, 'title', 'Request')
                create_notification(emp.employee_user_id_id, 'Request Approved',
                                  f'Your request "{title}" has been approved')

        return Response({
            'id': str(item.id),
            'request_id': get_request_id('REQ', item.id),
            'status': 'approved',
        })


class RequestRejectView(APIView):
    def put(self, request, pk):
        serializer = RequestActionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        rejection_reason = serializer.validated_data.get('rejection_reason')

        type_models = [LeaveRequest, Ticket, ShiftRequestModel,
                       WorkTypeRequestModel, AttendanceRequestModel, AssetRequestModel]

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
        if emp_id:
            emp = get_employee_by_id(emp_id)
            if emp and emp.employee_user_id_id:
                title = getattr(item, 'title', 'Request')
                create_notification(emp.employee_user_id_id, 'Request Rejected',
                                  f'Your request "{title}" was rejected' +
                                  (f': {rejection_reason}' if rejection_reason else ''))

        return Response({
            'id': str(item.id),
            'request_id': get_request_id('REQ', item.id),
            'status': 'rejected',
            'rejection_reason': rejection_reason,
        })


class RequestCancelView(APIView):
    def delete(self, request, pk):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        type_models = [LeaveRequest, ClaimRequest, Ticket, ShiftRequestModel,
                       WorkTypeRequestModel, AttendanceRequestModel, AssetRequestModel]

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

        return Response({
            'message': 'Request cancelled successfully',
            'request_id': get_request_id('REQ', pk)
        })


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
            employee_id_id=employee.id,
            start_date__gte=start,
            start_date__lte=end
        ).first()

        if not payslip:
            return Response({'error': 'Payslip not found'}, status=status.HTTP_404_NOT_FOUND)

        return Response({
            'id': payslip.id,
            'month': payslip.month,
            'year': payslip.year,
            'gross_pay': float(payslip.gross_pay or 0),
            'net_pay': float(payslip.net_pay or 0),
            'basic_pay': float(payslip.basic_pay or 0),
            'deduction': float(payslip.deduction or 0),
            'status': payslip.status,
        })


class PayslipsListView(APIView):
    def get(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)

        year = int(request.query_params.get('year', datetime.now().year))

        payslips = Payslip.objects.filter(
            employee_id_id=employee.id,
            start_date__year=year
        )

        month_names = ['', 'January', 'February', 'March', 'April', 'May', 'June',
                      'July', 'August', 'September', 'October', 'November', 'December']

        return Response({
            'year': year,
            'payslips': [{
                'month': p.month,
                'label': month_names[p.month] if p.month and 1 <= p.month <= 12 else '',
                'net_pay': float(p.net_pay) if p.net_pay else 0,
            } for p in payslips]
        })


class PayslipPDFView(APIView):
    def get(self, request, pk):
        from django.http import HttpResponse
        from reportlab.lib.pagesizes import A4
        from reportlab.lib import colors
        from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
        from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
        from reportlab.lib.units import inch
        import io

        payslip = get_object_or_404(Payslip, id=pk)
        employee = get_employee_by_id(payslip.employee_id_id)
        emp_name = employee.name if employee else 'Unknown'
        badge = (employee.badge_id or str(employee.id)) if employee else ''

        work_info = EmployeeWorkInformation.objects.filter(employee_id_id=payslip.employee_id_id).first()
        designation = ''
        dept_name = ''
        if work_info:
            if work_info.job_position_id_id:
                jp = JobPosition.objects.filter(id=work_info.job_position_id_id).first()
                designation = jp.job_position if jp else ''
            if work_info.department_id_id:
                dept = Department.objects.filter(id=work_info.department_id_id).first()
                dept_name = dept.department if dept else ''

        month_names = ['', 'January', 'February', 'March', 'April', 'May', 'June',
                      'July', 'August', 'September', 'October', 'November', 'December']
        month_label = month_names[payslip.month] if payslip.month and 1 <= payslip.month <= 12 else ''

        gross = float(payslip.gross_pay or 0)
        net = float(payslip.net_pay or 0)
        basic = float(payslip.basic_pay or 0)
        deduction = float(payslip.deduction or 0)
        hra = round(basic * 0.4, 2)
        da = round(basic * 0.2, 2)
        special = max(0, round(gross - basic - hra - da, 2))
        pf = round(basic * 0.12, 2)
        tax = max(0, round(deduction - pf, 2))

        # Generate PDF
        buf = io.BytesIO()
        doc = SimpleDocTemplate(buf, pagesize=A4, topMargin=0.5*inch, bottomMargin=0.5*inch)
        styles = getSampleStyleSheet()
        title_style = ParagraphStyle('Title', parent=styles['Heading1'], fontSize=18, alignment=1, spaceAfter=6)
        subtitle_style = ParagraphStyle('Sub', parent=styles['Normal'], fontSize=11, alignment=1, textColor=colors.grey)
        section_style = ParagraphStyle('Section', parent=styles['Heading2'], fontSize=13, spaceAfter=8, spaceBefore=16,
                                       textColor=colors.HexColor('#3B5FE5'))

        elements = []

        # Header
        elements.append(Paragraph('PPulse Technologies', title_style))
        elements.append(Paragraph(f'Payslip for {month_label} {payslip.year}', subtitle_style))
        elements.append(Spacer(1, 20))

        # Employee details table
        elements.append(Paragraph('Employee Details', section_style))
        emp_data = [
            ['Name', emp_name, 'Employee ID', badge],
            ['Designation', designation, 'Department', dept_name],
            ['Pay Period', f'{month_label} {payslip.year}', 'Status', payslip.status or 'Generated'],
        ]
        emp_table = Table(emp_data, colWidths=[1.3*inch, 2*inch, 1.3*inch, 2*inch])
        emp_table.setStyle(TableStyle([
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
            ('FONTNAME', (2, 0), (2, -1), 'Helvetica-Bold'),
            ('TEXTCOLOR', (0, 0), (0, -1), colors.grey),
            ('TEXTCOLOR', (2, 0), (2, -1), colors.grey),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
        ]))
        elements.append(emp_table)
        elements.append(Spacer(1, 16))

        # Earnings
        elements.append(Paragraph('Earnings', section_style))
        earn_data = [
            ['Component', 'Amount (\u20B9)'],
            ['Basic Pay', f'{basic:,.0f}'],
            ['HRA', f'{hra:,.0f}'],
            ['DA', f'{da:,.0f}'],
            ['Special Allowance', f'{special:,.0f}'],
            ['Gross Pay', f'{gross:,.0f}'],
        ]
        earn_table = Table(earn_data, colWidths=[4*inch, 2.5*inch])
        earn_table.setStyle(TableStyle([
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTNAME', (0, -1), (-1, -1), 'Helvetica-Bold'),
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#F0F0F0')),
            ('BACKGROUND', (0, -1), (-1, -1), colors.HexColor('#E8F5E9')),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#E0E0E0')),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
            ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
        ]))
        elements.append(earn_table)
        elements.append(Spacer(1, 12))

        # Deductions
        elements.append(Paragraph('Deductions', section_style))
        ded_data = [
            ['Component', 'Amount (\u20B9)'],
            ['Provident Fund (12%)', f'{pf:,.0f}'],
            ['Professional Tax', f'{tax:,.0f}'],
            ['Total Deductions', f'{deduction:,.0f}'],
        ]
        ded_table = Table(ded_data, colWidths=[4*inch, 2.5*inch])
        ded_table.setStyle(TableStyle([
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTNAME', (0, -1), (-1, -1), 'Helvetica-Bold'),
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#F0F0F0')),
            ('BACKGROUND', (0, -1), (-1, -1), colors.HexColor('#FFEBEE')),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#E0E0E0')),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
            ('ALIGN', (1, 0), (1, -1), 'RIGHT'),
        ]))
        elements.append(ded_table)
        elements.append(Spacer(1, 20))

        # Net Pay
        net_data = [['Net Pay', f'\u20B9 {net:,.0f}']]
        net_table = Table(net_data, colWidths=[4*inch, 2.5*inch])
        net_table.setStyle(TableStyle([
            ('FONTSIZE', (0, 0), (-1, -1), 14),
            ('FONTNAME', (0, 0), (-1, -1), 'Helvetica-Bold'),
            ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor('#E3F2FD')),
            ('TEXTCOLOR', (1, 0), (1, 0), colors.HexColor('#1565C0')),
            ('BOX', (0, 0), (-1, -1), 1, colors.HexColor('#1565C0')),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
            ('TOPPADDING', (0, 0), (-1, -1), 12),
            ('ALIGN', (1, 0), (1, 0), 'RIGHT'),
        ]))
        elements.append(net_table)

        doc.build(elements)
        buf.seek(0)

        response = HttpResponse(buf.getvalue(), content_type='application/pdf')
        response['Content-Disposition'] = f'attachment; filename="payslip_{emp_name.replace(" ", "_")}_{month_label}_{payslip.year}.pdf"'
        return response


class NotificationsView(APIView):
    def get(self, request):
        user = request.user

        notifications = NotificationModel.objects.filter(recipient_id=user.id)

        return Response({
            'unread_count': notifications.filter(unread=True).count(),
            'notifications': [{
                'id': n.id,
                'title': n.verb or '',
                'body': n.description or '',
                'read': not n.unread,
                'timestamp': n.timestamp.isoformat() if n.timestamp else None,
            } for n in notifications.order_by('-timestamp')[:20]]
        })


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
                'platform': serializer.validated_data['platform']
            }
        )

        return Response({'message': 'Device registered successfully'})


class EmployeesListView(APIView):
    def get(self, request):
        search = request.query_params.get('search', '')
        department = request.query_params.get('department', '')

        employees = Employee.objects.filter(is_active=True)

        if search:
            employees = employees.filter(
                Q(employee_first_name__icontains=search) |
                Q(employee_last_name__icontains=search) |
                Q(email__icontains=search) |
                Q(badge_id__icontains=search)
            )

        if department:
            dept_ids = Department.objects.filter(department__icontains=department).values_list('id', flat=True)
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
            emp_list.append({
                'id': str(emp.id),
                'employee_id': emp.badge_id or str(emp.id),
                'name': emp.name,
                'designation': designation,
                'department': dept_name,
                'email': emp.email,
                'phone': emp.phone,
                'avatar_url': emp.avatar_url
            })

        return Response({
            'total': employees.count(),
            'employees': emp_list
        })


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
                    reporting_manager = {
                        'id': str(reporting_emp.id),
                        'name': reporting_emp.name
                    }

        return Response({
            'id': str(employee.id),
            'employee_id': employee.badge_id or str(employee.id),
            'name': employee.name,
            'email': employee.email,
            'phone': employee.phone,
            'designation': designation,
            'department': dept_name,
            'date_of_joining': date_joining.isoformat() if date_joining else None,
            'reporting_manager': reporting_manager,
            'avatar_url': employee.avatar_url
        })


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

        if attendance:
            attendance_status = attendance.computed_status
            punch_in = attendance.attendance_clock_in.isoformat() if attendance.attendance_clock_in else None
            punch_out = attendance.attendance_clock_out.isoformat() if attendance.attendance_clock_out else None
            total_hours = attendance.attendance_worked_hour or '00:00'

        available_leaves = AvailableLeave.objects.filter(employee_id_id=employee.id)
        total_remaining = sum(leave.remaining_days for leave in available_leaves)

        leave_summary = {}
        for leave in available_leaves:
            leave_type = LeaveType.objects.filter(id=leave.leave_type_id_id).first()
            key = str(leave.leave_type_id_id)
            leave_summary[key] = {
                'label': leave_type.name if leave_type else 'Unknown',
                'used': leave.used_days,
                'total': leave.total_leave_days or 0
            }

        # Calculate real attendance percentage for current month
        month_start = date(today.year, today.month, 1)
        month_attendances = Attendance.objects.filter(
            employee_id_id=employee.id,
            attendance_date__gte=month_start,
            attendance_date__lte=today
        )
        present_days = sum(1 for a in month_attendances if a.attendance_clock_in is not None)
        working_days = sum(1 for d in range((today - month_start).days + 1)
                          if (month_start + timedelta(days=d)).weekday() < 5)
        attendance_pct = round((present_days / working_days * 100), 1) if working_days > 0 else 0.0

        # Build recent activity from ALL request types
        recent_activity = []
        for lr in LeaveRequest.objects.filter(employee_id_id=employee.id).order_by('-id')[:5]:
            lt = LeaveType.objects.filter(id=lr.leave_type_id_id).first()
            recent_activity.append({
                'type': 'leave',
                'title': f"{lt.name if lt else 'Leave'} Request",
                'status': lr.status,
                'date': lr.start_date.isoformat() if lr.start_date else None,
            })
        for sr in ShiftRequestModel.objects.filter(employee_id_id=employee.id).order_by('-id')[:3]:
            recent_activity.append({
                'type': 'shift',
                'title': 'Shift Change Request',
                'status': sr.status,
                'date': sr.requested_date.isoformat() if sr.requested_date else None,
            })
        for wr in WorkTypeRequestModel.objects.filter(employee_id_id=employee.id).order_by('-id')[:3]:
            recent_activity.append({
                'type': 'work_type',
                'title': 'Work Type Request',
                'status': wr.status,
                'date': wr.requested_date.isoformat() if wr.requested_date else None,
            })
        for ar in AttendanceRequestModel.objects.filter(employee_id=employee.id).order_by('-id')[:3]:
            recent_activity.append({
                'type': 'attendance',
                'title': 'Attendance Request',
                'status': ar.status,
                'date': ar.requested_date.isoformat() if ar.requested_date else None,
            })
        # Sort all by date descending and limit to 8
        recent_activity.sort(key=lambda x: x.get('date') or '', reverse=True)
        recent_activity = recent_activity[:8]

        # Pending requests counts for manager view
        pending_leaves = LeaveRequest.objects.filter(status='requested').count()
        try:
            pending_claims = ClaimRequest.objects.filter(status='requested').count()
        except Exception:
            pending_claims = 0
        try:
            pending_tickets = Ticket.objects.filter(status='open').count()
        except Exception:
            pending_tickets = 0

        return Response({
            'attendance': {
                'status': attendance_status,
                'punch_in': punch_in,
                'punch_out': punch_out,
                'total_hours': total_hours
            },
            'leave_balance': {
                'total_remaining': int(total_remaining),
                'attendance_percentage': attendance_pct
            },
            'leave_summary': leave_summary,
            'recent_activity': recent_activity,
            'pending_approvals': {
                'leave_requests': pending_leaves,
                'claims': pending_claims,
                'tickets': pending_tickets,
                'total': pending_leaves + pending_claims + pending_tickets,
            }
        })


class DashboardAnnouncementsView(APIView):
    def get(self, request):
        announcements = Announcement.objects.filter(is_active=True)[:5]

        return Response({
            'announcements': [{
                'id': str(a.id),
                'title': a.title,
                'subtitle': a.subtitle or '',
                'icon': a.icon or 'announcement',
            } for a in announcements]
        })


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

        return Response({
            'total_employees': total_employees,
            'new_joiners_this_month': 0,
            'attrition_rate': 0.0,
            'department_breakdown': dept_breakdown,
            'leave_analytics': {
                'most_used_type': most_used,
                'avg_leaves_per_employee': avg_leaves
            }
        })


class DepartmentsView(APIView):
    def get(self, request):
        departments = Department.objects.all()
        return Response({
            'departments': [{
                'id': str(d.id),
                'name': d.department or '',
            } for d in departments]
        })


class ShiftsListView(APIView):
    def get(self, request):
        shifts = Shift.objects.all()
        return Response({
            'shifts': [{
                'id': str(s.id),
                'name': s.employee_shift or '',
            } for s in shifts]
        })


class WorkTypesListView(APIView):
    def get(self, request):
        work_types = WorkType.objects.all()
        return Response({
            'work_types': [{
                'id': str(w.id),
                'name': w.work_type or '',
            } for w in work_types]
        })


class LeaveTypesListView(APIView):
    def get(self, request):
        leave_types = LeaveType.objects.all()
        return Response({
            'leave_types': [{
                'id': str(lt.id),
                'name': lt.name or '',
            } for lt in leave_types]
        })


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
        working_days = sum(1 for d in range((today - month_start).days + 1)
                          if (month_start + timedelta(days=d)).weekday() < 5)
        total_possible = total_employees * max(working_days, 1)
        total_present = Attendance.objects.filter(
            attendance_date__gte=month_start, attendance_date__lte=today,
            attendance_clock_in__isnull=False
        ).count()
        attendance_rate = round((total_present / total_possible * 100), 1) if total_possible > 0 else 0

        # Avg work hours (from employees who checked out this month)
        checked_out = Attendance.objects.filter(
            attendance_date__gte=month_start, attendance_date__lte=today,
            attendance_clock_in__isnull=False, attendance_clock_out__isnull=False
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
            leave_util.append({
                'label': lt.name,
                'used': round(total_used, 1),
                'total': round(total_alloc, 1),
                'percentage': pct,
            })

        return Response({
            'total_employees': total_employees,
            'active_employees': total_employees,
            'inactive_employees': inactive,
            'present_today': today_punched,
            'absent_today': max(0, absent_today),
            'on_leave_today': on_leave_today,
            'attendance_rate': attendance_rate,
            'avg_work_hours': avg_hours,
            'leave_utilization': leave_util,
        })


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
            report_ids = EmployeeWorkInformation.objects.filter(
                reporting_manager_id_id=emp.id
            ).values_list('employee_id_id', flat=True)
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
        managed_ids = set(EmployeeWorkInformation.objects.filter(
            reporting_manager_id_id__isnull=False
        ).values_list('employee_id_id', flat=True))

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

        return Response({
            'theme': settings_obj.theme,
            'notifications_enabled': settings_obj.notifications_enabled,
            'biometric_enabled': settings_obj.biometric_enabled,
            'language': settings_obj.language
        })

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

        return Response({
            'theme': settings_obj.theme,
            'notifications_enabled': settings_obj.notifications_enabled,
            'biometric_enabled': settings_obj.biometric_enabled,
            'language': settings_obj.language
        })
