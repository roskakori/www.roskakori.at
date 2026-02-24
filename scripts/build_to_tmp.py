import logging
import shutil
import subprocess
from pathlib import Path

TEMP_FOLDER = Path("/tmp/roskakori.at/")  # TODO: Clean up ugly hardcoded folder.
_log = logging.getLogger("build")

if __name__ == "__main__":
    shutil.rmtree(TEMP_FOLDER)
    subprocess.run([
        "uv",
        "run",
        "lektor",
        "build",
        "--output-path",
        str(TEMP_FOLDER.resolve()),
    ])
    _log.info("✅ The built files are located in %s.", str(TEMP_FOLDER))
