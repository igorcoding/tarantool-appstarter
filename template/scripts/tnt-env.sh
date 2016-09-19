#! /usr/bin/env bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT=${SCRIPT_DIR}/..

LUA_PATH="${ROOT}/?.lua;\
${ROOT}/?/init.lua;\
${ROOT}/libs/share/lua/5.1/?.lua;
${ROOT}/libs/share/lua/5.1/?/init.lua;;"
