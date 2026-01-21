import psycopg2
from psycopg2 import pool
from psycopg2.extras import RealDictCursor
from datetime import datetime, timezone
from typing import List, Dict, Optional
from contextlib import contextmanager
from src.config import DB_URL, DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD, DB_SSL_MODE


# Connection pool (reuses connections for better performance)
connection_pool = None


def init_connection_pool():
    global connection_pool
    
    if connection_pool is None:
        try:
            if DB_URL:
                connection_pool = psycopg2.pool.SimpleConnectionPool(
                    minconn=2,
                    maxconn=10,
                    dsn=DB_URL,
                    sslmode=DB_SSL_MODE

                )
                print(f"Connected to PostgreSQL via {DB_URL}")
            else:   
                connection_pool = psycopg2.pool.SimpleConnectionPool(
                minconn=2,
                maxconn=10,
                host=DB_HOST,
                port=DB_PORT,
                database=DB_NAME,
                user=DB_USER,
                password=DB_PASSWORD,
                sslmode=DB_SSL_MODE
            )
                print(f"Connected to PostgreSQL at {DB_HOST}:{DB_PORT}/{DB_NAME}")
        except psycopg2.Error as e:
            print(f"Failed to connect to PostgreSQL: {e}")
            raise


@contextmanager
def get_db_connection():
    if connection_pool is None:
        init_connection_pool()
    
    conn = connection_pool.getconn()
    try:
        yield conn
    finally:
        connection_pool.putconn(conn)


def _now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def init_db() -> None:
    init_connection_pool()
    
    with get_db_connection() as conn:
        with conn.cursor() as cursor:
            # Create table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS cves (
                    cve_id TEXT PRIMARY KEY,
                    description TEXT,
                    cvss NUMERIC(3,1),
                    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
                    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
                )
            """)
            
            # Create indexes
            cursor.execute("""
                CREATE INDEX IF NOT EXISTS idx_cvss ON cves(cvss)
            """)
            cursor.execute("""
                CREATE INDEX IF NOT EXISTS idx_updated_at ON cves(updated_at)
            """)
            
            conn.commit()
    
    print(f"Database initialized: {DB_NAME}")


def upsert_cves(cves: Dict[str, dict]) -> None:
    if not cves:
        print("  No CVEs to insert")
        return
    
    with get_db_connection() as conn:
        with conn.cursor() as cursor:
            now = _now_utc()
            inserted_count = 0
            updated_count = 0
            
            for cve_id, cve_data in cves.items():
                # Check if exists
                cursor.execute(
                    "SELECT cve_id FROM cves WHERE cve_id = %s",
                    (cve_id,)
                )
                exists = cursor.fetchone() is not None
                
                # Upsert
                cursor.execute("""
                    INSERT INTO cves (cve_id, description, cvss, created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s)
                    ON CONFLICT(cve_id) DO UPDATE SET
                        description = EXCLUDED.description,
                        cvss = EXCLUDED.cvss,
                        updated_at = EXCLUDED.updated_at
                """, (
                    cve_data["CVE_ID"],
                    cve_data["description"],
                    cve_data["CVSS"],
                    now,
                    now
                ))
                
                if exists:
                    updated_count += 1
                else:
                    inserted_count += 1
            
            conn.commit()
    
    print(f"{inserted_count} inserted, {updated_count} updated")


def get_cve(cve_id: str) -> Optional[dict]:
    with get_db_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(
                "SELECT * FROM cves WHERE cve_id = %s",
                (cve_id,)
            )
            row = cursor.fetchone()
            return dict(row) if row else None


def get_all_cves(limit: int = 100, offset: int = 0) -> List[dict]:
    with get_db_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(
                "SELECT * FROM cves ORDER BY updated_at DESC LIMIT %s OFFSET %s",
                (limit, offset)
            )
            rows = cursor.fetchall()
            return [dict(row) for row in rows]


def close_connection_pool():
    global connection_pool
    if connection_pool:
        connection_pool.closeall()
        print("Database connections closed")