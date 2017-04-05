
# This file is included by the top-level script.
# Do not try to run it on its own, it won't help you.

ARG="$1"
HERE="$(pwd)"
TEMPFILE=/tmp/zendtopatching
ARCH="$(uname -m)"
# This tomfoolery is to handle people doing "sudo install.sh"
# which is just WRONG.
SRCSTORE="$( eval echo "~root" )"
SRCSTORE="$SRCSTORE/zendto-build-store"

# Tell the user what is happening, in bold
shout() {
  echo -e '\033[1m'"$*"'\033[0m'
}

# Wait a bit. Optional arg is number of seconds. Default=4
# If we are running with --defaults, only wait 2 seconds ever.
pause() {
  SECS="$1"
  if [ "x$SECS" = "x" ]; then
    SECS=4
  fi
  if [ "x$ALLDEFAULTS" = "xy" ]; then
    SECS=2
  fi
  while [ $SECS -gt 0 ];
  do
    echo -ne '\033[1mPausing '$SECS'\033[0m'
    sleep 1
    echo -ne '\015\033[2K'
    SECS=$((SECS-1))
  done
}

# Check I am root!
shout ' '
IAM="$( id -nu )"
if [ "x$IAM" = "xroot" ]; then
  shout "Good, I am root. Bow down before me..."
  shout " "
else
  shout "Sorry, this script must be run as root."
  shout "Please become root with 'sudo su -' or"
  shout "'su -' and then run this again."
  exit 1
fi

# Process the optional '--defaults' command-line argument.
if [ "x$ARG" = "x--defaults" ]; then
  # We were told what to do.
  ALLDEFAULTS=y
  shout ' '
  shout 'Warning: About to install with all defaults.'
  shout 'Press Ctrl-C now if you did not intend this.'
  pause
else
  # Only set it to no if it isn't already defined.
  # That way if we're running a sub-script, we leave it alone.
  if [ "x$ALLDEFAULTS" = "x" ]; then
    ALLDEFAULTS=n
  fi
fi

# Prompt the user for a response. Pass in
# 1. prompt string
# 2. default default value to be used if the default is blank
# 3. default value (what we guess it should be)
# Call it like the examples below.
prompt() {
  PROMPT="$1"
  DEFDEF="$2"
  DEF="$3"

  if [ "x$DEF" = "x" ]; then
    DEF="$DEFDEF"
  fi

  if [ "$ALLDEFAULTS" = "y" ]; then
    echo -e "\033[1m$PROMPT [Default is $DEF]:\033[0m $DEF" 1>&2
    ANSWER="$DEF"
  else
    echo -ne "\033[1m$PROMPT [Default is $DEF]:\033[0m " 1>&2
    read ANSWER
    if [ "x$ANSWER" = "x" ]; then
      ANSWER="$DEF"
    fi
  fi

  echo "$ANSWER"
}

# Ask a yes/no question. Return true (0) if they said yes, 1 otherwise.
# Pass in the prompt and the default to offer ('y' or 'n').
# Returns true (0) if they said yes. False (1) otherwise.
yesno() {
  YPROMPT="$1"
  YDEFAULT="$2"

  YANSWER=''
  while [ "x$YANSWER" != "xn" -a "x$YANSWER" != "xy" ]
  do
    YANSWER="$(prompt "$YPROMPT (y/n)" "y" "$YDEFAULT" )"
    # Turn anything into a single lower-case letter
    YANSWER="$(echo "$YANSWER" | cut -c 1 | tr '[:upper:]' '[:lower:]' )"
  done
  if [ "x$YANSWER" = "xy" ]; then
    return 0
  fi
  return 1
}

# Run a script if they answer yes to the question.
# Pass in the prompt and the name of the script to run.
# Don't try to do anything clever on the command-line of the script,
# this function is VERY simple.
runIfYes() {
  RPROMPT="$1"
  RSCRIPT="$2"

  if yesno "$RPROMPT" "y"; then
    # Run the script and return true if it succeeded
    $RSCRIPT && return 0
    # We ran it but it failed. Probably want to bail out.
    return 1
  fi
  # They didn't want to run it. Fine, their choice.
  return 0
}

