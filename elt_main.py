import luigi
import os
from pipeline.extract import Extract
from pipeline.load import Load
from pipeline.transform import Transform
from dotenv import load_dotenv

load_dotenv()

if __name__ == "__main__":
    os.makedirs(os.getenv("DIR_TEMP_DATA", "./temp/data"), exist_ok=True)

    luigi.build(
        [Extract(), Load(), Transform()],
        local_scheduler=True
    )
