"""
Django settings for ppulse_backend project.
"""

import os
from pathlib import Path
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.environ.get('SECRET_KEY', 'django-insecure-c%fg^^0bq=c_o9l0x80zlbdq9h%976bof@d3_g%xvylsq(z6ca')

DEBUG = True

ALLOWED_HOSTS = ['*']

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'rest_framework_simplejwt',
    'corsheaders',
    'api',
]

AUTH_USER_MODEL = 'api.User'

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'ppulse_backend.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'ppulse_backend.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': '/Users/kaasprord/Projects/HRMS-Demo/shared_hrms.db',
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
MEDIA_URL = 'media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

AUTH_USER_MODEL = 'api.User'

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'AUTH_HEADER_TYPES': ('Bearer',),
}

CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_CREDENTIALS = True

# ═══════════════════════════════════════════
# MICROSOFT SSO CONFIGURATION
# ═══════════════════════════════════════════
MICROSOFT_AUTH_CLIENT_ID = os.environ.get('MICROSOFT_AUTH_CLIENT_ID', '22a6161f-4a71-4a09-9b03-3eb026c8ec88')
MICROSOFT_AUTH_CLIENT_SECRET = os.environ.get('MICROSOFT_AUTH_CLIENT_SECRET', 'Ij38Q~pO12WiOgwapwW2kGYVE7ouPBg3MCXKFch7')
MICROSOFT_AUTH_TENANT_ID = os.environ.get('MICROSOFT_AUTH_TENANT_ID', '6cf47e8a-fa07-4cb7-bc19-c75fb013d1fb')
MICROSOFT_AUTH_ENABLED = os.environ.get('MICROSOFT_AUTH_LOGIN_ENABLED', 'True') == 'True'

# For mobile: deep link scheme callback
MOBILE_AUTH_CALLBACK_SCHEME = 'ppulse'  # ppulse://auth-callback

# ═══════════════════════════════════════════
# GOOGLE SSO CONFIGURATION (hidden for now)
# ═══════════════════════════════════════════
GOOGLE_AUTH_CLIENT_ID = os.environ.get('GOOGLE_AUTH_CLIENT_ID', '')
GOOGLE_AUTH_CLIENT_SECRET = os.environ.get('GOOGLE_AUTH_CLIENT_SECRET', '')
GOOGLE_AUTH_ENABLED = os.environ.get('GOOGLE_AUTH_LOGIN_ENABLED', 'False') == 'True'

AUTH_PASSWORD_HASHERS = [
    'django.contrib.auth.hashers.PBKDF2PasswordHasher',
    'django.contrib.auth.hashers.PBKDF2SHA1PasswordHasher',
    'django.contrib.auth.hashers.Argon2PasswordHasher',
    'django.contrib.auth.hashers.BCryptSHA256PasswordHasher',
]
