#!/usr/bin/env bash

VENV_DIR=".venv"

if [ -f "uv.lock" ] && command -v uv &>/dev/null; then
  uv sync --all-extras
  source "$VENV_DIR/bin/activate"
elif [ -f "pyproject.toml" ]; then
  if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
  fi
  source "$VENV_DIR/bin/activate"
  if grep -q '\[tool.poetry\]' pyproject.toml && command -v poetry &>/dev/null; then
    poetry install
  else
    pip install -U pip build setuptools wheel
    pip install -e . || true  # fallback if PEP 621 style
  fi
elif [ -f "Pipfile" ]; then
  if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
  fi
  source "$VENV_DIR/bin/activate"
  pip install pipenv
  pipenv install --dev
elif [ -f "requirements.txt" ]; then
  if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
  fi
  source "$VENV_DIR/bin/activate"
  pip install -r requirements.txt
fi
