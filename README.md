# THIS PROJECT IS NO LONGER SUPPORTED. PLEASE USE [moonlibs/tarantoolapp](https://github.com/moonlibs/tarantoolapp)

# tarantool-appstarter
Tarantool application starter

## Requirements
* tarantool >= 1.6
* luarocks (for lua 5.1)

## Run
Clone and run
```
bin/tntstartapp /path/to/app
```

You can add `bin/` folder to your `PATH` variable to run in arbitrary directory:
```
cd /path/to/my/app
tntstartapp .
```

## Rationale

The main idea behind this appstarter is to provide you with a default approach of developing apps for Tarantool.
To create a project starter you can run
```
mkdir -p /path/to/app
tntstartapp /path/to/app
```

And you'll end up with a default structure of an app. There are some important parts in it:
1) `dep.lua` and `meta.yaml`. Luarocks spec files does not support specifying dependencies on GH projects (via link to *.rockspec file), but the luarocks itself does. So, `meta.yaml` is a place where you drop your external dependencies (like a package.json for npm or requirements.txt for pip). You can specify either tarantool modules there (in the `tntdeps` section) by there names (like `queue` or `http`) or just bare links to *.rockspec files (in the `deps` section). Then a bundled `dep.lua` script will use this `meta.yaml` file to install all the required dependencies to a specified location.
2) `Makefile`. There are 2 main commands there:
* `make dep` - This command installs all the dependencies from meta.yaml to a local folder `.rocks` inside your project (already in bundled .gitignore)
* `make run`. After a successful installation of dependencies you can run your application. Practically it just creates a temporary folder `.tnt_{LISTEN_URI}`, `cd`'s inside and runs `tarantool init.lua`.
3) `init.lua` - An entry point to your entire application. Specifically, it does this:
* patches package.path and package.cpath to import packages from ./.rocks and ./app folders directly.
* `require`'s [package.reload module](https://github.com/Mons/tnt-package-reload)
* `require`'s config module (please refer to @mons's [tnt-config module](https://github.com/Mons/tnt-config) for more details). By default (if not specified in ENV variable CONF) it uses config file from /etc/{your_app_name}/conf.lua
* Runs `require('app')`. Which is essentially is run of your application.
* Also it starts the interactive console immediately (so you don't need to explicitly connect to your Tarantool instance)
4) `app`. This is a directory that contains all of your application code. It is absolutely up to you how you organize your code in this folder. By default `app/init.lua` `require`'s your inner application module and registers in the package-reload module. So when code reload happens, the `destroy` function of your module is called (to cleanup resources, stop fibers or whatever you want).

### Project deploy structure

The recommended way to deploy apps with `tarantool-appstarter` is to the following file structure:
```
/
├── etc
│   └── {{__appname__}}
│       └── conf.lua
└── usr
    └── share
        └── {{__appname__}}
            ├── init.lua
            ├── app/
            └── .rocks/
```
As you can see, `init.lua`, `app folder` and `.rocks folder` (so you, obviously, need to bundle your dep or rpm package with your dependencies) deploy to `/usr/share/{appname}/`, and `conf.lua` deploys to `/etc/{appname}/conf.lua`.

In order to run your applcation by either `tarantoolctl` or `systemd` you need to do the following:
* put a symlink `/etc/tarantool/instances.enabled/{appname}.lua -> /usr/share/{appname}/init.lua`.
* execute either `tarantoolctl start {appname}` or `systemctl start tarantool@appname`.

### Hot-reload

After all of that, if you want to hot-reload your application you just deploy your new code, connect to your running instance by any preferred method (for example, by executing `tarantoolctl enter {appname}`) and run `package.reload()`. That should be it.
