from rest_framework import serializers
from django.contrib.auth import authenticate
from .models import (
    User, Employee, Department, JobPosition, EmployeeWorkInformation,
    Shift, WorkType, Attendance, LeaveType, AvailableLeave, LeaveRequest,
    ClaimRequest, Ticket, ShiftRequestModel, WorkTypeRequestModel, 
    AttendanceRequestModel, AssetCategoryModel, AssetRequestModel,
    Payslip, NotificationModel, Announcement, DeviceTokenModel, UserSettingsModel
)


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'role', 'phone', 'avatar']


class EmployeeSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source='employee_first_name', read_only=True)
    reporting_manager = serializers.SerializerMethodField()
    
    class Meta:
        model = Employee
        fields = [
            'id', 'badge_id', 'employee_first_name', 'employee_last_name', 'name',
            'employee_profile', 'email', 'phone', 'address', 'country', 'state', 'city',
            'zip', 'dob', 'gender', 'qualification', 'marital_status', 'children',
            'emergency_contact', 'emergency_contact_name', 'emergency_contact_relation',
            'is_active', 'employee_user_id', 'reporting_manager', 'created_at', 'updated_at'
        ]
    
    def get_reporting_manager(self, obj):
        try:
            work_info = EmployeeWorkInformation.objects.get(employee_id_id=obj.employee_user_id_id)
            if work_info.reporting_manager:
                return {
                    'id': work_info.reporting_manager.id,
                    'name': work_info.reporting_manager.name,
                    'employee_id': work_info.reporting_manager.badge_id
                }
        except EmployeeWorkInformation.DoesNotExist:
            pass
        return None


class EmployeeWorkInfoSerializer(serializers.ModelSerializer):
    employee = EmployeeSerializer(read_only=True)
    department_name = serializers.CharField(source='department.name', read_only=True)
    designation = serializers.CharField(source='job_position.title', read_only=True)
    reporting_manager = serializers.SerializerMethodField()
    
    class Meta:
        model = EmployeeWorkInformation
        fields = ['id', 'employee', 'email', 'mobile', 'date_joining', 'department', 
                  'department_name', 'job_position', 'designation', 'reporting_manager', 'work_type']
    
    def get_reporting_manager(self, obj):
        if obj.reporting_manager:
            return {
                'id': obj.reporting_manager.id,
                'name': obj.reporting_manager.name
            }
        return None


class DepartmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Department
        fields = '__all__'


class JobPositionSerializer(serializers.ModelSerializer):
    class Meta:
        model = JobPosition
        fields = '__all__'


class ShiftSerializer(serializers.ModelSerializer):
    class Meta:
        model = Shift
        fields = '__all__'


class WorkTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = WorkType
        fields = '__all__'


class AttendanceSerializer(serializers.ModelSerializer):
    employee_name = serializers.CharField(source='employee.name', read_only=True)
    employee_id = serializers.CharField(source='employee.badge_id', read_only=True)
    
    class Meta:
        model = Attendance
        fields = '__all__'


class LeaveTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = LeaveType
        fields = '__all__'


class AvailableLeaveSerializer(serializers.ModelSerializer):
    type = serializers.CharField(source='leave_type.code')
    label = serializers.CharField(source='leave_type.name')
    total = serializers.FloatField(source='total_leave_days')
    used = serializers.FloatField(source='used_days')
    remaining = serializers.FloatField(source='remaining_days')
    
    class Meta:
        model = AvailableLeave
        fields = ['type', 'label', 'total', 'used', 'remaining']


class LeaveRequestSerializer(serializers.ModelSerializer):
    leave_type_name = serializers.CharField(source='leave_type.name', read_only=True)
    
    class Meta:
        model = LeaveRequest
        fields = '__all__'


class ClaimRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = ClaimRequest
        fields = '__all__'


class TicketSerializer(serializers.ModelSerializer):
    class Meta:
        model = Ticket
        fields = '__all__'


class ShiftRequestSerializer(serializers.ModelSerializer):
    shift_details = serializers.SerializerMethodField()
    
    class Meta:
        model = ShiftRequestModel
        fields = '__all__'
    
    def get_shift_details(self, obj):
        return {
            'name': obj.requesting_shift.employee_shift,
            'timing': obj.requesting_shift.full_time
        }


class WorkTypeRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = WorkTypeRequestModel
        fields = '__all__'


class AttendanceRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = AttendanceRequestModel
        fields = '__all__'


class AssetRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = AssetRequestModel
        fields = '__all__'


