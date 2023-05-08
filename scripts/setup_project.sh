#!/bin/sh
set -ex
poetry install
poetry run pre-commit install --install-hooks
# TODO: Download bootstrap instead including it in the repo.
# curl --output assets/static/bootstrap.min.css --silent https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/css/bootstrap.min.css
# curl --output assets/static/bootstrap-icons.css --silent https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.3/font/bootstrap-icons.css
# curl --output assets/static/bootstrap.bundle.min.js --silent https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/js/bootstrap.bundle.min.js
