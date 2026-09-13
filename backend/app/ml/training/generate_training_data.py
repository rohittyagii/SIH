from __future__ import annotations

import os
import random
import logging
import pandas as pd
import numpy as np

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

def generate_data(num_samples: int = 5000):
    np.random.seed(42)
    random.seed(42)
    
    data = []
    
    # Distribution: 60% Routine, 25% Monitor, 15% Intervention
    num_routine = int(num_samples * 0.6)
    num_monitor = int(num_samples * 0.25)
    num_intervention = num_samples - num_routine - num_monitor
    
    def generate_sample(risk_tier):
        if risk_tier == "Routine":
            avg_overall = np.random.uniform(3.5, 5.0)
            avg_sleep = np.random.uniform(3.5, 5.0)
            avg_physical = np.random.uniform(3.5, 5.0)
            avg_focus = np.random.uniform(3.5, 5.0)
            score_trend = np.random.uniform(-0.1, 0.5)
            checkin_consistency = np.random.uniform(0.7, 1.0)
            avg_weekly_duty_hours = np.random.uniform(30, 50)
            days_since_last_leave = np.random.uniform(0, 50)
            deployment_history_months = np.random.uniform(0, 12)
            hrv_baseline_deviation = np.random.uniform(0, 12)
            
        elif risk_tier == "Monitor":
            avg_overall = np.random.uniform(2.5, 3.5)
            avg_sleep = np.random.uniform(2.5, 3.5)
            avg_physical = np.random.uniform(2.5, 3.5)
            avg_focus = np.random.uniform(2.5, 3.5)
            score_trend = np.random.uniform(-0.3, 0.1)
            checkin_consistency = np.random.uniform(0.4, 0.8)
            avg_weekly_duty_hours = np.random.uniform(48, 58)
            days_since_last_leave = np.random.uniform(50, 100)
            deployment_history_months = np.random.uniform(6, 24)
            hrv_baseline_deviation = np.random.uniform(10, 20)
            
        else: # Intervention_Recommended
            avg_overall = np.random.uniform(1.0, 2.5)
            avg_sleep = np.random.uniform(1.0, 2.5)
            avg_physical = np.random.uniform(1.0, 2.5)
            avg_focus = np.random.uniform(1.0, 2.5)
            score_trend = np.random.uniform(-1.0, -0.2)
            checkin_consistency = np.random.uniform(0.1, 0.5)
            avg_weekly_duty_hours = np.random.uniform(55, 70)
            days_since_last_leave = np.random.uniform(100, 200)
            deployment_history_months = np.random.uniform(12, 36)
            hrv_baseline_deviation = np.random.uniform(20, 40)
            
        avg_overall = np.clip(avg_overall + np.random.normal(0, 0.3), 1, 5)
        avg_sleep = np.clip(avg_sleep + np.random.normal(0, 0.3), 1, 5)
        avg_physical = np.clip(avg_physical + np.random.normal(0, 0.3), 1, 5)
        avg_focus = np.clip(avg_focus + np.random.normal(0, 0.3), 1, 5)
        
        base_res = (avg_overall*10 + avg_sleep*6 - hrv_baseline_deviation*0.8 - days_since_last_leave*0.1 + score_trend*10 + 20)
        noise = np.random.uniform(-5, 5)
        resilience_score = int(np.clip(base_res + noise, 15, 98))
        
        return {
            "avg_overall": avg_overall,
            "avg_sleep": avg_sleep,
            "avg_physical": avg_physical,
            "avg_focus": avg_focus,
            "score_trend": score_trend,
            "checkin_consistency": checkin_consistency,
            "avg_weekly_duty_hours": avg_weekly_duty_hours,
            "days_since_last_leave": days_since_last_leave,
            "deployment_history_months": deployment_history_months,
            "hrv_baseline_deviation": hrv_baseline_deviation,
            "risk_level": risk_tier,
            "resilience_score": resilience_score
        }

    for _ in range(num_routine):
        data.append(generate_sample("Routine"))
    for _ in range(num_monitor):
        data.append(generate_sample("Monitor"))
    for _ in range(num_intervention):
        data.append(generate_sample("Intervention_Recommended"))
        
    df = pd.DataFrame(data)
    
    output_dir = os.path.dirname(__file__)
    output_path = os.path.join(output_dir, "training_data.csv")
    df.to_csv(output_path, index=False)
    logger.info("Generated %d samples and saved to %s", len(df), output_path)

if __name__ == "__main__":
    generate_data()
