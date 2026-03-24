from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin


class UserManager(BaseUserManager):
    def create_user(self, username, email, password=None, **extra_fields):
        if not email:
            raise ValueError('Email is required')
        email = self.normalize_email(email)
        user = self.model(username=username, email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, username, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)
        return self.create_user(username, email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    is_new_employee = models.BooleanField(default=False)
    username = models.TextField(unique=True, blank=True, null=True)
    first_name = models.TextField(blank=True, null=True)
    last_name = models.TextField(blank=True, null=True)
    email = models.TextField(blank=True, null=True)
    is_staff = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    date_joined = models.DateTimeField(blank=True, null=True)

    objects = UserManager()

    class Meta:
        managed = False
        db_table = 'horilla_auth_horillauser'

    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = ['email']

    def __str__(self):
        return self.username or ''


class Employee(models.Model):
    badge_id = models.TextField(unique=True, blank=True, null=True)
    employee_first_name = models.TextField(blank=True, null=True)
    employee_last_name = models.TextField(blank=True, null=True)
    employee_profile = models.TextField(blank=True, null=True)
    email = models.TextField(unique=True, blank=True, null=True)
    phone = models.TextField(blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    country = models.TextField(blank=True, null=True)
    state = models.TextField(blank=True, null=True)
    city = models.TextField(blank=True, null=True)
    zip = models.TextField(blank=True, null=True)
    dob = models.DateField(blank=True, null=True)
    gender = models.TextField(blank=True, null=True)
    qualification = models.TextField(blank=True, null=True)
    marital_status = models.TextField(blank=True, null=True)
    children = models.BigIntegerField(blank=True, null=True)
    emergency_contact = models.TextField(blank=True, null=True)
    emergency_contact_name = models.TextField(blank=True, null=True)
    emergency_contact_relation = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    additional_info = models.TextField(blank=True, null=True)
    is_from_onboarding = models.BooleanField(blank=True, null=True)
    is_directly_converted = models.BooleanField(blank=True, null=True)
    employee_user_id_id = models.BigIntegerField(unique=True, blank=True, null=True)
    experience = models.FloatField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_employee'

    @property
    def name(self):
        return f"{self.employee_first_name or ''} {self.employee_last_name or ''}".strip()

    def __str__(self):
        return self.name or ''


class EmployeeWorkInformation(models.Model):
    location = models.TextField(blank=True, null=True)
    email = models.TextField(blank=True, null=True)
    mobile = models.TextField(blank=True, null=True)
    date_joining = models.DateField(blank=True, null=True)
    contract_end_date = models.DateField(blank=True, null=True)
    basic_salary = models.BigIntegerField(blank=True, null=True)
    salary_hour = models.BigIntegerField(blank=True, null=True)
    additional_info = models.TextField(blank=True, null=True)
    experience = models.FloatField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    department_id_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(unique=True, blank=True, null=True)
    employee_type_id_id = models.BigIntegerField(blank=True, null=True)
    job_position_id_id = models.BigIntegerField(blank=True, null=True)
    job_role_id_id = models.BigIntegerField(blank=True, null=True)
    reporting_manager_id_id = models.BigIntegerField(blank=True, null=True)
    shift_id_id = models.BigIntegerField(blank=True, null=True)
    work_type_id_id = models.BigIntegerField(blank=True, null=True)
    performance_role_id = models.BigIntegerField(blank=True, null=True)
    ai_recruitment_role = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_employeeworkinformation'


class Department(models.Model):
    department = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_department'

    def __str__(self):
        return self.department or ''


class JobPosition(models.Model):
    job_position = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_jobposition'

    def __str__(self):
        return self.job_position or ''


class Shift(models.Model):
    employee_shift = models.TextField(blank=True, null=True)
    full_time = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_employeeshift'

    def __str__(self):
        return self.employee_shift or ''


class WorkType(models.Model):
    work_type = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_worktype'

    def __str__(self):
        return self.work_type or ''


class LeaveType(models.Model):
    name = models.TextField(blank=True, null=True)
    color = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_leavetype'

    def __str__(self):
        return self.name or ''


class AvailableLeave(models.Model):
    available_days = models.FloatField(blank=True, null=True)
    carryforward_days = models.FloatField(blank=True, null=True)
    total_leave_days = models.FloatField(blank=True, null=True)
    assigned_date = models.DateField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    leave_type_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_availableleave'


class LeaveRequest(models.Model):
    start_date = models.DateField(blank=True, null=True)
    start_date_breakdown = models.TextField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    end_date_breakdown = models.TextField(blank=True, null=True)
    requested_days = models.FloatField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    requested_date = models.DateField(blank=True, null=True)
    reject_reason = models.TextField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    leave_type_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_leaverequest'


class Attendance(models.Model):
    attendance_date = models.DateField(blank=True, null=True)
    attendance_clock_in = models.TimeField(blank=True, null=True)
    attendance_clock_out = models.TimeField(blank=True, null=True)
    attendance_worked_hour = models.TextField(blank=True, null=True)
    minimum_hour = models.TextField(blank=True, null=True)
    attendance_overtime = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_attendance'


class Ticket(models.Model):
    title = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    priority = models.TextField(blank=True, null=True)
    created_date = models.DateField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'helpdesk_ticket'


class TicketType(models.Model):
    title = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'helpdesk_tickettype'


class ClaimRequest(models.Model):
    title = models.TextField(blank=True, null=True)
    claim_type = models.TextField(blank=True, null=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    date = models.DateField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'claim_request'


class AssetRequest(models.Model):
    asset_category = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_assetrequest'


class ShiftRequest(models.Model):
    requested_date = models.DateField(blank=True, null=True)
    requested_till = models.DateField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    shift_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_shiftrequest'


class WorkTypeRequest(models.Model):
    requested_date = models.DateField(blank=True, null=True)
    requested_till = models.DateField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    work_type_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_worktyperequest'


class AttendanceRequest(models.Model):
    attendance_date = models.DateField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_permission_request'


class Payslip(models.Model):
    month = models.IntegerField(blank=True, null=True)
    year = models.IntegerField(blank=True, null=True)
    month_label = models.TextField(blank=True, null=True)
    gross_salary = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    net_pay = models.DecimalField(max_digits=12, decimal_places=2, blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payslip'


class Notification(models.Model):
    title = models.TextField(blank=True, null=True)
    body = models.TextField(blank=True, null=True)
    category = models.TextField(blank=True, null=True)
    read = models.BooleanField(default=False)
    employee_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'notification'


class Announcement(models.Model):
    title = models.TextField(blank=True, null=True)
    subtitle = models.TextField(blank=True, null=True)
    icon = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        managed = False
        db_table = 'base_announcement'


class DeviceToken(models.Model):
    fcm_token = models.TextField(blank=True, null=True)
    platform = models.TextField(blank=True, null=True)
    device_id = models.TextField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'device_token'


class UserSettings(models.Model):
    theme = models.TextField(default='system')
    notifications_enabled = models.BooleanField(default=True)
    biometric_enabled = models.BooleanField(default=False)
    language = models.TextField(default='en')
    employee_id_id = models.BigIntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'user_settings'


# Aliases for views compatibility
ShiftRequestModel = ShiftRequest
WorkTypeRequestModel = WorkTypeRequest
AttendanceRequestModel = AttendanceRequest
NotificationModel = Notification
DeviceTokenModel = DeviceToken
UserSettingsModel = UserSettings
AssetRequestModel = AssetRequest
AssetCategoryModel = AssetRequest  # Using AssetRequest as placeholder
