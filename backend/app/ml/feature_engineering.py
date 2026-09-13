from __future__ import annotations

import logging
from typing import List, Dict, Optional
import numpy as np

logger = logging.getLogger(__name__)

FEATURE_NAMES = [
    "avg_overall",
    "avg_sleep",
    "avg_physical",
    "avg_focus",
    "score_trend",
    "checkin_consistency",
    "avg_weekly_duty_hours",
    "days_since_last_leave",
    "deployment_history_months",
    "hrv_baseline_deviation",
]

def extract_features(checkins: list[dict], hr_metrics: dict | None) -> np.ndarray:
    """
    Extract a 10-feature vector from check-ins and HR metrics.
    """
    if not checkins:
        avg_overall = 3.0
        avg_sleep = 3.0
        avg_physical = 3.0
        avg_focus = 3.0
        score_trend = 0.0
        checkin_consistency = 0.0
    else:
        checkins = checkins[-14:]
        
        avg_overall = float(np.mean([c.get("overall_score", 3.0) for c in checkins]))
        avg_sleep = float(np.mean([c.get("sleep_score", 3.0) for c in checkins]))
        avg_physical = float(np.mean([c.get("physical_score", 3.0) for c in checkins]))
        avg_focus = float(np.mean([c.get("focus_score", 3.0) for c in checkins]))
        
        checkin_consistency = len(checkins) / 14.0
        
        avg_scores = [np.mean([c.get("overall_score", 3.0), c.get("sleep_score", 3.0), c.get("physical_score", 3.0), c.get("focus_score", 3.0)]) for c in checkins]
        if len(avg_scores) > 1:
            x = np.arange(len(avg_scores))
            y = np.array(avg_scores)
            slope, _ = np.polyfit(x, y, 1)
            score_trend = float(slope)
        else:
            score_trend = 0.0

    if not hr_metrics:
        avg_weekly_duty_hours = 48.0
        days_since_last_leave = 0.0
        deployment_history_months = 0.0
        hrv_baseline_deviation = 5.0
    else:
        avg_weekly_duty_hours = float(hr_metrics.get("avg_weekly_duty_hours", 48.0))
        days_since_last_leave = float(hr_metrics.get("days_since_last_leave", 0.0))
        deployment_history_months = float(hr_metrics.get("deployment_history_months", 0.0))
        hrv_baseline_deviation = float(hr_metrics.get("hrv_baseline_deviation", 5.0))

    features = [
        avg_overall,
        avg_sleep,
        avg_physical,
        avg_focus,
        score_trend,
        checkin_consistency,
        avg_weekly_duty_hours,
        days_since_last_leave,
        deployment_history_months,
        hrv_baseline_deviation
    ]

    return np.array(features)
