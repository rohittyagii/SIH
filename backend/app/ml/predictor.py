from __future__ import annotations

import logging
import os
import threading
from typing import Dict, Any, Optional, List
import numpy as np
import joblib

from app.ml.feature_engineering import extract_features

logger = logging.getLogger(__name__)

class WelfarePredictor:
    """
    Predictor class for wellness risk and resilience.
    """
    def __init__(self, models_dir: str):
        self.models_dir = models_dir
        self.risk_classifier = None
        self.resilience_regressor = None
        self.feature_scaler = None
        self._is_loaded = False
        self._lock = threading.Lock()

    def load_models(self) -> bool:
        """
        Load the trained models and scaler from the models directory.
        """
        with self._lock:
            if self._is_loaded:
                return True

            try:
                risk_path = os.path.join(self.models_dir, "risk_classifier.joblib")
                resilience_path = os.path.join(self.models_dir, "resilience_regressor.joblib")
                scaler_path = os.path.join(self.models_dir, "feature_scaler.joblib")

                if not (os.path.exists(risk_path) and os.path.exists(resilience_path) and os.path.exists(scaler_path)):
                    logger.warning("One or more model files are missing in %s", self.models_dir)
                    return False

                self.risk_classifier = joblib.load(risk_path)
                self.resilience_regressor = joblib.load(resilience_path)
                self.feature_scaler = joblib.load(scaler_path)
                
                self._is_loaded = True
                logger.info("Successfully loaded ML models from %s", self.models_dir)
                return True
            except Exception as e:
                logger.warning("Failed to load models: %s", str(e))
                return False

    @property
    def is_loaded(self) -> bool:
        return self._is_loaded

    def predict_risk(self, features: np.ndarray) -> str | None:
        if not self.is_loaded:
            return None
        features_scaled = self.feature_scaler.transform(features.reshape(1, -1))
        return self.risk_classifier.predict(features_scaled)[0]

    def predict_resilience(self, features: np.ndarray) -> int | None:
        if not self.is_loaded:
            return None
        features_scaled = self.feature_scaler.transform(features.reshape(1, -1))
        pred = self.resilience_regressor.predict(features_scaled)[0]
        return int(max(0, min(100, pred)))

    def predict_risk_probabilities(self, features: np.ndarray) -> dict | None:
        if not self.is_loaded:
            return None
        features_scaled = self.feature_scaler.transform(features.reshape(1, -1))
        probs = self.risk_classifier.predict_proba(features_scaled)[0]
        classes = self.risk_classifier.classes_
        return {str(cls): float(prob) for cls, prob in zip(classes, probs)}

    def predict(self, checkins: list[dict], hr_metrics: dict | None) -> dict | None:
        """
        High-level prediction function.
        """
        if not self.is_loaded:
            if not self.load_models():
                return None
                
        features = extract_features(checkins, hr_metrics)
        
        risk_level = self.predict_risk(features)
        resilience_score = self.predict_resilience(features)
        probabilities = self.predict_risk_probabilities(features)
        
        confidence = probabilities.get(risk_level, 0.0) if probabilities else 0.0

        from app.ml.feature_engineering import FEATURE_NAMES
        features_dict = {name: float(val) for name, val in zip(FEATURE_NAMES, features)}

        return {
            "risk_level": risk_level,
            "resilience_score": resilience_score,
            "confidence": confidence,
            "features_dict": features_dict
        }

# Singleton instance
default_models_dir = os.path.join(os.path.dirname(__file__), "models")
predictor = WelfarePredictor(default_models_dir)
