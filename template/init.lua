#! /usr/bin/env tarantool

local function script_path() local fio = require('fio');local b = debug.getinfo(2, "S").source:sub(2);local lb = fio.readlink(b);if lb ~= nil then b = lb end;return b:match("(.*/)") end
local function addpaths(...) local cur = script_path();local path = '';for _, p in ipairs({...}) do path = path .. cur .. p .. ';';end;package.path = path .. package.path;return cur; end
addpaths('?.lua', '?/init.lua', 'app/?.lua', 'app/?/init.lua', 'libs/share/lua/5.1/?.lua', 'libs/share/lua/5.1/?/init.lua')

require('package.reload')
local fio = require('fio')

local conf_path = os.getenv('CONF')
if conf_path == nil then
	conf_path = '/etc/{{__appname__}}/conf.lua'
end
local conf = require('config')(conf_path)

local app = require('app')
package.reload:register(app)
app.start(conf.get('app'))

if tonumber(os.getenv('DEV')) == 1 then
	require('console').start()
end
