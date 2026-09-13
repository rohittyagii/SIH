from __future__ import annotations

import numpy as np
import pytest

from app.ml.feature_engineering import FEATURE_NAMES, extract_features
from app.ml.narrative import generate_narrative
from app.ml.predictor import predictor


class TestFeatureEngineering:
    def test_extract_features_normal(self) -> None:
        checkins = [
            {"overall_score": 4, "sleep_score": 3, "physical_score": 4, "focus_score": 4},
            {"overall_score": 3, "sleep_score": 4, "physical_score": 3, "focus_score": 3},
            {"overall_score": 4, "sleep_score": 3, "physical_score": 4, "focus_score": 4},
            {"overall_score": 5, "sleep_score": 4, "physical_score": 5, "focus_score": 4},
            {"overall_score": 4, "sleep_score": 4, "physical_score": 4, "focus_score": 5},
        ]
        hr_metrics = {
            "avg_weekly_duty_hours": 50.0,
            "days_since_last_leave": 30.0,
            "deployment_history_months": 12.0,
            "hrv_baseline_deviation": 8.0,
        }

        features = extract_features(checkins, hr_metrics)

        assert isinstance(features, np.ndarray)
        assert features.shape == (10,)
        assert len(features) == len(FEATURE_NAMES)
        assert np.issubdtype(features.dtype, np.floating)
        assert features[0] == pytest.approx(4.0)  # avg_overall
        assert features[1] == pytest.approx(3.6)  # avg_sleep
        assert features[2] == pytest.approx(4.0)  # avg_physical
        assert features[3] == pytest.approx(4.0)  # avg_focus
        assert features[5] == pytest.approx(5 / 14.0)  # checkin_consistency
        assert features[6] == pytest.approx(50.0)  # avg_weekly_duty_hours
        assert features[7] == pytest.approx(30.0)  # days_since_last_leave
        assert features[8] == pytest.approx(12.0)  # deployment_history_months
        assert features[9] == pytest.approx(8.0)  # hrv_baseline_deviation

    def test_extract_features_empty_checkins(self) -> None:
        features = extract_features([], hr_metrics={"avg_weekly_duty_hours": 40.0, "days_since_last_leave": 10.0, "deployment_history_months": 2.0, "hrv_baseline_deviation": 4.0})

        assert isinstance(features, np.ndarray)
        assert features.shape == (10,)
        # Empty checkins -> defaults (3.0 scores, 0 trend, 0 consistency)
        assert features[0] == 3.0  # avg_overall
        assert features[1] == 3.0  # avg_sleep
        assert features[2] == 3.0  # avg_physical
        assert features[3] == 3.0  # avg_focus
        assert features[4] == 0.0  # score_trend
        assert features[5] == 0.0  # checkin_consistency

    def test_extract_features_no_hr(self) -> None:
        checkins = [
            {"overall_score": 4, "sleep_score": 4, "physical_score": 4, "focus_score": 4}
        ]

        features = extract_features(checkins, hr_metrics=None)

        assert isinstance(features, np.ndarray)
        assert features.shape == (10,)
        # None hr_metrics -> defaults (48, 0, 0, 5.0)
        assert features[6] == 48.0  # avg_weekly_duty_hours
        assert features[7] == 0.0  # days_since_last_leave
        assert features[8] == 0.0  # deployment_history_months
        assert features[9] == 5.0  # hrv_baseline_deviation

    def test_extract_features_single_checkin(self) -> None:
        checkins = [
            {"overall_score": 4, "sleep_score": 3, "physical_score": 5, "focus_score": 4}
        ]

        features = extract_features(checkins, hr_metrics=None)

        assert isinstance(features, np.ndarray)
        assert features.shape == (10,)
        # 1 checkin -> trend=0, consistency=1/14
        assert features[4] == 0.0
        assert features[5] == pytest.approx(1.0 / 14.0)

    def test_extract_features_shape(self) -> None:
        empty_features = extract_features([], None)
        assert empty_features.shape == (10,)

        single_features = extract_features([{"overall_score": 3}], None)
        assert single_features.shape == (10,)

        multi_features = extract_features(
            [{"overall_score": 4, "sleep_score": 3, "physical_score": 2, "focus_score": 5}] * 20,
            {"avg_weekly_duty_hours": 55.0, "days_since_last_leave": 60.0, "deployment_history_months": 10.0, "hrv_baseline_deviation": 12.0}
        )
        assert multi_features.shape == (10,)


