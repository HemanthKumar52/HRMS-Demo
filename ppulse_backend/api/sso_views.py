"""
Microsoft & Google SSO OAuth2 views for mobile app authentication.

Flow:
1. Mobile opens browser → /v1/auth/microsoft/login?redirect_uri=ppulse://auth-callback
2. Backend redirects → Microsoft OAuth login page
3. User authenticates with Microsoft
4. Microsoft redirects → /v1/auth/microsoft/callback?code=xxx&state=yyy
5. Backend exchanges code for user info, matches/creates user, generates JWT
6. Backend redirects → ppulse://auth-callback?access_token=xxx&refresh_token=yyy&user=json
7. Mobile app catches deep link, stores token, navigates to dashboard
"""

import json
import uuid
import urllib.parse
import msal
from django.conf import settings
from django.http import HttpResponseRedirect, JsonResponse
from django.views import View
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Employee, EmployeeWorkInformation, Department, JobPosition

# ═══════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════

def _get_employee_from_email(email):
    """Find employee by email in Employee or User table."""
    from django.contrib.auth import get_user_model
    User = get_user_model()

    # Try matching by employee email first
    employee = Employee.objects.filter(email__iexact=email, is_active=True).first()
    if employee and employee.employee_user_id_id:
        user = User.objects.filter(id=employee.employee_user_id_id).first()
        if user:
            return user, employee

    # Try matching by user email
    user = User.objects.filter(email__iexact=email, is_active=True).first()
    if user:
        employee = Employee.objects.filter(employee_user_id_id=user.id).first()
        return user, employee

    return None, None


def _build_user_response(request, user, employee):
    """Build JWT token and user data response."""
    refresh = RefreshToken.for_user(user)

    department = ''
    designation = ''
    if employee:
        work_info = EmployeeWorkInformation.objects.filter(employee_id_id=employee.id).first()
        if work_info:
            if work_info.department_id_id:
                dept = Department.objects.filter(id=work_info.department_id_id).first()
                department = dept.department if dept else ''
            if work_info.job_position_id_id:
                jp = JobPosition.objects.filter(id=work_info.job_position_id_id).first()
                designation = jp.job_position if jp else ''

    return {
        'access_token': str(refresh.access_token),
        'refresh_token': str(refresh),
        'expires_in': 3600,
        'user': {
            'id': str(user.id),
            'employee_id': (employee.badge_id or str(employee.id)) if employee else str(user.id),
            'name': employee.name if employee else (user.first_name or user.username or ''),
            'email': user.email,
            'designation': designation,
            'department': department,
            'avatar_url': employee.avatar_url if employee else None,
        }
    }


# ═══════════════════════════════════════════════════════
# MICROSOFT SSO
# ═══════════════════════════════════════════════════════

def _get_msal_app():
    """Create MSAL confidential client."""
    authority = f"https://login.microsoftonline.com/{settings.MICROSOFT_AUTH_TENANT_ID}"
    return msal.ConfidentialClientApplication(
        settings.MICROSOFT_AUTH_CLIENT_ID,
        authority=authority,
        client_credential=settings.MICROSOFT_AUTH_CLIENT_SECRET,
    )


class MicrosoftLoginView(View):
    """
    GET /v1/auth/microsoft/login?redirect_uri=ppulse://auth-callback
    Redirects user to Microsoft OAuth2 login page.
    """

    def get(self, request):
        # The mobile app passes its deep link as redirect_uri
        mobile_redirect = request.GET.get('redirect_uri', f'{settings.MOBILE_AUTH_CALLBACK_SCHEME}://auth-callback')

        # Build our backend callback URL
        callback_url = request.build_absolute_uri('/v1/auth/microsoft/callback')

        # Store mobile redirect in state so we can use it after callback
        state = json.dumps({
            'id': str(uuid.uuid4()),
            'mobile_redirect': mobile_redirect,
        })

        app = _get_msal_app()
        auth_url = app.get_authorization_request_url(
            scopes=['User.Read'],
            redirect_uri=callback_url,
            state=state,
        )

        return HttpResponseRedirect(auth_url)


