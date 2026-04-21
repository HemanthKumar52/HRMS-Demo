from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models


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

    # ── Security extensions (admin user management) ──────────────
    # Bumped on force-logout / password reset; embedded as a "tv" claim in
    # every JWT and validated by VersionedJWTAuthentication. Old tokens are
    # rejected once the version changes.
    token_version = models.IntegerField(default=0)
    # Failed-login monitor + lockout.
    failed_login_count = models.IntegerField(default=0)
    locked_until = models.DateTimeField(blank=True, null=True)

    objects = UserManager()

    class Meta:
        managed = True
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
        managed = True
        db_table = 'employee_employee'

    @property
    def name(self):
        return f'{self.employee_first_name or ""} {self.employee_last_name or ""}'.strip()

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
        managed = True
        db_table = 'employee_employeeworkinformation'


class Department(models.Model):
    department = models.TextField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'base_department'

    def __str__(self):
        return self.department or ''


class JobPosition(models.Model):
    job_position = models.TextField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'base_jobposition'

    def __str__(self):
        return self.job_position or ''


class Shift(models.Model):
    employee_shift = models.TextField(blank=True, null=True)
    full_time = models.TextField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'base_employeeshift'

    def __str__(self):
        return self.employee_shift or ''


class WorkType(models.Model):
    work_type = models.TextField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'base_worktype'

    def __str__(self):
        return self.work_type or ''


class LeaveType(models.Model):
    name = models.TextField(blank=True, null=True)
    color = models.TextField(blank=True, null=True)

    class Meta:
        managed = True
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
        managed = True
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
        managed = True
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

    # ── Source tracking (mobile/biometric/web) ───────────────
    punch_in_source = models.CharField(max_length=20, blank=True, null=True)
    punch_out_source = models.CharField(max_length=20, blank=True, null=True)

    # ── Location capture (silent, backend-only) ──────────────
    punch_in_lat = models.FloatField(blank=True, null=True)
    punch_in_lng = models.FloatField(blank=True, null=True)
    punch_in_location = models.CharField(max_length=255, blank=True, null=True)
    punch_out_lat = models.FloatField(blank=True, null=True)
    punch_out_lng = models.FloatField(blank=True, null=True)
    punch_out_location = models.CharField(max_length=255, blank=True, null=True)

    # ── Device info (silent, backend-only) ───────────────────
    punch_in_device = models.CharField(max_length=255, blank=True, null=True)
    punch_out_device = models.CharField(max_length=255, blank=True, null=True)

    class Meta:
        managed = True
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
        managed = True
        db_table = 'helpdesk_ticket'


class TicketType(models.Model):
    title = models.TextField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'helpdesk_tickettype'


class ClaimRequest(models.Model):
    """Maps to helpdesk_claimrequest - approval on a ticket"""

    is_active = models.BooleanField(default=True)
    is_approved = models.BooleanField(default=False)
    is_rejected = models.BooleanField(default=False)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    ticket_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = True
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
        managed = True
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
        managed = True
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
        managed = True
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
    attendance_type = models.TextField(blank=True, null=True)
    shift_name = models.TextField(blank=True, null=True)
    attachment_name = models.TextField(blank=True, null=True)

    class Meta:
        managed = True
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
    pay_head_data = models.JSONField(blank=True, null=True, default=dict)

    class Meta:
        managed = True
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
        managed = True
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
        managed = True
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
        managed = True
        db_table = 'device_token'


