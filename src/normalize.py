from typing import Any, Dict, List, Optional

def get_english_description(descriptions: List[Dict[str, Any]]) -> Optional[str]:
    if not descriptions:
        return None
    for d in descriptions:
        if d.get("lang") == "en":
            return d.get("value")
    return None

def get_cvss_score(cvss_metrics: Dict[str, Any]) -> Optional[float]:
    if not cvss_metrics or not isinstance(cvss_metrics, dict):
        return None
    for key in ("cvssMetricV31", "cvssMetricV30", "cvssMetricV2"):
        metrics = cvss_metrics.get(key)
        if metrics and isinstance(metrics, list) and len(metrics) > 0:
            data = metrics[0].get("cvssData") or {}
            score = data.get("baseScore")
            try:
                return float(score) if score is not None else None
            except (TypeError, ValueError):
                return None
    return None

def format_cve(vuln_item: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    if not isinstance(vuln_item, dict):
        return None
    cve = vuln_item.get("cve") or {}
    cve_id = cve.get("id")
    if not cve_id:
        return None

    descriptions = cve.get("descriptions") or []
    metrics = cve.get("metrics") or {}

    normalized = {
        "CVE_ID": cve_id,
        "description": get_english_description(descriptions),
        "CVSS": get_cvss_score(metrics),
    }
    return normalized