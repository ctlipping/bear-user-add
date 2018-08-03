#!/bin/bash

get_product {
    if [ "${ARRAY[$i]}" = "bearbin" ]; then
        product="server_rhel6"
    elif [ "${$ARRAY[$i]}" = "snowbear" ]; then
        product="cluster_rhel6"
    else
        product="server_rhel7"
    fi
}

USER="$0"
UID="$(id -u $USER)"
ARRAY=(bearbin snowbear fibear seisbear)

echo "WARNING: You are removing user $USER from all BEAR systems."
echo "Proceed (y/n)? "
read PROCEED
case "$PROCEED" in
    Y|y|Yes|yes)    return 0 ;;
    *)              return 1 ;;
esac

for i in {0..3};
do
    get_product

    cd /remote/cfengine/product_$product/${ARRAY[$i]}.lbl.gov/etc
    co -l passwd
    sed '/$USER/d' ./passwd -i
    rcsdiff passwd
    ci -u -m"bear-user-del for $USER \($UID:100\)" passwd
    cmpush -a
done
