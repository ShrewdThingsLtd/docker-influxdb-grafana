#!/bin/bash
set -e

. ${SRC_DIR}/docker-entrypoint.sh

mkdir -p ${SRC_DIR}/runtime/env
mkdir -p ${SRC_DIR}/runtime/utils

for env_file in $(ls -tr ${SRC_DIR}/runtime/env/)
do
	. ${SRC_DIR}/runtime/env/${env_file}
done

for utils_file in $(ls -tr ${SRC_DIR}/runtime/utils/)
do
	. ${SRC_DIR}/runtime/utils/${utils_file}
done

exec "$@"
