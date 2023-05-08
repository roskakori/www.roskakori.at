#!/bin/sh
# Update requirements files and pre-commit hooks to current versions.
set -e
echo "🧱 Updating project"
poetry update
echo "🛠️ Updating pre-commit"
poetry run pre-commit autoupdate
echo "🎉 Successfully updated dependencies"
