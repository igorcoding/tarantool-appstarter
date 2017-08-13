local conf = require 'config'
local log = require 'log'

box.once('access:v1', function()
	box.schema.user.grant('guest', 'read,write,execute', 'universe')
	-- Uncomment this to create user {{__appname__}}_user
	-- box.schema.user.create('{{__appname__}}_user', { password = '{{__appname__}}_pass' })
	-- box.schema.user.grant('{{__appname__}}_user', 'read,write,execute', 'universe')
end)

local app = {
	{{__appname__}} = require('{{__appname__}}'),
}

function app.start(config)
	log.info('Starting app')
	
    app.{{__appname__}}.init(config)
end

function app.destroy()
	log.info('Unloading app')
end

package.reload:register(app)
rawset(_G, 'app', app)
app.start(conf.get('app'))