class Geofence(models.Model):
    """Admin-managed allowed punch-in zone (replaces the hardcoded
    OFFICE_LOCATIONS list in views.py).
    """

    name = models.CharField(max_length=200)
    latitude = models.FloatField()
    longitude = models.FloatField()
    radius_meters = models.IntegerField(default=50)
    is_office = models.BooleanField(
        default=True,
        help_text='Office geofence — if has_biometric is True, blocks mobile punch-in inside it',
    )
    has_biometric = models.BooleanField(
        default=False,
        help_text='Office has a biometric device — mobile check-in blocked when inside this zone',
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        managed = True
        db_table = 'api_geofence'

    def __str__(self):
        return f'{self.name} ({self.latitude},{self.longitude}/{self.radius_meters}m)'


class Holiday(models.Model):
    """Company holiday calendar — admin-managed, used by attendance compliance."""

    name = models.CharField(max_length=200)
    holiday_date = models.DateField(db_index=True)
    is_recurring = models.BooleanField(default=False, help_text='Repeats every year on this date')
    description = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        managed = True
        db_table = 'api_holiday'
        ordering = ['holiday_date']

    def __str__(self):
        return f'{self.name} ({self.holiday_date})'


class EmailTemplate(models.Model):
    """Editable system-email template. The backend looks up by `key` instead of
    using hardcoded strings, so admins can change copy without a code release.
    """

    key = models.CharField(max_length=64, unique=True, db_index=True)
    subject = models.CharField(max_length=255)
    body = models.TextField(help_text='Plain-text body. {{placeholder}} variables expanded by backend.')
    html_body = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        managed = True
        db_table = 'api_email_template'

    def __str__(self):
        return f'{self.key} — {self.subject}'


class TimesheetProject(models.Model):
    """Mirror of Horilla's `timesheet_project` table — read-only here.
    `managed=False` because the schema is owned by the web app's migrations.
    """

    name = models.TextField()
    description = models.TextField(blank=True, null=True)
    project_code = models.TextField(blank=True, null=True)
    client_name = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    is_billable = models.BooleanField(default=True)
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'timesheet_project'

    def __str__(self):
        return self.name or f'Project #{self.id}'


class TimesheetTask(models.Model):
    """Mirror of `timesheet_task`."""

    name = models.TextField()
    description = models.TextField(blank=True, null=True)
    task_code = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    project_id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'timesheet_task'

    def __str__(self):
        return self.name or f'Task #{self.id}'


class SimpleTimesheetPeriod(models.Model):
    """Mirror of `simple_timesheet_period` — weekly periods owned by an
    employee. The mobile flow auto-creates a draft period for the current
    week if one doesn't exist.
    """

    period_start = models.DateField()
    period_end = models.DateField()
    status = models.TextField(default='draft')
    total_hours = models.FloatField(default=0)
    total_wfo_days = models.IntegerField(default=0)
    total_wfh_days = models.IntegerField(default=0)
    total_wfo_hours = models.FloatField(default=0)
    total_wfh_hours = models.FloatField(default=0)
    is_active = models.BooleanField(default=True)
    employee_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    submitted_at = models.DateTimeField(blank=True, null=True)
    approved_at = models.DateTimeField(blank=True, null=True)
    rejected_at = models.DateTimeField(blank=True, null=True)
    rejection_reason = models.TextField(default='', blank=True)
    approved_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'simple_timesheet_period'

    def __str__(self):
        return f'Period {self.period_start}–{self.period_end}'


class SimpleTimesheetEntry(models.Model):
    """Mirror of `simple_timesheet_entry` — daily timesheet rows."""

    date = models.DateField()
    activity_name = models.TextField(default='', blank=True)
    hours = models.FloatField(default=0)
    work_location = models.TextField(default='wfo', blank=True)  # 'wfo' / 'wfh'
    comments = models.TextField(default='', blank=True)
    is_active = models.BooleanField(default=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    project_id = models.BigIntegerField(blank=True, null=True)  # legacy column
    timesheet_period_id = models.BigIntegerField(blank=True, null=True)
    timesheet_project_id = models.BigIntegerField(blank=True, null=True)
    timesheet_task_id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'simple_timesheet_entry'

    def __str__(self):
        return f'{self.date} {self.hours}h #{self.id}'


class UserPresence(models.Model):
    """Per-user "online now" tracking. Updated by /v1/me/heartbeat every 30s
    while the app is foregrounded. `is_visible` lets the user opt out of
    being shown as online to others.
    """

    user_id = models.BigIntegerField(unique=True)
    last_seen_at = models.DateTimeField(auto_now=True)
    is_visible = models.BooleanField(default=True)
    push_enabled = models.BooleanField(default=True)
    timesheet_reminders_enabled = models.BooleanField(default=True)

    class Meta:
        managed = True
        db_table = 'api_user_presence'

    def __str__(self):
        return f'presence({self.user_id}, last={self.last_seen_at})'


class AppFeedback(models.Model):
    """Stores per-user app feedback. Once submitted, the user won't be asked
    again until the next app version update."""

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='feedbacks')
    rating = models.IntegerField(default=0)  # 1-5 stars
    comment = models.TextField(blank=True, default='')
    app_version = models.CharField(max_length=20, default='1.0.0')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        managed = True
        db_table = 'api_app_feedback'
        unique_together = [('user', 'app_version')]

    def __str__(self):
        return f'feedback(user={self.user_id}, v={self.app_version}, stars={self.rating})'


class RequestCc(models.Model):
    """Carbon-copy entries for requests. When an employee submits a leave /
    claim / ticket / work-type / regularization / asset request they can
    optionally CC other employees who will receive a read-only notification
    (no approval rights).

    `request_type` matches the type label used by RequestsListView, e.g.
    "Leave" / "Claims" / "Tickets" / "Work Type Requests" /
    "Attendance Requests" / "Asset Requests" / "Shift Requests".
    """

    request_type = models.CharField(max_length=64)
    request_id = models.BigIntegerField()
    user_id = models.BigIntegerField(db_index=True)
    user_name = models.CharField(max_length=200, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        managed = True
        db_table = 'api_request_cc'
        unique_together = (('request_type', 'request_id', 'user_id'),)
        indexes = [models.Index(fields=['request_type', 'request_id'])]

    def __str__(self):
        return f'cc({self.request_type}#{self.request_id} → user {self.user_id})'


class LoginRecord(models.Model):
    """Per-login telemetry. Captured by AuthView on every successful login.

    Stores lat/lng + reverse-geocoded place name + device info + IP so the
    super-admin can audit who logged in from where on which device. Different
    from AuditLog (which is action-oriented) — this is per-session.
    """

    user_id = models.BigIntegerField(db_index=True)
    user_name = models.CharField(max_length=200, blank=True, null=True)
    role = models.CharField(max_length=20, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    latitude = models.FloatField(blank=True, null=True)
    longitude = models.FloatField(blank=True, null=True)
    location_name = models.CharField(max_length=255, blank=True, null=True)
    device_info = models.CharField(max_length=255, blank=True, null=True)
    ip_address = models.CharField(max_length=64, blank=True, null=True)
    user_agent = models.TextField(blank=True, null=True)
    success = models.BooleanField(default=True)

    class Meta:
        managed = True
        db_table = 'api_login_record'
        indexes = [models.Index(fields=['-created_at'])]

    def __str__(self):
        return f'login({self.user_name}, {self.created_at})'


class AllowedIp(models.Model):
    """Admin-managed login IP allowlist.

    When *any* active row exists, AuthView rejects logins from IPs that
    don't match one of these CIDR blocks. Empty table = unrestricted
    (backwards compatible).
    """

    label = models.CharField(max_length=200)
    cidr = models.CharField(
        max_length=64,
        help_text='Single IP (e.g. 203.0.113.42) or CIDR block (e.g. 203.0.113.0/24)',
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        managed = True
        db_table = 'api_allowed_ip'

    def __str__(self):
        return f'{self.label} ({self.cidr})'


class Webhook(models.Model):
    """Outgoing HTTP hook fired when configured events occur.

    `events` is a comma-separated list of event keys (e.g.
    "request_approved,face_punch_in_succeeded"). The dispatcher signs each
    POST with `secret` in the X-PPulse-Signature header (HMAC-SHA256).
    """

    name = models.CharField(max_length=200)
    url = models.URLField(max_length=500)
    events = models.TextField(help_text='Comma-separated event keys')
    secret = models.CharField(max_length=128, blank=True, null=True)
    is_active = models.BooleanField(default=True)
    last_fired_at = models.DateTimeField(blank=True, null=True)
    last_status = models.IntegerField(blank=True, null=True)
    failure_count = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        managed = True
        db_table = 'api_webhook'

    def __str__(self):
        return f'{self.name} → {self.url}'


class RetentionPolicy(models.Model):
    """Per-table retention rule. A daily management command purges rows older
    than `max_days` from `model_name`. `model_name` is the lowercased Django
    label, e.g. "auditlog", "attendance".
    """

    model_name = models.CharField(max_length=64, unique=True)
    max_days = models.IntegerField(default=365)
    is_active = models.BooleanField(default=True)
    last_run_at = models.DateTimeField(blank=True, null=True)
    last_purged_count = models.IntegerField(default=0)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        managed = True
        db_table = 'api_retention_policy'

    def __str__(self):
        return f'{self.model_name} keep {self.max_days}d'


class UserConsent(models.Model):
    """Per-user consent ledger. One row per accepted T&Cs version."""

    user_id = models.BigIntegerField(db_index=True)
    user_name = models.CharField(max_length=200, blank=True, null=True)
    consent_key = models.CharField(max_length=64, default='terms_v1')
    accepted_at = models.DateTimeField(auto_now_add=True)
    ip_address = models.CharField(max_length=64, blank=True, null=True)
    user_agent = models.TextField(blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'api_user_consent'

    def __str__(self):
        return f'consent({self.user_id}, {self.consent_key})'


class AuditLog(models.Model):
    """Append-only audit trail for security-sensitive actions.

    Recorded events:
      - request_approved / request_rejected (with optional reason / comment)
      - employee_updated (field-level diff JSON in `payload`)
      - face_punch_in_failed (mismatch / unknown / location_required)
      - face_punch_in_succeeded
    Visible only to super-admin via /v1/admin/audit-logs.
    """

    created_at = models.DateTimeField(auto_now_add=True)
    actor_user_id = models.BigIntegerField(blank=True, null=True)
    actor_name = models.TextField(blank=True, null=True)
    actor_role = models.CharField(max_length=20, blank=True, null=True)
    target_user_id = models.BigIntegerField(blank=True, null=True)
    target_name = models.TextField(blank=True, null=True)
    action = models.CharField(max_length=64)
    target_type = models.CharField(max_length=64, blank=True, null=True)
    target_id = models.CharField(max_length=64, blank=True, null=True)
    payload = models.TextField(blank=True, null=True)  # JSON-encoded extra context
    ip_address = models.CharField(max_length=64, blank=True, null=True)

    class Meta:
        managed = True
        db_table = 'api_audit_log'
        indexes = [
            models.Index(fields=['-created_at']),
            models.Index(fields=['action']),
        ]

    def __str__(self):
        return f'AuditLog({self.action} by {self.actor_name} at {self.created_at})'


class EmployeeFaceData(models.Model):
    """Stores face embedding(s) for an employee, used for WFH face-verified punch-in.

    One row per employee. `embedding` is a packed float32 vector (512 dims for ArcFace
    buffalo_l) representing the L2-normalized average of all enrolled samples.
    """

    employee_id_id = models.BigIntegerField(unique=True, blank=True, null=True)
    embedding = models.BinaryField(blank=True, null=True)
    embedding_dim = models.IntegerField(default=512)
    num_samples = models.IntegerField(default=0)
    source_files = models.TextField(blank=True, null=True)  # comma-separated filenames
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        managed = True
        db_table = 'employee_face_data'

    def __str__(self):
        return f'FaceData(emp={self.employee_id_id}, samples={self.num_samples})'


class UserSettings(models.Model):
    theme = models.TextField(default='system')
    notifications_enabled = models.BooleanField(default=True)
    biometric_enabled = models.BooleanField(default=False)
    language = models.TextField(default='en')
    employee_id_id = models.BigIntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = True
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