# Is this an rpm/yum-based system?
isyum() {
    if [ -x /bin/yum -o -x /usr/bin/yum ]; then
      return 0
    else
      return 1
    fi
}

# Is this an apt-based system?
isapt() {
    if [ -x /usr/bin/apt -o -x /usr/bin/apt-get ]; then
      return 0
    else
      return 1
    fi
}

#
# Give the user some hints
#
shout ' '
shout 'Output from the ZendTo installer itself will look like this.'
shout ' '
shout 'When you are prompted for a value, always just press Return'
shout 'to accept the default value suggested, unless either'
shout 'a) you are absolutely sure of what you are doing'
shout 'or'
shout 'b) it is blank or clearly rubbish, which usually means'
shout '   something has gone wrong. If that happens, look back'
shout '   through the output and see if you want work it out.'
shout '   No installer is 100% perfect in all situations.'
shout ' '
pause 6

# Work out what OS and release we are running.
# This has to go here as it needs the prompt() function, and $OS[VER]
# are used in the installSrpmAndDeps function.
OS=unknown
OSRELEASE=/etc/redhat-release
if [ -f $OSRELEASE ]; then
  if grep -q 'Red *Hat' $OSRELEASE; then
    OS=redhat
  elif grep -q 'CentOS' $OSRELEASE; then
    OS=centos
  fi
  if isyum; then
    rpm -q --quiet perl || {
      shout Just going to install Perl...
      yum -y install perl
    }
    rpm -q --quiet wget || {
      shout Just going to install wget...
      yum -y install wget
    }
  fi
  OSVERFULL="$( perl -pe 's/^[^\d]+([\d.]+).*?$/$1/' < $OSRELEASE )"
  OSVER="$( echo "$OSVERFULL" | cut -d. -f1 )"
fi
if [ "$OS" = "unknown" ]; then
  OSRELEASE=/etc/debian_version
  if [ -f $OSRELEASE -a -x /usr/bin/lsb_release ]; then
    # Should give me the string "ubuntu"
    OS="$( lsb_release --id | sed -e 's/^.*:\s*//' | tr '[:upper:]' '[:lower:]' )"
    OSVER="$( lsb_release --release | sed -e 's/^.*:\s*\([0-9]*\)\..*$/\1/' )"
  fi
fi

if [ "$OS" = "unknown" ]; then
  OS="$(prompt "Am I running redhat, centos or ubuntu" "centos" "$OS")"
  OS="$(echo "$OS" | tr '[:upper:]' '[:lower:]')" # Lower-case it
fi
OSVER="$(prompt "$OS major release number" "5" "$OSVER")"
ARCH="$(prompt "Architecture" "x86_64" "$ARCH")"
shout "I am running $OS release $OSVER on $ARCH"

# Is SELinux installed?
# If so, is it enabled?
# And what policy is it using?
# May need to install policycoreutils on Ubuntu
if sestatus >/dev/null 2>&1; then
  SELINUX="$(sestatus | grep -i 'selinux status:' | awk '{ print $NF }' | tr '[:upper:]' '[:lower:]')"
  #SELINUX="$(prompt "SELinux status" "enabled" "$SELINUX")"
  if [ "x$SELINUX" = "xdisabled" ]; then
    SELINUXPOLICY=none
  else
    if [ "$OS" = "ubuntu" ]; then
      shout Installing packages needed for SELinux management
      apt-get -y policycoreutils
    elif [ "$OSVER" -ge "6" ]; then
      # CentOS or RedHat
      # SELinux on 6 and above needs semanage and other tools,
      # which aren't installed by default
      rpm -q --quiet policycoreutils-python || {
        shout Installing packages needed for SELinux management
        yum -y install policycoreutils-python
      }
    fi
    SELINUXPOLICY="$(sestatus | egrep -i 'Policy from config file:|Loaded policy name:' | awk '{ print $NF }')"
    SELINUXPOLICY="$(prompt "SELinux policy" "targeted" "$SELINUXPOLICY")"
  fi
else
  SELINUX=disabled
  SELINUXPOLICY=none
fi

