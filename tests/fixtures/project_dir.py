import tempfile
from pathlib import Path
from typing import Generator

import pytest

from tests.utils.project import generate_project


@pytest.fixture(scope="session")
def project_dir() -> Generator[Path, None, None]:
    with tempfile.TemporaryDirectory() as tmp_dir:
        template_values = {"repo_name": "test_repo"}
        generated_repo_dir = generate_project(Path(tmp_dir), template_values)

        yield generated_repo_dir

        print("Destroying project")
