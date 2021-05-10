#!/usr/bin/env python3
# -*- coding:utf-8 -*-
###
# File: build.py
# Project: Kodi-Module-Generator
# File Created: Monday, 10th May 2021 8:52:42 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 10th May 2021 11:34:57 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

# Requirements = `python3 -m pip install pipgrip`

import json
import os
import shutil
import subprocess

template_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'template')
out_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'out')
cache_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'cache')


def install_module(module_dir, module_name, version):
    module_lib_dir = os.path.abspath(os.path.join(module_dir, 'lib'))
    if not module_lib_dir:
        os.makedirs(module_lib_dir)

    # First install local
    cmd = 'python3 -m pip install --user {}=={}'.format(module_name, version)
    subprocess.call(cmd, shell=True)

    # Then install to module directory
    cmd = 'python3 -m pip install --ignore-installed --no-dependencies --target={} {}=={}'.format(module_lib_dir,
                                                                                                  module_name,
                                                                                                  version)
    subprocess.call(cmd, shell=True)


def update_module_data(module_dir, module_name, module_deps_list):
    # Read data from module
    res = subprocess.check_output('python3 -m pip show  {}'.format(module_name), shell=True)
    module_version = ''
    module_author = ''
    module_author_email = ''
    module_license = ''
    module_summary = ''
    module_website = 'https://pypi.org/project/{}/'.format(module_name)
    for line in res.splitlines():
        x = str(line.decode("utf-8"))
        print(x)
        if x.startswith('Version:'):
            module_version = x.split(': ')[1].strip()
        elif x.startswith('Author:'):
            module_author = x.split(': ')[1].strip()
        elif x.startswith('Author-email:'):
            module_author_email = x.split(': ')[1].strip()
        elif x.startswith('License:'):
            module_license = x.split(': ')[1].strip()
        elif x.startswith('Summary:'):
            module_summary = x.split(': ')[1].strip()

    module_xml = os.path.join(module_dir, 'addon.xml')
    # Read in the file
    with open(module_xml, 'r') as file:
        file_data = file.read()

    # Replace the target string with data from pip show
    if module_author_email:
        module_author = '{} ({})'.format(module_author, module_author_email)
    file_data = file_data.replace('PYTHON_MODULE_NAME', module_name)
    file_data = file_data.replace('PYTHON_MODULE_VERSION', module_version)
    file_data = file_data.replace('PYTHON_MODULE_AUTHOR', module_author)
    file_data = file_data.replace('PYTHON_MODULE_LICENSE', module_license)
    file_data = file_data.replace('PYTHON_MODULE_SUMMARY', module_summary)
    file_data = file_data.replace('PYTHON_MODULE_DESCRIPTION', module_summary)
    file_data = file_data.replace('PYTHON_MODULE_WEBSITE', module_website)

    # Append dependencies list
    template = '    <import addon="script.module.{}" version="{}" />'
    deps_to_add = ""
    for dep in module_deps_list:
        line = template.format(dep.get('name'), dep.get('version'))
        deps_to_add = "{}\n{}".format(deps_to_add, line)
    file_data = file_data.replace('PYTHON_MODULE_DEPENDENCIES', deps_to_add)

    # Write the file out again
    with open(module_xml, 'w') as file:
        file.write(file_data)


def sanitize_module(module_name):
    module_dir = os.path.join(out_dir, 'script.module.{}'.format(module_name))
    sanitize_script = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'sanitize.sh')
    cmd = '{} {}'.format(sanitize_script, module_dir)
    subprocess.call(cmd, shell=True)


def build_script_module(module_name, version, module_deps):
    module_dir = os.path.join(out_dir, 'script.module.{}'.format(module_name))
    if not os.path.exists(module_dir):
        os.makedirs(module_dir)

    if not os.path.exists(os.path.join(module_dir, 'addon.xml')):
        shutil.copy(os.path.join(template_dir, 'addon.xml'), os.path.join(module_dir, 'addon.xml'))

    if not os.path.exists(os.path.join(module_dir, 'icon.png')):
        shutil.copy(os.path.join(template_dir, 'icon.png'), os.path.join(module_dir, 'icon.png'))

    # Install modules
    install_module(module_dir, module_name, version)

    # Sanitize module
    sanitize_module(module_name)

    # Write addon.xml
    update_module_data(module_dir, module_name, module_deps)


def process_module_deps_list(deps_list):
    for dep in deps_list:
        module_name = dep.get('name')
        module_version = dep.get('version')
        child_deps = dep.get('dependencies', [])

        # Build module for each item found in depends list
        process_module_deps_list(child_deps)

        # Build module
        print("Building Kodi Python module for {} v{}".format(module_name, module_version))
        build_script_module(module_name, module_version, child_deps)


def create_dep_list(module, version):
    deps_cache = os.path.join(cache_dir, 'deps-{}-{}.json'.format(module, version))

    if not os.path.exists(deps_cache):
        print("Fetching Dependencies list for {} v{}".format(module, version))
        cmd = 'pipgrip --tree --json unmanic'.format(module, version)
        res = subprocess.check_output(cmd, shell=True)
        decoded = str(res.decode("utf-8"))
        data = json.loads(decoded)

        with open(deps_cache, 'w') as file:
            json.dump(data, file, indent=2)

    with open(deps_cache, 'r') as file:
        deps_list = json.load(file)

    return deps_list


def run():
    if not os.path.exists(template_dir):
        os.makedirs(template_dir)
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)
    if not os.path.exists(cache_dir):
        os.makedirs(cache_dir)

    try:
        with open(os.path.join(os.path.dirname(os.path.realpath(__file__)), 'modules.json'), 'r') as file:
            modules = json.load(file)
    except Exception as e:
        print("No modules configured... - {}".format(str(e)))
        modules = []

    for module_data in modules:
        original_module = module_data.get('module')
        version = module_data.get('version')
        deps_list = create_dep_list(original_module, version)
        process_module_deps_list(deps_list)


if __name__ == '__main__':
    run()
