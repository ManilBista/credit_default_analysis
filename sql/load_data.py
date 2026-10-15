# load_data.py - load the Excel file into the MySQL table made by schema.sql
# Run from the project folder:  python sql/load_data.py
# Needs: pip install sqlalchemy pymysql xlrd  (already in requirements.txt)

import pandas as pd
from sqlalchemy import create_engine

# 1. connection string -> change user, password, host if yours are different
DB_URL = "mysql+pymysql://root:password@localhost:3306/credit_default"
engine = create_engine(DB_URL)

# 2. read the Excel file (real column names are on the 2nd row -> header=1)
df = pd.read_excel("data/default of credit card clients.xls", header=1)

# 3. rename the target so it matches the table column
df = df.rename(columns={"default payment next month": "default_next_month"})

# 4. write the DataFrame into the table (table already exists, so append)
df.to_sql("customers", engine, if_exists="append", index=False, chunksize=5000)

# 5. confirm the row count
print("customers:", len(df))
