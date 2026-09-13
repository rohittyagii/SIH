from __future__ import annotations

import os
import shutil
import logging
from datetime import datetime
import pandas as pd
import joblib

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

def retrain_models():
    """
    Dummy retrain script that mocks DB connections.
    Connects to database, extracts features, and retrains if enough data.
    """
    logger.info("Connecting to database...")
    
    script_dir = os.path.dirname(__file__)
    data_path = os.path.join(script_dir, "training_data.csv")
    
    if not os.path.exists(data_path):
        logger.error(f"No existing data to retrain on at {data_path}")
        return
        
    df = pd.read_csv(data_path)
    
    if len(df) < 100:
        logger.warning(f"Not enough labeled samples to retrain. Found {len(df)}, need 100.")
        return
        
    logger.info(f"Found {len(df)} samples. Retraining models...")
    
    models_dir = os.path.abspath(os.path.join(script_dir, "..", "models"))
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_dir = os.path.join(models_dir, f"backup_{timestamp}")
    
    if os.path.exists(models_dir) and any(f.endswith(".joblib") for f in os.listdir(models_dir)):
        os.makedirs(backup_dir, exist_ok=True)
        for f in os.listdir(models_dir):
            if f.endswith(".joblib") or f.endswith(".json"):
                shutil.copy(os.path.join(models_dir, f), os.path.join(backup_dir, f))
        logger.info(f"Backed up old models to {backup_dir}")
        
    from app.ml.training.train_models import train_and_evaluate
    train_and_evaluate()
    
    logger.info("Retraining complete.")

if __name__ == "__main__":
    retrain_models()