class TestPredictor:
    def test_load_models(self) -> None:
        loaded = predictor.load_models()
        assert loaded is True
        assert predictor.is_loaded is True

    def test_predict_risk_valid_output(self) -> None:
        predictor.load_models()
        features = extract_features([], None)
        risk = predictor.predict_risk(features)
        assert risk in ["Routine", "Monitor", "Intervention_Recommended"]

    def test_predict_resilience_range(self) -> None:
        predictor.load_models()
        features = extract_features([], None)
        resilience = predictor.predict_resilience(features)
        assert isinstance(resilience, int)
        assert 0 <= resilience <= 100

    def test_predict_probabilities_sum(self) -> None:
        predictor.load_models()
        features = extract_features([], None)
        probabilities = predictor.predict_risk_probabilities(features)
        assert isinstance(probabilities, dict)
        assert set(probabilities.keys()) == {"Routine", "Monitor", "Intervention_Recommended"}
        assert sum(probabilities.values()) == pytest.approx(1.0, abs=1e-3)
        for prob in probabilities.values():
            assert 0.0 <= prob <= 1.0

    def test_predict_high_level(self) -> None:
        predictor.load_models()
        checkins = [
            {"overall_score": 3, "sleep_score": 3, "physical_score": 3, "focus_score": 3}
        ]
        hr_metrics = {
            "avg_weekly_duty_hours": 45.0,
            "days_since_last_leave": 20.0,
            "deployment_history_months": 4.0,
            "hrv_baseline_deviation": 5.0,
        }

        result = predictor.predict(checkins, hr_metrics)

        assert isinstance(result, dict)
        assert "risk_level" in result
        assert "resilience_score" in result
        assert "confidence" in result
        assert "features_dict" in result
        assert result["risk_level"] in ["Routine", "Monitor", "Intervention_Recommended"]
        assert isinstance(result["resilience_score"], int)
        assert 0 <= result["resilience_score"] <= 100
        assert isinstance(result["confidence"], float)
        assert 0.0 <= result["confidence"] <= 1.0
        assert isinstance(result["features_dict"], dict)
        assert len(result["features_dict"]) == 10
        assert set(result["features_dict"].keys()) == set(FEATURE_NAMES)

    def test_predict_intervention_case(self) -> None:
        predictor.load_models()
        bad_checkins = [
            {"overall_score": 1, "sleep_score": 1, "physical_score": 2, "focus_score": 1}
        ] * 5
        bad_hr = {
            "avg_weekly_duty_hours": 65.0,
            "days_since_last_leave": 150.0,
            "deployment_history_months": 24.0,
            "hrv_baseline_deviation": 30.0,
        }

        result = predictor.predict(bad_checkins, bad_hr)

        assert result is not None
        assert result["risk_level"] == "Intervention_Recommended"

    def test_predict_routine_case(self) -> None:
        predictor.load_models()
        good_checkins = [
            {"overall_score": 5, "sleep_score": 5, "physical_score": 4, "focus_score": 5}
        ] * 5
        good_hr = {
            "avg_weekly_duty_hours": 40.0,
            "days_since_last_leave": 10.0,
            "deployment_history_months": 2.0,
            "hrv_baseline_deviation": 3.0,
        }

        result = predictor.predict(good_checkins, good_hr)

        assert result is not None
        assert result["risk_level"] == "Routine"


