#!/usr/bin/env python
#-*- coding: utf-8 -*-

import plistlib
import sys

info = plistlib.readPlist(sys.argv[1] + '/Contents/Info.plist')

if info:
    print(info['CFBundleShortVersionString'])
