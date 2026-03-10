# Backend Documentation

The following doc describes the structure of the backend application and environment variables it uses.


## Modules

1. [api](./api/README.md) - API endpoints, middleware, ...
2. [db](./db/README.md) - database models, migrations, ...
3. [admin](./admin/README.md) - admin interface


## Environment Variables

Environment variables are loaded from a `.env` file in `config.py` on startup.
Each environment variable uses `GOLEM_` as a prefix to avoid conflicts with other applications.

- `GOLEM_DATABASE_URL` - the PostgreSQL connection string
- `GOLEM_SECRET_KEY` - the secret key for JWT encoding and decoding
- `GOLEM_ALGORITHM` - the algorithm used for JWT encoding and decoding (default: HS256)
- `GOLEM_ACCESS_TOKEN_EXPIRE_MINUTES` - the number of minutes that an access token is valid for
- `GOLEM_DEFAULT_ADMIN_USERNAME` - the default (created on first startup) admin username
- `GOLEM_DEFAULT_ADMIN_PASSWORD` - the default (created on first startup) admin password
- `GOLEM_DATA_DIR` - the directory used for storing sequence and metadata files