class TestNarrative:
    def test_narrative_intervention(self) -> None:
        features = {
            "avg_sleep": 1.5,
            "days_since_last_leave": 150.0,
            "hrv_baseline_deviation": 30.0,
        }
        confidence = {"Intervention_Recommended": 0.95}

        result = generate_narrative("Intervention_Recommended", features, confidence)

        assert isinstance(result, dict)
        assert "contributing_factors" in result
        assert "recommended_intervention" in result
        assert "ai_narrative" in result
        assert len(result["contributing_factors"].strip()) > 0
        assert result["contributing_factors"] != "• All monitored wellness and operational indicators within normal limits."
        assert "Immediate leave authorization" in result["recommended_intervention"]
        assert "Intervention Recommended" in result["ai_narrative"]

    def test_narrative_routine(self) -> None:
        features = {
            "avg_overall": 4.5,
            "avg_sleep": 4.5,
            "avg_physical": 4.5,
            "avg_focus": 4.5,
            "score_trend": 0.1,
            "checkin_consistency": 1.0,
            "avg_weekly_duty_hours": 40.0,
            "days_since_last_leave": 10.0,
            "deployment_history_months": 2.0,
            "hrv_baseline_deviation": 3.0,
        }
        confidence = {"Routine": 0.98}

        result = generate_narrative("Routine", features, confidence)

        assert isinstance(result, dict)
        assert "contributing_factors" in result
        assert "recommended_intervention" in result
        assert "ai_narrative" in result
        assert len(result["contributing_factors"].strip()) > 0
        assert len(result["recommended_intervention"].strip()) > 0
        assert len(result["ai_narrative"].strip()) > 0
        assert "Routine" in result["ai_narrative"]

    def test_narrative_no_confidence(self) -> None:
        features = {"avg_sleep": 4.0}

        result = generate_narrative("Routine", features, confidence=None)

        assert isinstance(result, dict)
        assert "contributing_factors" in result
        assert "recommended_intervention" in result
        assert "ai_narrative" in result
        assert len(result["contributing_factors"].strip()) > 0
        assert len(result["recommended_intervention"].strip()) > 0
        assert len(result["ai_narrative"].strip()) > 0
        assert "confidence" not in result["ai_narrative"]


class TestIntegration:
    def test_full_pipeline(self) -> None:
        predictor.load_models()
        raw_checkins = [
            {"overall_score": 2, "sleep_score": 2, "physical_score": 2, "focus_score": 2},
            {"overall_score": 1, "sleep_score": 2, "physical_score": 2, "focus_score": 1},
        ]
        raw_hr_metrics = {
            "avg_weekly_duty_hours": 60.0,
            "days_since_last_leave": 100.0,
            "deployment_history_months": 18.0,
            "hrv_baseline_deviation": 20.0,
        }

        # Step 1: Feature Extraction
        features = extract_features(raw_checkins, raw_hr_metrics)
        assert isinstance(features, np.ndarray)
        assert features.shape == (10,)

        # Step 2: Prediction
        prediction = predictor.predict(raw_checkins, raw_hr_metrics)
        assert prediction is not None
        assert prediction["risk_level"] in ["Routine", "Monitor", "Intervention_Recommended"]
        assert isinstance(prediction["resilience_score"], int)
        assert 0 <= prediction["resilience_score"] <= 100
        assert isinstance(prediction["confidence"], float)
        assert 0.0 <= prediction["confidence"] <= 1.0

        probabilities = predictor.predict_risk_probabilities(features)
        assert probabilities is not None
        assert sum(probabilities.values()) == pytest.approx(1.0, abs=1e-3)

        # Step 3: Narrative Generation
        narrative = generate_narrative(
            risk_level=prediction["risk_level"],
            features=prediction["features_dict"],
            confidence=probabilities,
        )

        # Step 4: Verify all outputs are valid
        assert isinstance(narrative, dict)
        assert "contributing_factors" in narrative
        assert "recommended_intervention" in narrative
        assert "ai_narrative" in narrative
        assert len(narrative["contributing_factors"].strip()) > 0
        assert len(narrative["recommended_intervention"].strip()) > 0
        assert len(narrative["ai_narrative"].strip()) > 0
