#!/bin/bash

# Lib to gather a lot of usefull bash functions to be used in custom scripts
DEBUG=0
MEDIA_STYLE="1;33"
DATE_STYLE="1;34"
ERROR_STYLE="1;31"

# Display messages

function no_stderr {
	$@ 2>/dev/null
}
function no_stdout {
	$@ 1>/dev/null
}
function no_output {
	$@ 1>/dev/null 2>/dev/null
}

# <header> <msg>		or		<msg>
function progress_msg {
	if [ $# -gt 1 ] ; then
	    echo -e "\033[1;36m$1>\033[0m $@"
	else
	    echo -e "\033[1;36m$1\033[0m"
	fi
}

# <error msg>
function error_msg {
    echo -e "\033[${ERROR_STYLE}mError: \033[0m$1"
}

# Usefull display functions

function print_date {
    var=$(date +%H:%M:%S)
    echo -e "\033[${DATE_STYLE}m${var}\033[0m"
}

# User interactions

# <question>
function ask_yes_no {
	echo "$1 [y/n]"
	read answer
	if [[ "$answer" =~ ^([yY][eE][sS]|[yY])$ ]]
	then
		return 0;
	else
		return 1;
	fi
}

# Filesystem management

# <dir>
function list_directories {
	echo "$(no_stderr ls -d $1/*/)" | awk -F/ '{print $(NF-1)}'
}

# <path>
function get_abs_dir {
	realpath $(dirname $1)
}

# <dir to search> <name to search> <dir to copy>
function find_and_copy {
    FOUND_FILES=$(find $1 -name "$2")
    if [ ! -z "$FOUND_FILES" ] ; then
        cp $FOUND_FILES $3
    fi
}

# Git repositories management

# <dir>
function is_git_repo {
	test -d $1/.git
}

function check_inside_git_repo {
	test ! $(no_output git status)
}

function get_current_branch {
	git branch |grep '*'|cut -d ' ' -f 2
}

# Execute inside git repo
# <reference to compare>
function echo_git_changes {
	if ! check_inside_git_repo; then
		echo "Not in git repo"
		return
	fi
	fchange=$(git diff --name-only HEAD)
	fchange="$(git diff --name-only $1 HEAD) $(git diff --name-only)"
	echo $fchange
    for f in $fchange; do
        if [ ! -f $f ] ; then
            echo -e "$f | Not found"
            continue
        fi
        echo -e "$(git diff --staged --stat $f | head -n 1)"
    done

}

# Custom script initialisation

function test_dep {
	if ! no_output dpkg -s $1; then
		echo "Dependency $1 need to be installed"
		echo -e "\tsudo apt install $1"
		return 1;
	fi
	return 0;
}

# Filter inputs

# <blacklist> [input]
function purge_list {
	BLACKLIST="$1"
	shift
    for el in "$@" ; do
        if [ -f $el ] ; then
            if [[ "$BLACKLIST" == *"$el"* ]]; then
                continue;
            fi
            echo "$el"
        fi
    done
}

# Misc
function random_uuid {
	python -c "import uuid; u=uuid.uuid4(); print('UUID: ' + str(u)); \
	   n = [', 0x'] * 11; \
	   n[::2] = ['{:12x}'.format(u.node)[i:i + 2] for i in range(0, 12, 2)]; \
	   print('\n#define UUID { ' + \
			 '0x{:08x}'.format(u.time_low) + ', ' + \
			 '0x{:04x}'.format(u.time_mid) + ', ' + \
			 '0x{:04x}'.format(u.time_hi_version) + ', { ' + \
			 '0x{:02x}'.format(u.clock_seq_hi_variant) + ', ' + \
			 '0x{:02x}'.format(u.clock_seq_low) + ', ' + \
			 '0x' + ''.join(n) + '} }')"
}
