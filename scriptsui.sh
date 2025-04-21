#!/bin/sh
#------------------------------------------------#
#                                                #
#     ____            _ _         _   _ ___      #
#    / ___|  ___ _ __(_) |_ _ __ | | | |_ _|     #
#    \___ \ / __| '__| | __| '_ \| | | || |      #
#     ___) | (__| |  | | |_| |_) | |_| || |      #
#    |____/ \___|_|  |_|\__| .__/ \___/|___|     #
#                          |_|                   #
#------------------------------------------------#
# Author:       kstamand
# Date:         2025-04-31
# Synopsis:     Install and maintain a custom webpage on Asuswrt-Merlin routers
#+      for running predefined scripts and showing results in router's WebUI
# Description:  Installs/uninstals/updates files necessary to add a custom webpage
#+      to an Asuswrt-Merlin based router, which allows for selecting and running
#+      predefined shell scripts on the router and returning the results for dispaly
#+      within the routers web interface
# Reference:    This script is based on Asuswrt-merlin third party addon api
#+      https://github.com/RMerl/asuswrt-merlin/wiki/Addons-API/90b49e443b8ce64e82c0970237199deff46869f5
# Documentation: https://github.com/kstamand/scriptsui
# Credits:      Thanks to dave14305 for his pointers and guidance in devloping this solution
#+      much of the code in this script was modeled Dave's FlexQoS script and 
#+      Jack Yaz's YazFI scripts
#------------------------------------------------------------------------------#


# -x is a flag to show verbose script output for debugging purposes only
Debug(){
    clear
    set -x
    Yellow "Debugging enabled ..."
}

# AsusWRT Merlin Addon API helper functions
source /usr/sbin/helper.sh

### Start of Script Variables
readonly SCRIPT_NAME="scriptsui"
readonly SCRIPT_VERSION="v1.0.0"
readonly SCRIPT_NAME_DISPLAY="ScriptsUI"
readonly GIT_URL=https://raw.githubusercontent.com/kstamand/${SCRIPT_NAME}/master/
readonly ADDON_DIR="/jffs/addons/${SCRIPT_NAME}"
readonly SCRIPT_INSTALL_PATH="${ADDON_DIR}/${SCRIPT_NAME}.sh"
readonly ASP_INSTALL_PATH="${ADDON_DIR}/${SCRIPT_NAME}.asp"
readonly JSON_INSTALL_PATH="${ADDON_DIR}/${SCRIPT_NAME}.json"
readonly WEB_DIR="$(readlink /www/user)" # directory for custom web page to be installed
readonly SCRIPT_WEB_DIR="${WEB_DIR}/${SCRIPT_NAME}" # directory for scriptsui.json and results.js files
readonly EVENT_NAME="scrptsui"  # for some reason, using the name scriptsui for the event would not cause service-event to fire
readonly SCRIPT_LAUNCHER="${SCRIPT_PATH}/scriptlauncher"
readonly LOCK_FILE="/tmp/addonwebui.lock" # lock file to avoid conflicts with other custom WebUI addons
### End of Script Variables

# Detect if script is run from an SSH shell interactively or from the WebUI (unattended)
if tty >/dev/null 2>&1; then
    mode="interactive"
else
    mode="unattended"
fi

# Update version number in custom_settings.txt for reading in WebUI
#+ Purpose of which is to ensure the version of this script is reflected in the 
#+  /jffs/adddons/custom_settings.txt "name space" for this script
if [ "$(am_settings_get "${SCRIPTNAME}"_ver)" != "${SCRIPT_VERSION}" ]; then
    am_settings_set "${SCRIPTNAME}"_ver "${SCRIPT_VERSION}"
fi

Logmsg() {
    # Parameter options - $1 = message, $2 = loglevel
    if [ "$#" = "0" ]; then #if no parameters passed, then just return
        return
    fi
    logger -t "${SCRIPT_NAME_DISPLAY}" "$*" # display any/all parameters passed
} # Logmsg

Red() {
    printf -- '\033[1;31m%s\033[0m\n' "${1}"
}

Green() {
    printf -- '\033[1;32m%s\033[0m\n' "${1}"
}

