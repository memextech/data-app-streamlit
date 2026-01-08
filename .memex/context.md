# Application Setup
- Update the following files to describe current application
- `pyproject.toml` - `name` and `description`
- `app.py` - `page_title` and `title`
- `README.md`

# How to run Data App
Use `start.sh`
Start script runs `uv sync` and `uv run`

# Data Sources

## CRITICAL: Read Before Implementation

1. **ALWAYS check this context.md file before implementing any feature**
2. **NEVER implement custom solutions for patterns documented here**
3. **ALWAYS use st.secrets for credentials, NEVER os.getenv()**

## Data Source Implementation - MANDATORY PATTERN

**CRITICAL**: ALL data source implementations MUST use Streamlit's st.connection pattern.
DO NOT implement custom connection code with gspread, psycopg2, etc.

### When implementing ANY data source:
1. Available connectors are listed in the system prompt under "Available Connectors" with their type and secret keys that match environment variables.
1. Check if a Streamlit connection exists for that source
2. Install the appropriate st-* connection package
3. Add connection config to `.streamlit/secrets.toml` using exact secret keys / env vars references from the connector
4. Use st.connection() - NEVER custom clients
5. `setup_secrets()` is already called in `app.py` at startup - no additional setup needed do not remove
6. Use the connector-specific code pattern below based on the connector type

## Secret/Credential Access

**ALWAYS use st.secrets - NEVER use os.getenv() or environment variables directly**

✅ Correct: `spreadsheet_url = st.secrets["connections"]["gsheets"]["spreadsheet"]`
❌ Wrong: `spreadsheet_url = os.getenv("SAMPLE_SPREADSHEET")`

Secrets are configured in `.streamlit/secrets.toml` and ALWAYS should reference env vars with `$VAR_NAME` syntax.
The secrets_utils.py expands these automatically at startup.
Only replace values starting with `$` with the connector's secret keys/env vars. Keep literal values like `"service_account"` or URLs unchanged.

## Caching Strategy

### @st.cache_resource - For connection objects (can't be pickled)
```python
@st.cache_resource
def get_connection():
    return st.connection("mydb", type=MyConnection)
```

### @st.cache_data - For data results (can be pickled)
```python
@st.cache_data
def load_tables(_conn):
    return _conn.query("SELECT table_name FROM information_schema.tables")

@st.cache_data(ttl=600)  # Cache for 10 minutes
def load_data(_conn, table_name):
    return _conn.query(f"SELECT * FROM {table_name}")
```

### Underscore prefix (_conn)
Tells Streamlit not to hash this parameter when caching. Use for connection objects passed to cached functions.

## File Uploads

When the user mentions a file using the `@filename` syntax (file-mention), the agent must:

1. Extract the file label and path from the mention
2. Add the file to `.streamlit/secrets.toml` under `[files]`:
   ```toml
   [files]
   "my file name.csv" = "/data/users/.../uploads/my file name.csv"
   ```
3. Access the file path in code using `st.secrets["files"]["my file name.csv"]`
4. Load the file using pandas or appropriate library:
   ```python
   import pandas as pd

   path = st.secrets["files"]["my file name.csv"]
   df = pd.read_csv(path)
   ```

### File mention format
File mentions appear in prompts as:
```html
<span data-file-mention="" class="file-mention" data-id="..." data-label="my file name.csv.csv" data-path="/data/users/.../uploads/my file name.csv.csv">my file name.csv.csv</span>
```

Extract:
- **data-label**: Use as the key in `[files]`
- **data-path**: Use as the value (the actual file path)

## Connector Types

### supabase
Install: `uv add st-supabase-connection`
secrets.toml:
```toml
[connections.supabase]
SUPABASE_URL = "$SUPABASE_URL"
SUPABASE_KEY = "$SUPABASE_KEY"
```
Usage:
```python
from st_supabase_connection import SupabaseConnection
import pandas as pd
conn = st.connection("supabase", type=SupabaseConnection)
result = conn.client.table("mytable").select("*").execute()
df = pd.DataFrame(result.data)
```

### neon
Install: `uv add psycopg2-binary sqlalchemy`
secrets.toml:
```toml
[connections.neon]
url = "$URL"
```
Usage:
```python
conn = st.connection("neon", type="sql")
df = conn.query("SELECT * FROM table_name")
```

