FROM python:3.13-slim

# installing uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

COPY . /geneweb
COPY app/.env.template /geneweb/app/.env

WORKDIR /geneweb

RUN uv export --no-hashes --format requirements-txt > requirements.txt
RUN pip install -r requirements.txt

RUN chmod +x /geneweb/entrypoint.sh

ENTRYPOINT ["/geneweb/entrypoint.sh"]