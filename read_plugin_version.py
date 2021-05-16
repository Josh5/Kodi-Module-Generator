#!/usr/bin/env python3
# -*- coding:utf-8 -*-
###
# File: read_plugin_version.py
# Project: Kodi-Module-Generator
# File Created: Friday, 14th May 2021 5:40:12 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Sunday, 16th May 2021 6:21:37 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

import os
import sys
import xml.etree.ElementTree as ET

plugin_directory = " ".join(sys.argv[1:])

tree = ET.parse(os.path.join(plugin_directory, 'addon.xml'))
root = tree.getroot()

# Return version
print(root.attrib.get('version'))
