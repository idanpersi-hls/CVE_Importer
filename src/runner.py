from typing import List, Dict
from src.utils.dates import allowable_date_range, cycles_to_wanted_date, now_utc_iso
from src.nvd_client import fetch_cves
from src.normalize import format_cve
from src.sql_db import upsert_cves, init_db, close_connection_pool
from src.config import RESULTS_PER_PAGE, START_DATE
import os, sys

def load_to_db(vuln_list: List[Dict]) -> None:
    normalized = {}
    for item in vuln_list:
        n = format_cve(item)
        if not n:
            continue
        cve_id = n.get("CVE_ID")
        if not cve_id:
            continue
        normalized[cve_id] = n
    if normalized:
        upsert_cves(normalized)

def load_by_dates(pubStartDate: str) -> str:
    start_index = 0
    pubEndDate = allowable_date_range(pubStartDate)
    cves_list = []

    while True:
        data = fetch_cves(
            start_index=start_index,
            results_per_page=RESULTS_PER_PAGE,
            pubStartDate=pubStartDate,
            pubEndDate=pubEndDate,
        )
        cves_list.extend(data.get("vulnerabilities", []))
        total = int(data.get("totalResults", 0))
        start_index += RESULTS_PER_PAGE
        if start_index >= total:
            break
    load_to_db(cves_list)
    return pubEndDate

def run(start_date: str | None = None) -> None:
    if not start_date:
        raise ValueError("START_DATE must be set in configuration")
    if os.getenv("SMOKE_TEST")=="true":
        print("smoke test succesfull")
        sys.exit(0)
    else:
        init_db()
    try:
        num_cycles = cycles_to_wanted_date(start_date, now_utc_iso())
        current_start = start_date
        for _ in range(num_cycles):
            current_start = load_by_dates(current_start)
    finally:
        close_connection_pool()