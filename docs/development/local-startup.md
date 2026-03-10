# Local Startup
The following doc describes how to run the application on your local machine.

## Prerequisites
1. Python 3.13 (Backend)
2. [uv](https://docs.astral.sh/uv/#installation) (Backend package management)
3. [Docker](https://www.docker.com/) (Database)
4. [Flutter SDK](https://docs.flutter.dev/install) (UI)

## Database
The project uses PostgreSQL database for storage. An easy way to get one running is using docker:
```bash
$ docker run -it --rm -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:18-alpine
```

## Backend

Let's start by navigating to the `backend/` directory:
```bash
$ cd backend
```

Now we need to get the required backend packages:
```bash
$ uv sync
```

Now we can run the migrations:
```bash
$ uv run alembic -c app/db/alembic.ini upgrade head
```

There is also a script we can use to populate the database with some test data:
```bash
$ uv run app/db/seed.py
```

Last thing to do is to start the API:
```bash
$ uv run fastapi dev
```

## UI

The UI code lives in the `ui/` directory, so let's navigate there:
```bash
$ cd ui/
```

Now we need to get the required ui packages:
```bash
$ flutter pub get
```

Once the packages are installed, we can run the UI app:
```bash
$ flutter run --dart-define=GOLEM_API_URL=http://localhost:8000 --web-port 4200 -d web-server
```

Once the app is started, you can access it on [http://localhost:4200](http://localhost:4200).

> **Note:** The seed also creates an user with administrative priviledges: 
> - **username:** admin 
> - **password:** admin 
