#! /usr/bin/env tarantool

local function script_path() local fio = require('fio');local b = debug.getinfo(2, "S").source:sub(2);local lb = fio.readlink(b);if lb ~= nil then b = lb end;return b:match("(.*/)") end
local function addpaths(dst,...) local cwd = script_path(); local pp = {}; for s in package[dst]:gmatch("([^;]+)") do pp[s] = 1 end; local add = ''; for _, p in ipairs({...}) do if not pp[cwd..p] then add = add..cwd..p..';'; end end;package[dst]=add..package[dst];return end
addpaths('path', '?.lua', '?/init.lua', 'app/?.lua', 'app/?/init.lua', '.rocks/share/lua/5.1/?.lua', '.rocks/share/lua/5.1/?/init.lua')
addpaths('cpath', '.rocks/lib/lua/5.1/?.so', '.rocks/lib/lua/?.so', '.rocks/lib64/lua/5.1/?.so')

require 'package.reload'
local fio = require 'fio'

local conf_path = os.getenv('CONF')
if conf_path == nil then
	conf_path = '/etc/{{__appname__}}/conf.lua'
end
local conf = require('config')(conf_path)
local app = require 'app'
if app ~= nil and app.start ~= nil then
	app.start(conf.get('app'))
end

if tonumber(os.getenv('DEV')) == 1 then
	require('strict').on()
	require('console').start()
	os.exit(0)
end