class PayslipSerializer(serializers.ModelSerializer):
    earnings = serializers.SerializerMethodField()
    deductions = serializers.SerializerMethodField()
    
    class Meta:
        model = Payslip
        fields = ['id', 'month', 'year', 'month_label', 'gross_salary', 'net_pay',
                  'total_deductions', 'earnings', 'deductions', 'paid_on', 'pdf_url']
    
    def get_earnings(self, obj):
        return {
            'basic': float(obj.basic),
            'hra': float(obj.hra),
            'da': float(obj.da),
            'special_allowance': float(obj.special_allowance),
            'other_allowance': float(obj.other_allowance)
        }
    
    def get_deductions(self, obj):
        return {
            'provident_fund': float(obj.provident_fund),
            'esi': float(obj.esi),
            'professional_tax': float(obj.professional_tax),
            'income_tax': float(obj.income_tax)
        }


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationModel
        fields = '__all__'


class AnnouncementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Announcement
        fields = '__all__'


class UserSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserSettingsModel
        fields = '__all__'


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)
    device_id = serializers.CharField(required=False)
    fcm_token = serializers.CharField(required=False)
    
    def validate(self, data):
        username = data.get('username')
        password = data.get('password')
        
        if username and password:
            user = authenticate(username=username, password=password)
            if not user:
                raise serializers.ValidationError('Invalid credentials')
            if not user.is_active:
                raise serializers.ValidationError('User account is disabled')
            data['user'] = user
        else:
            raise serializers.ValidationError('Username and password are required')
        
        return data


class RefreshTokenSerializer(serializers.Serializer):
    refresh_token = serializers.CharField()


class ChangePasswordSerializer(serializers.Serializer):
    current_password = serializers.CharField()
    new_password = serializers.CharField()


class UserProfileUpdateSerializer(serializers.Serializer):
    name = serializers.CharField(required=False)
    phone = serializers.CharField(required=False)


class PunchInSerializer(serializers.Serializer):
    latitude = serializers.FloatField(required=False)
    longitude = serializers.FloatField(required=False)
    method = serializers.CharField(required=False)


class PunchOutSerializer(serializers.Serializer):
    latitude = serializers.FloatField(required=False)
    longitude = serializers.FloatField(required=False)


class LeaveApplySerializer(serializers.Serializer):
    leave_type = serializers.CharField()
    start_date = serializers.DateField()
    start_breakdown = serializers.CharField()
    end_date = serializers.DateField(required=False)
    end_breakdown = serializers.CharField(required=False)
    description = serializers.CharField(required=False)
    attachment = serializers.FileField(required=False)


class ClaimSubmitSerializer(serializers.Serializer):
    title = serializers.CharField()
    claim_type = serializers.CharField()
    amount = serializers.FloatField()
    date = serializers.DateField()
    description = serializers.CharField(required=False)
    images = serializers.ListField(child=serializers.FileField(), required=False)


class TicketRaiseSerializer(serializers.Serializer):
    title = serializers.CharField()
    description = serializers.CharField()
    ticket_type = serializers.CharField()
    priority = serializers.CharField()
    assign_department = serializers.CharField(required=False)
    cc_emails = serializers.ListField(child=serializers.EmailField(), required=False)
    attachments = serializers.ListField(child=serializers.FileField(), required=False)


class ShiftRequestSerializer(serializers.Serializer):
    requesting_shift = serializers.CharField()
    requested_date = serializers.DateField()
    requested_till = serializers.DateField(required=False)
    description = serializers.CharField(required=False)
    is_permanent = serializers.BooleanField(required=False)


class WorkTypeRequestSerializer(serializers.Serializer):
    work_type = serializers.CharField()
    requested_date = serializers.DateField()
    requested_till = serializers.DateField(required=False)
    description = serializers.CharField(required=False)
    is_permanent = serializers.BooleanField(required=False)


class AttendanceRegularizeSerializer(serializers.Serializer):
    attendance_date = serializers.DateField()
    shift = serializers.CharField(required=False)
    attendance_status = serializers.CharField(required=False)
    expected_check_in = serializers.TimeField(required=False)
    expected_check_out = serializers.TimeField(required=False)
    actual_check_in = serializers.TimeField(required=False)
    actual_check_out = serializers.TimeField(required=False)
    work_type = serializers.CharField(required=False)
    worked_hours = serializers.CharField(required=False)
    reason = serializers.CharField(required=False)
    description = serializers.CharField(required=False)
    attachment = serializers.FileField(required=False)


class AssetRequestSerializer(serializers.Serializer):
    asset_category = serializers.CharField()
    description = serializers.CharField(required=False)


class RequestActionSerializer(serializers.Serializer):
    comment = serializers.CharField(required=False)
    rejection_reason = serializers.CharField(required=False)


class DeviceRegisterSerializer(serializers.Serializer):
    fcm_token = serializers.CharField()
    platform = serializers.CharField()
    device_id = serializers.CharField()
