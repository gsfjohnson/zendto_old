#!/bin/bash

# Setup firewall for Apache

# If we haven't read functions.sh by now, then read it
if [ "x$ZTFUNCTIONS" = "x" ]; then
  if [ -f lib/functions.sh ]; then
    . lib/functions.sh
  elif [ -f ../lib/functions.sh ]; then
    cd ..
    . lib/functions.sh
  else
    echo 'Sorry, I need to be able to source functions.sh first.'
    echo Exiting...
    exit 1
  fi
fi

shout
shout =================================================================
shout
shout Configure firewall to allow in http and https traffic
shout
shout =================================================================
shout
pause

if [ "$OSVER" -ge "7" ]; then
  #
  # 7
  #
  if rpm --quiet -q firewalld; then
    shout Adding firewall holes for http and https
    firewall-cmd --permanent --add-service http --add-service https
    shout Reloading firewall policy
    firewall-cmd --reload
  fi
elif [ "$OSVER" = "6" ]; then
  #
  # 6
  #
  # IPv4
  if rpm --quiet -q iptables; then
    shout Adding IPv4 firewall holes for http and https
    N="$(iptables -L INPUT -n --line-numbers | egrep '(DROP|REJECT)\s*all' | tail -1 | awk '{ print $1 }')"
    if [ "x$N" = "x" ]; then
        # There is no REJECT rule
        WHERE="-A INPUT"
    else
        # Go just above the last REJECT rule
        WHERE="-I INPUT $N"
    fi
    iptables $WHERE -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
    iptables $WHERE -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
    shout Saving IPv4 firewall policy
    /etc/init.d/iptables save
  fi
  # IPv6
  if rpm --quiet -q iptables-ipv6; then
    shout Adding IPv6 firewall holes for http and https
    N="$(ip6tables -L INPUT -n --line-numbers | egrep '(DROP|REJECT)\s*all' | tail -1 | awk '{ print $1 }')"
    if [ "x$N" = "x" ]; then
        # There is no REJECT rule
        WHERE="-A INPUT"
    else
        # Go just above the last REJECT rule
        WHERE="-I INPUT $N"
    fi
    ip6tables $WHERE -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
    ip6tables $WHERE -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
    shout Saving IPv6 firewall policy
    /etc/init.d/ip6tables save
  fi
else
  #
  # 5
  #
  # IPv4
  if rpm --quiet -q iptables; then
    shout Adding IPv4 firewall holes for http and https
    RH_RULE="$(iptables -L INPUT -n --line-numbers | grep -i 'RH-Firewall-1-INPUT\s*all' | tail -1 | awk '{ print $1 }')"
    REJECT_RULE="$(iptables -L INPUT -n --line-numbers |egrep '(DROP|REJECT)\s*all' | tail -1 | awk '{ print $1 }')"
    if [ "x$RH_RULE" != "x" ]; then
        # If RH_RULE exists, go just above it
        WHERE="-I INPUT $RH_RULE"
    elif [ "x$REJECT_RULE" != "x" ]; then
        # Else If REJECT_RULE exists, go just above that
        WHERE="-I INPUT $REJECT_RULE"
    else
        # Else APPEND
        WHERE="-A INPUT"
    fi
    iptables $WHERE -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
    iptables $WHERE -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
    shout Saving IPv4 firewall policy
    /etc/init.d/iptables save
  fi
  # IPv6
  if rpm --quiet -q iptables-ipv6; then
    shout Adding IPv6 firewall holes for http and https
    RH_RULE="$(ip6tables -L INPUT -n --line-numbers | grep -i 'RH-Firewall-1-INPUT\s*all' | tail -1 | awk '{ print $1 }')"
    REJECT_RULE="$(ip6tables -L INPUT -n --line-numbers |egrep '(DROP|REJECT)\s*all' | tail -1 | awk '{ print $1 }')"
    if [ "x$RH_RULE" != "x" ]; then
        # If RH_RULE exists, go just above it
        WHERE="-I INPUT $RH_RULE"
    elif [ "x$REJECT_RULE" != "x" ]; then
        # Else If REJECT_RULE exists, go just above that
        WHERE="-I INPUT $REJECT_RULE"
    else
        # Else APPEND
        WHERE="-A INPUT"
    fi
    ip6tables $WHERE -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
    ip6tables $WHERE -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
    shout Saving IPv6 firewall policy
    /etc/init.d/ip6tables save
  fi
fi

shout
shout Your firewall has been configured to allow in http and https traffic
shout on ports 80/tcp and 443/tcp.
shout

exit 0

