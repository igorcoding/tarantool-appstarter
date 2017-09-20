local is_dev = tonumber(os.getenv("DEV")) == 1

box = {
	listen = os.getenv("LISTEN") or "127.0.0.1:3301",
	memtx_memory = 100 * 1024 * 1024, -- 100 MB
	background = not is_dev,
	
	pid_file = "tarantool.pid",
	-- log = 'file:tarantool.log',
	-- replication = { }
}

app = {
	
}
