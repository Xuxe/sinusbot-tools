#!/bin/bash
#
### AUTHOR INFO
# (C) Patrik Kernstock
#  Website: pkern.at
#
### SCRIPT INFO
# Version: 0.3.7
# Licence: GNU GPL v2
# Description:
#  Collects some important diagnostic data about
#  the operating system and the bot installation.
#  When finished it returns informative information,
#  ready to copy and paste it in the right section
#  in the sinusbot forum to your post.
#
# Important links:
#  Development of this script: https://github.com/patschi/sinusbot-tools
#  TeamSpeak: http://www.teamspeak.com
#  Sinusbot forum: https://forum.sinusbot.com
#  Sinusbot forum thread [english]: https://forum.sinusbot.com/threads/diagsinusbot-sh-sinusbot-diagnostic-script.831/#post-4418
#  Sinusbot forum thread [german]: https://forum.sinusbot.com/threads/diagsinusbot-sh-sinusbot-diagnostik-script.832/#post-4419
#
### CHANGELOG
#  v0.1.0: [25.11.2015 12:00]
#          Release: Alpha.
#          New: Basic functionality.
## v0.2.0: [25.11.2015 14:00]
#          New: OpenVZ checks
#          New: YouTubeDL support
#          New: welcome header
#          New: asking for automated package install
#          New: Missing operating system packages check
#          New: Check when package manager was updated last time
#          New: parameter support
#          New: parameter: '-w|--no-welcome' to hide welcome text
#          New: parameter: '-u|--no-os-update-check' to skip OS update check
#  v0.2.1: [25.11.2015 18:00]
#          Fixed: Corrected calculating RAM usage (now without cached RAM)
#          New: Added time as prefix to log messages
#          New: Added report date including timezone to output
#  v0.2.5: [25.11.2015 21:00]
#          New: Added help with '-h|--help' parameter
#          New: More colorful output (everyone likes colors... and cookies.)
#          Fixed: TS3Path check if exists
#          Fixed: 'cpu model' was shown multiple times if more processors exists (even when different processors)
#          New: Fallback for bot location when binary not found to /opt/ts3bot/
#          Changed: Output style. From BBCode to clean text.
#          New: Added '-v|--version' parameter
#          New: Added '-c|--credits' parameter
#          Improved: own function for trimming whitespaces
#  v0.3.0: [26.11.2015 19:00]
#          Release: Beta.
#          New: Added TS3Client version to output.
#          New: Added support to retrieve sinusbot version by 'sinusbot --version' parameter (including fallback to old method)
#          New: Added SWAP info display
#          New: Added DISK info display
#          New: Added KERNEL info display
#          New: Added LOAD AVERAGE info display
#          New: Added UPTIME info display
#          New: Added 'installed bot scripts' display
#          New: Added TS3client bot-plugin checks
#          New: Added bot running checks (and under which user it is running)
#          New: Added bot webinterface port checks
#          Improved: Supported operating system checks.
#  v0.3.1: [26.11.2015 21:00]
#          Changed: Using 'lscpu' for determining CPU data now
#          New: Check for bot autostart script (/etc/init.d/sinusbot)
#  v0.3.2: [26.11.2015 21:20]
#          New: Added advanced permissions checks for the autostart script
#  v0.3.3: [02.12.2015 10:00]
#          New: Check if x64 bit operating system
#          New: Added DNS resolution check of google.com
#  v0.3.4: [04.12.2015 18:15]
#          Changed: Switched from 'nc' to 'netstat' to determine if webinterface port is up
#          Improved: Some text changes
#  v0.3.5: [01.01.2016 04:00]
#          Happy new year!
#          Changed: Added CODE-tags for forum to output
#          Changed copyright year
#  v0.3.6: [16.01.2016 13:55]
#          Fixed some bugs in operating system package detection function
#          Fixed lsb_release errors when checking OS support before checking package installation of lsb-release
#          Fixed dpkg-query errors when package was never installed before (when package detection)
#  v0.3.7: [29.01.2016 00:45]
#          Fixed retrieving of youtube-dl version when binary exists and is set in the bot configuration (Thanks Xuxe!, see PR #1)
#
### THANKS TO...
# all people, who helped developing and testing
# this script in any way. For more information
# see with parameter: '-c' or '--credits'.
#
### USAGE
# To download and execute you can use:
#  $ wget https://raw.githubusercontent.com/patschi/sinusbot-tools/master/tools/diagSinusbot.sh
#  $ bash diagSinusbot.sh
#
### DISCLAIMER
# No warranty, execute on your own risk.
# No cats were harmed during development.
# May contain traces of eastereggs.
#
##################################################
#### DO NOT TOUCH ANYTHING BELOW, IF YOU 
#### DO NOT KNOW WHAT YOU ARE DOING!
##################################################

### SCRIPT CONFIGURATION VARIABLES
# setting important variables

# general settings
# SCRIPT
SCRIPT_AUTHOR_NAME="Patrik Kernstock"
SCRIPT_AUTHOR_WEBSITE="pkern.at"
SCRIPT_YEAR="2015-2016"

SCRIPT_NAME="diagSinusbot"
SCRIPT_VERSION_NUMBER="0.3.7"
SCRIPT_VERSION_DATE="29.01.2016 00:45"

