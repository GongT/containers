#!/usr/bin/bash



echo "ensure network connection..."
I=0
while true ; do
    RES=$(nslookup ns1.he.net | tail -n +3 | grep Address | sed 's/Address: /nameserver /g')
    if [[ -n "$RES" ]]; then
        break
    fi
    sleep 1
    I=$((I + 1))
    
    if [[ "$I" -gt 5 ]] ; then
        echo 'Failed resolve domain, maybe network issue.'
        echo '======================'
        ip addr
        echo '======================'
        cat /etc/resolv.conf
        echo '======================'
        exit 1
    fi
    
    echo "retry ($I)..."
done
echo "dns resolve ok:
$RES"
echo "$RES" > /etc/resolv.conf
sleep 2
