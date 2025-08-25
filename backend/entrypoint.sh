#!/bin/bash

# This script runs migrations before running the fastapi server.
# It is used in the Dockerfile.

# run database migrations
alembic -c app/db/alembic.ini upgrade head

exec uvicorn app.main:golem_app --port 8000 --host 0.0.0.0 --forwarded-allow-ips='*' --proxy-headers