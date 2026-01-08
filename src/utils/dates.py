from datetime import datetime, timedelta, timezone
from typing import Union
from src.config import CYCLE_DAYS

def allowable_date_range(start_date: str) -> str:
    start = datetime.fromisoformat(start_date)
    end = start + timedelta(days=CYCLE_DAYS - 1)
    return end.isoformat()

def now_utc_iso() -> str:
    return datetime.now(timezone.utc).isoformat()

def cycles_to_wanted_date(start_date: str, wanted_date: Union[str, datetime]) -> int:
    start = datetime.fromisoformat(start_date)
    if isinstance(wanted_date, str):
        wanted = datetime.fromisoformat(wanted_date)
    else:
        wanted = wanted_date
    delta = wanted - start
    cycles = (delta.days // CYCLE_DAYS) + 1
    return max(0, cycles)