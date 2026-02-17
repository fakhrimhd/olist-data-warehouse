import luigi
from pipeline.load import Load
from pipeline.utils.db_conn import db_connection
from pipeline.utils.read_sql import read_sql_file
from sqlalchemy.orm import sessionmaker
import sqlalchemy
import os
from dotenv import load_dotenv

load_dotenv()

DIMS = ['dim_customer', 'dim_product', 'dim_seller']
FACTS = ['fct_order', 'fct_order_items', 'fct_order_payments', 'fct_order_reviews']


class Transform(luigi.Task):

    def requires(self):
        return Load()

    def run(self):
        DIR_TRANSFORM_QUERY = os.getenv("DIR_TRANSFORM_QUERY")

        # ── 1. Connect ───────────────────────────────────────────────────────
        _, dwh_engine = db_connection()

        Session = sessionmaker(bind=dwh_engine)

        # ── 2. Build dimension tables ────────────────────────────────────────
        session = Session()
        try:
            for table in DIMS:
                query = read_sql_file(f'{DIR_TRANSFORM_QUERY}/{table}.sql')
                session.execute(sqlalchemy.text(query))
            session.commit()
        except Exception:
            session.rollback()
            raise
        finally:
            session.close()

        # ── 3. Build fact tables ─────────────────────────────────────────────
        session = Session()
        try:
            for table in FACTS:
                query = read_sql_file(f'{DIR_TRANSFORM_QUERY}/{table}.sql')
                session.execute(sqlalchemy.text(query))
            session.commit()
        except Exception:
            session.rollback()
            raise
        finally:
            session.close()

        with self.output().open('w') as f:
            f.write('Transform completed.\n')

    def output(self):
        return luigi.LocalTarget(os.getenv("DIR_TEMP_DATA") + "/transform_done.txt")


if __name__ == "__main__":
    luigi.run()
