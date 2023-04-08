#!/bin/bash

# Ask for network interface
read -p "Enter your network interface: " INTERFACE

function activate_tor_proxy {
    # Set up Tor transparent proxy
    iptables -F
    iptables -t nat -F
    iptables -t nat -A PREROUTING -i $INTERFACE -p tcp --syn -j REDIRECT --to-ports 9040

    # Redirect DNS traffic through Tor
    echo "nameserver 127.0.0.1" > /etc/resolv.conf

    # Enable IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward

    # Set default policies
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT

    # Allow loopback traffic
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT

    # Allow established and related traffic
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

    # Allow Tor traffic
    iptables -A INPUT -i $INTERFACE -p tcp --dport 9040 -j ACCEPT
    iptables -A INPUT -i $INTERFACE -p tcp --dport 9050 -j ACCEPT
    iptables -A FORWARD -i $INTERFACE -p tcp --dport 9040 -j ACCEPT
    iptables -A FORWARD -i $INTERFACE -p tcp --dport 9050 -j ACCEPT

    echo "Tor transparent proxy activated."
}

function restore_defaults {
    # Restore defaults
    iptables -F
    iptables -t nat -F
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    echo "" > /etc/resolv.conf
    echo 0 > /proc/sys/net/ipv4/ip_forward

    echo "Defaults restored."
}

if [[ "$1" == "start" ]]; then
    activate_tor_proxy
elif [[ "$1" == "stop" ]]; then
    restore_defaults
else
    echo "Usage: $0 {start|stop}"
    exit 1
fi
