# DuckDB Quick Guide

DuckDB is an in-process analytical database — think SQLite but built for analytics. It runs entirely in your Python process (no server needed) and is extremely fast at querying Parquet files, CSVs, and Pandas DataFrames.

---

## Installation

```bash
pip install duckdb
```

---

## Basic Usage

```python
import duckdb

# In-memory database (gone when the process ends)
con = duckdb.connect()

# Persistent database (saved to disk)
con = duckdb.connect('poker.duckdb')
```

---

## Querying Parquet Files Directly

You don't need to load data into the database first — DuckDB can query Parquet files on disk directly.

```python
con = duckdb.connect()

# Query a single file
con.execute("SELECT * FROM 'data/hands.parquet' LIMIT 10").df()

# Query with a wildcard (all parquet files in a folder)
con.execute("SELECT * FROM 'data/*.parquet'").df()
```

`.df()` returns a Pandas DataFrame. Use `.fetchall()` for plain Python tuples.

---

## Querying Pandas DataFrames

DuckDB can query an in-memory DataFrame directly by name — no loading step needed.

```python
import pandas as pd

actions_df = pd.read_parquet('data/actions.parquet')

result = con.execute("""
    SELECT player, action, COUNT(*) AS count
    FROM actions_df
    GROUP BY player, action
    ORDER BY count DESC
""").df()
```

---

## Loading Parquet into a Persistent Table

If you want to store data inside a `.duckdb` file for repeated use:

```python
con = duckdb.connect('poker.duckdb')

con.execute("""
    CREATE TABLE IF NOT EXISTS actions AS
    SELECT * FROM 'data/actions.parquet'
""")

con.execute("""
    CREATE TABLE IF NOT EXISTS hands AS
    SELECT * FROM 'data/hands.parquet'
""")
```

After this, query like a normal database:

```python
con.execute("SELECT COUNT(*) FROM actions").fetchone()
```

---

## Useful Patterns for This Project

```python
# How often does each action occur by street?
con.execute("""
    SELECT street, action, COUNT(*) AS n
    FROM 'data/actions.parquet'
    GROUP BY street, action
    ORDER BY street, n DESC
""").df()

# Join hands and actions
con.execute("""
    SELECT h.id, h.stakes, a.street, a.action, a.amount
    FROM 'data/hands.parquet'   h
    JOIN 'data/actions.parquet' a ON a.hand_id = h.id
    WHERE a.action = 'raise'
    LIMIT 100
""").df()

# Quick summary stats
con.execute("""
    SELECT
        MIN(starting_stack) AS min_stack,
        MAX(starting_stack) AS max_stack,
        AVG(starting_stack) AS avg_stack
    FROM 'data/players.parquet'
""").df()
```

---

## Tips

- **No server needed** — `duckdb.connect()` is all you need to get started.
- **Parquet is the best input format** — DuckDB reads Parquet columns lazily, so `SELECT col1, col2` only reads those two columns from disk.
- **Use `.df()`** to get results back as a Pandas DataFrame for further processing or plotting.
- **Close your connection** when done with a persistent database: `con.close()`.
- DuckDB supports most standard SQL plus extras like `DESCRIBE`, `SUMMARIZE`, and window functions.

```python
# Quick schema inspection
con.execute("DESCRIBE SELECT * FROM 'data/actions.parquet'").df()

# Auto summary stats for every column
con.execute("SUMMARIZE SELECT * FROM 'data/actions.parquet'").df()
```
