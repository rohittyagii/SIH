from __future__ import annotations

import os
import json
import logging
from datetime import datetime
import pandas as pd
import numpy as np
import joblib

from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import GradientBoostingClassifier, GradientBoostingRegressor
from sklearn.model_selection import cross_validate, StratifiedKFold, KFold
from sklearn.metrics import make_scorer, accuracy_score, precision_score, recall_score, f1_score, mean_absolute_error, root_mean_squared_error, r2_score, confusion_matrix

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

def train_and_evaluate():
    script_dir = os.path.dirname(__file__)
    data_path = os.path.join(script_dir, "training_data.csv")
    models_dir = os.path.abspath(os.path.join(script_dir, "..", "models"))
    
    if not os.path.exists(data_path):
        logger.error(f"Training data not found at {data_path}")
        return
        
    df = pd.DataFrame(pd.read_csv(data_path))
    
    feature_names = [
        "avg_overall", "avg_sleep", "avg_physical", "avg_focus",
        "score_trend", "checkin_consistency", "avg_weekly_duty_hours",
        "days_since_last_leave", "deployment_history_months", "hrv_baseline_deviation"
    ]
    
    X = df[feature_names].values
    y_risk = df["risk_level"].values
    y_res = df["resilience_score"].values
    
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)
    
    clf = GradientBoostingClassifier(n_estimators=200, max_depth=4, learning_rate=0.1, random_state=42)
    
    skf = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
    scoring_clf = {
        'accuracy': make_scorer(accuracy_score),
        'precision_macro': make_scorer(precision_score, average='macro', zero_division=0),
        'recall_macro': make_scorer(recall_score, average='macro', zero_division=0),
        'f1_macro': make_scorer(f1_score, average='macro', zero_division=0)
    }
    cv_clf = cross_validate(clf, X_scaled, y_risk, cv=skf, scoring=scoring_clf)
    
    clf.fit(X_scaled, y_risk)
    y_risk_pred = clf.predict(X_scaled)
    conf_matrix = confusion_matrix(y_risk, y_risk_pred, labels=clf.classes_)
    
    logger.info("--- Classification Metrics (5-fold CV) ---")
    logger.info(f"Accuracy: {np.mean(cv_clf['test_accuracy']):.4f}")
    logger.info(f"Precision (macro): {np.mean(cv_clf['test_precision_macro']):.4f}")
    logger.info(f"Recall (macro): {np.mean(cv_clf['test_recall_macro']):.4f}")
    logger.info(f"F1 (macro): {np.mean(cv_clf['test_f1_macro']):.4f}")
    logger.info(f"Confusion Matrix (Full Dataset):\n{conf_matrix}")
    logger.info(f"Classes: {clf.classes_}")
    
    reg = GradientBoostingRegressor(n_estimators=200, max_depth=4, learning_rate=0.1, random_state=42)
    
    kf = KFold(n_splits=5, shuffle=True, random_state=42)
    scoring_reg = {
        'mae': make_scorer(mean_absolute_error),
        'rmse': make_scorer(root_mean_squared_error),
        'r2': make_scorer(r2_score)
    }
    cv_reg = cross_validate(reg, X_scaled, y_res, cv=kf, scoring=scoring_reg)
    
    reg.fit(X_scaled, y_res)
    
    logger.info("--- Regression Metrics (5-fold CV) ---")
    logger.info(f"MAE: {np.mean(cv_reg['test_mae']):.4f}")
    logger.info(f"RMSE: {np.mean(cv_reg['test_rmse']):.4f}")
    logger.info(f"R²: {np.mean(cv_reg['test_r2']):.4f}")
    
    os.makedirs(models_dir, exist_ok=True)
    joblib.dump(clf, os.path.join(models_dir, "risk_classifier.joblib"))
    joblib.dump(reg, os.path.join(models_dir, "resilience_regressor.joblib"))
    joblib.dump(scaler, os.path.join(models_dir, "feature_scaler.joblib"))
    
    metadata = {
        "timestamp": datetime.now().isoformat(),
        "feature_names": feature_names,
        "classes": list(clf.classes_),
        "metrics": {
            "classification": {
                "accuracy": float(np.mean(cv_clf['test_accuracy'])),
                "f1_macro": float(np.mean(cv_clf['test_f1_macro']))
            },
            "regression": {
                "mae": float(np.mean(cv_reg['test_mae'])),
                "r2": float(np.mean(cv_reg['test_r2']))
            }
        }
    }
    
    with open(os.path.join(models_dir, "model_metadata.json"), "w") as f:
        json.dump(metadata, f, indent=2)
        
    logger.info(f"Models and metadata saved to {models_dir}")

if __name__ == "__main__":
    train_and_evaluate()
