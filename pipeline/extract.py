import luigi
import pandas as pd
import sqlalchemy
from pipeline.utils.db_conn import db_connection
from pipeline.utils.read_sql import read_sql_file
import os
from dotenv import load_dotenv

load_dotenv()

# Dimension tables — always full extract (small, rarely change, Type 1 SCD)
DIM_TABLES = [
    'public.products',
    'public.sellers',
    'public.customers',
    'public.geolocation',
    'public.product_category_name_translation',
]

# Fact tables — incremental after first run
# Orders drives the watermark; related tables filter by new order_ids
FACT_TABLES = [
    'public.orders',
    'public.order_items',
    'public.order_payments',
    'public.order_reviews',
]

# Incremental queries — only pull rows linked to orders newer than watermark
INCREMENTAL_QUERIES = {
    'public.orders': """
        SELECT * FROM public.orders
        WHERE CAST(order_purchase_timestamp AS TIMESTAMP) > '{watermark}'
    """,
    'public.order_items': """
        SELECT oi.* FROM public.order_items oi
        WHERE oi.order_id IN (
            SELECT order_id FROM public.orders
            WHERE CAST(order_purchase_timestamp AS TIMESTAMP) > '{watermark}'
        )
    """,
    'public.order_payments': """
        SELECT op.* FROM public.order_payments op
        WHERE op.order_id IN (
            SELECT order_id FROM public.orders
            WHERE CAST(order_purchase_timestamp AS TIMESTAMP) > '{watermark}'
        )
    """,
    'public.order_reviews': """
        SELECT r.* FROM public.order_reviews r
        WHERE r.order_id IN (
            SELECT order_id FROM public.orders
            WHERE CAST(order_purchase_timestamp AS TIMESTAMP) > '{watermark}'
        )
    """,
}


def get_watermark(dwh_engine):
    """
    Return MAX(order_purchase_timestamp) from stg.orders.
    Returns None on first run (stg table is empty).
    stg.orders is used (not public.orders) because stg accumulates
    across runs while public gets truncated each cycle.
    """
    with dwh_engine.connect() as conn:
        result = conn.execute(
            sqlalchemy.text("SELECT MAX(order_purchase_timestamp) FROM stg.orders")
        )
        row = result.fetchone()
        return row[0] if row and row[0] is not None else None


class Extract(luigi.Task):

    def run(self):
        DIR_TEMP_DATA     = os.getenv("DIR_TEMP_DATA")
        DIR_EXTRACT_QUERY = os.getenv("DIR_EXTRACT_QUERY")

        src_engine, dwh_engine = db_connection()

        watermark    = get_watermark(dwh_engine)
        is_first_run = watermark is None
        print(f"[Extract] Mode: {'full (first run)' if is_first_run else f'incremental since {watermark}'}")

        full_query = read_sql_file(f'{DIR_EXTRACT_QUERY}/all-tables.sql')
        extracted  = []

        # ── 1. Dimension tables — always full extract ─────────────────────────
        for table_name in DIM_TABLES:
            try:
                df = pd.read_sql_query(full_query.format(table_name=table_name), src_engine)
                output_path = f"{DIR_TEMP_DATA}/{table_name}.csv"
                df.to_csv(output_path, index=False)
                extracted.append(output_path)
            except Exception as e:
                raise RuntimeError(f"Failed to extract '{table_name}': {e}") from e

        # ── 2. Fact tables — full on first run, incremental after ─────────────
        if is_first_run:
            for table_name in FACT_TABLES:
                try:
                    df = pd.read_sql_query(full_query.format(table_name=table_name), src_engine)
                    output_path = f"{DIR_TEMP_DATA}/{table_name}.csv"
                    df.to_csv(output_path, index=False)
                    extracted.append(output_path)
                except Exception as e:
                    raise RuntimeError(f"Failed to extract '{table_name}': {e}") from e
        else:
            with src_engine.connect() as conn:
                for table_name in FACT_TABLES:
                    try:
                        query = INCREMENTAL_QUERIES[table_name].format(
                            watermark=watermark.strftime('%Y-%m-%d %H:%M:%S.%f')
                        )
                        df = pd.read_sql_query(query, conn)
                        output_path = f"{DIR_TEMP_DATA}/{table_name}.csv"
                        df.to_csv(output_path, index=False)
                        extracted.append(output_path)
                        print(f"[Extract] {table_name}: {len(df)} new rows")
                    except Exception as e:
                        raise RuntimeError(f"Failed incremental extract '{table_name}': {e}") from e

        with self.output().open('w') as f:
            f.write('\n'.join(extracted) + '\n')

    def output(self):
        return luigi.LocalTarget(os.getenv("DIR_TEMP_DATA") + "/extracted_files.txt")


if __name__ == "__main__":
    luigi.run()
