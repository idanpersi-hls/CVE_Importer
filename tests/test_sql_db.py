import os
import time
import pytest
import psycopg2
from datetime import datetime
from src.sql_db import init_db, upsert_cves, get_cve, get_all_cves
import src.sql_db as sql_db

# Test DB configuration
TEST_DB_URL = os.getenv(
    "TEST_DB_URL", "postgresql://test_cve_user:123456@localhost:5432/test_cve_db"
)

@pytest.fixture(autouse=True)
def setup_test_db(monkeypatch):
    """
    Fixture that runs before each test.
    Crucial: It forces a disconnect from the real DB and connects to the Test DB.
    """
    if sql_db.connection_pool:
        sql_db.close_connection_pool()
        sql_db.connection_pool = None
    
    # Patch the URL to point to the Test DB
    monkeypatch.setattr(sql_db, "DB_URL", TEST_DB_URL)
    

    init_db()

    yield


    conn = psycopg2.connect(TEST_DB_URL)
    cur = conn.cursor()
    try:
        cur.execute('TRUNCATE TABLE cves')
        conn.commit()
    except psycopg2.errors.UndefinedTable:
        conn.rollback()
    finally:
        cur.close()
        conn.close()

    if sql_db.connection_pool:
        sql_db.close_connection_pool()
        sql_db.connection_pool = None


class TestInitDb:
    """Tests for database initialization"""

    def test_init_db_creates_connection(self):
        conn = psycopg2.connect(TEST_DB_URL)
        conn.close()

    def test_init_db_creates_table(self):
        conn = psycopg2.connect(TEST_DB_URL)
        cur = conn.cursor()
        cur.execute(
            "SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename = 'cves';"
        )
        assert cur.fetchone() is not None
        cur.close()
        conn.close()

    def test_init_db_table_has_correct_columns(self):
        conn = psycopg2.connect(TEST_DB_URL)
        cur = conn.cursor()
        cur.execute(
            """
            SELECT column_name FROM information_schema.columns
            WHERE table_name = 'cves' AND table_schema = 'public';
            """
        )
        columns = {row[0] for row in cur.fetchall()}
        cur.close()
        conn.close()

        expected_columns = {"cve_id", "description", "cvss", "created_at", "updated_at"}
        assert expected_columns.issubset(columns)


class TestUpsertCves:
    """Tests for inserting/updating CVEs"""

    def test_upsert_single_cve(self):
        cves = {
            "CVE-2024-0001": {
                "CVE_ID": "CVE-2024-0001",
                "description": "Test vulnerability",
                "CVSS": 7.5,
            }
        }

        upsert_cves(cves)

        result = get_cve("CVE-2024-0001")
        assert result is not None
        assert result["cve_id"] == "CVE-2024-0001"
        assert result["description"] == "Test vulnerability"
        assert float(result["cvss"]) == 7.5

    def test_upsert_multiple_cves(self):
        cves = {
            "CVE-2024-0001": {
                "CVE_ID": "CVE-2024-0001",
                "description": "First vulnerability",
                "CVSS": 7.5,
            },
            "CVE-2024-0002": {
                "CVE_ID": "CVE-2024-0002",
                "description": "Second vulnerability",
                "CVSS": 9.0,
            },
        }

        upsert_cves(cves)

        result1 = get_cve("CVE-2024-0001")
        result2 = get_cve("CVE-2024-0002")

        assert result1 is not None
        assert result2 is not None

    def test_upsert_updates_existing_cve(self):
        cves = {
            "CVE-2024-0001": {
                "CVE_ID": "CVE-2024-0001",
                "description": "Original description",
                "CVSS": 5.0,
            }
        }
        upsert_cves(cves)

        updated_cves = {
            "CVE-2024-0001": {
                "CVE_ID": "CVE-2024-0001",
                "description": "Updated description",
                "CVSS": 8.0,
            }
        }
        upsert_cves(updated_cves)

        result = get_cve("CVE-2024-0001")
        assert result["description"] == "Updated description"
        assert float(result["cvss"]) == 8.0

    def test_upsert_with_none_cvss(self):
        cves = {
            "CVE-2024-0001": {
                "CVE_ID": "CVE-2024-0001",
                "description": "No score vulnerability",
                "CVSS": None,
            }
        }

        upsert_cves(cves)
        result = get_cve("CVE-2024-0001")
        assert result["cvss"] is None

    def test_upsert_sets_timestamps(self):
        cves = {
            "CVE-2024-0001": {
                "CVE_ID": "CVE-2024-0001",
                "description": "Test",
                "CVSS": 5.0,
            }
        }

        upsert_cves(cves)
        result = get_cve("CVE-2024-0001")

        assert result["created_at"] is not None
        assert result["updated_at"] is not None
        
        assert isinstance(result["created_at"], datetime)
        assert isinstance(result["updated_at"], datetime)


class TestGetCve:
    def test_get_existing_cve(self):
        cves = {
            "CVE-2024-0001": {
                "CVE_ID": "CVE-2024-0001",
                "description": "Test vulnerability",
                "CVSS": 7.5,
            }
        }
        upsert_cves(cves)
        result = get_cve("CVE-2024-0001")
        assert result is not None
        assert result["cve_id"] == "CVE-2024-0001"

    def test_get_nonexistent_cve_returns_none(self):
        result = get_cve("CVE-9999-9999")
        assert result is None


class TestGetAllCves:
    def test_get_all_cves_empty_database(self):
        result = get_all_cves()
        assert result == []

    def test_get_all_cves_returns_all(self):
        cves = {
            f"CVE-2024-000{i}": {
                "CVE_ID": f"CVE-2024-000{i}",
                "description": f"Test {i}",
                "CVSS": 5.0,
            }
            for i in range(5)
        }
        upsert_cves(cves)

        result = get_all_cves(limit=100)
        assert len(result) == 5

    def test_get_all_cves_respects_limit(self):
        cves = {
            f"CVE-2024-000{i}": {
                "CVE_ID": f"CVE-2024-000{i}",
                "description": f"Test {i}",
                "CVSS": 5.0,
            }
            for i in range(10)
        }
        upsert_cves(cves)

        result = get_all_cves(limit=5)
        assert len(result) == 5

    def test_get_all_cves_respects_offset(self):
        cves = {
            f"CVE-2024-{i:04d}": {
                "CVE_ID": f"CVE-2024-{i:04d}",
                "description": f"Test {i}",
                "CVSS": 5.0,
            }
            for i in range(10)
        }
        upsert_cves(cves)

        first_page = get_all_cves(limit=5, offset=0)
        second_page = get_all_cves(limit=5, offset=5)

        assert len(first_page) == 5
        assert len(second_page) == 5
        first_ids = {cve["cve_id"] for cve in first_page}
        second_ids = {cve["cve_id"] for cve in second_page}
        assert first_ids.isdisjoint(second_ids)

    def test_get_all_cves_ordered_by_updated_at(self):
        for i in range(3):
            cves = {
                f"CVE-2024-000{i}": {
                    "CVE_ID": f"CVE-2024-000{i}",
                    "description": f"Test {i}",
                    "CVSS": 5.0,
                }
            }
            upsert_cves(cves)
            time.sleep(0.01)

        result = get_all_cves()
        assert result[0]["cve_id"] == "CVE-2024-0002"
        assert result[1]["cve_id"] == "CVE-2024-0001"
        assert result[2]["cve_id"] == "CVE-2024-0000"