#!/bin/bash
pip install -r requirements-vercel.txt
python manage.py collectstatic --noinput 2>/dev/null || true
