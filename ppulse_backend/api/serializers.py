from django.contrib.auth import authenticate
from rest_framework import serializers

from .models import (
    Announcement,
    AssetRequestModel,
    Attendance,
    AttendanceRequestModel,
    AvailableLeave,
    ClaimRequest,
    Department,
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
    User,
    UserSettingsModel,
    WorkType,
    WorkTypeRequestModel,
)


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'is_staff', 'is_active']


class EmployeeSerializer(serializers.ModelSerializer):
    name = serializers.SerializerMethodField()

    class Meta:
        model = Employee
        fields = [
            'id',
            'badge_id',
            'employee_first_name',
            'employee_last_name',
            'name',
            'employee_profile',
            'email',
            'phone',
            'address',
            'country',
            'state',
            'city',
            'zip',
            'dob',
            'gender',
            'qualification',
            'marital_status',
            'children',
            'emergency_contact',
            'emergency_contact_name',
            'emergency_contact_relation',
            'is_active',
            'employee_user_id_id',
            'experience',
        ]

    def get_name(self, obj):
        return f'{obj.employee_first_name or ""} {obj.employee_last_name or ""}'.strip()


class EmployeeWorkInfoSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmployeeWorkInformation
        fields = [
            'id',
            'email',
            'mobile',
            'date_joining',
            'department_id_id',
            'job_position_id_id',
            'reporting_manager_id_id',
            'work_type_id_id',
            'basic_salary',
            'shift_id_id',
        ]


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
    class Meta:
        model = Attendance
        fields = '__all__'


class LeaveTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = LeaveType
        fields = '__all__'


class AvailableLeaveSerializer(serializers.ModelSerializer):
    class Meta:
        model = AvailableLeave
        fields = [
            'id',
            'available_days',
            'carryforward_days',
            'total_leave_days',
            'assigned_date',
            'employee_id_id',
            'leave_type_id_id',
        ]


class LeaveRequestSerializer(serializers.ModelSerializer):
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
    class Meta:
        model = ShiftRequestModel
        fields = '__all__'


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
    class Meta:
        model = Payslip
        fields = ['id', 'month', 'year', 'month_label', 'gross_salary', 'net_pay', 'employee_id_id']


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
    location_name = serializers.CharField(required=False, allow_blank=True)
    method = serializers.CharField(required=False)
    source = serializers.CharField(required=False)  # 'mobile_ios', 'mobile_android', 'web', 'biometric'
    device_info = serializers.CharField(required=False, allow_blank=True)


class FaceVerifyPunchInSerializer(serializers.Serializer):
    """WFH face-verified punch-in. `image` is required (base64 or data-URI)."""

    image = serializers.CharField()  # base64-encoded JPEG/PNG (or data-URI) — primary frame
    extra_frames = serializers.ListField(  # additional frames for multi-frame liveness
        child=serializers.CharField(),
        required=False,
        default=[],
    )
    latitude = serializers.FloatField(required=False)
    longitude = serializers.FloatField(required=False)
    location_name = serializers.CharField(required=False, allow_blank=True)
    source = serializers.CharField(required=False)
    device_info = serializers.CharField(required=False, allow_blank=True)


class PunchOutSerializer(serializers.Serializer):
    latitude = serializers.FloatField(required=False)
    longitude = serializers.FloatField(required=False)
    location_name = serializers.CharField(required=False, allow_blank=True)
    source = serializers.CharField(required=False)
    device_info = serializers.CharField(required=False, allow_blank=True)


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
    ticket_type = serializers.CharField(required=False, default='General')
    priority = serializers.CharField(required=False, default='medium')
    assign_department = serializers.CharField(required=False)
    cc_emails = serializers.ListField(child=serializers.EmailField(), required=False)
    attachments = serializers.ListField(child=serializers.FileField(), required=False)


class ShiftRequestCreateSerializer(serializers.Serializer):
    requesting_shift = serializers.CharField()
    requested_date = serializers.DateField()
    requested_till = serializers.DateField(required=False)
    description = serializers.CharField(required=False)
    is_permanent = serializers.BooleanField(required=False)


class WorkTypeRequestCreateSerializer(serializers.Serializer):
    work_type = serializers.CharField()
    requested_date = serializers.DateField()
    requested_till = serializers.DateField(required=False)
    description = serializers.CharField(required=False)
    is_permanent = serializers.BooleanField(required=False)


class AttendanceRegularizeSerializer(serializers.Serializer):
    attendance_date = serializers.DateField()
    attendance_type = serializers.CharField()
    shift = serializers.CharField(required=False, allow_blank=True)
    requested_check_in = serializers.TimeField(required=False)
    requested_check_out = serializers.TimeField(required=False)
    reason = serializers.CharField()
    attachment_name = serializers.CharField(required=False, allow_blank=True)


class AssetRequestCreateSerializer(serializers.Serializer):
    asset_category = serializers.CharField()
    description = serializers.CharField(required=False)


class RequestActionSerializer(serializers.Serializer):
    comment = serializers.CharField(required=False)
    rejection_reason = serializers.CharField(required=False)


class DeviceRegisterSerializer(serializers.Serializer):
    fcm_token = serializers.CharField()
    platform = serializers.CharField()
    device_id = serializers.CharField()
