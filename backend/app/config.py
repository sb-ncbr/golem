import os

from dataclasses import dataclass

from dotenv import load_dotenv

load_dotenv(verbose=True)


@dataclass(frozen=True)
class AppConfig:
    database_url: str
    secret_key: str
    algorithm: str
    access_token_expire_minutes: int
    data_dir: str
    default_admin_username: str
    default_admin_password: str

    def __post_init__(self):
        missing = [name.upper() for name, value in self.__dict__.items() if value in (None, "")]
        if missing:
            raise ValueError(f"Missing environment variable(s): {', '.join(missing)}")

    @classmethod
    def from_env(cls, env_file: str | None = ".env") -> "AppConfig":
        """
        Load environment variables from a .env file.

        Args:
            env_file (str, optional): The path to the .env file. Defaults to ".env".
        Raises:
            ValueError: If required environment variables are missing.
        Returns:
            AppConfig: An instance of AppConfig containing the environment variables.
        """

        load_dotenv(env_file, verbose=True)
        return cls(
            database_url=os.environ.get("GOLEM_DATABASE_URL"),
            secret_key=os.environ.get("GOLEM_SECRET_KEY"),
            algorithm=os.environ.get("GOLEM_ALGORITHM"),
            access_token_expire_minutes=int(os.environ.get("GOLEM_ACCESS_TOKEN_EXPIRE_MINUTES")),
            data_dir=os.environ.get("GOLEM_DATA_DIR"),
            default_admin_username=os.environ.get("GOLEM_DEFAULT_ADMIN_USERNAME"),
            default_admin_password=os.environ.get("GOLEM_DEFAULT_ADMIN_PASSWORD"),
        )


app_config = AppConfig.from_env()
