from __future__ import annotations

"""ML-driven narrative generator for defense personnel welfare assessments."""

__doc__ = """ML-driven narrative generator for defense personnel welfare assessments.

This module evaluates physiological, operational, and psychological features
against established clinical thresholds to produce structured, concise, and
medically sound welfare assessment reports without military jargon.
"""

from typing import Any

# Default baseline values used when features are missing or unspecified
DEFAULT_FEATURES: dict[str, float] = {
    "avg_overall": 3.5,
    "avg_sleep": 3.5,
    "avg_physical": 3.5,
    "avg_focus": 3.5,
    "score_trend": 0.0,
    "checkin_consistency": 1.0,
    "avg_weekly_duty_hours": 42.0,
    "days_since_last_leave": 20.0,
    "deployment_history_months": 6.0,
    "hrv_baseline_deviation": 5.0,
}


class _FactorEvaluation:
    """Internal container for an evaluated feature factor."""

    __slots__ = ("severity", "excess", "bullet", "prose")

    def __init__(self, severity: int, excess: float, bullet: str, prose: str) -> None:
        self.severity = severity  # 2: critical, 1: concerning, 0: normal
        self.excess = excess      # normalized excess over threshold for ranking
        self.bullet = bullet      # concise bullet point text
        self.prose = prose        # inline phrasing for AI narrative summary


def _get_feature_val(features: dict[str, float], key: str, aliases: tuple[str, ...] = ()) -> float:
    """Safely extracts a numeric feature value with alias and default fallbacks."""
    for k in (key, *aliases):
        if k in features and features[k] is not None:
            try:
                return float(features[k])
            except (ValueError, TypeError):
                pass
    return DEFAULT_FEATURES.get(key, 0.0)


def _fmt_number(val: float) -> str:
    """Formats a float concisely as an integer if whole or 1 decimal place."""
    if abs(val - round(val)) < 0.05:
        return str(int(round(val)))
    return f"{val:.1f}"


