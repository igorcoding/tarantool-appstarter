#! /usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT=${SCRIPT_DIR}/..

if [ -z "$LISTEN" ]; then
	LISTEN="127.0.0.1:3301"
fi

TNT_DIR=${ROOT}/.tnt_${LISTEN}
mkdir -p ${TNT_DIR}
pushd ${TNT_DIR} > /dev/null
	DEV=1 CONF=${ROOT}/conf.lua tarantool ${ROOT}/init.lua
popd > /dev/null
