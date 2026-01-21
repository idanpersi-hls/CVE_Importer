import os
from urllib.parse import quote_plus
from dotenv import load_dotenv

load_dotenv()

DB_USER = os.getenv("DB_USER", "cve_user")
DB_PASSWORD = quote_plus(os.getenv("DB_PASSWORD", "123456"))
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "cve_db")
NVD_API_URL = os.getenv("NVD_API_URL", "https://services.nvd.nist.gov/rest/json/cves/2.0")
START_DATE = os.getenv("START_DATE", "2025-10-01T00:00:00+00:00")
DB_URL = os.getenv("DB_URL")
DB_SSL_MODE = os.getenv("DB_SSL_MODE", "prefer")

CYCLE_DAYS = int(os.getenv("CYCLE_DAYS", "120"))
RESULTS_PER_PAGE = int(os.getenv("RESULTS_PER_PAGE", "2000"))
REQUEST_TIMEOUT = int(os.getenv("REQUEST_TIMEOUT", "30"))
RETRIES = int(os.getenv("REQUEST_RETRIES", "3"))
BACKOFF_FACTOR = float(os.getenv("BACKOFF_FACTOR", "1.0"))
SLEEP_SECONDS = float(os.getenv("SLEEP_SECONDS", "1.0"))