#!/bin/sh

#  Script.sh
#  swiftArchitecture
#
#  Created by KelanJiang on 2020/4/9.
#  Copyright © 2020 KleinMioke. All rights reserved.

pod lib lint --verbose --allow-warnings

pod trunk push --verbose --allow-warnings
