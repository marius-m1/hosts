#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 <hosts_file>"
    exit 1
fi

HOSTS_FILE="$1"

if [ ! -f "$HOSTS_FILE" ]; then
    echo "Error: File '$HOSTS_FILE' does not exist."
    exit 1
fi

verify_IP() {
    name=$1
    expected_ip=$2

    addresses=$(nslookup "$name" | awk '
        /^Name:/ { found=1; next }
        found && /^Address:/ { print $2 }
    ')

    if [ -z "$addresses" ]; then
        return 2
    fi

    found=0

    while read -r ip
    do
        if [ "$ip" = "$expected_ip" ]; then
            found=1
        fi
    done <<< "$addresses"

    if [ "$found" -eq 1 ]; then
        return 0
    else
        echo "Bogus IP for $name in $HOSTS_FILE!"
        return 1
    fi
}

while read -r ip name rest
do
    [ -z "$ip" ] && continue
    [[ "$ip" == \#* ]] && continue
    
    [[ "$name" != *.* ]] && continue

    verify_IP "$name" "$ip"

    result=$?

    if [ "$result" -eq 2 ]; then
        echo "Could not resolve $name"
    fi

done < "$HOSTS_FILE"