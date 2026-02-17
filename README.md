# 🏬 Olist Data Warehouse

A dimensional data warehouse built on **Olist** — Brazil's largest e-commerce marketplace. This project covers the full ELT cycle: from raw transactional data in a source PostgreSQL database to a clean star schema ready for analytics, orchestrated with **Luigi**.

---

## 🛠️ Tech Stack

| Layer        | Tool                          |
|--------------|-------------------------------|
| Orchestration | Python + Luigi               |
| Database     | PostgreSQL 16 (Docker)        |
| Data Loading | SQLAlchemy + Pandas           |
| SQL          | Raw `.sql` files per task     |
| Environment  | Docker Compose + `.env`       |

---

## 📐 Data Model

### Source (9 tables — `olist_src`)
`orders` · `order_items` · `order_payments` · `order_reviews` · `products` · `sellers` · `customers` · `geolocation` · `product_category_name_translation`

### DWH — Star Schema (`olist_dwh.final`)

**Dimensions**
- `dim_customer` — customer ID, city, state
- `dim_product` — product ID, category (EN), dimensions, weight
- `dim_seller` — seller ID, city, state

**Facts**
- `fct_order` — order lifecycle: status, timestamps, delivery delta
- `fct_order_items` — line items: price, freight, seller, product
- `fct_order_payments` — payment type, installments, value
- `fct_order_reviews` — review score, comment, response time

### SCD Strategy: Type 1
Stakeholders only need current values — no historical tracking required. All dimensions use **overwrite on change** (no versioning, no date ranges).

---

## 📂 Project Structure

```
dwh-olist/
├── elt_main.py              # Entry point — runs Extract → Load → Transform
├── docker-compose.yml       # Spins up olist-src (5433) + olist-dwh (5434)
├── requirements.txt
├── .env.example
│
├── pipeline/
│   ├── extract.py           # Task 1: source DB → CSV
│   ├── load.py              # Task 2: CSV → public schema → stg schema
│   ├── transform.py         # Task 3: stg → final star schema
│   ├── utils/
│   │   ├── db_conn.py       # SQLAlchemy engine factory
│   │   └── read_sql.py      # SQL file reader
│   ├── sql/
│   │   ├── extract/         # SELECT queries per source table
│   │   ├── load/            # INSERT INTO stg.* queries
│   │   └── transform/       # dim_* and fct_* build queries
│   └── temp/                # Runtime CSVs + Luigi marker files (gitignored)
│
└── infra/
    ├── source/              # Init SQL for source DB (9 tables + seed data)
    └── dwh/                 # Init SQL for DWH (schema definitions)
```

---

## 🔄 Pipeline Flow

```
olist-src (port 5433)
      │
      ▼
[Extract]  →  CSV files in pipeline/temp/
      │
      ▼
[Load]     →  olist-dwh public schema → stg schema
      │
      ▼
[Transform]→  olist-dwh final schema (star schema)
```

Luigi handles task dependencies and idempotency via marker files — rerun by deleting `pipeline/temp/*.txt`.

**Incremental loading** is supported for fact tables. On first run, everything is extracted and loaded in full. On subsequent runs, only orders (and related payments, items, reviews) newer than the last watermark are extracted — the watermark is `MAX(order_purchase_timestamp)` read from `stg.orders`. Dimension tables (products, sellers, customers, etc.) are always full-refreshed since they're small and use Type 1 SCD.

---

## ▶️ How to Run

**Prerequisites:** Docker, Python 3.10+

### 1. Clone & configure

```bash
git clone https://github.com/fakhrimhd/dwh-olist.git
cd dwh-olist
cp .env.example .env
# Edit .env with your paths and passwords
```

### 2. Start databases

```bash
docker-compose up -d
```

### 3. Set up Python environment

```bash
python3 -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

### 4. Run the pipeline

```bash
python3 elt_main.py
```

### 5. Query the results

Connect to `olist-dwh` on port `5434`, schema `final`:

```sql
-- Example: top 10 product categories by revenue
SELECT
    p.product_category_name_english AS category,
    COUNT(DISTINCT o.order_id)       AS total_orders,
    ROUND(SUM(i.price)::numeric, 2)  AS total_revenue
FROM final.fct_order_items i
JOIN final.dim_product p ON i.product_id = p.product_id
JOIN final.fct_order o   ON i.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY total_revenue DESC
LIMIT 10;
```

---

## 📎 Notes

- This project is built for learning and portfolio purposes.
- For production use: add retry logic and alerting (e.g. Sentry/Slack on task failure).
- Luigi marker files in `pipeline/temp/` control task idempotency — delete them to force a full re-run.
