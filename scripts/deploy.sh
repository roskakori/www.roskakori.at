#!/bin/sh
set -ex
poetry run lektor build
poetry run lektor deploy
