box.once('access:v1', function()
	box.schema.user.grant('guest', 'read,write,execute', 'universe')
end)

local {{__appname__}} = require('{{__appname__}}')
rawset(_G, '{{__appname__}}', {{__appname__}})

return {
	start = function(conf)
		conf = conf or {}
		{{__appname__}}.start(conf.{{__appname__}})
	end,
	destroy = function()
		{{__appname__}}.stop()
	end
}
