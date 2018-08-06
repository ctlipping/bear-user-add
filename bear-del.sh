#!/bin/bash

basedir=/remote/cfengine/

function call_help {
    echo bear-del: Remove a user from bear systems
    echo Usage: bear-del \(-u\|-h\) 
    echo -------------------
    echo -u \| --user : specify user for deletion
    echo -h \| --help : call this help prompt
    echo -t \| --test : test run \(not production\)
    exit 0
}

function get_product {
    if [ "$current" = "bearbin" ]; then
        product="server_rhel6"
    elif [ "$current" = "snowbear" ]; then
        product="cluster_rhel6"
    else
        product="server_rhel7"
    fi
}

function verify {
    if [ $basedir == "/remote/cfengine/" ]; then
        printf "\033[1;31mNote: the -t option is not set.  YOU ARE IN PRODUCTION\n"
    else
        printf "\033[1;32mNote: the -t option is set.  You are NOT IN PRODUCTION\n"
    fi
    printf "WARNING: You are removing user $uname from all BEAR systems.\033[0m\n"
    echo -n "Proceed (y/n)? "
    read PROCEED
    case "$PROCEED" in
        Y|y|Yes|yes) return 1;;
        *)           echo Aborting... ;exit 0;;
    esac

}

userID="$(id -u $uname)"
bears=(bearbin snowbear fibear seisbear)

while test $# -gt 0; do
    case "$1" in
        -u | --user)
            shift
            uname=$1
            shift;;
        -t | --test)
            basedir=`pwd -P`
            shift;;
        -h | --help)
            call_help;;
        *)
            break;;
    esac
done

if [ -z $uname ]; then
    echo -n "Enter user to remove: "
    read uname
fi

verify

for i in {0..3};
do
    current=${bears[$i]}
    get_product
    cd $basedir/product_$product/${current}.lbl.gov/etc
    #co -l passwd
    exist=`fgrep "${uname}:" passwd | wc -l`
    if [ $exist == 0 ]; then
        echo ERROR: User does not exist on $current
        echo Files have not been modified.
        continue
    fi
    sed "/${uname}/d" passwd >> passwd.new
    if [ `diff passwd passwd.new | wc -l` != 2 ]; then
        echo ERROR: internal sanity check failed.
        echo Files have not been modified.
        echo Aborting...
        exit 1
    fi
    mv passwd passwd.bak
    mv passwd.new passwd
    #rcsdiff passwd

    #ci -u -m"bear-user-del for $USER \($UID:100\)" passwd
    #cmpush -a
done
