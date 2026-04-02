from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .sso_views import (
    MicrosoftLoginView, MicrosoftCallbackView,
    GoogleLoginView, GoogleCallbackView,
    SSOStatusView,
)
from .views import (
    AuthView, RefreshTokenView, LogoutView, ChangePasswordView,
    UserMeView, AvatarUploadView,
    AttendancePunchInView, AttendancePunchOutView, AttendanceTodayView,
    AttendanceMonthlyView, AttendanceWeeklyView, AttendanceTeamView,
    LeaveBalanceView, LeaveApplyView,
    ClaimSubmitView, TicketRaiseView,
    ShiftRequestView, WorkTypeRequestView,
    AttendanceRegularizeView, AssetRequestView,
    RequestsListView, RequestDetailView, RequestAcceptView, RequestRejectView, RequestCancelView,
    PayslipsView, PayslipsListView, PayslipPDFView,
    NotificationsView, NotificationReadView, NotificationsReadAllView, DeviceRegisterView,
    EmployeesListView, EmployeeDetailView,
    DashboardSummaryView, DashboardAnnouncementsView, DashboardAnalyticsView,
    DepartmentsView, ShiftsListView, WorkTypesListView, LeaveTypesListView,
    ManagerStatsView, OrgChartView,
    SettingsView
)

urlpatterns = [
    # Auth
    path('auth/login', AuthView.as_view(), name='login'),
    path('auth/refresh', RefreshTokenView.as_view(), name='token_refresh'),
    path('auth/logout', LogoutView.as_view(), name='logout'),
    path('auth/change-password', ChangePasswordView.as_view(), name='change_password'),

    # SSO
    path('auth/microsoft/login', MicrosoftLoginView.as_view(), name='microsoft_login'),
    path('auth/microsoft/callback', MicrosoftCallbackView.as_view(), name='microsoft_callback'),
    path('auth/google/login', GoogleLoginView.as_view(), name='google_login'),
    path('auth/google/callback', GoogleCallbackView.as_view(), name='google_callback'),
    path('auth/sso/status', SSOStatusView.as_view(), name='sso_status'),
    
    # User
    path('users/me', UserMeView.as_view(), name='user_me'),
    path('users/me/avatar', AvatarUploadView.as_view(), name='avatar_upload'),
    
    # Attendance
    path('attendance/punch-in', AttendancePunchInView.as_view(), name='punch_in'),
    path('attendance/punch-out', AttendancePunchOutView.as_view(), name='punch_out'),
    path('attendance/today', AttendanceTodayView.as_view(), name='attendance_today'),
    path('attendance/monthly', AttendanceMonthlyView.as_view(), name='attendance_monthly'),
    path('attendance/weekly', AttendanceWeeklyView.as_view(), name='attendance_weekly'),
    path('attendance/team', AttendanceTeamView.as_view(), name='attendance_team'),
    path('attendance/regularize', AttendanceRegularizeView.as_view(), name='attendance_regularize'),
    
    # Leaves
    path('leaves/balance', LeaveBalanceView.as_view(), name='leave_balance'),
    path('leaves/apply', LeaveApplyView.as_view(), name='leave_apply'),
    
    # Claims
    path('claims/submit', ClaimSubmitView.as_view(), name='claim_submit'),
    
    # Tickets
    path('tickets/raise', TicketRaiseView.as_view(), name='ticket_raise'),
    
    # Shift Requests
    path('shifts/request', ShiftRequestView.as_view(), name='shift_request'),
    
    # Work Type Requests
    path('work-type/request', WorkTypeRequestView.as_view(), name='work_type_request'),
    
    # Asset Requests
    path('assets/request', AssetRequestView.as_view(), name='asset_request'),
    
    # Requests
    path('requests', RequestsListView.as_view(), name='requests_list'),
    path('requests/<int:pk>', RequestDetailView.as_view(), name='request_detail'),
    path('requests/<int:pk>/accept', RequestAcceptView.as_view(), name='request_accept'),
    path('requests/<int:pk>/reject', RequestRejectView.as_view(), name='request_reject'),
    path('requests/<int:pk>/cancel', RequestCancelView.as_view(), name='request_cancel'),
    
    # Payslips
    path('payslips', PayslipsView.as_view(), name='payslips'),
    path('payslips/list', PayslipsListView.as_view(), name='payslips_list'),
    path('payslips/<int:pk>/pdf', PayslipPDFView.as_view(), name='payslip_pdf'),
    
    # Notifications
    path('notifications', NotificationsView.as_view(), name='notifications'),
    path('notifications/<int:pk>/read', NotificationReadView.as_view(), name='notification_read'),
    path('notifications/read-all', NotificationsReadAllView.as_view(), name='notifications_read_all'),
    path('notifications/register-device', DeviceRegisterView.as_view(), name='device_register'),
    
    # Employees
    path('employees', EmployeesListView.as_view(), name='employees_list'),
    path('employees/<int:pk>', EmployeeDetailView.as_view(), name='employee_detail'),
    
    # Dashboard
    path('dashboard/summary', DashboardSummaryView.as_view(), name='dashboard_summary'),
    path('dashboard/announcements', DashboardAnnouncementsView.as_view(), name='dashboard_announcements'),
    path('dashboard/analytics', DashboardAnalyticsView.as_view(), name='dashboard_analytics'),
    
    # Reference Data
    path('departments', DepartmentsView.as_view(), name='departments'),
    path('shifts', ShiftsListView.as_view(), name='shifts'),
    path('work-types', WorkTypesListView.as_view(), name='work_types'),
    path('leave-types', LeaveTypesListView.as_view(), name='leave_types'),

    # Manager Stats & Org Chart
    path('dashboard/manager-stats', ManagerStatsView.as_view(), name='manager_stats'),
    path('org-chart', OrgChartView.as_view(), name='org_chart'),

    # Settings
    path('settings', SettingsView.as_view(), name='settings'),
]
