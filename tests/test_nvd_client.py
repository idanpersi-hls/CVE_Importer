import requests
from types import SimpleNamespace
from src import nvd_client
from src import config

class DummyResp:
    def __init__(self, status=200, payload=None):
        self.status_code = status
        self._payload = payload or {}
    def json(self):
        return self._payload
    def raise_for_status(self):
        if self.status_code >= 400:
            raise requests.HTTPError(f"HTTP {self.status_code}")

def test_fetch_cves_calls_requests(monkeypatch):
    captured = {}
    def fake_get(url, headers, params, timeout):
        captured["url"] = url
        captured["params"] = params
        captured["timeout"] = timeout
        return DummyResp(200, {"totalResults": 0, "vulnerabilities": []})

    monkeypatch.setattr(nvd_client.requests, "get", fake_get)
    res = nvd_client.fetch_cves(
        start_index=0,
        results_per_page=100,
        pubStartDate="2025-01-01T00:00:00",
        pubEndDate="2025-05-01T00:00:00",
    )
    assert captured["params"]["startIndex"] == 0
    assert captured["timeout"] == config.REQUEST_TIMEOUT
    assert res["totalResults"] == 0

def test_fetch_cves_retries_on_server_error(monkeypatch):
    calls = {"n": 0}
    def fake_get(url, headers, params, timeout):
        calls["n"] += 1
        if calls["n"] == 1:
            return DummyResp(500, {})
        return DummyResp(200, {"totalResults": 0, "vulnerabilities": []})

    monkeypatch.setattr(nvd_client.requests, "get", fake_get)
    res = nvd_client.fetch_cves()
    assert calls["n"] >= 2
    assert res["totalResults"] == 0