SCRIPT_PROJECT_SITE="https://raw.githubusercontent.com/patschi/sinusbot-tools/master/tools/diagSinusbot.sh"

# script COMMANDS dependencies
SCRIPT_REQ_CMDS="apt-get pwd awk wc free grep echo cat date df stat getconf netstat"
# script PACKAGES dependencies
SCRIPT_REQ_PKGS="bc binutils coreutils lsb-release util-linux"

# BOT
# bot PACKAGES dependencies
BOT_REQ_PACKAGES="ca-certificates bzip2 libglib2.0-0 sudo screen python"
BOT_REQ_PACKAGES_VER="1"

### FUNCTIONS
## Function for text output
say()
{
	if [ -z "$1" ] && [ -z "$2" ]; then
		echo
		return
	fi

	# criteria
	CRIT=$(echo $1 | tr '[:lower:]' '[:upper:]')

	# message
	MSG="$2"

	# default prefix
	PREFIX=""

	# modes for echo command
	MODES="-e"
	if [ "$CRIT" == "WAIT" ] || [ "$CRIT" == "QUESTION" ]; then
		MODES="$MODES -n"
	fi

	# color for criterias
	if [ ! -z "$CRIT" ]; then
		# prefix
		PREFIX="[$(date +"%Y-%m-%d %H:%M:%S")] "

		case "$CRIT" in
			ERROR)
				# RED
				CRIT="\e[0;31m$CRIT\e[0;37m"
				;;

			WARNING)
				# YELLOW
				CRIT="\e[0;33m$CRIT\e[0;37m"
				;;

			INFO)
				# CYAN
				CRIT="\e[0;36m$CRIT\e[0;37m"
				;;

			OKAY|QUESTION|WAIT|WELCOME)
				# GREEN
				CRIT="\e[0;32m$CRIT\e[0;37m"
				;;

			DEBUG)
				# PURPLE
				CRIT="\e[0;35m$CRIT\e[0;37m"
				;;

			*)
				# WHITE
				CRIT="\e[0;37m$CRIT"
				;;
		esac
	fi

	echo -ne "\e[40m"
	# echo message
	if [ ! -z "$CRIT" ]; then
		# if $CRIT is set...
		echo $MODES "$PREFIX[$CRIT] $MSG"
	else
		# if $CRIT is NOT set...
		echo $MODES "$PREFIX$MSG"
	fi
	echo -ne "\e[0m"
}

pause()
{
	say "wait" "Press [ENTER] to continue..."
	read -p "" < /proc/${PPID}/fd/0
	# workaround with /proc/[...] required only when read command
	# is in a function. When not given, the script may not wait
	# for an entered answer.
}

## Function for welcome header
show_welcome()
{
	say
	say "welcome" "================================================"
	say "welcome" "= HELLO! Please invest some time to read this. ="
	say "welcome" "=                                              ="
	say "welcome" "=  Thanks for using this diagnostic script!    ="
	say "welcome" "=  The more information you provide, the       ="
	say "welcome" "=  better we can help to solve your problem.   ="
	say "welcome" "=                                              ="
	say "welcome" "=  The execution may take some moments to      ="
	say "welcome" "=  collection the most important information   ="
	say "welcome" "=  of your system and your bot installation.   ="
	say "welcome" "=                                              ="
	say "welcome" "=  After everything is done, you will get a    ="
	say "welcome" "=  diagnostic output, ready for copy & pasting ="
	say "welcome" "=  it within a CODE-tag in the Sinusbot forum. ="
	say "welcome" "=  [Link: https://forum.sinusbot.com]          ="
	say "welcome" "=                                              ="
	say "welcome" "=  No private information will be collected    ="
	say "welcome" "=  nor the data will be sent to anywhere.      ="
	say "welcome" "=  This just generates an example forum post.  ="
	say "welcome" "=                                              ="
	say "welcome" "=  The script does perform a DNS resolution    ="
	say "welcome" "=  of 'google.com' to determine if your DNS    ="
	say "welcome" "=  settings are working as expected.           ="
	say "welcome" "================================================"
	say
	pause
}

show_help()
{
	say "info" "Available parameters:"
	say "info" "  -h|--help                 This help."
	say "info" "  -w|--no-welcome           Skips the welcome screen."
	say "info" "  -u|--no-os-update-check   Skips the OS updates check."
	say "info" "  -c|--credits              Show credits."
	say "info" "  -v|--version              Show version."
	say "info" "This tool has Super Cow Powers."
}

show_version()
{
	say "info" "(C) $SCRIPT_YEAR, $SCRIPT_AUTHOR_NAME ($SCRIPT_AUTHOR_WEBSITE)"
	say "info" "$SCRIPT_NAME v$SCRIPT_VERSION_NUMBER [$SCRIPT_VERSION_DATE]"
	say "info" "Project site: $SCRIPT_PROJECT_SITE"
}

show_credits()
{
	say "info" "THANKS TO..."
	say "info" "  \e[1mflyth\e[0;37m, Michael F.        for developing sinusbot, testing this script and ideas"
	say "info" "  \e[1mXuxe\e[0;37m, Julian H.          for testing"
	say "info" "  \e[1mGetMeOutOfHere\e[0;37m           for testing and ideas"
	say "info" "  \e[1mJANNIX\e[0;37m, Jan              for testing"
}

