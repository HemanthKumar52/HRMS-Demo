from rest_framework import viewsets, status, generics
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.db.models import Q, Count, Sum
from datetime import datetime, date, timedelta
from calendar import monthrange
import calendar

from .models import (
    User, Employee, Department, JobPosition, EmployeeWorkInformation,
    Shift, WorkType, Attendance, LeaveType, AvailableLeave, LeaveRequest,
    ClaimRequest, Ticket, ShiftRequestModel, WorkTypeRequestModel,
    AttendanceRequestModel, AssetCategoryModel, AssetRequestModel,
    Payslip, NotificationModel, Announcement, DeviceTokenModel, UserSettingsModel
)
from .serializers import (
    UserSerializer, EmployeeSerializer, DepartmentSerializer,
    JobPositionSerializer, ShiftSerializer, WorkTypeSerializer,
    AttendanceSerializer, LeaveTypeSerializer, AvailableLeaveSerializer,
    LeaveRequestSerializer, ClaimRequestSerializer, TicketSerializer,
    ShiftRequestSerializer, WorkTypeRequestSerializer, AttendanceRequestSerializer,
    AssetRequestSerializer, PayslipSerializer, NotificationSerializer,
    AnnouncementSerializer, UserSettingsSerializer,
    LoginSerializer, RefreshTokenSerializer, ChangePasswordSerializer,
    UserProfileUpdateSerializer, PunchInSerializer, PunchOutSerializer,
    LeaveApplySerializer, ClaimSubmitSerializer, TicketRaiseSerializer,
    ShiftRequestSerializer as ShiftRequestSeralizerReq,
    WorkTypeRequestSerializer as WorkTypeRequestSerializerReq,
    AttendanceRegularizeSerializer, AssetRequestSerializer as AssetReqSerializer,
    RequestActionSerializer, DeviceRegisterSerializer
)

User = get_user_model()


def get_employee_from_user(user):
    try:
        return Employee.objects.get(employee_user_id_id=user.id)
    except Employee.DoesNotExist:
        return None


def get_request_id(prefix, obj_id):
    return f"{prefix}-{str(obj_id).zfill(4)}"


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
        except Exception as e:
            department = ''
            designation = ''
        
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
                'avatar_url': request.build_absolute_uri(employee.employee_profile.url) if employee.employee_profile else None
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
                try:
                    reporting_emp = Employee.objects.get(id=work_info.reporting_manager_id_id)
                    reporting_manager = {
                        'id': str(reporting_emp.id),
                        'name': reporting_emp.name,
                        'employee_id': reporting_emp.badge_id or str(reporting_emp.id)
                    }
                except Employee.DoesNotExist:
                    pass
        
        return Response({
            'id': str(user.id),
            'employee_id': employee.badge_id or str(employee.id),
            'name': employee.name,
            'email': user.email,
            'phone': employee.phone,
            'role': 'employee',
            'designation': designation,
            'department': department,
            'date_of_joining': date_joining.isoformat() if date_joining else None,
            'reporting_manager': reporting_manager,
            'avatar_url': request.build_absolute_uri(employee.employee_profile.url) if employee.employee_profile else None
        })
    
    def put(self, request):
        serializer = UserProfileUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        user = request.user
        employee = get_employee_from_user(user)
        
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
        
        employee.employee_profile = request.FILES['file']
        employee.save()
        
        return Response({
            'avatar_url': request.build_absolute_uri(employee.employee_profile.url)
        })


