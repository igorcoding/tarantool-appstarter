local errno = require('errno')
local fio = require('fio')
local yaml = require('yaml')

local function errorf(s, ...)
    error(string.format(s, ...))
end

local function printf(s, ...)
    print(string.format(s, ...))
end

local function merge_tables(t, ...)
    for _, tt in ipairs({...}) do
        for _, v in ipairs(tt) do
            table.insert(t, v)
        end
    end
    return t
end

local S_IFREG = tonumber('0100000', 8)  -- regular file
local S_IFDIR = tonumber('0040000', 8)  -- directory

local modes = fio.c.mode
local perms = bit.bor(modes.S_IRUSR, modes.S_IWUSR,
                      modes.S_IRGRP, modes.S_IWGRP,
                      modes.S_IROTH, modes.S_IWOTH)
local folder_perms = bit.bor(modes.S_IRUSR, modes.S_IWUSR, modes.S_IXUSR,
                             modes.S_IRGRP, modes.S_IWGRP, modes.S_IXGRP,
                             modes.S_IROTH,                modes.S_IXOTH)

local function get_mode(file_path)
    local f_mode = fio.stat(file_path).mode
    local is_directory = (bit.band(f_mode, S_IFDIR) > 0)
    local is_file = (bit.band(f_mode, S_IFREG) > 0)

    if is_directory then
        return 'directory'
    end
    return 'file'
end

function listdir(path)
    local files = {}
    for _, postfix in ipairs({'/*', '/.*'}) do
        for _, file in ipairs(fio.glob(path .. postfix)) do
            if fio.basename(file) ~= "." and fio.basename(file) ~= ".." then
                local mode = get_mode(file)
                table.insert(files, {
                    mode = mode,
                    path = file
                })
                if mode == "directory" then
                    files = merge_tables(files, listdir(file))
                end
            end
        end
    end
    return files
end

local function read_file(filepath)
    local fh = fio.open(filepath, {'O_RDONLY'})
    if not fh then
        errorf("Failed to open file %s: %s", filepath, errno.strerror())
    end

    local data = ''
    while true do
        local d = fh:read(4096)
        if d == '' or d == nil then
            break
        else
            data = data .. d
        end
    end
    fh:close()
    return data
end

local function render(s, opts)
    s = string.gsub(s, "{{__appname__}}", opts.name)
    s = string.gsub(s, "{{__version__}}", opts.version)
    return s
end

local function render_name(filepath, opts)
    local filename = fio.basename(filepath)
    local filedir = fio.dirname(filepath)

    local new_filename = render(filename, opts)
    local new_filepath = fio.pathjoin(filedir, new_filename)
    fio.rename(filepath, new_filepath)
    return new_filepath
end

local function render_file(filepath, opts)
    local s = read_file(filepath)
    local new_s = render(s, opts)

    local src_mode = fio.stat(filepath).mode

    local fh = fio.open(filepath, {'O_WRONLY', 'O_TRUNC'}, src_mode)
    if not fh then
        errorf("Failed to open file %s: %s", filepath, errno.strerror())
    end

    fh:write(new_s)
    fh:close()
end

local function copyfile(src, dest)
    local src_fh = fio.open(src, {'O_RDONLY'})
    if not src_fh then
        errorf("Failed to open file %s: %s", src, errno.strerror())
    end
    local src_mode = fio.stat(src).mode

    local local_perms = bit.bor(perms,
                                bit.band(src_mode, fio.c.mode.S_IXUSR),
                                bit.band(src_mode, fio.c.mode.S_IXGRP),
                                bit.band(src_mode, fio.c.mode.S_IXOTH))

    local dest_fh = fio.open(dest, {'O_WRONLY', 'O_CREAT'}, local_perms)
    if not dest_fh then
        errorf("Failed to open file %s: %s", dest, errno.strerror())
    end

    local data = nil
    while true do
        local d = src_fh:read(4096)
        if d == nil or d == '' then
            break
        else
            dest_fh:write(d)
        end
    end
    src_fh:close()
    dest_fh:close()
    return data
end

local function copydir(src, dest)
    local files = listdir(src)

    local msrc, _ = src:gsub('([().%+-*?[^$])', '%%%1')

    assert(dest ~= nil)
    for _, f in ipairs(files) do
        local fmode, fpath = f.mode, f.path

        local filename = fio.basename(fpath)
        local filedir = fio.dirname(fpath)
        local relative_path = fpath:match(msrc .. '/(.*)')

        local p = fio.pathjoin(dest, relative_path)

        if fmode == 'directory' then
            local ok = fio.mkdir(p, folder_perms)
            if not ok then
                errorf("Couln't create folder %s: %s", p, errno.strerror())
            end
        else
            copyfile(fpath, p)
        end

        -- printf('Copied %s to %s', fpath, p)
    end
end

local function start_app(rootdir, opts)
    assert(opts.name ~= nil and opts.name ~= '', 'App name must be defined and should not be empty')
    assert(opts.workdir ~= nil and opts.workdir ~= '', 'Workdir must be defined and should not be empty')
    if fio.stat(opts.workdir) == nil then
        fio.mkdir(opts.workdir, folder_perms)
    end

    local src = fio.pathjoin(rootdir, 'template')
    copydir(src, opts.workdir)
    local files = listdir(opts.workdir)
    for _, f in ipairs(files) do
        local fmode, fpath = f.mode, f.path
        if fmode == 'file' then
            render_file(fpath, opts)
        end
        render_name(fpath, opts)
    end
end

return {
    start_app = start_app,
    render = render,
    render_name = render_name,
    render_file = render_file,
}
