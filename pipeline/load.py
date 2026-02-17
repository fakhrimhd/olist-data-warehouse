import luigi
import sqlalchemy
from sqlalchemy.orm import sessionmaker
import pandas as pd
from pipeline.extract import Extract
from pipeline.utils.db_conn import db_connection
from pipeline.utils.read_sql import read_sql_file
import os
from dotenv import load_dotenv

load_dotenv()

# Dimension tables — truncate + full reload every run (Type 1 SCD: overwrite)
DIM_TABLES = [
    ('product_category_name_translation', 'public.product_category_name_translation.csv'),
    ('geolocation',                       'public.geolocation.csv'),
    ('customers',                         'public.customers.csv'),
    ('sellers',                           'public.sellers.csv'),
    ('products',                          'public.products.csv'),
]

# Fact tables — truncate only on first run; append on subsequent runs
# CSVs contain only new rows on incremental runs (handled by Extract)
FACT_TABLES = [
    ('orders',          'public.orders.csv'),
    ('order_payments',  'public.order_payments.csv'),
    ('order_reviews',   'public.order_reviews.csv'),
    ('order_items',     'public.order_items.csv'),
]

STG_QUERY_FILES = [
    'stg-product_category_name_translation.sql',
    'stg-geolocation.sql',
    'stg-customers.sql',
    'stg-orders.sql',
    'stg-products.sql',
    'stg-sellers.sql',
    'stg-order_payments.sql',
    'stg-order_items.sql',
    'stg-order_reviews.sql',
]


def get_watermark(dwh_engine):
    """
    Return MAX(order_purchase_timestamp) from stg.orders.
    Returns None on first run (stg table is empty).
    """
    with dwh_engine.connect() as conn:
        result = conn.execute(
            sqlalchemy.text("SELECT MAX(order_purchase_timestamp) FROM stg.orders")
        )
        row = result.fetchone()
        return row[0] if row and row[0] is not None else None


class Load(luigi.Task):

    def requires(self):
        return Extract()

    def run(self):
        DIR_TEMP_DATA  = os.getenv("DIR_TEMP_DATA")
        DIR_LOAD_QUERY = os.getenv("DIR_LOAD_QUERY")

        _, dwh_engine = db_connection()

        # Check watermark BEFORE loading — stg.orders is empty on first run
        watermark    = get_watermark(dwh_engine)
        is_first_run = watermark is None
        print(f"[Load] Mode: {'full (first run)' if is_first_run else 'incremental (append)'}")

        Session = sessionmaker(bind=dwh_engine)

        # ── 1. Dimension tables — always truncate + reload (Type 1 SCD) ──────
        session = Session()
        try:
            for table_name, _ in DIM_TABLES:
                session.execute(sqlalchemy.text(f"TRUNCATE TABLE public.{table_name} CASCADE"))
            session.commit()
        finally:
            session.close()

        for table_name, file_name in DIM_TABLES:
            df = pd.read_csv(f'{DIR_TEMP_DATA}/{file_name}')
            df.to_sql(table_name, con=dwh_engine, if_exists='append', index=False, schema='public')

        # ── 2. Fact tables — truncate on first run only, then append ─────────
        if is_first_run:
            session = Session()
            try:
                for table_name, _ in FACT_TABLES:
                    session.execute(sqlalchemy.text(f"TRUNCATE TABLE public.{table_name} CASCADE"))
                session.commit()
            finally:
                session.close()

        for table_name, file_name in FACT_TABLES:
            df = pd.read_csv(f'{DIR_TEMP_DATA}/{file_name}')
            if not df.empty:
                df.to_sql(table_name, con=dwh_engine, if_exists='append', index=False, schema='public')
                print(f"[Load] {table_name}: {len(df)} rows → public schema")

        # ── 3. public → stg (upsert — ON CONFLICT handles duplicates) ────────
        session = Session()
        try:
            for f in STG_QUERY_FILES:
                query = read_sql_file(f'{DIR_LOAD_QUERY}/{f}')
                session.execute(sqlalchemy.text(query))
            session.commit()
        finally:
            session.close()

        with self.output().open('w') as f:
            f.write('Load completed.\n')

    def output(self):
        return luigi.LocalTarget(os.getenv("DIR_TEMP_DATA") + "/load_done.txt")


if __name__ == "__main__":
    luigi.run()
