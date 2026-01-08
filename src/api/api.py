from fastapi import FastAPI, HTTPException
from typing import List, Optional
from contextlib import asynccontextmanager
import src.sql_db as sql_db
from pydantic import BaseModel
from datetime import datetime

class CVEResponse(BaseModel):
    cve_id: str
    description: Optional[str]
    cvss: Optional[float]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


@asynccontextmanager
async def lifespan(app: FastAPI):
    sql_db.init_connection_pool()
    print("API started - Database connection pool initialized")
    
    yield
    
    sql_db.close_connection_pool()
    print("API shutting down - Database connections closed")


app = FastAPI(
    title="CVE Importer API",
    description="API to query CVE data from PostgreSQL",
    version="1.0.0",
    lifespan=lifespan
)

@app.get("/")
async def root():
    return {
        "message": "CVE Importer API",
        "version": "1.0.0",
        "endpoints": {
            "/cves/latest": "Get the latest 5 CVEs",
            "/cves": "Get all CVEs (with pagination)",
            "/cves/{cve_id}": "Get a specific CVE by ID"
        }
    }

@app.get("/cves/latest", response_model=List[CVEResponse])
async def get_latest_cves():
    """
    Retrieve the 5 most recently updated CVEs from the database.
    """
    try:
        cves = sql_db.get_all_cves(limit=5, offset=0)
        if not cves:
            raise HTTPException(status_code=404, detail="No CVEs found in database")
        return cves
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@app.get("/cves/", response_model=List[CVEResponse])
async def get_cves(limit: int = 100, offset: int = 0):
    """
    Retrieve CVEs with pagination.
    
    - **limit**: Number of records to return (default: 100, max: 1000)
    - **offset**: Number of records to skip (default: 0)
    """
    if limit > 1000:
        raise HTTPException(status_code=400, detail="Limit cannot exceed 1000")
    if limit < 1:
        raise HTTPException(status_code=400, detail="Limit must be at least 1")
    if offset < 0:
        raise HTTPException(status_code=400, detail="Offset cannot be negative")
    

    cves = sql_db.get_all_cves(limit=limit, offset=offset)
    if not cves:
        raise HTTPException(status_code=404, detail="No CVEs found")
    return cves


@app.get("/cves/{cve_id}", response_model=CVEResponse)
async def get_cve_by_id(cve_id: str):
    """
    Retrieve a specific CVE by its ID.
    
    - **cve_id**: The CVE identifier (e.g., CVE-2024-1234)
    """
    try:
        cve = sql_db.get_cve(cve_id)
        if not cve:
            raise HTTPException(status_code=404, detail=f"CVE {cve_id} not found")
        return cve
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@app.get("/health")
async def health_check():
    """
    Check if the API and database connection are healthy.
    """
    try:
        sql_db.get_all_cves(limit=1)
        return {
            "status": "healthy",
            "database": "connected"
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "database": "disconnected",
            "error": str(e)
        }