"""
Seed Neon database with all users, employees, departments, job positions,
and work information from the local database.
"""

import os
import sys

import django

# Connect to LOCAL database first to read data
os.environ.pop('DATABASE_URL', None)
os.environ['DJANGO_SETTINGS_MODULE'] = 'ppulse_backend.settings'
django.setup()

from api.models import (  # noqa: E402
    Department,
    Employee,
    EmployeeWorkInformation,
    JobPosition,
    Shift,
    User,
    WorkType,
)

# Read all data from local DB
print('Reading local data...')
local_users = list(
    User.objects.all().values(
        'id',
        'username',
        'email',
        'password',
        'is_staff',
        'is_superuser',
        'is_active',
    )
)
local_employees = list(
    Employee.objects.all().values(
        'id',
        'employee_user_id_id',
        'employee_first_name',
        'employee_last_name',
        'email',
        'badge_id',
        'phone',
        'is_active',
        'gender',
        'dob',
        'marital_status',
        'address',
        'city',
        'state',
        'country',
        'zip',
        'qualification',
        'experience',
        'employee_profile',
    )
)
local_departments = list(Department.objects.all().values('id', 'department'))
local_positions = list(JobPosition.objects.all().values('id', 'job_position'))
local_work_info = list(
    EmployeeWorkInformation.objects.all().values(
        'id',
        'employee_id_id',
        'department_id_id',
        'job_position_id_id',
        'reporting_manager_id_id',
        'work_type_id_id',
        'shift_id_id',
        'date_joining',
        'company_id_id',
    )
)
local_work_types = list(WorkType.objects.all().values('id', 'work_type'))
local_shifts = list(Shift.objects.all().values('id', 'employee_shift', 'full_time'))

print(f'  Users: {len(local_users)}')
print(f'  Employees: {len(local_employees)}')
print(f'  Departments: {len(local_departments)}')
print(f'  Positions: {len(local_positions)}')
print(f'  Work Info: {len(local_work_info)}')
print(f'  Work Types: {len(local_work_types)}')
print(f'  Shifts: {len(local_shifts)}')

# Now switch to Neon database
NEON_URL = os.environ.get('NEON_URL') or sys.argv[1] if len(sys.argv) > 1 else None
if not NEON_URL:
    print('ERROR: Pass Neon URL as argument or set NEON_URL env var')
    sys.exit(1)

import dj_database_url  # noqa: E402
from django.conf import settings  # noqa: E402

settings.DATABASES['default'] = dj_database_url.parse(NEON_URL)

# Force new connection
from django.db import connections  # noqa: E402

connections['default'].close()
connections['default'].settings_dict.update(settings.DATABASES['default'])

print('\nWriting to Neon...')

# Departments
for d in local_departments:
    Department.objects.get_or_create(id=d['id'], defaults={'department': d['department']})
print(f'  Departments: {len(local_departments)} synced')

# Job Positions
for p in local_positions:
    JobPosition.objects.get_or_create(
        id=p['id'],
        defaults={'job_position': p['job_position']},
    )
print(f'  Positions: {len(local_positions)} synced')

# Work Types
for wt in local_work_types:
    WorkType.objects.get_or_create(id=wt['id'], defaults={'work_type': wt['work_type']})
print(f'  Work Types: {len(local_work_types)} synced')

# Shifts
for s in local_shifts:
    Shift.objects.get_or_create(
        id=s['id'],
        defaults={
            'employee_shift': s['employee_shift'],
            'full_time': s.get('full_time'),
        },
    )
print(f'  Shifts: {len(local_shifts)} synced')

# Users (preserve password hashes)
for u in local_users:
    if User.objects.filter(username=u['username']).exists():
        continue
    user = User(
        username=u['username'],
        email=u['email'],
        is_staff=u['is_staff'],
        is_superuser=u['is_superuser'],
        is_active=u['is_active'],
    )
    user.password = u['password']  # copy hashed password directly
    user.save()
print(f'  Users: {len(local_users)} synced')

# Build username→new_id map for foreign keys
user_map = {u.username: u.id for u in User.objects.all()}
local_user_id_to_username = {u['id']: u['username'] for u in local_users}

# Employees
for e in local_employees:
    if (
        Employee.objects.filter(badge_id=e['badge_id']).exists()
        or Employee.objects.filter(email=e['email']).exists()
    ):
        continue
    # Resolve user FK
    local_uid = e['employee_user_id_id']
    username = local_user_id_to_username.get(local_uid)
    new_uid = user_map.get(username) if username else None

    Employee.objects.create(
        employee_user_id_id=new_uid,
        employee_first_name=e['employee_first_name'],
        employee_last_name=e['employee_last_name'],
        email=e['email'],
        badge_id=e['badge_id'],
        phone=e['phone'] or '',
        is_active=e['is_active'],
        gender=e.get('gender') or '',
        dob=e.get('dob'),
        marital_status=e.get('marital_status') or '',
        address=e.get('address') or '',
        city=e.get('city') or '',
        state=e.get('state') or '',
        country=e.get('country') or '',
        zip=e.get('zip') or '',
        qualification=e.get('qualification') or '',
        experience=e.get('experience'),
    )
print(f'  Employees: {len(local_employees)} synced')

# Build badge→new_emp_id map for manager references
emp_map = {emp.badge_id: emp.id for emp in Employee.objects.all()}
local_emp_id_to_badge = {e['id']: e['badge_id'] for e in local_employees}

# Work Information
for wi in local_work_info:
    local_emp_id = wi['employee_id_id']
    badge = local_emp_id_to_badge.get(local_emp_id)
    new_emp_id = emp_map.get(badge) if badge else None
    if not new_emp_id:
        continue

    if EmployeeWorkInformation.objects.filter(employee_id_id=new_emp_id).exists():
        continue

    # Resolve manager FK
    mgr_new_id = None
    if wi['reporting_manager_id_id']:
        mgr_badge = local_emp_id_to_badge.get(wi['reporting_manager_id_id'])
        mgr_new_id = emp_map.get(mgr_badge)

    EmployeeWorkInformation.objects.create(
        employee_id_id=new_emp_id,
        department_id_id=wi['department_id_id'],
        job_position_id_id=wi['job_position_id_id'],
        reporting_manager_id_id=mgr_new_id,
        work_type_id_id=wi.get('work_type_id_id'),
        shift_id_id=wi.get('shift_id_id'),
        date_joining=wi.get('date_joining'),
        company_id_id=wi.get('company_id_id'),
    )
print(f'  Work Info: {len(local_work_info)} synced')

print('\nDone! All data seeded to Neon.')
