from datetime import datetime, timedelta, timezone
from unittest.mock import patch
import pytest

from src.utils import dates
from src import normalize
from src import runner


class TestAllowableDateRange:
    def test_allowable_date_range_adds_119_days(self):
        start_date = "2024-01-01T00:00:00+00:00"
        expected = (datetime.fromisoformat(start_date) + timedelta(days=119)).isoformat()
        result = dates.allowable_date_range(start_date)
        # parse both to datetimes to avoid formatting differences
        assert datetime.fromisoformat(result) == datetime.fromisoformat(expected)

    def test_allowable_date_range_handles_leap_year(self):
        start_date = "2024-02-01T00:00:00+00:00"
        result = dates.allowable_date_range(start_date)
        start = datetime.fromisoformat(start_date)
        end = datetime.fromisoformat(result)
        assert (end - start).days == 119


class TestGetEnglishDescription:
    def test_get_english_description_returns_english(self):
        descriptions = [
            {"lang": "es", "value": "es"},
            {"lang": "en", "value": "English description"},
        ]
        assert normalize.get_english_description(descriptions) == "English description"

    def test_get_english_description_returns_none_if_missing(self):
        descriptions = [{"lang": "es", "value": "es"}]
        assert normalize.get_english_description(descriptions) is None

    def test_get_english_description_empty_list(self):
        assert normalize.get_english_description([]) is None


class TestGetCvssScore:
    def test_get_cvss_score_v31(self):
        metrics = {"cvssMetricV31": [{"cvssData": {"baseScore": 7.5}}]}
        assert normalize.get_cvss_score(metrics) == 7.5

    def test_get_cvss_score_v30(self):
        metrics = {"cvssMetricV30": [{"cvssData": {"baseScore": 6.5}}]}
        assert normalize.get_cvss_score(metrics) == 6.5

    def test_get_cvss_score_v2(self):
        metrics = {"cvssMetricV2": [{"cvssData": {"baseScore": 5.0}}]}
        assert normalize.get_cvss_score(metrics) == 5.0

    def test_get_cvss_score_prefers_newer_version(self):
        metrics = {
            "cvssMetricV2": [{"cvssData": {"baseScore": 5.0}}],
            "cvssMetricV30": [{"cvssData": {"baseScore": 6.5}}],
            "cvssMetricV31": [{"cvssData": {"baseScore": 7.5}}],
        }
        assert normalize.get_cvss_score(metrics) == 7.5

    def test_get_cvss_score_no_metrics(self):
        assert normalize.get_cvss_score({}) is None


class TestFormatCve:
    def test_format_cve_complete_data(self):
        cve_data = {
            "cve": {
                "id": "CVE-2024-0001",
                "descriptions": [{"lang": "en", "value": "Test vulnerability"}],
                "metrics": {"cvssMetricV31": [{"cvssData": {"baseScore": 7.5}}]},
            }
        }
        result = normalize.format_cve(cve_data)
        assert result["CVE_ID"] == "CVE-2024-0001"
        assert result["description"] == "Test vulnerability"
        assert result["CVSS"] == 7.5

    def test_format_cve_missing_cvss(self):
        cve_data = {
            "cve": {
                "id": "CVE-2024-0001",
                "descriptions": [{"lang": "en", "value": "Test vulnerability"}],
                "metrics": {},
            }
        }
        result = normalize.format_cve(cve_data)
        assert result["CVE_ID"] == "CVE-2024-0001"
        assert result["CVSS"] is None


class TestLoadToDb:
    @patch("src.runner.upsert_cves")
    def test_load_to_db_normalizes_and_inserts(self, mock_upsert):
        cves_list = [
            {
                "cve": {
                    "id": "CVE-2024-0001",
                    "descriptions": [{"lang": "en", "value": "Test 1"}],
                    "metrics": {"cvssMetricV31": [{"cvssData": {"baseScore": 7.5}}]},
                }
            },
            {
                "cve": {
                    "id": "CVE-2024-0002",
                    "descriptions": [{"lang": "en", "value": "Test 2"}],
                    "metrics": {"cvssMetricV31": [{"cvssData": {"baseScore": 5.0}}]},
                }
            },
        ]

        runner.load_to_db(cves_list)
        mock_upsert.assert_called_once()
        call_args = mock_upsert.call_args[0][0]
        assert "CVE-2024-0001" in call_args
        assert "CVE-2024-0002" in call_args
        assert call_args["CVE-2024-0001"]["description"] == "Test 1"
        assert call_args["CVE-2024-0002"]["CVSS"] == 5.0


class TestLoadByDates:
    @patch("src.runner.fetch_cves")
    @patch("src.runner.load_to_db")
    def test_load_by_dates_single_page(self, mock_load_to_db, mock_fetch):
        mock_fetch.return_value = {"totalResults": 100, "vulnerabilities": [{"cve": {"id": f"CVE-{i}"}} for i in range(100)]}
        result = runner.load_by_dates("2024-01-01T00:00:00+00:00")
        assert mock_load_to_db.call_count == 1
        assert isinstance(result, str)

    @patch("src.runner.fetch_cves")
    @patch("src.runner.load_to_db")
    def test_load_by_dates_multiple_pages(self, mock_load_to_db, mock_fetch):
        mock_fetch.side_effect = [
            {"totalResults": 5000, "vulnerabilities": [{"cve": {"id": f"CVE-{i}"}} for i in range(2000)]},
            {"totalResults": 5000, "vulnerabilities": [{"cve": {"id": f"CVE-{i}"}} for i in range(2000, 4000)]},
            {"totalResults": 5000, "vulnerabilities": [{"cve": {"id": f"CVE-{i}"}} for i in range(4000, 5000)]},
        ]
        result = runner.load_by_dates("2024-01-01T00:00:00+00:00")
        assert mock_fetch.call_count == 3
        assert mock_load_to_db.call_count == 1