Cyan() {
    printf -- '\033[1;36m%s\033[0m\n' "${1}"
}

Yellow() {
    printf -- '\033[1;33m%s\033[0m\n' "${1}"
}

Scriptinfo() {
    # Version header used in interactive sessions
    [ "${mode}" = "interactive" ] || return
    printf "\n"
    Green "${SCRIPT_NAME_DISPLAY} ${SCRIPT_VERSION}"
    printf "\n"
} # end of Scriptinfo ()

About() {
    Scriptinfo
    cat <<EOF
License
${SCRIPT_NAME_DISPLAY} is free to use under the GNU General Public License, version 3 (GPL-3.0).
https://opensource.org/licenses/GPL-3.0

For discussion visit this thread:
https://www.snbforums.com/forums/asuswrt-merlin-addons.60/?prefix_id=8
https://github.com/kstamand/scriptsui (Source Code)

About
Script maintains a Custom Webpage for selecting, running, and displaying script results
Reason - for those wishing to do as much as they can in the Router WebUI and avoid SSH for simple / informational commands
EOF
} # end of about() information

Check_Firmware() {
    Cyan "...Checking firmware support"
    if ! nvram get rc_support | grep -q am_addons; then
        Red "${SCRIPT_NAME_DISPLAY} requires ASUSWRT-Merlin Addon API support. Installation aborted."
        return 1
    fi
    if [ "$(nvram get jffs2_scripts)" != "1" ]; then
        Red "\"Enable JFFS custom scripts and configs\" is not enabled. Please enable it in the GUI. Aborting installation."
        return 1
    fi
} # end of Check_Firmware()

Press_Enter(){
    [ "${mode}" = "interactive" ] || return
    printf "\n"
    while true; do
        printf "Press enter to continue..."
        read -r "key"
        case "${key}" in
            *)
                break
            ;;
        esac
    done
    return 0
} # end of Press_Enter

Main_Menu() {

    local yn
    [ "${mode}" = "interactive" ] || return
    clear
    sed -n '2,10p' "${0}"		# display banner
    Scriptinfo
    printf "  (1) About        explain functionality\n"
    printf "  (2) Install      install scriptsui files\n"
    printf "  (3) Start        inserts custom webpage in Router WebUI under Tools\n"
    printf "  (4) Stop         removes custom webpage from Router\n"
    printf "  (5) Update       check for updates\n"
    printf "  (6) Uninstall    completely remove scriptsui from the router\n"
    printf "  (7) Run          run script selected from custom webpage\n"
    printf "  (8) Debug        enable verbose logging for troubleshooting\n"
    printf "  (e) Exit         exit without doing anything\n"
    printf "\nMake a selection: "
    read -r input
    case "${input}" in
        '1')
            clear
            about
            prinf "\nHit enter to continue"
            read -r input
        ;;
        '2')
            Install
        ;;
        '3')
            Start
        ;;
        '4')
            Stop
        ;;
        '5')
            Update
        ;;
        '6')
            Uninstall
        ;;
        '7')
            Run
        ;;
        '8')
            Debug
        ;;
        'e'|'E'|'exit')
            return
        ;;
        *)
            printf "\n"
            Red "$input is not a valid option!"
            printf "n"
            exit 5
        ;;
    esac
    Press_Enter
    Main_Menu		# stay in the menu loop until exit is chosen
} # end of Main_Menu()

Download_File() {
    # Parameter options: $1 = file name to download, $2 = full path + filename to download to
    # Download file from Github once to a temp location. If the same as the destination file, don't replace.
    # Otherwise move it from the temp location to the destination.
    if curl -fsL --retry 3 --connect-timeout 3 "${GIT_URL}/${1}" -o "/tmp/${1}"; then
        if [ "$(md5sum "/tmp/${1}" | awk '{print $1}')" != "$(md5sum "${2}" 2>/dev/null | awk '{print $1}')" ]; then
            mv -f "/tmp/${1}" "${2}"
            Green "Updated $(basename "${1}")"
        else
            Yellow "File $(basename "${2}") is already up-to-date"
            rm -f "/tmp/${1}" 2>/dev/null
        fi
    else
        Red "Updating $(basename "${1}") failed"
    fi
} # download_file

