#!/usr/bin/env bash

# Ensure the script exits on error
set -euo pipefail

# Find all shell scripts and run ShellCheck
#find . -type f -name "*.sh" -exec shellcheck -s bash -a -x -f diff {} \;
find . -type f -name "*.sh" -exec shellcheck -s bash -a -x {} \;
#find . -type f -name "*.sh" -exec shellcheck -s bash -a -e SC1090 -e SC1091 -e SC2034 -e SC2181 {} \;

echo "ShellCheck passed!"
