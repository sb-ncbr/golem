# UI Documentation

The following doc describes the structure of the frontend application.

## Modules

1. [analysis](./analysis/README.md)
2. [api](./api/README.md)
3. [genes](./genes/README.md)
4. [output](./output/README.md)
5. [utilities](./utilities/README.md)
6. [widgets](./widgets/README.md)

## Environment Variables

Each environment variable should use the `GOLEM_` prefix to avoid conflicts with other applications.

- `GOLEM_API_PORT` - The port of the backend API (e.g. 8000).
    - Only relevant for local development, can be omitted (defaults to 8000).
