#!/bin/bash

set -ex

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# install core and development Python dependencies into the currently activated venv
function install {
    python -m pip install --upgrade pip
    python -m pip install -e $THIS_DIR/[dev]
}

# lint the project
function lint {
    pre-commit run --all-files
}

function run_tests {
    python -m pytest -n auto tests/
}

function generate-project {
    copier copy $THIS_DIR/template "$1" --data-file "$2"
    cd "$3"
    git init
    git branch -M main
    git add --all
    git commit -m "Initial commit"
}

# remove all files generated by tests, builds, or operating this codebase
function clean {
    rm -rf dist build coverage.xml test-reports ~/Desktop/COPIER/*
    find . \
      -type d \
      \( \
        -name "*cache*" \
        -o -name "*.dist-info" \
        -o -name "*.egg-info" \
        -o -name "*htmlcov" \
      \) \
      -not -path "*env/*" \
      -exec rm -r {} + || true

    find . \
      -type f \
      -name "*.pyc" \
      -not -path "*env/*" \
      -exec rm {} +
}

# export the contents of .env as environment variables
function try-load-dotenv {
    if [ ! -f "$THIS_DIR/.env" ]; then
        echo "no .env file found"
        return 1
    fi

    while read -r line; do
        export "$line"
    done < <(grep -v '^#' "$THIS_DIR/.env" | grep -v '^$')
}

function create-repo-if-not-exists {
  local IS_PUBLIC_REPO=${IS_PUBLIC_REPO:-false}
  echo "Checking if $GITHUB_USERNAME/$REPO_NAME exists..."
  gh repo view "$GITHUB_USERNAME/$REPO_NAME" > /dev/null \
      && echo "Repo exists already, exiting..." \
      && return 0

  if [[ "$IS_PUBLIC_REPO" == "true" ]]; then
    PUBLIC_OR_PRIVATE="public"
  else
    PUBLIC_OR_PRIVATE="private"
  fi

  echo "Creating $GITHUB_USERNAME/$REPO_NAME as a $PUBLIC_OR_PRIVATE repo..."
  gh repo create "$GITHUB_USERNAME/$REPO_NAME" "--$PUBLIC_OR_PRIVATE"

  echo "# $REPO_NAME" > "$REPO_NAME/README.md"
  cd "$REPO_NAME"
  git branch -M main || true
  git add --all
  git commit -m "Feat: created repository"
  git push origin main
}

function configure-repo {
  return 0
}

function open-pr-with-generate-template {
  cd "$THIS_DIR"
  rm -rf "./$REPO_NAME" || true
  gh repo clone "$GITHUB_USERNAME/$REPO_NAME" "./$REPO_NAME"

  mv "$REPO_NAME/.git" "./$REPO_NAME.git.bak"
  rm -rf "$REPO_NAME"
  mkdir "$REPO_NAME"
  mv "./$REPO_NAME.git.bak" "$REPO_NAME/.git"

  OUTDIR="./outdir"
  CONFIG_FILE_PATH="./$REPO_NAME.yml"
  cat <<EOF > "$CONFIG_FILE_PATH"
repo_name: $REPO_NAME
package_import_name: $PACKAGE_IMPORT_NAME
EOF
  copier copy ./template "$OUTDIR" --data-file "$CONFIG_FILE_PATH"

  mv "$REPO_NAME/.git" "$OUTDIR/$REPO_NAME"
  cd "$OUTDIR/$REPO_NAME"
  git checkout -b "feat/populating-from-template"
  git add --all

  lint || true

  git add --all
  git commit -m "feat: populate from template"
  git push origin "feat/populating-from-template"
}

# print all functions in this file
function help {
    echo "$0 <task> <args>"
    echo "Tasks:"
    compgen -A function | cat -n
}

TIMEFORMAT="Task completed in %3lR"
time ${@:-help}
