from src import normalize

def test_get_english_description_basic():
    descriptions = [
        {"lang": "es", "value": "es"},
        {"lang": "en", "value": "en-value"}
    ]
    assert normalize.get_english_description(descriptions) == "en-value"

def test_get_cvss_score_prefers_v31_and_casts():
    metrics = {
        "cvssMetricV31": [{"cvssData": {"baseScore": "7.5"}}],
        "cvssMetricV30": [{"cvssData": {"baseScore": "6.5"}}]
    }
    assert normalize.get_cvss_score(metrics) == 7.5

def test_format_cve_complete():
    item = {
        "cve": {
            "id": "CVE-TEST-1",
            "descriptions": [{"lang": "en", "value": "desc"}],
            "metrics": {"cvssMetricV31": [{"cvssData": {"baseScore": 5.0}}]}
        }
    }
    out = normalize.format_cve(item)
    assert out["CVE_ID"] == "CVE-TEST-1"
    assert out["description"] == "desc"
    assert out["CVSS"] == 5.0