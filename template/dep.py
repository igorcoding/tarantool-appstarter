#! /usr/bin/env python

import argparse
import os

import sys

import subprocess
from os.path import expanduser


class Options:
    def __init__(self,
                 meta_config,
                 luarocks_config,
                 luarocks_tree):
        self.meta_config = meta_config
        self.luarocks_config = luarocks_config
        self.luarocks_tree = luarocks_tree


def ensure_tarantool_rocks_repo(luarocks_config):
    luarocks_config_dir = os.path.dirname(luarocks_config)
    if not os.path.isdir(luarocks_config_dir):
        os.mkdir(luarocks_config_dir)

    if os.path.exists(luarocks_config):
        with open(luarocks_config, 'r') as f:
            f_contents = f.read()
            if 'rocks.tarantool.org' in f_contents:
                return

    with open(luarocks_config, 'a') as f:
        f.write("""\nrocks_servers = {
	[[https://rocks.moonscript.org]],
	[[http://rocks.tarantool.org/]],
}\n""")


def exec_command(cmd):
    process = subprocess.Popen(cmd)
    exit_code = process.wait()
    assert exit_code == 0, "{0} failed".format(cmd)
    print('{0} finished with code {1}'.format(' '.join(cmd), exit_code))
    return exit_code

def exec_luarocks(subcommand, dep, tree=None):
    cmd = ['luarocks', subcommand, dep]
    if tree:
        cmd.append("--tree={0}".format(tree))
    return exec_command(cmd)

def exec_tarantoolctl(subcommand, dep, tree=None):
    cmd = ['tarantoolctl', 'rocks', subcommand, dep]
    return exec_command(cmd)

def luarocks_install(dep, tree=None):
    return exec_luarocks('install', dep, tree)

def luarocks_remove(dep, tree=None):
    return exec_luarocks('remove', cmd, tree)

def luarocks_make(dep, tree=None):
    return exec_luarocks('make', dep, tree)

def tarantoolctl_install(dep, tree=None):
    return exec_tarantoolctl('install', dep, tree)

def tarantoolctl_make(dep, tree=None):
    return exec_tarantoolctl('make', dep, tree)


def run(opts):
    app_name = opts.meta_config.get('name')
    assert app_name, 'name must be defined'

    # noinspection PyRedeclaration
    def fprint(s):
        print('[{0}] {1}'.format(app_name, s))

    fprint('Installing dependencies...')

    general_deps = opts.meta_config.get('deps', [])
    tnt_deps = opts.meta_config.get('tntdeps', [])
    local_deps = opts.meta_config.get('local', [])

    if not general_deps and not tnt_deps:
        fprint('Nothing to install')

    if tnt_deps:
        ensure_tarantool_rocks_repo(opts.luarocks_config)
        for dep in tnt_deps:
            fprint('Installing tntdep: {0}'.format(dep))
            tarantoolctl_install(dep, tree=opts.luarocks_tree)
            fprint('Installed tntdep: {0}\n\n'.format(dep))

    if general_deps:
        for dep in general_deps:
            fprint('Installing dep: {0}'.format(dep))
            luarocks_install(dep, tree=opts.luarocks_tree)
            fprint('Installed dep: {0}\n\n'.format(dep))

    if local_deps:
        for dep in local_deps:
            fprint('Installing local dep: {0}'.format(dep))
            dep = os.path.abspath(dep)
            cwd = os.getcwd()
            dep_path = os.path.dirname(dep)
            os.chdir(dep_path)
            try:
                try:
                    luarocks_remove(dep, tree=opts.luarocks_tree)
                except Exception as e:
                    print('remove of {0} failed: {1}'.format(dep, str(e)))
                luarocks_make(dep, tree=opts.luarocks_tree)
            finally:
                os.chdir(cwd)
            fprint('Installed local dep: {0}\n\n'.format(dep))

    return 0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--meta-file', help='meta.yaml file with tarantool deps', required=True)
    parser.add_argument('--luarocks-config',
                        help='path to luarocks config file',
                        type=str,
                        default=expanduser('~/.luarocks/config.lua'))
    parser.add_argument('--tree',
                        help='path to luarocks installation tree',
                        type=str,
                        default='.rocks')
    args = parser.parse_args()

    meta_file = os.path.abspath(args.meta_file)
    with open(meta_file, 'r') as f:
        try:
            import yaml
            meta_config = yaml.load(f)
        except Exception as e:
            print('Fall back to JSON parse due to: {}'.format(e))
            import json
            meta_config = json.load(f, encoding='utf-8')

    tree = os.path.abspath(args.tree)
    opts = Options(meta_config=meta_config,
                   luarocks_config=args.luarocks_config,
                   luarocks_tree=tree)
    return run(opts)

if __name__ == "__main__":
    sys.exit(main())