### bigquery
Install: `uv add google-cloud-bigquery pandas-gbq`
secrets.toml:
```toml
[gcp_service_account]
type = "service_account"
project_id = "$PROJECT_ID"
private_key_id = "$PRIVATE_KEY_ID"
private_key = "$PRIVATE_KEY"
client_email = "$CLIENT_EMAIL"
client_id = "$CLIENT_ID"
auth_uri = "https://accounts.google.com/o/oauth2/auth"
token_uri = "https://oauth2.googleapis.com/token"
auth_provider_x509_cert_url = "https://www.googleapis.com/oauth2/v1/certs"
client_x509_cert_url = "$CLIENT_X509_CERT_URL"
```

**Note**: The `secrets_utils.py` automatically handles converting literal `\n` in the private_key to actual newlines.

Usage:
```python
from google.oauth2 import service_account
from google.cloud import bigquery
import pandas as pd

# Create API client
credentials = service_account.Credentials.from_service_account_info(
    st.secrets["gcp_service_account"]
)
client = bigquery.Client(credentials=credentials)

# Perform query
@st.cache_data(ttl=600)
def run_query(query):
    query_job = client.query(query)
    rows_raw = query_job.result()
    # Convert to list of dicts for caching
    rows = [dict(row) for row in rows_raw]
    return rows

# Use the query
rows = run_query("SELECT * FROM `dataset.table` LIMIT 1000")
df = pd.DataFrame(rows)
```

### google_sheet_public
Using st.connection:
Install: `uv add st-gsheets-connection`
secrets.toml:
```toml
[connections.gsheets]
spreadsheet = "$SPREADSHEET"
```
Usage:
```python
from streamlit_gsheets import GSheetsConnection
conn = st.connection("gsheets", type=GSheetsConnection)
df = conn.read()
```

### google_sheet_private
Install: `uv add st-gsheets-connection`
secrets.toml:
```toml
[connections.gsheets]
spreadsheet = "$SPREADSHEET"
type = "service_account"
project_id = "$PROJECT_ID"
private_key_id = "$PRIVATE_KEY_ID"
private_key = "$PRIVATE_KEY"
client_email = "$CLIENT_EMAIL"
client_id = "$CLIENT_ID"
auth_uri = "https://accounts.google.com/o/oauth2/auth"
token_uri = "https://oauth2.googleapis.com/token"
auth_provider_x509_cert_url = "https://www.googleapis.com/oauth2/v1/certs"
client_x509_cert_url = "$CLIENT_X509_CERT_URL"
```
Usage:
```python
from streamlit_gsheets import GSheetsConnection
conn = st.connection("gsheets", type=GSheetsConnection)
df = conn.read()
```

### aws_s3
Install: `uv add s3fs st-files-connection`
secrets.toml:
```toml
AWS_ACCESS_KEY_ID = "$AWS_ACCESS_KEY_ID"
AWS_SECRET_ACCESS_KEY = "$AWS_SECRET_ACCESS_KEY"
AWS_DEFAULT_REGION = "$AWS_DEFAULT_REGION"
```
Usage:
```python
from st_files_connection import FilesConnection
conn = st.connection('s3', type=FilesConnection)
df = conn.read("testbucket/myfile.csv", input_format="csv", ttl=600)
```

### mssql
Install: `uv add pyodbc`
secrets.toml:
```toml
[mssql]
server = "$SERVER"
database = "$DATABASE"
username = "$USERNAME"
password = "$PASSWORD"
```
Usage:
```python
import pyodbc

@st.cache_resource
def init_connection():
    return pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};SERVER="
        + st.secrets["mssql"]["server"]
        + ";DATABASE=" + st.secrets["mssql"]["database"]
        + ";UID=" + st.secrets["mssql"]["username"]
        + ";PWD=" + st.secrets["mssql"]["password"]
    )

conn = init_connection()

@st.cache_data(ttl=600)
def run_query(query):
    with conn.cursor() as cur:
        cur.execute(query)
        return cur.fetchall()

rows = run_query("SELECT * from mytable;")
```

### mongodb
Install: `uv add pymongo`
secrets.toml:
```toml
[mongo]
host = "$HOST"
port = "$PORT"
username = "$USERNAME"
password = "$PASSWORD"
```
Usage:
```python
import pymongo

@st.cache_resource
def init_connection():
    return pymongo.MongoClient(**st.secrets["mongo"])

client = init_connection()

@st.cache_data(ttl=600)
def get_data():
    db = client.mydb
    items = db.mycollection.find()
    items = list(items)
    return items

items = get_data()
```