Auto_ServiceEvent() {
    # Borrowed from Adamm00
    # https://github.com/Adamm00/IPSet_ASUS/blob/master/firewall.sh
    local cmdline
    # Delete existing lines related to this script
    sed -i "\~${SCRIPT_NAME_DISPLAY} Addition~d" /jffs/scripts/service-event
    # Add line to handle other events triggered from webui
    cmdline='if echo "$2" | /bin/grep -q "'"^$EVENT_NAME"'"; then { '"$SCRIPT_LAUNCHER"' run "$@" & } ; fi # '"$SCRIPT_NAME_DISPLAY"
    echo "${cmdline}" >> /jffs/scripts/service-event
} # Auto_ServiceEvent

Setup_Aliases() {
    # shortcuts to launching script
    local cmdline
    if [ -d /opt/bin ]; then
        # Entware is installed, so setup link to /opt/bin
        Cyan "...Adding ${SCRIPT_NAME} link in Entware /opt/bin"
        ln -sf "${SCRIPT_INSTALL_PATH}" "/opt/bin/${SCRIPT_NAME}"
    else
        # Setup shell alias
        Cyan "... Adding ${SCRIPT_NAME} alias in profile.add"
        sed -i "/alias ${SCRIPT_NAME}/d" /jffs/configs/profile.add 2>/dev/null
        cmdline="alias ${SCRIPT_NAME}=\"sh ${SCRIPT_INSTALL_PATH}\" # ${SCRIPT_NAME_DISPLAY} Addition"
        echo "${cmdline}" >> /jffs/configs/profile.add
    fi
} # Setup_Aliases

Webconfigpage() {
    local urlpage urlproto urldomain urlport

    # Eye candy function that will construct a URL to display after install or upgrade so a user knows where to
    # find the webUI page. In most cases though, they will go to the Adaptive QoS tab and find the FlexQoS sub-tab anyway.
    urlpage="$(sed -nE "/${SCRIPT_NAME_DISPLAY}/ s/.*url\: \"(user[0-9]+\.asp)\".*/\1/p" /tmp/menuTree.js)"
    if [ "$(nvram get http_enable)" = "1" ]; then
        urlproto="https"
    else
        urlproto="http"
    fi
    if [ -n "$(nvram get lan_domain)" ]; then
        urldomain="$(nvram get lan_hostname).$(nvram get lan_domain)"
    else
        urldomain="$(nvram get lan_ipaddr)"
    fi
    if [ "$(nvram get ${urlproto}_lanport)" = "80" ] || [ "$(nvram get ${urlproto}_lanport)" = "443" ]; then
        urlport=""
    else
        urlport=":$(nvram get ${urlproto}_lanport)"
    fi

    if echo "${urlpage}" | grep -qE "user[0-9]+\.asp"; then
        Green "Advanced configuration available via:\n"
        Cyan "  ${urlproto}://${urldomain}${urlport}/${urlpage}"
    fi
} # end of webconfigpage()

Init_UserScript() {
    # Parameter options: $1 = system script to update (e.g., service-event)
    # Properly setup an empty Merlin user script
    local userscript
    if [ -z "${1}" ]; then
        return
    fi
    userscript="/jffs/scripts/${ADDONS_DIR}/$1"
    if [ ! -f "${userscript}" ]; then
        # If script doesn't exist yet, create with shebang
        printf "#!/bin/sh\n\n" > "${userscript}"
    elif [ -f "${userscript}" ] && ! head -1 "${userscript}" | /bin/grep -qE "^#!/bin/sh"; then
        #  Script exists but no shebang, so insert it at line 1
        sed -i '1s~^~#!/bin/sh\n~' "${userscript}"
    elif [ "$(tail -c1 "${userscript}" | wc -l)" = "0" ]; then
        # Script exists with shebang, but no linefeed before EOF; makes appending content unpredictable if missing
        printf "\n" >> "${userscript}"
    fi
    if [ ! -x "${userscript}" ]; then
        # Ensure script is executable by owner
        chmod 755 "${userscript}"
    fi
} # Init_UserScript

