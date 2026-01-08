from unittest.mock import patch, MagicMock
from src.cron import run_cron_job
import pytest

def test_run_cron_job_calls_run_with_current_time(monkeypatch):
    """Test that cron job calls runner.run with current UTC time"""
    fake_time = "2025-01-06T14:30:00"
    
    def fake_hour_ago():
        return fake_time
    
    def fake_run(start):
        pass

    monkeypatch.setattr("src.cron.one_hour_ago_iso", fake_hour_ago)
    monkeypatch.setattr("src.cron.run", fake_run)
    
    run_cron_job()  # Should not raise

def test_run_cron_job_logs_errors(monkeypatch, caplog):
    """Test that cron job logs errors properly"""
    def fake_run(start):
        raise RuntimeError("API error")
    
    monkeypatch.setattr("src.cron.run", fake_run)
    
    with pytest.raises(RuntimeError):
        run_cron_job()
    
    assert "Cron job failed" in caplog.text