class AttendancePunchInView(APIView):
    def post(self, request):
        serializer = PunchInSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        
        today = date.today()
        
        existing = Attendance.objects.filter(employee=employee, attendance_date=today).first()
        if existing and existing.status != 'not_clocked_in':
            return Response({'error': {'code': 'ALREADY_PUNCHED_IN', 'message': 'Already clocked in today'}}, 
                           status=status.HTTP_400_BAD_REQUEST)
        
        now = timezone.now()
        
        if existing:
            existing.attendance_clock_in = now.time()
            existing.attendance_clock_in_date = today
            existing.status = 'checked_in'
            existing.save()
            attendance = existing
        else:
            attendance = Attendance.objects.create(
                employee=employee,
                attendance_date=today,
                attendance_clock_in=now.time(),
                attendance_clock_in_date=today,
                status='checked_in'
            )
        
        return Response({
            'id': str(attendance.id),
            'employee_id': employee.badge_id or str(employee.id),
            'punch_in': attendance.attendance_clock_in.isoformat(),
            'punch_out': attendance.attendance_clock_out.isoformat() if attendance.attendance_clock_out else None,
            'status': attendance.status,
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
        
        attendance = Attendance.objects.filter(employee=employee, attendance_date=today).first()
        if not attendance or attendance.status == 'not_clocked_in':
            return Response({'error': {'code': 'NOT_PUNCHED_IN', 'message': 'Cannot punch out without punching in'}}, 
                           status=status.HTTP_400_BAD_REQUEST)
        
        now = timezone.now()
        attendance.attendance_clock_out = now.time()
        attendance.attendance_clock_out_date = today
        attendance.status = 'checked_out'
        
        if attendance.attendance_clock_in:
            in_seconds = attendance.attendance_clock_in.hour * 3600 + attendance.attendance_clock_in.minute * 60
            out_seconds = now.hour * 3600 + now.minute * 60
            worked_seconds = out_seconds - in_seconds
            hours = worked_seconds // 3600
            minutes = (worked_seconds % 3600) // 60
            attendance.attendance_worked_hour = f"{hours:02d}:{minutes:02d}"
        
        attendance.save()
        
        return Response({
            'id': str(attendance.id),
            'punch_in': attendance.attendance_clock_in.isoformat(),
            'punch_out': attendance.attendance_clock_out.isoformat(),
            'total_hours': attendance.attendance_worked_hour or '00:00',
            'status': attendance.status
        })


class AttendanceTodayView(APIView):
    def get(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        
        today = date.today()
        attendance = Attendance.objects.filter(employee=employee, attendance_date=today).first()
        
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
            'status': attendance.status,
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
            employee=employee,
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
                if att.status == 'checked_out':
                    status_val = 'present'
                    present += 1
                    punch_in = att.attendance_clock_in.isoformat() if att.attendance_clock_in else None
                    punch_out = att.attendance_clock_out.isoformat() if att.attendance_clock_out else None
                    total_hours = att.attendance_worked_hour
                elif att.status == 'checked_in':
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
            else:
                status_val = 'absent'
                absent += 1
                punch_in = None
                punch_out = None
                total_hours = None
            
            daily.append({
                'date': day_date.isoformat(),
                'status': status_val,
                'punch_in': punch_in,
                'punch_out': punch_out,
                'total_hours': total_hours
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
            employee=employee,
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
            
            if att and att.status in ['checked_in', 'checked_out']:
                present += 1
                hours = float(att.attendance_worked_hour.split(':')[0]) if att.attendance_worked_hour else 0
                daily_hours.append({'day': weekday, 'hours': hours})
                punch_times.append({
                    'day': weekday,
                    'punch_in': att.attendance_clock_in.hour + att.attendance_clock_in.minute / 60 if att.attendance_clock_in else 0,
                    'punch_out': att.attendance_clock_out.hour + att.attendance_clock_out.minute / 60 if att.attendance_clock_out else 0
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
        user = request.user
        
        month = int(request.query_params.get('month', datetime.now().month))
        year = int(request.query_params.get('year', datetime.now().year))
        
        employees = Employee.objects.filter(is_active=True)
        today = date.today()
        
        present_today = 0
        absent_today = 0
        on_leave_today = 0
        
        team_members = []
        
        for emp in employees:
            attendance = Attendance.objects.filter(employee=emp, attendance_date=today).first()
            
            if attendance and attendance.status == 'checked_in':
                status_val = 'present'
                present_today += 1
            elif attendance and attendance.status == 'checked_out':
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
            'total_employees': len(employees),
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
        
        available_leaves = AvailableLeave.objects.filter(employee=employee)
        
        balances = []
        total_remaining = 0
        
        for leave in available_leaves:
            balances.append({
                'type': leave.leave_type.code,
                'label': leave.leave_type.name,
                'total': leave.total_leave_days,
                'used': leave.used_days,
                'remaining': leave.remaining_days
            })
            total_remaining += leave.remaining_days
        
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
        
        leave_type = LeaveType.objects.filter(code=serializer.validated_data['leave_type']).first()
        if not leave_type:
            return Response({'error': 'Invalid leave type'}, status=status.HTTP_400_BAD_REQUEST)
        
        available = AvailableLeave.objects.filter(employee=employee, leave_type=leave_type).first()
        
        start_date = serializer.validated_data['start_date']
        end_date = serializer.validated_data.get('end_date') or start_date
        
        requested_days = (end_date - start_date).days + 1
        
        if available and available.available_days < requested_days:
            return Response({'error': {'code': 'LEAVE_INSUFFICIENT', 'message': 'Insufficient leave balance'}}, 
                           status=status.HTTP_400_BAD_REQUEST)
        
        leave_request = LeaveRequest.objects.create(
            employee=employee,
            leave_type=leave_type,
            start_date=start_date,
            start_date_breakdown=serializer.validated_data.get('start_breakdown', 'full_day'),
            end_date=end_date,
            end_date_breakdown=serializer.validated_data.get('end_breakdown', 'full_day'),
            requested_days=requested_days,
            description=serializer.validated_data.get('description', ''),
            attachment=request.FILES.get('attachment')
        )
        
        return Response({
            'id': str(leave_request.id),
            'request_id': get_request_id('LV', leave_request.id),
            'type': 'Leave',
            'title': f"{leave_type.name} Leave",
            'status': leave_request.status,
            'applied_date': leave_request.requested_date.isoformat(),
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
        
        claim_request = ClaimRequest.objects.create(
            employee=employee,
            title=serializer.validated_data['title'],
            claim_type=serializer.validated_data['claim_type'],
            amount=serializer.validated_data['amount'],
            date=serializer.validated_data['date'],
            description=serializer.validated_data.get('description', '')
        )
        
        image_urls = []
        for img in request.FILES.getlist('images'):
            image_urls.append(f"/media/claims/{img.name}")
        
        claim_request.image_urls = image_urls
        claim_request.save()
        
        return Response({
            'id': str(claim_request.id),
            'request_id': get_request_id('CL', claim_request.id),
            'type': 'Claims',
            'title': claim_request.title,
            'status': claim_request.status,
            'amount': float(claim_request.amount),
            'applied_date': claim_request.requested_date.isoformat(),
            'image_urls': image_urls
        }, status=status.HTTP_201_CREATED)


class TicketRaiseView(APIView):
    def post(self, request):
        serializer = TicketRaiseSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        
        ticket = Ticket.objects.create(
            employee=employee,
            title=serializer.validated_data['title'],
            description=serializer.validated_data['description'],
            ticket_type=serializer.validated_data['ticket_type'],
            priority=serializer.validated_data['priority'],
            assigned_department=serializer.validated_data.get('assign_department')
        )
        
        return Response({
            'id': str(ticket.id),
            'request_id': get_request_id('TK', ticket.id),
            'type': 'Tickets',
            'title': ticket.title,
            'status': ticket.status,
            'priority': ticket.priority,
            'assigned_department': ticket.assigned_department,
            'applied_date': ticket.created_date.isoformat()
        }, status=status.HTTP_201_CREATED)


class ShiftRequestView(APIView):
    def post(self, request):
        serializer = ShiftRequestSeralizerReq(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        
        shift = Shift.objects.filter(id=serializer.validated_data['requesting_shift']).first()
        if not shift:
            shift = Shift.objects.filter(employee_shift=serializer.validated_data['requesting_shift']).first()
            if not shift:
                return Response({'error': 'Invalid shift type'}, status=status.HTTP_400_BAD_REQUEST)
        
        shift_request = ShiftRequestModel.objects.create(
            employee=employee,
            requesting_shift=shift,
            requested_date=serializer.validated_data['requested_date'],
            requested_till=serializer.validated_data.get('requested_till'),
            description=serializer.validated_data.get('description', ''),
            is_permanent=serializer.validated_data.get('is_permanent', False)
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
            'from_date': shift_request.requested_date.isoformat(),
            'to_date': shift_request.requested_till.isoformat() if shift_request.requested_till else None,
            'is_permanent': shift_request.is_permanent,
            'applied_date': shift_request.created_at.isoformat()
        }, status=status.HTTP_201_CREATED)


class WorkTypeRequestView(APIView):
    def post(self, request):
        serializer = WorkTypeRequestSerializerReq(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        
        work_type = WorkType.objects.filter(name__icontains=serializer.validated_data['work_type']).first()
        if not work_type:
            return Response({'error': 'Invalid work type'}, status=status.HTTP_400_BAD_REQUEST)
        
        work_request = WorkTypeRequestModel.objects.create(
            employee=employee,
            work_type=work_type,
            requested_date=serializer.validated_data['requested_date'],
            requested_till=serializer.validated_data.get('requested_till'),
            description=serializer.validated_data.get('description', ''),
            is_permanent=serializer.validated_data.get('is_permanent', False)
        )
        
        return Response({
            'id': str(work_request.id),
            'request_id': get_request_id('WR', work_request.id),
            'type': 'Work Type Requests',
            'title': f"Work Type Change to {work_type.name}",
            'status': work_request.status,
            'work_type': work_type.name,
            'from_date': work_request.requested_date.isoformat(),
            'to_date': work_request.requested_till.isoformat() if work_request.requested_till else None,
            'is_permanent': work_request.is_permanent,
            'applied_date': work_request.created_at.isoformat()
        }, status=status.HTTP_201_CREATED)


class AttendanceRegularizeView(APIView):
    def post(self, request):
        serializer = AttendanceRegularizeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        
        att_request = AttendanceRequestModel.objects.create(
            employee=employee,
            attendance_date=serializer.validated_data['attendance_date'],
            attendance_status=serializer.validated_data.get('attendance_status', 'present'),
            expected_check_in=serializer.validated_data.get('expected_check_in'),
            expected_check_out=serializer.validated_data.get('expected_check_out'),
            actual_check_in=serializer.validated_data.get('actual_check_in'),
            actual_check_out=serializer.validated_data.get('actual_check_out'),
            worked_hours=serializer.validated_data.get('worked_hours'),
            reason=serializer.validated_data.get('reason', ''),
            description=serializer.validated_data.get('description', ''),
            attachment=request.FILES.get('attachment')
        )
        
        return Response({
            'id': str(att_request.id),
            'request_id': get_request_id('AR', att_request.id),
            'type': 'Attendance Requests',
            'title': f"Attendance Regularization for {att_request.attendance_date}",
            'status': att_request.status,
            'attendance_date': att_request.attendance_date.isoformat(),
            'applied_date': att_request.created_at.isoformat()
        }, status=status.HTTP_201_CREATED)


class AssetRequestView(APIView):
    def post(self, request):
        serializer = AssetReqSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        
        asset_request = AssetRequestModel.objects.create(
            employee=employee,
            asset_category=serializer.validated_data['asset_category'],
            description=serializer.validated_data.get('description', '')
        )
        
        return Response({
            'id': str(asset_request.id),
            'request_id': get_request_id('AS', asset_request.id),
            'type': 'Asset Requests',
            'title': f"{asset_request.get_asset_category_display()} Request",
            'status': asset_request.status,
            'asset_category': asset_request.asset_category,
            'applied_date': asset_request.asset_request_date.isoformat()
        }, status=status.HTTP_201_CREATED)


class RequestsListView(APIView):
    def get(self, request):
        role = request.query_params.get('role', 'self')
        req_status = request.query_params.get('status', 'all')
        req_type = request.query_params.get('type', 'all')
        
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        
        requests_list = []
        
        if role == 'self':
            leave_requests = LeaveRequest.objects.filter(employee=employee)
            claim_requests = ClaimRequest.objects.filter(employee=employee)
            ticket_requests = Ticket.objects.filter(employee=employee)
            shift_requests = ShiftRequestModel.objects.filter(employee=employee)
            work_requests = WorkTypeRequestModel.objects.filter(employee=employee)
            att_requests = AttendanceRequestModel.objects.filter(employee=employee)
            asset_requests = AssetRequestModel.objects.filter(employee=employee)
        else:
            
            leave_requests = LeaveRequest.objects.all()
            claim_requests = ClaimRequest.objects.all()
            ticket_requests = Ticket.objects.all()
            shift_requests = ShiftRequestModel.objects.all()
            work_requests = WorkTypeRequestModel.objects.all()
            att_requests = AttendanceRequestModel.objects.all()
            asset_requests = AssetRequestModel.objects.all()
        
        def filter_status(qs, status_field, status_val):
            if status_val == 'pending':
                return qs.filter(**{f'{status_field}__iexact': 'Pending'})
            elif status_val == 'accepted':
                return qs.filter(**{f'{status_field}__iexact': 'Accepted'})
            elif status_val == 'rejected':
                return qs.filter(**{f'{status_field}__iexact': 'Rejected'})
            return qs
        
        type_map = {
            'Leave': (leave_requests, 'leave_requests', 'status'),
            'Claims': (claim_requests, 'claim_requests', 'status'),
            'Tickets': (ticket_requests, 'tickets', 'status'),
            'Shift Requests': (shift_requests, 'shift_requests', 'status'),
            'Work Type Requests': (work_requests, 'work_type_requests', 'status'),
            'Attendance Requests': (att_requests, 'attendance_requests', 'status'),
            'Asset Requests': (asset_requests, 'asset_requests', 'status')
        }
        
        for type_name, (qs, rel, status_field) in type_map.items():
            if req_type != 'all' and type_name != req_type:
                continue
            qs = filter_status(qs, status_field, req_status)
            
            for item in qs:
                icon_map = {
                    'Leave': 'calendar',
                    'Claims': 'receipt',
                    'Tickets': 'support',
                    'Shift Requests': 'clock',
                    'Work Type Requests': 'home',
                    'Attendance Requests': 'fingerprint',
                    'Asset Requests': 'devices'
                }
                color_map = {
                    'Leave': '#4CAF50',
                    'Claims': '#2196F3',
                    'Tickets': '#FF9800',
                    'Shift Requests': '#9C27B0',
                    'Work Type Requests': '#00BCD4',
                    'Attendance Requests': '#795548',
                    'Asset Requests': '#607D8B'
                }
                
                requests_list.append({
                    'id': str(item.id),
                    'request_id': get_request_id(type_name[:2].upper(), item.id),
                    'type': type_name,
                    'title': getattr(item, 'title', f"{type_name} Request"),
                    'status': getattr(item, 'status', 'Pending'),
                    'icon_name': icon_map.get(type_name, 'file'),
                    'color_hex': color_map.get(type_name, '#000000'),
                    'employee': {
                        'id': str(item.employee.id),
                        'name': item.employee.name,
                        'employee_id': item.employee.badge_id or str(item.employee.id),
                        'avatar_url': request.build_absolute_uri(item.employee.employee_profile.url) if item.employee.employee_profile else None
                    },
                    'subtitle': f"{item.employee.name} - {type_name}",
                    'applied_date': getattr(item, 'requested_date', getattr(item, 'created_at', None)).isoformat() if hasattr(item, 'requested_date') or hasattr(item, 'created_at') else None,
                    'description': getattr(item, 'description', '')
                })
        
        requests_list.sort(key=lambda x: x['applied_date'] or '', reverse=True)
        
        return Response({
            'total': len(requests_list),
            'page': 1,
            'limit': 20,
            'requests': requests_list[:20]
        })


class RequestDetailView(APIView):
    def get(self, request, pk):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        
        all_requests = list(LeaveRequest.objects.filter(id=pk)) + \
                       list(ClaimRequest.objects.filter(id=pk)) + \
                       list(Ticket.objects.filter(id=pk)) + \
                       list(ShiftRequestModel.objects.filter(id=pk)) + \
                       list(WorkTypeRequestModel.objects.filter(id=pk)) + \
                       list(AttendanceRequestModel.objects.filter(id=pk)) + \
                       list(AssetRequestModel.objects.filter(id=pk))
        
        if not all_requests:
            return Response({'error': 'Request not found'}, status=status.HTTP_404_NOT_FOUND)
        
        item = all_requests[0]
        
        type_name = 'Leave'
        for req_type, model in [('Leave', LeaveRequest), ('Claims', ClaimRequest), 
                                 ('Tickets', Ticket), ('Shift Requests', ShiftRequestModel),
                                 ('Work Type Requests', WorkTypeRequestModel),
                                 ('Attendance Requests', AttendanceRequestModel),
                                 ('Asset Requests', AssetRequestModel)]:
            if isinstance(item, model):
                type_name = req_type
                break
        
        icon_map = {
            'Leave': 'calendar',
            'Claims': 'receipt',
            'Tickets': 'support',
            'Shift Requests': 'clock',
            'Work Type Requests': 'home',
            'Attendance Requests': 'fingerprint',
            'Asset Requests': 'devices'
        }
        
        timeline = [
            {
                'step': 'Applied',
                'date': getattr(item, 'requested_date', getattr(item, 'created_at', None)).strftime('%Y-%m-%d') if hasattr(item, 'requested_date') or hasattr(item, 'created_at') else '',
                'time': getattr(item, 'requested_date', getattr(item, 'created_at', None)).strftime('%H:%M') if hasattr(item, 'requested_date') or hasattr(item, 'created_at') else '',
                'done': True,
                'reason': None
            }
        ]
        
        if item.status in ['Accepted', 'Rejected']:
            timeline.append({
                'step': item.status,
                'date': datetime.now().strftime('%Y-%m-%d'),
                'time': datetime.now().strftime('%H:%M'),
                'done': True,
                'reason': getattr(item, 'reject_reason', None)
            })
        
        return Response({
            'id': str(item.id),
            'request_id': get_request_id(type_name[:2].upper(), item.id),
            'type': type_name,
            'title': getattr(item, 'title', f"{type_name} Request"),
            'status': item.status,
            'icon_name': icon_map.get(type_name, 'file'),
            'color_hex': '#000000',
            'employee': {
                'id': str(item.employee.id),
                'name': item.employee.name,
                'employee_id': item.employee.badge_id or str(item.employee.id)
            },
            'subtitle': f"{item.employee.name} - {type_name}",
            'applied_date': getattr(item, 'requested_date', getattr(item, 'created_at', None)).isoformat() if hasattr(item, 'requested_date') or hasattr(item, 'created_at') else None,
            'description': getattr(item, 'description', ''),
            'rejection_reason': getattr(item, 'reject_reason', None),
            'timeline': timeline,
            'metadata': {}
        })


class RequestAcceptView(APIView):
    def put(self, request, pk):
        if True:
            return Response({'error': {'code': 'INSUFFICIENT_ROLE', 'message': 'Access denied'}}, 
                           status=status.HTTP_403_FORBIDDEN)
        
        serializer = RequestActionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        all_requests = list(LeaveRequest.objects.filter(id=pk)) + \
                       list(ClaimRequest.objects.filter(id=pk)) + \
                       list(Ticket.objects.filter(id=pk)) + \
                       list(ShiftRequestModel.objects.filter(id=pk)) + \
                       list(WorkTypeRequestModel.objects.filter(id=pk)) + \
                       list(AttendanceRequestModel.objects.filter(id=pk)) + \
                       list(AssetRequestModel.objects.filter(id=pk))
        
        if not all_requests:
            return Response({'error': 'Request not found'}, status=status.HTTP_404_NOT_FOUND)
        
        item = all_requests[0]
        
        if item.status != 'Pending':
            return Response({'error': {'code': 'REQUEST_NOT_PENDING', 'message': 'Can only accept pending requests'}}, 
                           status=status.HTTP_400_BAD_REQUEST)
        
        item.status = 'Accepted'
        item.save()
        
        return Response({
            'id': str(item.id),
            'request_id': get_request_id('REQ', item.id),
            'status': 'Accepted',
            'accepted_by': {
                'id': str(request.user.id),
                'name': request.user.get_full_name() or request.user.username
            },
            'accepted_at': datetime.now().isoformat(),
            'timeline': []
        })


class RequestRejectView(APIView):
    def put(self, request, pk):
        if True:
            return Response({'error': {'code': 'INSUFFICIENT_ROLE', 'message': 'Access denied'}}, 
                           status=status.HTTP_403_FORBIDDEN)
        
        serializer = RequestActionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        rejection_reason = serializer.validated_data.get('rejection_reason')
        if not rejection_reason:
            return Response({'error': 'Rejection reason is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        all_requests = list(LeaveRequest.objects.filter(id=pk)) + \
                       list(ClaimRequest.objects.filter(id=pk)) + \
                       list(Ticket.objects.filter(id=pk)) + \
                       list(ShiftRequestModel.objects.filter(id=pk)) + \
                       list(WorkTypeRequestModel.objects.filter(id=pk)) + \
                       list(AttendanceRequestModel.objects.filter(id=pk)) + \
                       list(AssetRequestModel.objects.filter(id=pk))
        
        if not all_requests:
            return Response({'error': 'Request not found'}, status=status.HTTP_404_NOT_FOUND)
        
        item = all_requests[0]
        
        if item.status != 'Pending':
            return Response({'error': {'code': 'REQUEST_NOT_PENDING', 'message': 'Can only reject pending requests'}}, 
                           status=status.HTTP_400_BAD_REQUEST)
        
        item.status = 'Rejected'
        item.reject_reason = rejection_reason
        item.save()
        
        return Response({
            'id': str(item.id),
            'request_id': get_request_id('REQ', item.id),
            'status': 'Rejected',
            'rejected_by': {
                'id': str(request.user.id),
                'name': request.user.get_full_name() or request.user.username
            },
            'rejected_at': datetime.now().isoformat(),
            'rejection_reason': rejection_reason,
            'timeline': []
        })


class RequestCancelView(APIView):
    def delete(self, request, pk):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        
        all_requests = list(LeaveRequest.objects.filter(id=pk, employee=employee)) + \
                       list(ClaimRequest.objects.filter(id=pk, employee=employee)) + \
                       list(Ticket.objects.filter(id=pk, employee=employee)) + \
                       list(ShiftRequestModel.objects.filter(id=pk, employee=employee)) + \
                       list(WorkTypeRequestModel.objects.filter(id=pk, employee=employee)) + \
                       list(AttendanceRequestModel.objects.filter(id=pk, employee=employee)) + \
                       list(AssetRequestModel.objects.filter(id=pk, employee=employee))
        
        if not all_requests:
            return Response({'error': 'Request not found'}, status=status.HTTP_404_NOT_FOUND)
        
        item = all_requests[0]
        
        if item.status != 'Pending':
            return Response({'error': 'Can only cancel pending requests'}, status=status.HTTP_400_BAD_REQUEST)
        
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
        
        payslip = Payslip.objects.filter(employee=employee, month=month, year=year).first()
        
        if not payslip:
            return Response({'error': 'Payslip not found'}, status=status.HTTP_404_NOT_FOUND)
        
        serializer = PayslipSerializer(payslip)
        return Response(serializer.data)


class PayslipsListView(APIView):
    def get(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        
        year = int(request.query_params.get('year', datetime.now().year))
        
        payslips = Payslip.objects.filter(employee=employee, year=year)
        
        month_names = ['', 'January', 'February', 'March', 'April', 'May', 'June',
                      'July', 'August', 'September', 'October', 'November', 'December']
        
        return Response({
            'year': year,
            'payslips': [{
                'month': p.month,
                'label': month_names[p.month],
                'net_pay': float(p.net_pay),
                'status': p.status
            } for p in payslips]
        })


class PayslipPDFView(APIView):
    def get(self, request, pk):
        payslip = get_object_or_404(Payslip, id=pk)
        
        if payslip.pdf_url:
            return Response({'pdf_url': payslip.pdf_url})
        
        return Response({'error': 'PDF not available'}, status=status.HTTP_404_NOT_FOUND)


class NotificationsView(APIView):
    def get(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        
        notifications = NotificationModel.objects.filter(employee=employee)
        
        return Response({
            'unread_count': notifications.filter(read=False).count(),
            'notifications': NotificationSerializer(notifications, many=True).data
        })


class NotificationReadView(APIView):
    def put(self, request, pk):
        notification = get_object_or_404(NotificationModel, id=pk)
        notification.read = True
        notification.save()
        return Response({'message': 'Marked as read'})


class NotificationsReadAllView(APIView):
    def put(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        
        NotificationModel.objects.filter(employee=employee, read=False).update(read=True)
        return Response({'message': 'All notifications marked as read'})


class DeviceRegisterView(APIView):
    def post(self, request):
        serializer = DeviceRegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        
        DeviceTokenModel.objects.update_or_create(
            employee=employee,
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
            work_infos = EmployeeWorkInformation.objects.filter(
                department_id_id__in=Department.objects.filter(name__icontains=department).values_list('id', flat=True)
            ).values_list('employee_id_id', flat=True)
            employees = employees.filter(id__in=work_infos)
        
        emp_list = []
        for emp in employees[:20]:
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
                'avatar_url': request.build_absolute_uri(emp.employee_profile.url) if emp.employee_profile else None
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
                dept_name = dept.name if dept else ''
            date_joining = work_info.date_joining
            if work_info.reporting_manager_id_id:
                try:
                    reporting_emp = Employee.objects.get(id=work_info.reporting_manager_id_id)
                    reporting_manager = {
                        'id': str(reporting_emp.id),
                        'name': reporting_emp.name
                    }
                except Employee.DoesNotExist:
                    pass
        
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
            'avatar_url': request.build_absolute_uri(employee.employee_profile.url) if employee.employee_profile else None
        })


class DashboardSummaryView(APIView):
    def get(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        
        today = date.today()
        
        attendance = Attendance.objects.filter(employee=employee, attendance_date=today).first()
        
        attendance_status = 'not_clocked_in'
        punch_in = None
        punch_out = None
        total_hours = '00:00'
        
        if attendance:
            if attendance.status == 'checked_in':
                attendance_status = 'checked_in'
                punch_in = attendance.attendance_clock_in.isoformat() if attendance.attendance_clock_in else None
            elif attendance.status == 'checked_out':
                attendance_status = 'checked_out'
                punch_in = attendance.attendance_clock_in.isoformat() if attendance.attendance_clock_in else None
                punch_out = attendance.attendance_clock_out.isoformat() if attendance.attendance_clock_out else None
                total_hours = attendance.attendance_worked_hour or '00:00'
        
        available_leaves = AvailableLeave.objects.filter(employee=employee)
        total_remaining = sum(leave.remaining_days for leave in available_leaves)
        
        leave_summary = {}
        for leave in available_leaves:
            leave_summary[leave.leave_type.code] = {
                'used': leave.used_days,
                'total': leave.total_leave_days
            }
        
        response_data = {
            'attendance': {
                'status': attendance_status,
                'punch_in': punch_in,
                'punch_out': punch_out,
                'total_hours': total_hours
            },
            'leave_balance': {
                'total_remaining': int(total_remaining),
                'attendance_percentage': 0.0
            },
            'leave_summary': leave_summary,
            'recent_activity': []
        }
        
        if True:
            team_employees = Employee.objects.filter(
                work_info__reporting_manager=employee
            ).count()
            
            present_today = Attendance.objects.filter(
                employee__work_info__reporting_manager=employee,
                attendance_date=today,
                status__in=['checked_in', 'checked_out']
            ).count()
            
            response_data['team_attendance'] = {
                'present': present_today,
                'absent': team_employees - present_today,
                'on_leave': 0,
                'total': team_employees
            }
            response_data['pending_approvals'] = LeaveRequest.objects.filter(status='Pending').count()
            response_data['performance_metrics'] = {
                'team_productivity': 0.0,
                'avg_attendance': 0.0,
                'open_tickets': Ticket.objects.filter(status='Pending').count()
            }
        
        return Response(response_data)


class DashboardAnnouncementsView(APIView):
    def get(self, request):
        announcements = Announcement.objects.filter(is_active=True)[:5]
        
        return Response({
            'announcements': [{
                'id': str(a.id),
                'title': a.title,
                'subtitle': a.subtitle or '',
                'icon': a.icon or 'announcement',
                'created_at': a.created_at.isoformat()
            } for a in announcements]
        })


class DashboardAnalyticsView(APIView):
    def get(self, request):
        if True:
            return Response({'error': {'code': 'INSUFFICIENT_ROLE', 'message': 'HR access required'}}, 
                           status=status.HTTP_403_FORBIDDEN)
        
        total_employees = Employee.objects.filter(is_active=True).count()
        
        today = datetime.now()
        first_day = today.replace(day=1)
        new_joiners = Employee.objects.filter(
            created_at__gte=first_day
        ).count()
        
        departments = Department.objects.annotate(count=Count('employees'))
        
        return Response({
            'total_employees': total_employees,
            'new_joiners_this_month': new_joiners,
            'attrition_rate': 0.0,
            'department_breakdown': [
                {'department': d.name, 'count': d.count}
                for d in departments
            ],
            'leave_analytics': {
                'most_used_type': 'casual',
                'avg_leaves_per_employee': 0.0
            }
        })


class SettingsView(APIView):
    def get(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        
        settings, _ = UserSettingsModel.objects.get_or_create(employee=employee)
        
        return Response({
            'theme': settings.theme,
            'notifications_enabled': settings.notifications_enabled,
            'biometric_enabled': settings.biometric_enabled,
            'language': settings.language
        })
    
    def put(self, request):
        employee = get_employee_from_user(request.user)
        if not employee:
            return Response({'error': 'Employee not found'}, status=status.HTTP_404_NOT_FOUND)
        
        settings, _ = UserSettingsModel.objects.get_or_create(employee=employee)
        
        if 'theme' in request.data:
            settings.theme = request.data['theme']
        if 'notifications_enabled' in request.data:
            settings.notifications_enabled = request.data['notifications_enabled']
        if 'biometric_enabled' in request.data:
            settings.biometric_enabled = request.data['biometric_enabled']
        if 'language' in request.data:
            settings.language = request.data['language']
        
        settings.save()
        
        return Response({
            'theme': settings.theme,
            'notifications_enabled': settings.notifications_enabled,
            'biometric_enabled': settings.biometric_enabled,
            'language': settings.language
        })
