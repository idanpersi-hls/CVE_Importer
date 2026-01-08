import time
import requests
from typing import Optional, Dict, Any
from src.config import (
    NVD_API_URL,
    RESULTS_PER_PAGE,
    REQUEST_TIMEOUT,
    RETRIES,
    BACKOFF_FACTOR,
    SLEEP_SECONDS,
)

def fetch_cves(
    start_index: int = 0,
    results_per_page: int = RESULTS_PER_PAGE,
    pubStartDate: Optional[str] = None,
    pubEndDate: Optional[str] = None,
) -> Dict[str, Any]:
    params = {
        "startIndex": start_index,
        "resultsPerPage": results_per_page,
        "pubStartDate": pubStartDate,
        "pubEndDate": pubEndDate,
    }

    for attempt in range(1, RETRIES + 1):
        try:
            resp = requests.get(
                NVD_API_URL,
                headers={"Accept": "application/json"},
                params=params,
                timeout=REQUEST_TIMEOUT,
            )
            if resp.status_code == 429 or 500 <= resp.status_code < 600:
                # rate limited or server error — backoff and retry
                backoff = BACKOFF_FACTOR * (2 ** (attempt - 1))
                time.sleep(backoff)
                continue
            resp.raise_for_status()
            time.sleep(SLEEP_SECONDS)
            return resp.json()
        except requests.RequestException:
            if attempt == RETRIES:
                raise
            backoff = BACKOFF_FACTOR * (2 ** (attempt - 1))
            time.sleep(backoff)

    raise RuntimeError("Failed to fetch CVEs after retries")