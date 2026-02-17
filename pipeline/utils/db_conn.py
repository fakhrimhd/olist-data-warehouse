from sqlalchemy import create_engine
import os


def db_connection():
    try:
        src_conn = (
            f"postgresql://{os.getenv('SRC_POSTGRES_USER')}:{os.getenv('SRC_POSTGRES_PASSWORD')}"
            f"@{os.getenv('SRC_POSTGRES_HOST')}:{os.getenv('SRC_POSTGRES_PORT')}/{os.getenv('SRC_POSTGRES_DB')}"
        )
        dwh_conn = (
            f"postgresql://{os.getenv('DWH_POSTGRES_USER')}:{os.getenv('DWH_POSTGRES_PASSWORD')}"
            f"@{os.getenv('DWH_POSTGRES_HOST')}:{os.getenv('DWH_POSTGRES_PORT')}/{os.getenv('DWH_POSTGRES_DB')}"
        )

        src_engine = create_engine(src_conn)
        dwh_engine = create_engine(dwh_conn)

        return src_engine, dwh_engine

    except Exception as e:
        raise ConnectionError(f"Failed to establish database connections: {e}") from e
