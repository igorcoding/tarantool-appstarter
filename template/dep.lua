#! /usr/bin/env tarantool

local fio = require 'fio'
local yaml = require 'yaml'

local cfg


local function fprint(f, ...)
    print(string.format('[%s] ' .. f, cfg.name, ...))
end


local function ensure_rocksservers(path)
    local dir = fio.dirname(path)
    if not fio.path.is_dir(dir) then
        fio.mkdir(dir)
    end

    if fio.path.exists(path) then
        local data = fio.open(path):read()
        if data:match('rocks%.tarantool%.org') then
            fprint('Already have rocks.tarantool.org')
            return
        end
    end
    fprint("Patch %s with proper rocks servers", path)
    local fh = fio.open(path, {'O_APPEND', 'O_RDWR'})
    fh:write('\nrocks_servers = {[[http://rocks.tarantool.org/]], [[https://rocks.moonscript.org]]}\n')
    fh:close()
end


local function execute(cmd)
    local raw_cmd = table.concat(cmd, ' ')
    fprint("%s...", raw_cmd)
    local res = os.execute(raw_cmd)
    if res ~= 0 then
        error(string.format('[%s] %s failed', cfg.name, raw_cmd))
    end
end


local function cmd_luarocks(subcommand, dep, tree)
    assert(subcommand ~= nil, 'subcommand is required')
    assert(dep ~= nil, 'dep is required')

    local cmd = {'luarocks', subcommand, dep}
    if tree then
        table.insert(cmd, '--tree='..tree)
    end
    return execute(cmd)
end


local function cmd_tarantoolctl(subcommand, dep, tree)
    assert(subcommand ~= nil, 'subcommand is required')
    assert(dep ~= nil, 'dep is required')

    local cmd = {'tarantoolctl', 'rocks', subcommand, dep}
    return execute(cmd)
end


local function _gencmd(command, subcommand)
    return function(dep, tree)
        return command(subcommand, dep, tree)
    end
end

local luarocks_install = _gencmd(cmd_luarocks, 'install')
local luarocks_remove = _gencmd(cmd_luarocks, 'remove')
local luarocks_make = _gencmd(cmd_luarocks, 'make')
local tarantoolctl_install = _gencmd(cmd_tarantoolctl, 'install')


local function main()
    local luaroot = debug.getinfo(1, 'S')
    local source = fio.abspath(luaroot.source:match('^@(.+)'))
    local appname = fio.basename(fio.dirname(source))

    local args = {
        ['--luarocks-config'] = fio.pathjoin(os.getenv('HOME'), '.luarocks', 'config.lua'),
        ['--meta-file']       = '',
        ['--tree']            = '.rocks',
    }

    for i = 1,#arg/2 do args[ arg[i*2-1] ] = arg[i*2] end

    local meta_path = args['--meta-file']
    assert(meta_path ~= '', 'meta file is required')

    print('Using the following options:\n' .. yaml.encode(args))

    local meta_file = fio.abspath(meta_path)
    local metatext = fio.open(meta_file):read()
    local tree = fio.abspath(args['--tree'])

    cfg = metatext:match('^%s*%{') and require 'json'.decode(metatext) or yaml.decode(metatext)

    cfg.name = cfg.name or appname
    assert(cfg.name, 'Name must be defined')

    ensure_rocksservers(args['--luarocks-config'])

    fprint('Installing dependencies...')
    local deps = cfg.deps or {}
    local tnt_deps = cfg.tnt_deps or cfg.tntdeps or {}
    local local_deps = cfg.local_deps or cfg.localdeps or {}

    for _, dep in ipairs(deps) do
        fprint("Installing dep '%s'", dep)
        luarocks_install(dep, tree)
        fprint("Installed dep '%s'\n\n", dep)
    end

    for _, dep in ipairs(tnt_deps) do
        fprint("Installing tarantool dep '%s'", dep)
        tarantoolctl_install(dep, tree)
        fprint("Installed tarantool dep '%s'\n\n", dep)
    end

    for _, dep in ipairs(local_deps) do
        fprint("Installing local dep '%s'", dep)
        dep = fio.abspath(dep)
        dep_path = fio.dirname(dep)

        cwd = fio.cwd()
        fio.chdir(dep_path)
        local ok, res = pcall(luarocks_remove, dep, tree)
        if not ok then
            fprint(res)
        end

        luarocks_make(dep, tree)
        fio.chdir(cwd)
        fprint("Installed local dep '%s'\n\n", dep)
    end
    fprint('Done.')
end

xpcall(main, function(err)
    print(err .. '\n' .. debug.traceback())
end)
