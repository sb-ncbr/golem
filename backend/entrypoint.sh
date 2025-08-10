#!/bin/bash

# This script runs migrations before running the fastapi server.
# It is used in the Dockerfile.

cd app

# run database migrations
alembic -c db/alembic.ini upgrade head

exec fastapi run --port 8000 --host 0.0.0.0