### mysql
Install: `uv add mysqlclient sqlalchemy`
secrets.toml:
```toml
[connections.mysql]
dialect = "mysql"
host = "$HOST"
port = "$PORT"
database = "$DATABASE"
username = "$USERNAME"
password = "$PASSWORD"
```
Usage:
```python
conn = st.connection('mysql', type='sql')
df = conn.query('SELECT * from mytable;', ttl=600)
```

### postgresql
Install: `uv add psycopg2-binary sqlalchemy`
secrets.toml:
```toml
[connections.postgresql]
dialect = "postgresql"
host = "$HOST"
port = "$PORT"
database = "$DATABASE"
username = "$USERNAME"
password = "$PASSWORD"
```
Usage:
```python
conn = st.connection("postgresql", type="sql")
df = conn.query('SELECT * FROM mytable;', ttl="10m")
```

### snowflake
Install: `uv add snowflake-snowpark-python snowflake-connector-python`
secrets.toml:
```toml
[connections.snowflake]
account = "$ACCOUNT"
user = "$USER"
password = "$PASSWORD"  # or use private_key_file below
# private_key_file = "$PRIVATE_KEY_FILE"
role = "$ROLE"
warehouse = "$WAREHOUSE"
database = "$DATABASE"
schema = "$SCHEMA"
```
Usage:
```python
conn = st.connection("snowflake")
df = conn.query("SELECT * FROM mytable;", ttl="10m")
```

### tableau
Install: `uv add tableauserverclient`
secrets.toml:
```toml
[tableau]
token_name = "$TOKEN_NAME"
token_secret = "$TOKEN_SECRET"
server_url = "$SERVER_URL"
site_id = "$SITE_ID"
```
Usage:
```python
import tableauserverclient as TSC

tableau_auth = TSC.PersonalAccessTokenAuth(
    st.secrets["tableau"]["token_name"],
    st.secrets["tableau"]["token_secret"],
    st.secrets["tableau"]["site_id"],
)
server = TSC.Server(st.secrets["tableau"]["server_url"], use_server_version=True)

@st.cache_data(ttl=600)
def run_query():
    with server.auth.sign_in(tableau_auth):
        workbooks, pagination_item = server.workbooks.get()
        return [w.name for w in workbooks]

workbooks_names = run_query()
```

### tidb
Install: `uv add mysqlclient sqlalchemy`
secrets.toml:
```toml
[connections.tidb]
dialect = "mysql"
host = "$HOST"
port = "$PORT"
database = "$DATABASE"
username = "$USERNAME"
password = "$PASSWORD"
```
Usage:
```python
conn = st.connection('tidb', type='sql')
df = conn.query('SELECT * from mytable;', ttl=600)
```

### tigergraph
Install: `uv add pyTigerGraph`
secrets.toml:
```toml
[tigergraph]
host = "$HOST"
username = "$USERNAME"
password = "$PASSWORD"
graphname = "$GRAPHNAME"
```
Usage:
```python
import pyTigerGraph as tg

conn = tg.TigerGraphConnection(**st.secrets["tigergraph"])
conn.apiToken = conn.getToken(conn.createSecret())

@st.cache_data(ttl=600)
def get_data():
    result = conn.runInstalledQuery("queryName")[0]
    return result

data = get_data()
```

### openai
Install: `uv add openai`
secrets.toml:
```toml
[openai]
OPENAI_API_KEY = "$OPENAI_API_KEY"
```
Usage:
```python
from openai import OpenAI
client = OpenAI(api_key=st.secrets["openai"]["OPENAI_API_KEY"])
```

### anthropic
Install: `uv add anthropic`
secrets.toml:
```toml
[anthropic]
ANTHROPIC_API_KEY = "$ANTHROPIC_API_KEY"
```
Usage:
```python
from anthropic import Anthropic
client = Anthropic(api_key=st.secrets["anthropic"]["ANTHROPIC_API_KEY"])
```

### gemini
Install: `uv add google-generativeai`
secrets.toml:
```toml
[gemini]
GOOGLE_API_KEY = "$GOOGLE_API_KEY"
```
Usage:
```python
import google.generativeai as genai
genai.configure(api_key=st.secrets["gemini"]["GOOGLE_API_KEY"])
```

# Streamlit API Notes
- `use_container_width` is deprecated and will be removed in a future release. For `use_container_width=True`, use `width="stretch"`. For `use_container_width=False`, use `width="content"`.