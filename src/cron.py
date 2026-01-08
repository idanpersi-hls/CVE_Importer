import logging
import os
from datetime import datetime, timezone, timedelta
from src.runner import run

log_dir = "logs"
os.makedirs(log_dir, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(os.path.join(log_dir, "cron.log")),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

def one_hour_ago_iso() -> str:
    one_hour_ago = datetime.now(timezone.utc) - timedelta(hours=1)
    return one_hour_ago.isoformat()

def run_cron_job() -> None:
    try:
        start_time = one_hour_ago_iso()
        logger.info(f"Starting cron job at {start_time}")
        run(start_time)
        logger.info("Cron job completed successfully")
    except Exception as e:
        logger.error(f"Cron job failed: {e}", exc_info=True)
        raise

if __name__ == "__main__":
    run_cron_job()