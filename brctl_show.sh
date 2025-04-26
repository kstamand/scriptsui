#!/bin/sh
logger -t "ScriptsUI" "Running brctl_show script"
brctl show > /www/user/scriptsui/results.js
