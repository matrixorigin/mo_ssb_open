#!/usr/bin/env bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

##############################################################
# This script is used to create ssb queries
##############################################################

set -eo pipefail

ROOT=$(dirname "$0")
ROOT=$(
    cd "${ROOT}"
    pwd
)

CURDIR=${ROOT}
QUERIES_DIR=${CURDIR}/../ssb-queries

usage() {
    echo "
This script is used to run SSB 13queries, 
will use mysql client to connect MatrixOne server which parameter is specified in matrixone.conf file.
Usage: $0 
  "
    exit 1
}

OPTS=$(getopt \
    -n "$0" \
    -o '' \
    -o 'h' \
    -- "$@")

eval set -- "${OPTS}"
HELP=0

if [[ $# == 0 ]]; then
    usage
fi

while true; do
    case "$1" in
    -h)
        HELP=1
        shift
        ;;
    --)
        shift
        break
        ;;
    *)
        echo "Internal error"
        exit 1
        ;;
    esac
done

if [[ "${HELP}" -eq 1 ]]; then
    usage
fi

check_prerequest() {
    local CMD=$1
    local NAME=$2
    if ! ${CMD}; then
        echo "${NAME} is missing. This script depends on mysql to create tables in MatrixOne."
        exit 1
    fi
}

check_prerequest "mysqlslap --version" "mysql slap"
check_prerequest "mysql --version" "mysql"
check_prerequest "bc --version" "bc"

source "${CURDIR}/../conf/matrixone.conf"
export MYSQL_PWD=${PASSWORD}

echo "HOST: ${HOST}"
echo "PORT: ${PORT}"
echo "USER: ${USER}"
echo "DB: ${DB}"

run_sql() {
    echo "$@"
    mysql -h"${HOST}" -P"${PORT}" -u"${USER}" -D"${DB}" -e "$@"
}

sum=0
for i in '1.1' '1.2' '1.3' '2.1' '2.2' '2.3' '3.1' '3.2' '3.3' '3.4' '4.1' '4.2' '4.3'; do
    # Each query is executed 3 times and takes the min time
    res1=$(mysql -vvv -h"${HOST}" -u"${USER}" -P"${PORT}" -D"${DB}" -e "$(cat "${QUERIES_DIR}"/q"${i}".sql)" | perl -nle 'print $1 if /\((\d+\.\d+)+ sec\)/' || :)
    res2=$(mysql -vvv -h"${HOST}" -u"${USER}" -P"${PORT}" -D"${DB}" -e "$(cat "${QUERIES_DIR}"/q"${i}".sql)" | perl -nle 'print $1 if /\((\d+\.\d+)+ sec\)/' || :)
    res3=$(mysql -vvv -h"${HOST}" -u"${USER}" -P"${PORT}" -D"${DB}" -e "$(cat "${QUERIES_DIR}"/q"${i}".sql)" | perl -nle 'print $1 if /\((\d+\.\d+)+ sec\)/' || :)

    min_value=$(echo "${res1} ${res2} ${res3}" | tr ' ' '\n' | sort -n | head -n 1)
    echo -e "q${i}:\t${res1}\t${res2}\t${res3}\tfast:${min_value}"

    cost=$(echo "${min_value}" | cut -d' ' -f1)
    sum=$(echo "${sum} + ${cost}" | bc)
done
echo "total time: ${sum} seconds"
echo 'Finish ssb queries.'
