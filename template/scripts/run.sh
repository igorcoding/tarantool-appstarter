#! /usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT=${SCRIPT_DIR}/..

. ${SCRIPT_DIR}/tnt-env.sh
mkdir -p ${ROOT}/tnt
pushd ${ROOT}/tnt > /dev/null
	LUA_PATH=${LUA_PATH} LUA_CPATH=${LUA_CPATH} DEV=1 CONF=${ROOT}/conf.lua tarantool ${ROOT}/init.lua
popd > /dev/null