show_moo()
{
	cat <<EOF
                 (__)
                 (oo)
           /------\/
          / |    ||
         *  /\---/\\
            ~~   ~~
..."Have you mooed today?"...
EOF
}

## Function when something fails
failed()
{
	say "error" "Something went wrong!"
	say "wait" "Press [ENTER] to exit."
	read -p "" < /proc/${PPID}/fd/0
	if [ ! -z "$1" ]; then
		say "debug" "exit reason code: $1"
	fi
	exit 1
}

## Function for human output
bytes_format()
{
	# This separates the number from the text
	SPACE=" "
	# Convert input parameter (number of bytes)
	# to Human Readable form
	SLIST="B,KB,MB,GB,TB,PB,EB,ZB,YB"
	POWER=1
	VAL=$(echo "scale=2; $1 * 1024" | bc)
	VINT=$(echo $VAL / 1024 | bc )
	while [ $VINT -gt 0 ]
	do
		let POWER=POWER+1
		VAL=$(echo "scale=2; $VAL / 1024" | bc)
		VINT=$(echo $VAL / 1024 | bc )
	done
	echo "$VAL$SPACE$(echo $SLIST | cut -f$POWER -d',')"
}

## Function to confirm a command
confirm_package_install()
{
	say "question" "Should I install '$1' for you? [y/N] "
	read -p "" prompt < /proc/${PPID}/fd/0
	if [[ $prompt =~ [yY](es)* ]]; then
		INSTALL_CMD="apt-get install -y $1"
		say "debug" "Installing package '$1' using '$INSTALL_CMD'..."
		sleep 1
		eval "$INSTALL_CMD"
		if [ $? -ne 0 ]; then
			say "error" "Installing package '$1' went wrong! Check and retry."
			failed "failed package installation"
		else
			return 0
		fi
	else
		return 1
	fi
}

## Function for checking commands
check_command()
{
	if ! which "$1" >/dev/null; then
		if [ -z "$2" ]; then
			say "error" "Missing command '$1'."
			return 1
		else
			say "error" "Missing command '$1'. Please install package '$2': apt-get install $2"
			confirm_package_install $2
			if [ $? -ne 0 ]; then
				return 1
			else
				return 0
			fi
		fi
		return 1
	else
		return 0
	fi
}

## Function for checking if command exists
is_command_available()
{
	if which "$1" >/dev/null; then
		return 0
	else
		return 1
	fi
}

## Function to check root privileges
is_user_root()
{
	if [ $(id -u) -ne 0 ]; then
		say "error" "This diagnostic script must be run as root!"
		failed "no root privileges"
	fi
}

## Function to check if it is a debian-based operating system
is_supported_os()
{
	SYS_OS_LSBRELEASE_ID=$(lsb_release --id --short | tr '[:upper:]' '[:lower:]')
	SYS_OS_LSBRELEASE_RELEASE=$(lsb_release --release --short | tr '[:upper:]' '[:lower:]')
	SYS_OS_LSBRELEASE_DESCRIPTION=$(lsb_release --description --short)

	# check if operating system supported
	if [ "$SYS_OS_LSBRELEASE_ID" != "debian" ] && [ "$SYS_OS_LSBRELEASE_ID" != "ubuntu" ]; then
		say "error" "This script is only working on the operating systems Debian and Ubuntu!"
		failed "unsupported operating system"
	fi

	say "info" "Detected operating system: $SYS_OS_LSBRELEASE_DESCRIPTION"

	# check version of operating system: debian
	if [ "$SYS_OS_LSBRELEASE_ID" == "debian" ] && (( $(echo "$SYS_OS_LSBRELEASE_RELEASE <= 6" | bc -l) )); then
		# is less or equal 6 = too old.
		say "warning" "You are using a too old operating system! Debian Squeeze and before are not officially supported for Sinusbot. Please upgrade to a more recent system."
		sleep 1
	fi

	# check version of operating system: ubuntu
	if [ "$SYS_OS_LSBRELEASE_ID" == "ubuntu" ] && (( $(echo "$SYS_OS_LSBRELEASE_RELEASE <= 12.04" | bc -l) )); then
		# is less or equal 12.04 = too old.
		say "warning" "You are using a too old operating system! Ubuntu 12.04 and before are not officially supported for Sinusbot. Please upgrade to a more recent system."
		sleep 1
	fi
}

## Function to search bot binary
check_bot_binary()
{
	BOT_BINARY=""
	BINARIES="ts3bot sinusbot"
	for BINARY in $BINARIES; do
		if [ -f "$BOT_PATH/$BINARY" ]; then
			BOT_BINARY="$BINARY"
			say "debug" "Binary '$BOT_BINARY' found."
		fi
	done

	if [ -z "$BOT_BINARY" ]; then
		# empty. not found.
		return 1
	else
		return 0
	fi
}

## Function to check if bot config exists
check_bot_config()
{
	if [ ! -f "$BOT_PATH/config.ini" ]; then
		say "error" "Bot configuration not found!"
		failed "bot config not found"
	fi
}

## Function to check available updates via apt-get
check_available_updates()
{
	echo "$(apt-get -s dist-upgrade | awk '/^Inst/ { print $2 }' | wc -l)"
}