class MicrosoftCallbackView(View):
    """
    GET /v1/auth/microsoft/callback?code=xxx&state=yyy
    Handles Microsoft OAuth2 callback, authenticates user, redirects to mobile app.
    """

    def get(self, request):
        code = request.GET.get('code')
        state_str = request.GET.get('state', '{}')
        error = request.GET.get('error')

        try:
            state = json.loads(state_str)
        except (json.JSONDecodeError, TypeError):
            state = {}

        mobile_redirect = state.get('mobile_redirect', f'{settings.MOBILE_AUTH_CALLBACK_SCHEME}://auth-callback')

        if error:
            error_desc = request.GET.get('error_description', 'Authentication failed')
            return HttpResponseRedirect(
                f"{mobile_redirect}?error={urllib.parse.quote(error_desc)}"
            )

        if not code:
            return HttpResponseRedirect(
                f"{mobile_redirect}?error=no_auth_code"
            )

        # Exchange code for token
        callback_url = request.build_absolute_uri('/v1/auth/microsoft/callback')
        app = _get_msal_app()

        result = app.acquire_token_by_authorization_code(
            code,
            scopes=['User.Read'],
            redirect_uri=callback_url,
        )

        if 'error' in result:
            error_msg = result.get('error_description', result.get('error', 'Token exchange failed'))
            return HttpResponseRedirect(
                f"{mobile_redirect}?error={urllib.parse.quote(error_msg)}"
            )

        # Get user info from the ID token claims
        id_token_claims = result.get('id_token_claims', {})
        email = (
            id_token_claims.get('preferred_username')
            or id_token_claims.get('email')
            or id_token_claims.get('upn')
            or ''
        )
        ms_name = id_token_claims.get('name', '')

        if not email:
            return HttpResponseRedirect(
                f"{mobile_redirect}?error=no_email_in_token"
            )

        # Find or create user
        user, employee = _get_employee_from_email(email)

        if not user:
            # Auto-create user if not found (optional - you may want to disable this)
            from django.contrib.auth import get_user_model
            User = get_user_model()
            user = User.objects.create_user(
                username=email,
                email=email,
                password=None,  # SSO users don't need a password
            )
            if ms_name:
                parts = ms_name.split(' ', 1)
                user.first_name = parts[0]
                user.last_name = parts[1] if len(parts) > 1 else ''
                user.save()
            # Re-fetch employee (won't exist for new users)
            employee = Employee.objects.filter(employee_user_id_id=user.id).first()

        # Build JWT response
        auth_data = _build_user_response(request, user, employee)

        # Redirect to mobile app with token data
        params = {
            'access_token': auth_data['access_token'],
            'refresh_token': auth_data['refresh_token'],
            'user': json.dumps(auth_data['user']),
        }
        redirect_url = f"{mobile_redirect}?{urllib.parse.urlencode(params)}"
        return HttpResponseRedirect(redirect_url)


# ═══════════════════════════════════════════════════════
# GOOGLE SSO (ready for future - hidden in UI)
# ═══════════════════════════════════════════════════════

class GoogleLoginView(View):
    """
    GET /v1/auth/google/login?redirect_uri=ppulse://auth-callback
    Redirects user to Google OAuth2 login page.
    """

    def get(self, request):
        if not settings.GOOGLE_AUTH_ENABLED:
            return JsonResponse({'error': 'Google SSO is not enabled'}, status=403)

        mobile_redirect = request.GET.get('redirect_uri', f'{settings.MOBILE_AUTH_CALLBACK_SCHEME}://auth-callback')

        state = json.dumps({
            'id': str(uuid.uuid4()),
            'mobile_redirect': mobile_redirect,
        })

        callback_url = request.build_absolute_uri('/v1/auth/google/callback')

        params = {
            'client_id': settings.GOOGLE_AUTH_CLIENT_ID,
            'redirect_uri': callback_url,
            'response_type': 'code',
            'scope': 'openid email profile',
            'state': state,
            'access_type': 'offline',
            'prompt': 'select_account',
        }
        auth_url = f"https://accounts.google.com/o/oauth2/v2/auth?{urllib.parse.urlencode(params)}"
        return HttpResponseRedirect(auth_url)


