local is_dev = tonumber(os.getenv("DEV")) == 1

box = {
	listen = os.getenv("LISTEN_URI"),
	slab_alloc_arena = 0.1,
	background = not is_dev,
	pid_file = "tarantool.pid",
	-- logger = 'file:tarantool.log',
}

console = {
    listen = '127.0.0.1:3302'
}

app = {
	{{__appname__}} = {
		
	}
}