Install() {
    # Parameter options: None
    # Install script and download webui file
    # This is also called by the update process once a new script is downloaded by update() function
    if [ ! "${mode}" = "interactive" ]; then
        Logmsg "[ERROR] Install function can only be run interactively"
        exit 5
    fi
    clear
    Scriptinfo
    Green "Installing ${SCRIPT_NAME_DISPLAY}"
    if ! Check_Firmware; then
        Red "Addons are not supported in this routers firmware - script aborting!!!"
        Press_Enter
        rm -f "${0}" 2>/dev/null
        exit 5
    fi
    # Create the directory for the ScriptsUI addon files
    if [ ! -d "${ADDON_DIR}" ]; then
        Cyan "...Creating $SCRIPT_NAME_DISPLAY ADDON directorY..."
        mkdir -p "${ADDON_DIR}"
        chmod 755 "${ADDON_DIR}"
    fi
    # Create the Web Directory for the SciptsUI JSON and Results files
    if [ ! -d "${SCRIPT_WEB_DIR}" ]; then
        Cyan "...Creating $SCRIPT_NAME_DISPLAY Web directories..."
        mkdir -p "${SCRIPT_WEB_DIR}"
        chmod 755 "${SCRIPT_WEB_DIR}"
    fi

    # download all scriptsui files
    Cyan "...Downloading $(basename "${SCRIPT_INSTALL_PATH}")"
    Download_File "$(basename "${SCRIPT_INSTALL_PATH}")" "${SCRIPT_INSTALL_PATH}" #scriptsui.sh
    chmod 755 ${SCRIPT_INSTALL_PATH} # make script executable

    Cyan "...Downloading $(basename "${ASP_INSTALL_PATH}")"
    Download_File "$(basename "${ASP_INSTALL_PATH}")" "${ASP_INSTALL_PATH}" #custom webpage 

    Cyan "...Downloading $(basename "${JSON_INSTALL_PATH}")"
    Download_File "$(basename "${JSON_INSTALL_PATH}")" "${JSON_INSTALL_PATH}" #sample json file of scripts to display in custom webpage

    # add command line to /jffs/scripts/services-start to add custom webpage functionality on router bootup
    Cyan "...Adding ${SCRIPT_LAUNCHER} to services-start so the custom webpage is added during router bootup"
    Auto_ServiceEvent
    Cyan "...Adding ${SCRIPT_NAME} alias to the System and user profile"
    Setup_Aliases

    # Install complete messages
    Green "${SCRIPT_NAME_DISPLAY} installation complete!"
    Webconfigpage

} # end of Install()

Install_Webui() {
    # Parameters - None (Install) or $1 = mount
    local prev_webui_page
    local FD
    printf "Downloading WebUI file...\n"
    download_file "$(basename "${WEBPAGE_PATH}")" "${WEBPAGE_PATH}"
    FD=386
    eval exec "${FD}>${LOCKFILE}"
    /usr/bin/flock -x "${FD}"
    # Check if the webpage is already mounted in the GUI and reuse that page
    prev_webui_page="$(sed -nE "s/^\{url\: \"(user[0-9]+\.asp)\"\, tabName\: \"${SCRIPT_NAME_DISPLAY}\"\}\,$/\1/p" /tmp/menuTree.js 2>/dev/null)"
    if [ -n "${prev_webui_page}" ]; then
        # use the same filename as before
        am_webui_page="${prev_webui_page}"
    else
        # get a new mountpoint
        am_get_webui_page "${WEBPAGE_PATH}"
    fi
    if [ "${am_webui_page}" = "none" ]; then
        Logmsg "No API slots available to install web page"
    else
        cp -p "${WEBPAGE_PATH}" "/www/user/${am_webui_page}"
        if [ ! -f /tmp/menuTree.js ]; then
            cp /www/require/modules/menuTree.js /tmp/
            mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
        fi
        if ! /bin/grep -q "{url: \"$am_webui_page\", tabName: \"${SCRIPT_NAME_DISPLAY}\"}," /tmp/menuTree.js; then
            umount /www/require/modules/menuTree.js 2>/dev/null
            sed -i "/url: \"Tools_OtherSettings.asp\", tabName:/a {url: \"$am_webui_page\", tabName: \"$SCRIPT_NAME_DISPLAY\"}," /tmp/menuTree.js
            mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
        fi
    fi
    /usr/bin/flock -u "${FD}"
} # end of install_webui()

