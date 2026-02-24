#!/bin/sh
set -ex
uv run lektor build
uv run lektor deploy