def _evaluate_features(features: dict[str, float]) -> list[_FactorEvaluation]:
    """
    Evaluates all 10 features against clinical thresholds.

    Thresholds:
      - avg scores: < 3.0 = concerning, < 2.0 = critical
      - score_trend: < -0.2 = concerning
      - checkin_consistency: < 0.5 = concerning
      - duty_hours: > 55 = concerning, > 62 = critical
      - days_since_last_leave: > 80 = concerning, > 120 = critical
      - deployment_months: > 15 = concerning, > 24 = critical
      - hrv_deviation: > 15 = concerning, > 25 = critical
    """
    concerning: list[_FactorEvaluation] = []

    # 1. avg_sleep
    val = _get_feature_val(features, "avg_sleep")
    if val < 2.0:
        concerning.append(_FactorEvaluation(
            severity=2,
            excess=(2.0 - val) / 1.0,
            bullet=f"Critical sleep deficit (avg {val:.1f}/5)",
            prose=f"critical sleep deficit (avg {val:.1f}/5)",
        ))
    elif val < 3.0:
        concerning.append(_FactorEvaluation(
            severity=1,
            excess=(3.0 - val) / 2.0,
            bullet=f"Sleep quality declining (avg {val:.1f}/5)",
            prose=f"declining sleep quality (avg {val:.1f}/5)",
        ))

    # 2. hrv_baseline_deviation
    val = _get_feature_val(features, "hrv_baseline_deviation", ("hrv_deviation", "hrv"))
    hrv_str = _fmt_number(val)
    if val > 25.0:
        concerning.append(_FactorEvaluation(
            severity=2,
            excess=(val - 25.0) / 15.0,
            bullet=f"Marked HRV elevation (+{hrv_str}%)",
            prose=f"marked HRV elevation (+{hrv_str}%)",
        ))
    elif val > 15.0:
        concerning.append(_FactorEvaluation(
            severity=1,
            excess=(val - 15.0) / 25.0,
            bullet=f"HRV elevated at +{hrv_str}%",
            prose=f"HRV elevated at +{hrv_str}%",
        ))

    # 3. days_since_last_leave
    val = _get_feature_val(features, "days_since_last_leave", ("leave_days",))
    leave_days = int(round(val))
    if val > 120.0:
        concerning.append(_FactorEvaluation(
            severity=2,
            excess=(val - 120.0) / 80.0,
            bullet=f"Critical leave deficit ({leave_days} days since last leave)",
            prose=f"critical leave deficit ({leave_days} days without leave)",
        ))
    elif val > 80.0:
        concerning.append(_FactorEvaluation(
            severity=1,
            excess=(val - 80.0) / 120.0,
            bullet=f"{leave_days} days since last leave",
            prose=f"{leave_days} days since last leave",
        ))

    # 4. avg_weekly_duty_hours
    val = _get_feature_val(features, "avg_weekly_duty_hours", ("duty_hours", "weekly_duty_hours"))
    duty_str = _fmt_number(val)
    if val > 62.0:
        concerning.append(_FactorEvaluation(
            severity=2,
            excess=(val - 62.0) / 8.0,
            bullet=f"Severe duty overload ({duty_str} hrs/week)",
            prose=f"severe duty overload ({duty_str} hrs/week)",
        ))
    elif val > 55.0:
        concerning.append(_FactorEvaluation(
            severity=1,
            excess=(val - 55.0) / 15.0,
            bullet=f"Elevated duty load ({duty_str} hrs/week)",
            prose=f"elevated duty load ({duty_str} hrs/week)",
        ))

    # 5. deployment_history_months
    val = _get_feature_val(features, "deployment_history_months", ("deployment_months",))
    deploy_str = _fmt_number(val)
    if val > 24.0:
        concerning.append(_FactorEvaluation(
            severity=2,
            excess=(val - 24.0) / 12.0,
            bullet=f"Prolonged deployment exposure ({deploy_str} months)",
            prose=f"prolonged deployment exposure ({deploy_str} months)",
        ))
    elif val > 15.0:
        concerning.append(_FactorEvaluation(
            severity=1,
            excess=(val - 15.0) / 21.0,
            bullet=f"Extended deployment ({deploy_str} months)",
            prose=f"extended deployment ({deploy_str} months)",
        ))

    # 6. avg_overall
    val = _get_feature_val(features, "avg_overall")
    if val < 2.0:
        concerning.append(_FactorEvaluation(
            severity=2,
            excess=(2.0 - val) / 1.0,
            bullet=f"Critical overall wellness drop (avg {val:.1f}/5)",
            prose=f"critical drop in overall wellness (avg {val:.1f}/5)",
        ))
    elif val < 3.0:
        concerning.append(_FactorEvaluation(
            severity=1,
            excess=(3.0 - val) / 2.0,
            bullet=f"Low overall wellness score (avg {val:.1f}/5)",
            prose=f"low overall wellness score (avg {val:.1f}/5)",
        ))

    # 7. avg_physical
    val = _get_feature_val(features, "avg_physical")
    if val < 2.0:
        concerning.append(_FactorEvaluation(
            severity=2,
            excess=(2.0 - val) / 1.0,
            bullet=f"Severe physical fatigue (avg {val:.1f}/5)",
            prose=f"severe physical fatigue (avg {val:.1f}/5)",
        ))
    elif val < 3.0:
        concerning.append(_FactorEvaluation(
            severity=1,
            excess=(3.0 - val) / 2.0,
            bullet=f"Physical readiness declining (avg {val:.1f}/5)",
            prose=f"declining physical readiness (avg {val:.1f}/5)",
        ))

    # 8. avg_focus
    val = _get_feature_val(features, "avg_focus")
    if val < 2.0:
        concerning.append(_FactorEvaluation(
            severity=2,
            excess=(2.0 - val) / 1.0,
            bullet=f"Severe cognitive fatigue (avg {val:.1f}/5)",
            prose=f"severe cognitive fatigue (avg {val:.1f}/5)",
        ))
    elif val < 3.0:
        concerning.append(_FactorEvaluation(
            severity=1,
            excess=(3.0 - val) / 2.0,
            bullet=f"Mental focus declining (avg {val:.1f}/5)",
            prose=f"declining mental focus (avg {val:.1f}/5)",
        ))

    # 9. score_trend
    val = _get_feature_val(features, "score_trend")
    if val < -0.2:
        concerning.append(_FactorEvaluation(
            severity=1,
            excess=(-0.2 - val) / 0.8,
            bullet=f"Declining wellness trend ({val:+.2f} trajectory)",
            prose=f"declining wellness trajectory ({val:+.2f})",
        ))

    # 10. checkin_consistency
    val = _get_feature_val(features, "checkin_consistency")
    if val < 0.5:
        concerning.append(_FactorEvaluation(
            severity=1,
            excess=(0.5 - val) / 0.5,
            bullet=f"Low check-in compliance ({val * 100:.0f}% consistency)",
            prose=f"low check-in compliance ({val * 100:.0f}%)",
        ))

    # Rank by severity (critical first), then by normalized excess magnitude
    concerning.sort(key=lambda item: (item.severity, item.excess), reverse=True)
    return concerning


