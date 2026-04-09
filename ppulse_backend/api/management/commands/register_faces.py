"""
Enroll employee faces from the `registered_faces/` folder.

Filename convention (any of):
    <badge_id>.jpg                   → looked up by Employee.badge_id
    <badge_id>__anything.jpg         → multiple samples per employee
    <employee_db_id>.jpg             → looked up by Employee.id
    <email>.jpg                      → looked up by Employee.email
    firstname_lastname.jpg           → looked up by name (best-effort)

Multiple files per employee are averaged into one embedding.

Usage:
    python manage.py register_faces                       # scan ./registered_faces
    python manage.py register_faces --dir /path/to/dir
    python manage.py register_faces --employee 42 file.jpg [file2.jpg ...]
    python manage.py register_faces --clear               # wipe all enrollments first
"""

from collections import defaultdict
from pathlib import Path

from django.conf import settings
from django.core.management.base import BaseCommand

from api.face_verification import enroll_from_images
from api.models import Employee, EmployeeFaceData

SUPPORTED_EXT = {'.jpg', '.jpeg', '.png', '.bmp', '.webp'}


def _default_dir() -> Path:
    return Path(settings.BASE_DIR) / 'registered_faces'


def _resolve_employee(token: str):
    """Try several lookup strategies for a filename stem."""
    token = token.strip()
    if not token:
        return None
    # 1. badge_id (case-insensitive exact)
    emp = Employee.objects.filter(badge_id__iexact=token).first()
    if emp:
        return emp
    # 2. numeric id
    if token.isdigit():
        emp = Employee.objects.filter(id=int(token)).first()
        if emp:
            return emp
    # 3. email
    if '@' in token:
        emp = Employee.objects.filter(email__iexact=token).first()
        if emp:
            return emp
    # 4. firstname_lastname (or firstname-lastname / firstname.lastname)
    parts = token.replace('.', ' ').replace('-', ' ').replace('_', ' ').split()
    if len(parts) >= 2:
        first, last = parts[0], parts[-1]
        emp = Employee.objects.filter(
            employee_first_name__iexact=first,
            employee_last_name__iexact=last,
        ).first()
        if emp:
            return emp
    # 5. firstname only (rare, but useful for demos)
    if len(parts) == 1:
        emp = Employee.objects.filter(employee_first_name__iexact=parts[0]).first()
        if emp:
            return emp
    return None


def _stem_to_token(stem: str) -> str:
    """`john_doe__office` → `john_doe` (strip trailing __sample)."""
    return stem.split('__', 1)[0]


class Command(BaseCommand):
    help = 'Enroll employee faces from registered_faces/ folder.'

    def add_arguments(self, parser):
        parser.add_argument('--dir', type=str, default=None, help='Folder of images')
        parser.add_argument(
            '--employee', type=int, default=None, help='Employee.id; treats positional args as image paths'
        )
        parser.add_argument(
            '--clear', action='store_true', help='Delete all existing EmployeeFaceData rows first'
        )
        parser.add_argument('paths', nargs='*', help='Optional explicit image paths')

    def handle(self, *args, **opts):
        if opts['clear']:
            n = EmployeeFaceData.objects.all().count()
            EmployeeFaceData.objects.all().delete()
            self.stdout.write(self.style.WARNING(f'Cleared {n} existing face records'))

        # Mode 1: explicit --employee + paths
        if opts['employee']:
            paths = opts['paths']
            if not paths:
                self.stderr.write('--employee requires at least one image path')
                return
            ok, msg, n = enroll_from_images(opts['employee'], list(paths))
            if ok:
                self.stdout.write(
                    self.style.SUCCESS(f'Enrolled employee {opts["employee"]} from {n} sample(s)')
                )
            else:
                self.stderr.write(self.style.ERROR(f'Failed: {msg}'))
            return

        # Mode 2: scan a directory
        target_dir = Path(opts['dir']) if opts['dir'] else _default_dir()
        if not target_dir.exists():
            self.stderr.write(self.style.ERROR(f'Directory not found: {target_dir}'))
            return

        # Group files by resolved employee.
        groups = defaultdict(list)
        unresolved = []
        for entry in sorted(target_dir.iterdir()):
            if not entry.is_file():
                continue
            if entry.suffix.lower() not in SUPPORTED_EXT:
                continue
            token = _stem_to_token(entry.stem)
            emp = _resolve_employee(token)
            if emp is None:
                unresolved.append(entry.name)
                continue
            groups[emp.id].append(str(entry))

        if not groups:
            self.stdout.write(self.style.WARNING(f'No images matched any employee under {target_dir}'))
            for name in unresolved:
                self.stdout.write(f'  unresolved: {name}')
            return

        total_emp = 0
        total_samples = 0
        for emp_id, files in groups.items():
            ok, msg, n = enroll_from_images(emp_id, files)
            emp = Employee.objects.filter(id=emp_id).first()
            label = f'{emp.name} (#{emp_id})' if emp else f'#{emp_id}'
            if ok:
                total_emp += 1
                total_samples += n
                self.stdout.write(self.style.SUCCESS(f'  ✓ {label}: {n} sample(s) from {len(files)} file(s)'))
            else:
                self.stdout.write(self.style.ERROR(f'  ✗ {label}: {msg}'))

        if unresolved:
            self.stdout.write('')
            self.stdout.write(
                self.style.WARNING(f'{len(unresolved)} file(s) could not be matched to an employee:')
            )
            for name in unresolved:
                self.stdout.write(f'  - {name}')

        self.stdout.write('')
        self.stdout.write(
            self.style.SUCCESS(f'Done: enrolled {total_emp} employee(s), {total_samples} total sample(s)')
        )
