import json
import subprocess
from copy import deepcopy
from pathlib import Path
from typing import Dict


def generate_project(base_dir: Path, template_values: Dict[str, str]):
    repo_dir = base_dir / "sample"
    repo_dir.mkdir()
    template_values = deepcopy(template_values)
    config = base_dir / "data.yml"
    config.write_text(json.dumps(template_values))
    command = [
        f"{Path(__file__).parent.parent.parent / 'run.sh'}",
        "generate-project",
        str(repo_dir),
        str(config),
        f"{repo_dir / template_values['repo_name']}",
    ]
    print(" ".join(command))
    subprocess.run(command, check=True)

    generated_repo_dir = repo_dir / template_values["repo_name"]

    return generated_repo_dir
