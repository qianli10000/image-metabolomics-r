#!/usr/bin/env bash

set -eou pipefail
set -x

docker build "$@" --tag countdigi/metabolomics-r . 2>&1 | tee build.log
