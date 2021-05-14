#!/usr/bin/env python3
# -*- coding:utf-8 -*-
###
# File: read_plugin_version.py
# Project: Kodi-Module-Generator
# File Created: Friday, 14th May 2021 5:40:12 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Friday, 14th May 2021 5:46:35 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

import os
import sys
import xml.etree.ElementTree as ET

plugin_directory = '/home/josh5/dev/mystuff/Kodi-Module-Generator/out/script.module.click'
plugin_directory = " ".join(sys.argv[1:])

tree = ET.parse(os.path.join(plugin_directory, 'addon.xml'))
root = tree.getroot()

# Return version
print(root.attrib.get('version'))