class GoogleCallbackView(View):
    """
    GET /v1/auth/google/callback?code=xxx&state=yyy
    Handles Google OAuth2 callback.
    """

    def get(self, request):
        import urllib.request

        code = request.GET.get('code')
        state_str = request.GET.get('state', '{}')

        try:
            state = json.loads(state_str)
        except (json.JSONDecodeError, TypeError):
            state = {}

        mobile_redirect = state.get('mobile_redirect', f'{settings.MOBILE_AUTH_CALLBACK_SCHEME}://auth-callback')

        if not code:
            return HttpResponseRedirect(f"{mobile_redirect}?error=no_auth_code")

        # Exchange code for token
        callback_url = request.build_absolute_uri('/v1/auth/google/callback')
        token_data = urllib.parse.urlencode({
            'code': code,
            'client_id': settings.GOOGLE_AUTH_CLIENT_ID,
            'client_secret': settings.GOOGLE_AUTH_CLIENT_SECRET,
            'redirect_uri': callback_url,
            'grant_type': 'authorization_code',
        }).encode()

        try:
            req = urllib.request.Request('https://oauth2.googleapis.com/token', data=token_data)
            req.add_header('Content-Type', 'application/x-www-form-urlencoded')
            resp = urllib.request.urlopen(req)
            token_result = json.loads(resp.read())
        except Exception as e:
            return HttpResponseRedirect(f"{mobile_redirect}?error={urllib.parse.quote(str(e))}")

        # Get user info
        access_token = token_result.get('access_token')
        try:
            req = urllib.request.Request('https://www.googleapis.com/oauth2/v2/userinfo')
            req.add_header('Authorization', f'Bearer {access_token}')
            resp = urllib.request.urlopen(req)
            user_info = json.loads(resp.read())
        except Exception as e:
            return HttpResponseRedirect(f"{mobile_redirect}?error={urllib.parse.quote(str(e))}")

        email = user_info.get('email', '')
        name = user_info.get('name', '')

        if not email:
            return HttpResponseRedirect(f"{mobile_redirect}?error=no_email_from_google")

        user, employee = _get_employee_from_email(email)

        if not user:
            from django.contrib.auth import get_user_model
            User = get_user_model()
            user = User.objects.create_user(username=email, email=email, password=None)
            if name:
                parts = name.split(' ', 1)
                user.first_name = parts[0]
                user.last_name = parts[1] if len(parts) > 1 else ''
                user.save()
            employee = Employee.objects.filter(employee_user_id_id=user.id).first()

        auth_data = _build_user_response(request, user, employee)

        params = {
            'access_token': auth_data['access_token'],
            'refresh_token': auth_data['refresh_token'],
            'user': json.dumps(auth_data['user']),
        }
        return HttpResponseRedirect(f"{mobile_redirect}?{urllib.parse.urlencode(params)}")


# ═══════════════════════════════════════════════════════
# SSO STATUS API (for mobile to check what's enabled)
# ═══════════════════════════════════════════════════════

class SSOStatusView(APIView):
    """GET /v1/auth/sso/status - Returns which SSO providers are enabled."""
    permission_classes = [AllowAny]

    def get(self, request):
        return Response({
            'microsoft': {
                'enabled': settings.MICROSOFT_AUTH_ENABLED,
                'login_url': request.build_absolute_uri('/v1/auth/microsoft/login'),
            },
            'google': {
                'enabled': settings.GOOGLE_AUTH_ENABLED,
                'login_url': request.build_absolute_uri('/v1/auth/google/login') if settings.GOOGLE_AUTH_ENABLED else None,
            },
        })
