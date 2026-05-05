#!/usr/bin/env python
"""Seed mock geo-tracking data into Attendance and LoginRecord tables.

Idempotent: only fills null/empty fields. Safe to run multiple times.

Usage:
    cd ppulse_backend
    python seed_geo_data.py
"""

import os
import random
import sys

import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ppulse_backend.settings')
sys.path.insert(0, os.path.dirname(__file__))
django.setup()

from api.models import Attendance, LoginRecord  # noqa: E402

# ── Mock data pools ─────────────────────────────────────────────

LOCATIONS = [
    ('Manyata Tech Park, Hebbal, Bangalore', 13.0476, 77.6210),
    ('Prestige Tech Park, Marathahalli, Bangalore', 12.9583, 77.6974),
    ('Embassy Golf Links, Domlur, Bangalore', 12.9611, 77.6420),
    ('Bagmane Tech Park, CV Raman Nagar, Bangalore', 12.9880, 77.6690),
    ('RMZ Ecoworld, Bellandur, Bangalore', 12.9253, 77.6835),
    ('Home Office, Indiranagar, Bangalore', 12.9784, 77.6408),
    ('Home Office, Koramangala, Bangalore', 12.9352, 77.6245),
    ('Home Office, HSR Layout, Bangalore', 12.9116, 77.6389),
    ('WeWork Galaxy, Residency Road, Bangalore', 12.9706, 77.6010),
    ('Home Office, Whitefield, Bangalore', 12.9698, 77.7500),
]

DEVICES = [
    'iPhone 15 Pro (iPhone16,2, iOS 17.5)',
    'iPhone 14 (iPhone15,2, iOS 17.4)',
    'Samsung Galaxy S24 (SM-S921B, Android 14)',
    'Google Pixel 8 Pro (husky, Android 14)',
    'OnePlus 12 (CPH2573, Android 14)',
    'Samsung Galaxy A54 (SM-A546B, Android 14)',
    'iPhone 13 (iPhone14,5, iOS 17.3)',
    'Google Pixel 7a (lynx, Android 14)',
]

SOURCES = ['mobile_ios', 'mobile_android']

IP_POOLS = [
    '192.168.1.',
    '192.168.0.',
    '10.0.1.',
    '10.0.2.',
    '172.16.0.',
    '203.0.113.',
    '49.207.56.',
    '106.51.72.',
]


def random_ip():
    return random.choice(IP_POOLS) + str(random.randint(2, 254))  # noqa: S311


def random_location():
    name, lat, lng = random.choice(LOCATIONS)  # noqa: S311
    # Add small jitter for realism
    lat += random.uniform(-0.002, 0.002)  # noqa: S311
    lng += random.uniform(-0.002, 0.002)  # noqa: S311
    return name, round(lat, 6), round(lng, 6)


def seed_attendance():
    """Fill null geo fields on existing Attendance records."""
    attendances = Attendance.objects.all()
    updated = 0

    for a in attendances:
        changed = False

        if not a.punch_in_location:
            name, lat, lng = random_location()
            a.punch_in_location = name
            a.punch_in_lat = lat
            a.punch_in_lng = lng
            changed = True

        if not a.punch_in_device:
            a.punch_in_device = random.choice(DEVICES)  # noqa: S311
            changed = True

        if not a.punch_in_source:
            a.punch_in_source = random.choice(SOURCES)  # noqa: S311
            changed = True

        if not a.punch_in_ip:
            a.punch_in_ip = random_ip()
            changed = True

        # Punch out fields (only if there's a clock-out time)
        if a.attendance_clock_out:
            if not a.punch_out_location:
                name, lat, lng = random_location()
                a.punch_out_location = name
                a.punch_out_lat = lat
                a.punch_out_lng = lng
                changed = True

            if not a.punch_out_device:
                a.punch_out_device = random.choice(DEVICES)  # noqa: S311
                changed = True

            if not a.punch_out_source:
                a.punch_out_source = random.choice(SOURCES)  # noqa: S311
                changed = True

            if not a.punch_out_ip:
                a.punch_out_ip = random_ip()
                changed = True

        if changed:
            a.save()
            updated += 1

    print(f'Attendance: updated {updated}/{attendances.count()} records')


def seed_login_records():
    """Fill null geo fields on existing LoginRecord entries."""
    records = LoginRecord.objects.all()
    updated = 0

    for r in records:
        changed = False

        if not r.location_name:
            name, lat, lng = random_location()
            r.location_name = name
            r.latitude = lat
            r.longitude = lng
            changed = True

        if not r.device_info:
            r.device_info = random.choice(DEVICES)  # noqa: S311
            changed = True

        if not r.ip_address:
            r.ip_address = random_ip()
            changed = True

        if changed:
            r.save()
            updated += 1

    print(f'LoginRecord: updated {updated}/{records.count()} records')


if __name__ == '__main__':
    print('Seeding mock geo-tracking data...')
    seed_attendance()
    seed_login_records()
    print('Done!')
