#!/usr/bin/env bash
set -uo pipefail

systemctl stop nessusd.service
systemctl disable nessusd.service