## Function to parse bot configuration file
parse_bot_config()
{
	echo $(echo "$BOT_CONFIG" | grep "$1" | cut -d '=' -f2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | sed -e 's/^[\"]*//' -e 's/[\"]*$//')
}

## Function to get version of sinusbot
get_bot_version()
{
	say "debug" "Trying to get sinusbot version using version parameter..." > /proc/${PPID}/fd/0
	BOT_VERSION_CMD=$($BOT_PATH/$BOT_BINARY --version 2>&1)
	echo "$BOT_VERSION_CMD" | grep -q -P '^flag provided but not defined' >/dev/null
	if [ $? -eq 0 ]; then
		say "debug" "Error getting sinusbot version. Falling back to other method." > /proc/${PPID}/fd/0
		BOT_VERSION_STRING=$(strings $BOT_PATH/$BOT_BINARY | grep "Version:" | cut -d ' ' -f2)
		if [ "$BOT_VERSION_STRING" != "" ]; then
			echo "$BOT_VERSION_STRING"
		else
			echo "unknown"
		fi
	else
		BOT_VERSION_CMD=$(echo -e "$BOT_VERSION_CMD" | egrep "^SinusBot" | awk '{ print $2 }')
		echo "$BOT_VERSION_CMD"
	fi
}

## Function to check if package is installed
is_os_package_installed()
{
	dpkg-query -W -f='${Status}' $1 2>&1 | grep -q -P '^install ok installed$' 2>&1
	if [ $? -eq 0 ]; then
		return 0
	else
		return 1
	fi
}

## Function to check if package is installed
is_os_package_installed_check()
{
	if ! is_os_package_installed $1; then
		say "error" "Missing package '$1'. Please install package '$2': apt-get install $2"
		confirm_package_install $2
		if [ $? -eq 0 ]; then
			return 0
		else
			return 1
		fi
	fi
}

## Function to get missing packages from a list
get_missing_os_packages()
{
	OS_PACKAGES_MISSING=""
	for PACKAGE in $1; do
		is_os_package_installed "$PACKAGE"
		if [ $? -ne 0 ]; then
			OS_PACKAGES_MISSING="$OS_PACKAGES_MISSING $PACKAGE"
		fi
	done
	echo $(trim_spaces "$OS_PACKAGES_MISSING")
}

