#! /usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT=${SCRIPT_DIR}/..

TARANTOOL=tarantool

if [ -z "${LISTEN}" ]; then
	LISTEN="127.0.0.1:3301"
fi

if [ -z "${CONF}" ]; then
	CONF=${ROOT}/conf.lua
fi

TNT_DIR=${ROOT}/.tnt_${LISTEN}
mkdir -p ${TNT_DIR}
pushd ${TNT_DIR} > /dev/null
	DEV=1 CONF=${CONF} LISTEN=${LISTEN} ${TARANTOOL} ${ROOT}/init.lua
popd > /dev/null