def _extract_confidence(risk_level: str, confidence: dict[str, float] | None) -> float | None:
    """Extracts probability for the classified risk tier from confidence dictionary."""
    if not confidence or not isinstance(confidence, dict):
        return None

    # Direct match
    if risk_level in confidence:
        val = confidence[risk_level]
        if isinstance(val, (int, float)):
            return float(val)

    # Normalized comparison
    target_norm = risk_level.lower().replace("_", "").replace("-", "").replace(" ", "")
    for k, v in confidence.items():
        if not isinstance(v, (int, float)):
            continue
        k_norm = k.lower().replace("_", "").replace("-", "").replace(" ", "")
        if k_norm == target_norm:
            return float(v)

    # Keyword match fallback (intervention / monitor / routine)
    for k, v in confidence.items():
        if not isinstance(v, (int, float)):
            continue
        k_lower = k.lower()
        if ("interv" in target_norm and "interv" in k_lower) or \
           ("mon" in target_norm and "mon" in k_lower) or \
           ("rout" in target_norm and "rout" in k_lower):
            return float(v)

    return None


def generate_narrative(
    risk_level: str,
    features: dict[str, float],
    confidence: dict[str, float] | None = None,
) -> dict[str, str]:
    """
    Generates a concise, clinical narrative assessment for defense personnel welfare.

    Args:
        risk_level: Risk tier classification ('Routine', 'Monitor', 'Intervention_Recommended').
        features: Dictionary containing feature values for up to 10 clinical metrics.
        confidence: Optional class probabilities mapping risk tiers to confidence scores.

    Returns:
        dict[str, str]: Dictionary with keys:
            - 'contributing_factors': Top concerning factors formatted as bullet points.
            - 'recommended_intervention': Concrete, risk-appropriate clinical action steps.
            - 'ai_narrative': 2-3 sentence assessment summary.
    """
    normalized_risk = risk_level.strip().lower()
    is_intervention = "interv" in normalized_risk
    is_monitor = "mon" in normalized_risk
    is_routine = "rout" in normalized_risk or (not is_intervention and not is_monitor)

    # 1. Identify and rank concerning factors
    evaluated_factors = _evaluate_features(features or {})
    top_factors = evaluated_factors[:3]

    # 2. Format contributing factors (top 3 bullets)
    if top_factors:
        contributing_factors = "\n".join(f"• {f.bullet}" for f in top_factors)
    else:
        contributing_factors = "• All monitored wellness and operational indicators within normal limits."

    # 3. Determine recommended intervention
    if is_intervention:
        recommended_intervention = (
            "Immediate leave authorization, welfare officer consultation within 48 hours, and duty reduction."
        )
    elif is_monitor:
        recommended_intervention = (
            "Scheduled welfare check-in within 7 days and ongoing monitoring."
        )
    else:
        recommended_intervention = "Continue standard monitoring."

    # 4. Generate AI Narrative (2-3 concise sentences)
    # Sentence 1: Risk tier classification and confidence level
    if is_intervention:
        display_risk = "Intervention Recommended"
    elif is_monitor:
        display_risk = "Monitor"
    elif is_routine:
        display_risk = "Routine"
    else:
        display_risk = risk_level.replace("_", " ").title()

    conf_val = _extract_confidence(risk_level, confidence)
    if conf_val is not None:
        pct = round(conf_val * 100) if conf_val <= 1.0 else round(conf_val)
        s1 = f"Personnel assessed at {display_risk} risk level ({pct}% confidence)."
    else:
        s1 = f"Personnel assessed at {display_risk} risk level."

    # Sentence 2: Key risk drivers or normal baseline summary
    if top_factors:
        prose_items = [f.prose for f in top_factors]
        if len(prose_items) == 1:
            s2 = f"The primary risk driver is {prose_items[0]}."
        elif len(prose_items) == 2:
            s2 = f"Key risk drivers include {prose_items[0]} and {prose_items[1]}."
        else:
            s2 = f"Key risk drivers include {prose_items[0]}, {prose_items[1]}, and {prose_items[2]}."
    else:
        if is_routine:
            s2 = "All physiological, operational, and self-reported wellness indicators remain within normal parameters."
        elif is_monitor:
            s2 = "Current metrics remain near baseline, but monitoring is advised to detect early stress accumulation."
        else:
            s2 = "No single metric exceeded critical thresholds, but clinical review is indicated based on overall assessment."

    # Sentence 3: Recommended action summary
    if is_intervention:
        s3 = "Immediate leave authorization, welfare officer consultation, and duty reduction are recommended."
    elif is_monitor:
        s3 = "A scheduled check-in within 7 days and close monitoring are advised."
    else:
        s3 = "Continue standard monitoring with routine check-ins."

    ai_narrative = f"{s1} {s2} {s3}"

    return {
        "contributing_factors": contributing_factors,
        "recommended_intervention": recommended_intervention,
        "ai_narrative": ai_narrative,
    }