## Function to get installed scripts
get_installed_bot_scripts()
{
	INSTALLED_SCRIPTS=""
	for SCRIPT_FILE in $BOT_PATH/scripts/*; do
		if [ "$INSTALLED_SCRIPTS" == "" ]; then
			INSTALLED_SCRIPTS="$(basename $SCRIPT_FILE)"
		else
			INSTALLED_SCRIPTS="$INSTALLED_SCRIPTS; $(basename $SCRIPT_FILE)"
		fi
	done
	echo $(trim_spaces "$INSTALLED_SCRIPTS")
}

## Function to trim whitespaces before and after a string
trim_spaces()
{
	echo -e "$(echo -e "$@" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
}

## Function to get a md5 hash of a file
get_file_hash()
{
	echo "$(md5sum "$1" | awk '{print $1}')"
}

## Function to check if port is in use
port_in_use()
{
	# check if port $1 is in use.
	netstat -lnt | awk '$4 ~ ".${1}"' | grep -i 'LISTEN' &>/dev/null
	return $?
}

## Function to get user id from a running process id
get_userid_from_pid()
{
	echo "$(grep -r '^Uid:' /proc/$1/status | cut -f2)"
}

## Function to get username by id (linux os)
get_user_name_by_uid()
{
	echo "$(awk -F: "/:$1:/{print \$1}" /etc/passwd)"
}

## Function which exites the script with a successful exit code
script_done()
{
	exit 0
}

## Function to check DNS resolution
check_dns_resolution()
{
	if [ "$(getent hosts $1 | head -n 1 | cut -d ' ' -f 1)" != "" ]; then
		return 0
	else
		return 1
	fi
}

## MAIN CODE

# PARAMETERS
while [ $# -gt 0 ]; do
	case "$1" in
		-w|--no-welcome )
			NO_WELCOME="yes"
		;;

		-u|--no-os-update-check )
			NO_OS_UPD_CHECK="yes"
		;;

		-h|--help )
			show_help
			script_done
		;;

		-c|--credits )
			show_credits
			script_done
		;;

		-v|--version )
			show_version
			script_done
		;;

		moo )
			show_moo
			script_done
		;;

		# unknown parameters
		-*|--* )
			say "warning" "Unknown parameter: '$1'."
		;;
	esac
shift
done

# further checks.
is_user_root

# do not show welcome screen, when user dont want to
if [ "$NO_WELCOME" != "yes" ]; then
	show_welcome
fi

# check if commands are available for the script
REQ_CMDS=0
for SMCMD in $SCRIPT_REQ_CMDS; do
	check_command "$SMCMD"
	if [ $? -ne 0 ]; then
		REQ_CMDS=1
	fi
done

# checking scripts
for SMCMD in $SCRIPT_REQ_CMDS; do
	check_command "$SMCMD"
	if [ $? -ne 0 ]; then
		REQ_CMDS=1
	fi
done

# check if any commands are missing
if [ $REQ_CMDS -ne 0 ]; then
	say "error" "Missing commands... Install and try again please."
	failed "missing commands"
fi

# checking script dependencies
PACKAGES_MISSING=$(get_missing_os_packages "$SCRIPT_REQ_PKGS")
if [ "$PACKAGES_MISSING" != "" ]; then
	say "warning" "Required packages for the script are not installed on this system."
	say "info" "Following packages are missing: $PACKAGES_MISSING"

	say "question" "Should I install them for you now? [y/N] "
	read -p "" prompt < /proc/${PPID}/fd/0
	if [[ $prompt =~ [yY](es)* ]]; then
		INSTALL_CMD="apt-get install -y $PACKAGES_MISSING"
		say "debug" "Installing packages using '$INSTALL_CMD'..."
		sleep 1
		# initiating installation
		eval "$INSTALL_CMD"
		# check if everything worked
		if [ $? -ne 0 ]; then
			say "error" "Installation went wrong! Please install required packages manually!"
			failed "failed package installation for script"
		else
			say "info" "Installation seems to be finished. Please re-run this script now!"
			script_done
		fi
	else
		say "warning" "Installation aborted. Please install the packages yourself before re-starting this script."
		failed "automated script installation aborted"
	fi
fi

# checking bot dependencies
PACKAGES_MISSING=$(get_missing_os_packages "$BOT_REQ_PACKAGES")
if [ "$PACKAGES_MISSING" != "" ]; then
	say "warning" "Required packages for the bot are not installed on this system."
	say "info" "Following packages are missing: $PACKAGES_MISSING"

	say "question" "Should I install them for you now? [y/N] "
	read -p "" prompt
	if [[ $prompt =~ [yY](es)* ]]; then
		INSTALL_CMD="apt-get install -y $PACKAGES_MISSING"
		say "debug" "Installing packages using '$INSTALL_CMD'..."
		sleep 1
		# initiating installation
		eval "$INSTALL_CMD"
		# check if everything worked
		if [ $? -ne 0 ]; then
			say "error" "Installation went wrong! Please install required packages manually!"
			failed "failed package installation for bot"
		else
			say "info" "Installation seems to be finished. Please re-run this script now!"
			script_done
		fi
	else
		say "warning" "Installation aborted. Please install the packages yourself before re-starting the bot."
		failed "automated bot installation aborted"
	fi
fi

# checking if OS is supported after package installation
is_supported_os

# checking dependencies for bot
if [ "$PACKAGES_MISSING" == "" ]; then
	SYS_PACKAGES_MISSING="None (v$BOT_REQ_PACKAGES_VER)"
else
	SYS_PACKAGES_MISSING="Missing packages: $PACKAGES_MISSING"
fi

# current path of script
BOT_PATH=$(pwd)

# bot binary searching
say "debug" "Searching in directory '$BOT_PATH'..."

# checking for bot binary file
check_bot_binary
if [ $? -ne 0 ]; then
	BOT_PATH="/opt/ts3bot/"
	say "warning" "Binary not found in current path. Fallback to default directory."

	if [ ! -d "$BOT_PATH" ]; then
		say "error" "Bot binary not found in default directory!"
		failed "bot binary not found"
	else
		check_bot_binary
		if [ $? -ne 0 ]; then
			say "error" "Bot binary not found! Execute this script in the sinusbot directory!"
			failed "bot binary not found"
		fi
	fi
fi

# if bot dir was found, check config file now
check_bot_config

BOT_FULL_PATH="$(echo "$BOT_PATH/$BOT_BINARY" | sed -e 's|//|/|g')"
BOT_BINARY_HASH=$(get_file_hash "$BOT_PATH/$BOT_BINARY")
BOT_BINARY_HASH_TEXT="(Hash: $BOT_BINARY_HASH)"

# collecting information
say "debug" "Collecting information..."
say "info" "(Scan may take some moments...)"

# system
say "info" "Collecting system information..."
say "debug" "Getting operating system version..."
SYS_OS=$(lsb_release --short --description)
SYS_OS_EXTENDED=""
if [ -f "/proc/user_beancounters" ]; then
	SYS_OS_EXTENDED="(OpenVZ)"
	
elif [ -f "/proc/1/cgroup" ]; then 
	lxc=$(cat /proc/1/cgroup | grep -e '.*\/lxc\/.*')
	if [ lxc != "" ]; then
		SYS_OS_EXTENDED="(Lxc)"
	fi
	
elif [ -f "/.dockerinit" ]; then
	SYS_OS_EXTENDED="(Docker)"
fi

# get load avg
SYS_LOAD_AVG=$(cat /proc/loadavg | cut -d " " -f -3)

# get package manager date
SYS_APT_LASTUPDATE=$(date --date="@$(stat -c %Y '/var/lib/apt/lists')" +"%d.%m.%Y %H:%M:%S %Z %::z")

# get os date
SYS_TIME=$(date +"%d.%m.%Y %H:%M:%S %Z %::z")
SYS_TIME_ZONE=$(cat /etc/timezone)

# get uptime
SYS_UPTIME=$(</proc/uptime)
SYS_UPTIME=${SYS_UPTIME%%.*}
SYS_UP_SECONDS=$(($SYS_UPTIME%60))
SYS_UP_MINUTES=$(($SYS_UPTIME/60%60))
SYS_UP_HOURS=$(($SYS_UPTIME/60/60%24))
SYS_UP_DAYS=$(($SYS_UPTIME/60/60/24))
SYS_UPTIME_TEXT="$SYS_UP_DAYS days, $SYS_UP_HOURS hours, $SYS_UP_MINUTES minutes, $SYS_UP_SECONDS seconds"

# get kernel
SYS_OS_KERNEL=$(uname -srm)

# check if x64 bit os
SYS_OS_ARCH=`getconf LONG_BIT`
if [ "$SYS_OS_ARCH" = "64" ]; then
	SYS_OS_ARCH_X64="Y"
	SYS_OS_ARCH_X64_TEXT="OK"
else
	SYS_OS_ARCH_X64="N"
	SYS_OS_ARCH_X64_TEXT="FAIL: Not x64 OS. [$SYS_OS_ARCH]"
fi

# check dns resolution
check_dns_resolution "google.com"
if [ $? -eq 0 ]; then
	SYS_OS_DNS_CHECK="Y"
	SYS_OS_DNS_CHECK_TEXT="google.com -> OK"
else
	SYS_OS_DNS_CHECK="N"
	SYS_OS_DNS_CHECK_TEXT="google.com -> FAIL"
fi

# get CPU info
say "debug" "Getting processor information..."
SYS_CPU_DATA=$(lscpu | egrep "^(Architecture|CPU\(s\)|Thread\(s\) per core|Core\(s\) per socket:|Socket\(s\)|Model name|CPU MHz|Hypervisor|Virtualization)")
SYS_CPU_DATA=$(echo "$SYS_CPU_DATA" | sed 's/^/    /')

# get os updatesinfo
if [ "$NO_OS_UPD_CHECK" == "yes" ]; then
	SYS_AVAIL_UPDS="unknown"
	SYS_AVAIL_UPDS_TEXT="(check skipped)"
else
	say "debug" "Checking for available operating system updates..."
	SYS_AVAIL_UPDS=$(check_available_updates)
	if [ "$SYS_AVAIL_UPDS" -gt 0 ]; then
		SYS_AVAIL_UPDS_TEXT="(updates available!)"
	else
		SYS_AVAIL_UPDS_TEXT="(well done!)"
	fi
fi

# get ram/memory info
say "debug" "Getting RAM information..."
SYS_RAM_FIELD=$(free | grep Mem | sed 's/ \+/ /g')
SYS_RAM_TOTAL=$(echo "$SYS_RAM_FIELD" | cut -d " " -f2)
SYS_RAM_CACHED=$(echo "$SYS_RAM_FIELD" | cut -d " " -f7)
SYS_RAM_USAGE=$(($(echo "$SYS_RAM_FIELD" | cut -d " " -f3) - $SYS_RAM_CACHED))
SYS_RAM_PERNT=$(($SYS_RAM_USAGE * 10000 / $SYS_RAM_TOTAL / 100))

# get swap info
say "debug" "Getting SWAP information..."
SYS_SWAP_FIELD=$(free | grep Swap | sed 's/ \+/ /g')
SYS_SWAP_TOTAL=$(echo "$SYS_SWAP_FIELD" | cut -d " " -f2)
SYS_SWAP_USAGE=$(echo "$SYS_SWAP_FIELD" | cut -d " " -f3)
SYS_SWAP_PERNT=$(($SYS_SWAP_USAGE * 10000 / $SYS_SWAP_TOTAL / 100))

# get disk data
# check if the machine is a OpenVZ container
say "debug" "Getting DISK information..."
if [ -f "/proc/user_beancounters" ]; then
	# yes, so count it including simfs
	SYS_DISK_PARMS="-t ext4 -t ext3 -t ext2 -t reiserfs -t jfs -t ntfs -t fat32 -t btrfs -t fuseblk -t simfs"
else
	# if not, then no simfs
	SYS_DISK_PARMS="-t ext4 -t ext3 -t ext2 -t reiserfs -t jfs -t ntfs -t fat32 -t btrfs -t fuseblk"
fi

SYS_DISK_FIELD=$(df -Tl --total $SYS_DISK_PARMS | grep total | sed 's/ \+/ /g')
SYS_DISK_TOTAL=$(echo "$SYS_DISK_FIELD" | cut -d " " -f5)
SYS_DISK_USAGE=$(echo "$SYS_DISK_FIELD" | cut -d " " -f4)
SYS_DISK_PERNT=$(($SYS_DISK_USAGE * 10000 / $SYS_DISK_TOTAL / 100))

# collecting bot info
say "info" "Collecting bot information..."
BOT_VERSION=$(get_bot_version)
BOT_CONFIG=""
if [ -z "$BOT_CONFIG" ]; then
	say "debug" "Loading bot config file..."
	BOT_CONFIG=$(cat "$BOT_PATH/config.ini")
fi

# get bot status
say "debug" "Determining bot status..."
BOT_STATUS="unknown"
BOT_STATUS_EXTENDED=""

BOT_STATUS_PIDS=$(pidof "$BOT_PATH/$BOT_BINARY")
if [ "$BOT_STATUS_PIDS" == "" ]; then
	BOT_STATUS="not running"
else
	BOT_STATUS_PID_FIRST="$(echo "$BOT_STATUS_PIDS" | awk '{ print $1 }')"
	BOT_STATUS_PID_USER_ID="$(get_userid_from_pid "$BOT_STATUS_PID_FIRST")"
	BOT_STATUS_PID_USER_NAME="$(get_user_name_by_uid "$BOT_STATUS_PID_USER_ID")"

	BOT_STATUS="running"
	BOT_STATUS_EXTENDED="(PIDs: $BOT_STATUS_PIDS, User: $BOT_STATUS_PID_USER_NAME)"
fi

# check webinterface
say "debug" "Reading ListenPort from bot configuration..."
BOT_WEB_STATUS="unknown"
BOT_CONFIG_WEB_PORT=$(parse_bot_config "ListenPort")
if [ "$BOT_CONFIG_WEB_PORT" == "" ]; then
	BOT_WEB_STATUS_EXTENDED="(Port not set?)"
else
	if port_in_use "127.0.0.1" "$BOT_CONFIG_WEB_PORT"; then
		BOT_WEB_STATUS="port locally reachable"
	else
		BOT_WEB_STATUS="port locally not reachable"
	fi
	BOT_WEB_STATUS_EXTENDED="(Port: $BOT_CONFIG_WEB_PORT)"
fi

# check autostart script for bot
SYS_BOT_AUTOSTART="unknown"
SYS_BOT_AUTOSTART_EXTENDED=""

SYS_BOT_AUTOSTART_PATHS="/etc/init.d/sinusbot"
for SYS_BOT_AUTOSTART_PATH in $SYS_BOT_AUTOSTART_PATHS; do
	if [ -f "$SYS_BOT_AUTOSTART_PATH" ]; then
		SYS_BOT_AUTOSTART="found at $SYS_BOT_AUTOSTART_PATH"
		SYS_BOT_AUTOSTART_PERMS="$(stat "$SYS_BOT_AUTOSTART_PATH" | sed -n '/^Access: (/{s/Access: (\([0-9]\+\).*$/\1/;p}')"
		if [ $SYS_BOT_AUTOSTART_PERMS -le 0755 ]; then
			say "warning" "Please set the permissions of your autostart script at '$SYS_BOT_AUTOSTART_PATH' from $SYS_BOT_AUTOSTART_PERMS to 0755, using: chmod 0755 $SYS_BOT_AUTOSTART_PATH"
		fi
		SYS_BOT_AUTOSTART_EXTENDED="[perms: $SYS_BOT_AUTOSTART_PERMS]"
		break
	else
		SYS_BOT_AUTOSTART="not found"
	fi
done

# get installed scripts
say "debug" "Getting installed bot scripts..."
BOT_INSTALLED_SCRIPTS=$(get_installed_bot_scripts)

# getting log level
say "debug" "Reading LogLevel from bot configuration..."
BOT_CONFIG_LOGLEVEL=$(parse_bot_config "LogLevel")
BOT_CONFIG_LOGLEVEL_EXTENDED=""
if [ "$BOT_CONFIG_LOGLEVEL" == "10" ]; then
	BOT_CONFIG_LOGLEVEL_EXTENDED="(debug log active)"
fi

# getting ts3path
say "debug" "Reading TS3Path from bot configuration..."
BOT_CONFIG_TS3PATH=$(parse_bot_config "TS3Path")
BOT_CONFIG_TS3PATH_EXTENDED=""

BOT_TS3_PLUGIN="unknown"
BOT_TS3_PLUGIN_EXTENDED="(TS3client not found)"
BOT_TS3_PLUGIN_HASH_TS3CLIENT="unknown"
BOT_TS3_PLUGIN_HASH_BOTPLUGIN="unknown"

if [ -f "$BOT_CONFIG_TS3PATH" ]; then
	BOT_CONFIG_TS3PATH_DIRECTORY=$(dirname "$BOT_CONFIG_TS3PATH")
	# trying to get ts3client version
	say "debug" "Trying to get ts3client version..."
	if [ -f "$BOT_CONFIG_TS3PATH_DIRECTORY/CHANGELOG" ]; then
		BOT_CONFIG_TS3PATH_VERSION=$(cat "$BOT_CONFIG_TS3PATH_DIRECTORY/CHANGELOG" | awk 'match($0, /\=== Client Release (.*)/) { print $4 };' | awk 'NR==1')
		BOT_CONFIG_TS3PATH_EXTENDED="(Version $BOT_CONFIG_TS3PATH_VERSION)"
	else
		BOT_CONFIG_TS3PATH_EXTENDED="(CHANGELOG file not found!)"
	fi

	# checking bot plugin in ts3client
	say "debug" "Checking installation of bot plugin in ts3client..."
	if [ -f "$BOT_CONFIG_TS3PATH_DIRECTORY/plugins/libsoundbot_plugin.so" ]; then
		if [ -f "$BOT_PATH/plugin/libsoundbot_plugin.so" ]; then
			BOT_TS3_PLUGIN="installed"
			BOT_TS3_PLUGIN_HASH_TS3CLIENT="$(get_file_hash "$BOT_CONFIG_TS3PATH_DIRECTORY/plugins/libsoundbot_plugin.so")"
			BOT_TS3_PLUGIN_HASH_BOTPLUGIN="$(get_file_hash "$BOT_PATH/plugin/libsoundbot_plugin.so")"
			if [ "$BOT_TS3_PLUGIN_HASH_BOTPLUGIN" == "$BOT_TS3_PLUGIN_HASH_TS3CLIENT"  ]; then
				BOT_TS3_PLUGIN_EXTENDED="(md5 hash match)"
			else
				BOT_TS3_PLUGIN_EXTENDED="(md5 hash mismatch!)"
			fi
		else
			BOT_TS3_PLUGIN="installed"
			BOT_TS3_PLUGIN_EXTENDED="(plugin in bot directory not found)"
		fi
	else
		BOT_TS3_PLUGIN="not installed"
		BOT_TS3_PLUGIN_EXTENDED=""
	fi

else
	BOT_CONFIG_TS3PATH_EXTENDED="(TS3client-binary does not exist!)"
fi

# checking for youtube-dl
say "debug" "Checking for 'youtube-dl'..."
BOT_CONFIG_YTDLPATH=$(parse_bot_config "YoutubeDLPath")
if [ "$BOT_CONFIG_YTDLPATH" == "" ]; then
	BOT_CONFIG_YTDLPATH="not set"
	BOT_CONFIG_YTDLPATH_EXTENDED=""

	# check anyway, maybe the binary is installed anyway but just not set
	if [ -f "$(which youtube-dl)" ]; then
		YTDL_VERSION=$($(which youtube-dl) --version)
		BOT_CONFIG_YTDLPATH_EXTENDED="(does exist anyway, version: $YTDL_VERSION)"
	fi

else
	if [ -f "$BOT_CONFIG_YTDLPATH" ]; then
		YTDL_VERSION=$($BOT_CONFIG_YTDLPATH --version)
		BOT_CONFIG_YTDLPATH_EXTENDED="(does exist, version: $YTDL_VERSION)"
	else
		BOT_CONFIG_YTDLPATH_EXTENDED="(does not exist!)"
	fi
fi

# generate output
say "debug" "Generating output..."

OUTPUT=$(cat << EOF
==========================================================
SINUSBOT RELATED
SYSTEM INFORMATION
 - Operating System: $SYS_OS $SYS_OS_EXTENDED
 - OS x64 check: $SYS_OS_ARCH_X64_TEXT
 - Kernel: $SYS_OS_KERNEL
 - Load Average: $SYS_LOAD_AVG
 - Uptime: $SYS_UPTIME_TEXT
 - OS Updates: $SYS_AVAIL_UPDS $SYS_AVAIL_UPDS_TEXT
 - OS Missing Packages: $SYS_PACKAGES_MISSING
 - OS APT Last Update: $SYS_APT_LASTUPDATE
 - Bot Start Script: $SYS_BOT_AUTOSTART $SYS_BOT_AUTOSTART_EXTENDED
 - DNS resolution check: $SYS_OS_DNS_CHECK_TEXT
 - CPU:
$SYS_CPU_DATA
 - RAM: $(bytes_format $SYS_RAM_USAGE)/$(bytes_format $SYS_RAM_TOTAL) in use (${SYS_RAM_PERNT}%)
 - SWAP: $(bytes_format $SYS_SWAP_USAGE)/$(bytes_format $SYS_SWAP_TOTAL) in use (${SYS_SWAP_PERNT}%)
 - DISK: $(bytes_format $SYS_DISK_USAGE)/$(bytes_format $SYS_DISK_TOTAL) in use (${SYS_DISK_PERNT}%)
 - Report date: $SYS_TIME (timezone: $SYS_TIME_ZONE)

BOT INFORMATION
 - Status: $BOT_STATUS $BOT_STATUS_EXTENDED
 - Webinterface: $BOT_WEB_STATUS $BOT_WEB_STATUS_EXTENDED
 - Binary: $BOT_FULL_PATH $BOT_BINARY_HASH_TEXT
 - Version: $BOT_VERSION
 - TS3 Plugin: $BOT_TS3_PLUGIN $BOT_TS3_PLUGIN_EXTENDED
   - Bot Plugin: $BOT_TS3_PLUGIN_HASH_BOTPLUGIN
   - TS3 Client: $BOT_TS3_PLUGIN_HASH_TS3CLIENT
 - Config:
   - LogLevel = $BOT_CONFIG_LOGLEVEL $BOT_CONFIG_LOGLEVEL_EXTENDED
   - TS3Path = $BOT_CONFIG_TS3PATH $BOT_CONFIG_TS3PATH_EXTENDED
   - YoutubeDLPath = $BOT_CONFIG_YTDLPATH $BOT_CONFIG_YTDLPATH_EXTENDED
 - Installed Scripts: $BOT_INSTALLED_SCRIPTS
==========================================================
EOF
)

# new lines and the finished output
say
say

say "" "\e[1mPlease attach this output to your forum post:\e[0;37m"
say "" "[CODE]"
say "" "$OUTPUT"
say "" "[/CODE]"
say "" "\e[1mNotice\e[0;37m: For a better overview, post this data
in the forum within a CODE-tag!"

say
say

say "debug" "Done."

# we are done.
script_done