# Install an SRPM file and then all the dependencies that it needs
# installed before we can build it.
# Pass in the path of the SRPM file and the path of the .spec file.
installSrpmAndDeps() {
  SRPM="$1"
  SPEC="$2"

  rpm -Uvh "$SRPM" 2> >(grep -iv 'warning:.*does not exist')
  pause
  if [ "$OS$OSVER" = "redhat5" ]; then
    # yum-builddep on RHEL5 cannot open the php53 SRPM,
    # so we have to do it by hand :-(
    REQS=$(grep '^BuildRequires' "$SPEC" | \
           cut -d\  -f2- | \
           perl -pe 's/ *[<=>]+ *[0-9._-]+//g; s/, */\n/g;')
    if [ "x$REQS" = "x" ]; then
      shout "Failed to find list of required packages for building $SRPM."
      REQS="$( prompt "List of packages required to build $SRPM" "" "$REQS" )"
      REQS="$( echo "$REQS" | perl -pe 's/[, ]+/ /g;' )"
    fi
    pause
    shout "Going to fetch these packages as pre-requisites for building $SRPM:"
    shout "$REQS"
    pause
    yum -y install $REQS
    pause
  else
    # And for everyone else except RHEL5...
    #
    # Well, okay, this doesn't actually work on RHEL7.
    # But it does if you manually install all the nasty deps first.
    # And I ain't writing a recursive script to handle deps of deps of deps...
    yum-builddep -y "$SRPM"
  fi
}

# Set a value in files that look like "key = value".
# Pass in the filename, start-of-comment-character, key-name and new value.
# It will replace the last uncommented setting for the key if there is one.
# Otherwise it will replace the last commented-out setting for the key if there is one.
# Otherwise it will add it to the end of the file.
# N.B. This function does NOT take a backup of the file, it overwrites it.
setCfIni() {
  FILE="$1"
  SEP="$2"
  KEY="$3"
  NEWVALUE="$4"
  
  LASTCOMMENTLINE="$( grep -En "^${SEP} *${KEY}($| *=)" "$FILE" | tail -1 | cut -d: -f1 )"
  LASTUNCOMMENTLINE="$( grep -En "^${KEY} *=" "$FILE" | tail -1 | cut -d: -f1 )"

  if [ "x$LASTUNCOMMENTLINE" != "x" ]; then
    LINENUM="$LASTUNCOMMENTLINE"
  elif [ "x$LASTCOMMENTLINE" != "x" ]; then
    LINENUM="$LASTCOMMENTLINE"
  else
    LINENUM=last
  fi

  if [ "$LINENUM" = "last" ]; then
    shout "Appended: $KEY = $NEWVALUE"
    echo "$KEY = $NEWVALUE" >> "$FILE"
  else
    shout "Replaced line $LINENUM: $KEY = $NEWVALUE"
    sed -i -e "$LINENUM c \\$KEY = $NEWVALUE" "$FILE"
  fi
}

# Set a value in php.ini files. (These use ';' to mark start of a comment)
# Pass in the filename, key-name and new value.
# N.B. This function does NOT take a backup of the file, it overwrites it.
setphpini() {
  FILE="$1"
  KEY="$2"
  NEWVALUE="$3"

  setCfIni "$FILE" ';' "$KEY" "$NEWVALUE"
}

# Set a value in Postfix main.cf files. (These use '#' to mark start of a comment)
# Pass in the filename, key-name and new value.
# N.B. This function does NOT take a backup of the file, it overwrites it.
setmaincf() {
  FILE="$1"
  KEY="$2"
  NEWVALUE="$3"

  setCfIni "$FILE" '#' "$KEY" "$NEWVALUE"
}

# Set an SELinux boolean and tell the user what we have set to what
# Pass in the boolean name and the value.
setBool() {
  BOOL="$1"
  TRUEFALSE="$2"

  shout "$BOOL" = "$TRUEFALSE"
  setsebool -P "$BOOL" "$TRUEFALSE"
}

# Mark that we have sourced this file.
ZTFUNCTIONS=1

#
# These are all the things we need to export to subsequent parts of the install.
#
export HERE TEMPFILE ARCH SRCSTORE OS OSVER SELINUX SELINUXPOLICY ZTFUNCTIONS ALLDEFAULTS
export -f shout prompt yesno runIfYes pause installSrpmAndDeps
export -f isyum isapt setCfIni setphpini setmaincf setBool