Compare_Remote_Version() {
    # Parameter options: None
    # Check version on Github and determine the difference with the installed version
    # Outcomes: Version update, or no update
    local remotever
    # Fetch version of the shell script on Github
    remotever="$(curl -fsN --retry 3 --connect-timeout 3 "${GIT_URL}/$(basename "${SCRIPTPATH}")" | /bin/grep "^version=" | sed -e 's/version=//')"
    if [ "$( echo "${SCRIPT_VERSION}" | sed 's/\.//g' )" -lt "$( echo "${remotever}" | sed 's/\.//g' )" ]; then		# strip the . from version string for numeric comparison
        # version upgrade
        echo "${remotever}"
    else
        printf "NoUpdate\n"
    fi
} # compare_remote_version

Update() {
    # Check for, and optionally apply updates.
    # Parameter options: check (do not update), silent (update without prompting)
    local updatestatus yn
    Scriptinfo
    printf "Checking for updates\n"
    # Update the webui status thorugh detect_update.js ajax call.
    printf "var verUpdateStatus = \"%s\";\n" "InProgress" > "/www/ext/${SCRIPTNAME}/detect_update.js"
    updatestatus="$(compare_remote_version)"
    # Check to make sure we got back a valid status from compare_remote_version(). If not, indicate Error.
    case "${updatestatus}" in
        'NoUpdate'|[0-9].[0-9].[0-9]) ;;
        *) updatestatus="Error"
    esac
    printf "var verUpdateStatus = \"%s\";\n" "${updatestatus}" > "/www/ext/${SCRIPTNAME}/detect_update.js"

    if [ "${1}" = "check" ]; then
        # Do not proceed with any updating if check function requested
        return
    fi
    if [ "${mode}" = "interactive" ] && [ -z "${1}" ]; then
        case "${updatestatus}" in
        'NoUpdate')
            Green " You have the latest version installed"
            printf " Would you like to overwrite your existing installation anyway? [1=Yes 2=No]: "
            ;;
        'Error')
            Red " Error determining remote version status!"
            Press_Enter
            return
            ;;
        *)
            # New Version Number
            Green " ${SCRIPTNAME_DISPLAY} v${updatestatus} is now available!"
            printf " Would you like to update now? [1=Yes 2=No]: "
            ;;
        esac
        read -r yn
        printf "\n"
        if [ "${yn}" != "1" ]; then
            Green " No Changes have been made"
            return 0
        fi
    fi
    printf "Installing: %s...\n\n" "${SCRIPTNAME_DISPLAY}"
    download_file "$(basename "${SCRIPTPATH}")" "${SCRIPTPATH}"
    exec sh "${SCRIPTPATH}" -install "${1}"
    exit
} # update

### Script Mainline

# Check if a parameter was passed when calling this script
#+ If no parameter or menu passed AND scriptsui is not found in /jffs/script-services-start (means not installed already) then set parm to install
arg1="${1#-}"
if [ -z "${arg1}" ] && ! /bin/grep -qE "${SCRIPTPATH} .* # ${SCRIPT_NAME_DISPLAY}" /jffs/scripts/services-start; then
	clear
    arg1="menu"
else
    read -p "About to install ${SCRIPT_NAME_DISPLAY}... Continue (y/n)?" yn
    case $yn in
        [yY]) arg1="menu";;
        [nN]) Yellow 'Your answered "n", so exiting script';
            exit;;
        *) Red "Unknown response .... Exiting script";
            exit;; 
    esac
fi

case "${arg1}" in
    'menu')
        Main_Menu
    ;;
    'install')
        Install
    ;;
    'start')
        Start
    ;;
    'stop')
        Stop
    ;;
    'upate')
        Update
    ;;
    'uninstall')
        Uninstall
    ;;
    'run')
        Run
    ;;
    'debug')
        Debug
    ;;
    *)
        printf "\n"
        Red "$input is not a valid option!"
        printf "n"
        exit 5
    ;;
esac
