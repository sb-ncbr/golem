# Deployment Docs

- [Automatic Certificate Renewal](./certificate-renewal.md)

## Deployment to an Existing Environment

The deployment process is automated using GitHub Actions. The workflow can be triggered manually by navigating to **Actions** -> **GOLEM Deploy** -> **Run workflow**.

The pipeline allows to choose to which environment the deployment should happen: either **Production** or **Development**.

You can find the workflow yaml file [here](../../.github/workflows/golem-deploy.yml).

## Adding a New Environment

To add a new environment, follow these steps:

1. Add a new entry in the `inputs` section of the `.github/workflows/golem-deploy.yml` file.
2. Specify the required environment variables and secrets.
   - On GitHub, navigate to **Settings** -> **Environments** -> **New environment**.
   - Create variables and secrets as defined for the existing environments.

### Environment Requirements

The pipeline assumes that the deployment target is a linux system.

1. SSH Access
   - The necessary SSH configuration is part of the environment variables and secrets on GitHub.
2. Docker
3. Repository cloned into the users `$HOME` directory.
   - e.g. if you are using user named `golem`, then the repository should be cloned into `/home/golem/geneweb`.
4. SSL certificates for the given domain name(s).
   - Currently, it assumes the use of `certbot`. You can generate a new certificate using `sudo certbot certonly --standalone`.
   - Paths to certificates are currently configured in `deployment/docker-compose.yml` and `deployment/nginx/nginx.conf.template`
   - For automatic certificate renewal, see [certificate-renewal.md](./certificate-renewal.md)

### Initial Database Seed

After first deployment, you can populate the database with some initial data:

```bash
$ cd ~/geneweb
$ docker exec -it <api-container-hash> uv run app/db/seed.py
$ cp -r backend/data/* $GOLEM_DATA_DIR # variable defined in docker-compose.yml
```

This will initialize database with some organisms and an admin user. The credentials of the admin user are defined by `$GOLEM_DEFAULT_ADMIN_USERNAME` and `$GOLEM_DEFAULT_ADMIN_PASSWORD` environment variables.


### Misc
- nginx logs can also be viewed using journalctl:
   - `$ journalctl CONTAINER_TAG=golem-nginx`