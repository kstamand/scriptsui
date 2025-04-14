#!/bin/sh
logger -t "scriptsui" "Running brctl_show script"
brctl show > /www/user/scriptsui/results.js
