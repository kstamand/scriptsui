#!/bin/sh
###########################################################
#
#  ____            _ _         _   _ ___ 
# / ___|  ___ _ __(_) |_ _ __ | | | |_ _|
# \___ \ / __| '__| | __| '_ \| | | || | 
#  ___) | (__| |  | | |_| |_) | |_| || | 
# |____/ \___|_|  |_|\__| .__/ \___/|___|
#                       |_|                                                              
###########################################################
# ScriptUI maintaied by kstamand
# This script is based on the the sample from Asuswrt-merlin third party addon api
#+ Reference https://github.com/RMerl/asuswrt-merlin/wiki/Addons-API/90b49e443b8ce64e82c0970237199deff46869f5
# Credits: Thanks to dave14305 for his pointers and guidance 
###########################################################

{
    set -x # uncomment/comment to enable/disable debug mode
    
    # AsusWRT Merlin Addon API helper functions
    source /usr/sbin/helper.sh

    # Define Script Variables
    readonly MyPage="ScriptsUI"
    readonly MyAsp="scriptsui.asp"
    readonly TabName="ScriptsUI"
    readonly AddOnVersion="1.0"
    readonly ScriptsDir="/jffs/addons/scriptsui"
    readonly EventName="scrptsui"  # for some reason, using the name scriptsui for the event would not cause service-event to fire
    readonly ScriptLauncher="scriptsui"
    readonly ScriptPath="${ScriptsDir}/${ScriptLauncher}"
    readonly WebUIPath="$ScriptsDir/$MyAsp"
    readonly WWWUserDir="/www/user" # directory to copy custom webpage to 
    readonly WWWScriptsDir="$WWWUserDir/scriptsui" # direcotry for JSON file, and script results file
    readonly JSONFile="scriptsui.json" # file containing my scripts to be called from WebUI
    readonly LOCKFILE="/tmp/addonwebui.lock" # lock file to avoid conflicts with other custom WebUI addons

    # Does the firmware support addons?
    nvram get rc_support | grep -q am_addons
    if [ $? != 0 ]
    then
        echo "$MyPage" "System doesn't support addons"
        exit 5
    fi

    # Create a lockfile to prevent conflicts with other Webpage addons (e.g. using same user#.asp)
    local FD
    FD=386	
    eval exec "${FD}>${LOCKFILE}"
	/usr/bin/flock -x "${FD}"

    # Check if the webpage is already mounted in the GUI and reuse that page
	prev_webui_page="$(sed -nE "s/^\{url\: \"(user[0-9]+\.asp)\"\, tabName\: \"${TabName}\"\}\,$/\1/p" /tmp/menuTree.js 2>/dev/null)"
	if [ -n "${prev_webui_page}" ]; then
		# use the same filename as before
		am_webui_page="${prev_webui_page}" 2>/dev/null
	else
		# get a new mountpoint
		am_get_webui_page "${WebUIPath}" 2>/dev/null
	fi

	if [ "${am_webui_page}" = "none" ]; then
		echo "[ERROR] No API slots available to install web page"
	else
        # Copy custom page to WWW User space
        cp $ScriptsDir/$MyAsp $WWWUserDir/$am_webui_page

        # Copy ScriptsUI JSON file (list of scripts) to WWW User Space
        mkdir $WWWScriptsDir
        cp $ScriptsDir/$JSONFile $WWWScriptsDir

        # Copy menuTree (if no other script has done it yet) so we can modify it
        if [ ! -f /tmp/menuTree.js ]; then
            cp /www/require/modules/menuTree.js /tmp/
            mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
        fi

        # Check to see the Tab for this custom webpage already exists and if not add it
        if ! /bin/grep -q "{url: \"$am_webui_page\", tabName: \"${TabName}\"}," /tmp/menuTree.js; then
            # unmount System WebUI
            umount /www/require/modules/menuTree.js

            # Insert link at the end of the Tools menu.  Match partial string, since tabname can change between builds (if using an AS tag)
            sed -i "/url: \"Tools_OtherSettings.asp\", tabName:/a {url: \"$am_webui_page\", tabName: \"$TabName\"}," /tmp/menuTree.js

            # remount System WebUI with the new custom tab added
            mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
        fi 
    fi 

    # Remove lockfile
    /usr/bin/flock -u "${FD}"

    # Write out addons Custom Settings to /jffs/addons/custom_settings.txt
    am_settings_set "ScriptsUI_Version" $AddOnVersion
    am_settings_set "ScriptsUI_Page   " $am_webui_page

    # Add event listener to services-event, for launching the script selected from Custom web page
    cmdline='if echo "$2" | /bin/grep -q "'"^$EventName"'"; then { '"$ScriptPath"' run "$@" & } ; fi # '"$ScriptLauncher"
    echo "${cmdline}" >> /jffs/scripts/service-event
} 2>&1 | logger -t $(echo $(basename $0) | grep -Eo '^.{0,23}')[$$]
