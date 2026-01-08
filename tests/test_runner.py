from unittest.mock import patch
import src.runner as runner

def test_run_calls_init_and_close(monkeypatch):
    calls = {"init": 0, "close": 0, "load": 0}

    def fake_init():
        calls["init"] += 1

    def fake_close():
        calls["close"] += 1

    def fake_cycles(start, wanted):
        return 2

    def fake_load_by_dates(val):
        calls["load"] += 1
        return val

    monkeypatch.setattr(runner, "init_db", fake_init)
    monkeypatch.setattr(runner, "close_connection_pool", fake_close)
    monkeypatch.setattr(runner, "cycles_to_wanted_date", fake_cycles)
    monkeypatch.setattr(runner, "load_by_dates", fake_load_by_dates)

    runner.run("2025-01-01T00:00:00")
    assert calls["init"] == 1
    assert calls["close"] == 1
    assert calls["load"] == 2

def test_run_raises_on_missing_start():
    import pytest
    with pytest.raises(ValueError):
        runner.run(None)