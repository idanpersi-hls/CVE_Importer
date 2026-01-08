from datetime import datetime
from src.utils import dates
from src.config import CYCLE_DAYS

def test_allowable_date_range_days():
    start = "2025-01-01T00:00:00+00:00"
    end = dates.allowable_date_range(start)
    s = datetime.fromisoformat(start)
    e = datetime.fromisoformat(end)
    assert (e - s).days == CYCLE_DAYS - 1

def test_now_utc_iso_parseable():
    s = dates.now_utc_iso()
    datetime.fromisoformat(s)

def test_cycles_to_wanted_date_basic():
    start = "2025-01-01T00:00:00+00:00"
    wanted = "2025-05-01T00:00:00+00:00"
    cycles = dates.cycles_to_wanted_date(start, wanted)
    assert isinstance(cycles, int) and cycles >= 1