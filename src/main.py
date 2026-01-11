from src.config import START_DATE
from src.runner import run
import os,sys

def main():
    if os.getenv("SMOKE_TEST")=="true":
        print("smoke test succesfull")
        sys.exit(0)
    else:
        run(START_DATE)

if __name__ == "__main__":
    main()