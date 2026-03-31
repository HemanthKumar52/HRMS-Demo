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

    @property
    def avatar_url(self):
        if self.employee_profile:
            return self.employee_profile
        return None

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

    @property
    def used_days(self):
        total = self.total_leave_days or 0
        available = self.available_days or 0
        return total - available

    @property
    def remaining_days(self):
        return self.available_days or 0


class LeaveRequest(models.Model):
    created_at = models.DateTimeField(auto_now_add=True, blank=True, null=True)
    is_active = models.BooleanField(default=True)
    start_date = models.DateField(blank=True, null=True)
    start_date_breakdown = models.TextField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    end_date_breakdown = models.TextField(blank=True, null=True)
    requested_days = models.FloatField(blank=True, null=True)
    leave_clashes_count = models.IntegerField(default=0)
    description = models.TextField(default='', blank=True)
    attachment = models.CharField(max_length=100, blank=True, null=True)
    status = models.TextField(default='requested', blank=True, null=True)
    requested_date = models.DateField(auto_now_add=True, blank=True, null=True)
    approved_available_days = models.FloatField(default=0)
    approved_carryforward_days = models.FloatField(default=0)
    reject_reason = models.TextField(default='', blank=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    leave_type_id_id = models.BigIntegerField(blank=True, null=True)
    compensatory_work_date = models.DateField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_leaverequest'


class Attendance(models.Model):
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    attendance_date = models.DateField()
    attendance_clock_in_date = models.DateField(blank=True, null=True)
    attendance_clock_in = models.TimeField(blank=True, null=True)
    attendance_clock_out_date = models.DateField(blank=True, null=True)
    attendance_clock_out = models.TimeField(blank=True, null=True)
    attendance_worked_hour = models.CharField(max_length=10, blank=True, null=True)
    minimum_hour = models.CharField(max_length=10, default='00:00')
    attendance_overtime = models.CharField(max_length=10, default='00:00')
    attendance_overtime_approve = models.BooleanField(default=False)
    attendance_validated = models.BooleanField(default=False)
    at_work_second = models.IntegerField(blank=True, null=True)
    overtime_second = models.IntegerField(blank=True, null=True)
    approved_overtime_second = models.IntegerField(default=0)
    is_validate_request = models.BooleanField(default=False)
    is_bulk_request = models.BooleanField(default=False)
    is_validate_request_approved = models.BooleanField(default=False)
    request_description = models.TextField(blank=True, null=True)
    request_type = models.CharField(max_length=18, blank=True, null=True)
    is_holiday = models.BooleanField(default=False)
    requested_data = models.TextField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    shift_id_id = models.BigIntegerField(blank=True, null=True)
    work_type_id_id = models.BigIntegerField(blank=True, null=True)
    attendance_request_status = models.CharField(max_length=20, blank=True, null=True)
    excluded_gaps = models.TextField(default='')
    excluded_seconds = models.IntegerField(blank=True, null=True)
    expected_check_in = models.TimeField(blank=True, null=True)
    expected_check_out = models.TimeField(blank=True, null=True)
    attendance_attachment = models.CharField(max_length=100, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_attendance'

    @property
    def is_checked_in(self):
        return self.attendance_clock_in is not None and self.attendance_clock_out is None

    @property
    def is_checked_out(self):
        return self.attendance_clock_in is not None and self.attendance_clock_out is not None

    @property
    def computed_status(self):
        if self.is_checked_out:
            return 'checked_out'
        elif self.is_checked_in:
            return 'checked_in'
        return 'not_clocked_in'


class Ticket(models.Model):
    is_active = models.BooleanField(default=True)
    title = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    priority = models.TextField(blank=True, null=True)
    created_date = models.DateField(blank=True, null=True)
    status = models.TextField(default='open', blank=True, null=True)
    assigning_type = models.TextField(default='direct', blank=True, null=True)
    raised_on = models.TextField(default='other', blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    ticket_type_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'helpdesk_ticket'


class TicketType(models.Model):
    title = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'helpdesk_tickettype'


class ClaimRequest(models.Model):
    """Maps to helpdesk_claimrequest - approval on a ticket"""
    is_active = models.BooleanField(default=True)
    is_approved = models.BooleanField(default=False)
    is_rejected = models.BooleanField(default=False)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    ticket_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'helpdesk_claimrequest'

    @property
    def status(self):
        if self.is_approved:
            return 'approved'
        if self.is_rejected:
            return 'rejected'
        return 'requested'

    @property
    def title(self):
        try:
            ticket = Ticket.objects.get(id=self.ticket_id_id)
            return ticket.title
        except Exception:
            return 'Claim Request'

    @property
    def description(self):
        try:
            ticket = Ticket.objects.get(id=self.ticket_id_id)
            return ticket.description
        except Exception:
            return ''


class AssetRequest(models.Model):
    is_active = models.BooleanField(default=True)
    asset_request_date = models.DateField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    asset_request_status = models.TextField(default='Requested', blank=True, null=True)
    asset_category_id_id = models.BigIntegerField(blank=True, null=True)
    requested_employee_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_assetrequest'

    @property
    def employee_id_id(self):
        return self.requested_employee_id_id

    @property
    def status(self):
        s = (self.asset_request_status or '').lower()
        if 'approved' in s:
            return 'approved'
        if 'rejected' in s:
            return 'rejected'
        return 'requested'


class ShiftRequest(models.Model):
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    requested_date = models.DateField(blank=True, null=True)
    requested_till = models.DateField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    approved = models.BooleanField(default=False)
    canceled = models.BooleanField(default=False)
    shift_changed = models.BooleanField(default=False)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    shift_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_shiftrequest'

    @property
    def status(self):
        if self.approved:
            return 'approved'
        if self.canceled:
            return 'cancelled'
        return 'requested'


class WorkTypeRequest(models.Model):
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    requested_date = models.DateField(blank=True, null=True)
    requested_till = models.DateField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    approved = models.BooleanField(default=False)
    canceled = models.BooleanField(default=False)
    work_type_changed = models.BooleanField(default=False)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    work_type_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_worktyperequest'

    @property
    def status(self):
        if self.approved:
            return 'approved'
        if self.canceled:
            return 'cancelled'
        return 'requested'


class AttendanceRequest(models.Model):
    """Maps to attendance_permission_request"""
    requested_date = models.DateField(blank=True, null=True)
    from_time = models.TimeField(blank=True, null=True)
    to_time = models.TimeField(blank=True, null=True)
    reason = models.TextField(blank=True, null=True)
    status = models.TextField(default='requested', blank=True, null=True)
    employee_id = models.BigIntegerField(db_column='employee_id', blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_permission_request'

    @property
    def employee_id_id(self):
        return self.employee_id

    @property
    def description(self):
        return self.reason or ''

    @property
    def attendance_date(self):
        return self.requested_date


class Payslip(models.Model):
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    gross_pay = models.FloatField(blank=True, null=True)
    net_pay = models.FloatField(blank=True, null=True)
    basic_pay = models.FloatField(blank=True, null=True)
    deduction = models.FloatField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payslip'

    @property
    def month(self):
        return self.start_date.month if self.start_date else None

    @property
    def year(self):
        return self.start_date.year if self.start_date else None


class Notification(models.Model):
    verb = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    unread = models.BooleanField(default=True)
    timestamp = models.DateTimeField(blank=True, null=True)
    recipient_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'notifications_notification'

    @property
    def title(self):
        return self.verb or ''

    @property
    def body(self):
        return self.description or ''

    @property
    def read(self):
        return not self.unread

    @property
    def employee_id_id(self):
        return self.recipient_id


class Announcement(models.Model):
    title = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    expire_date = models.DateField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_announcement'

    @property
    def subtitle(self):
        return self.description or ''

    @property
    def icon(self):
        return 'announcement'


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
AssetCategoryModel = AssetRequest
