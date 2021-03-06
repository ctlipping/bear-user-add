#!/bin/bash
#bear-add by clipping

#uncomment this for production
dry=""
dry2=""
basedir=/remote/cfengine/
bears=(bearbin snowbear fibear seisbear)
ushell="bash"

function call_help {
    echo bear-add: Create a user account for all bear systems.
    echo "Usage: bear-user-add.sh (options)"
    echo ----------------
    echo Options:
    echo \-u \| --user : Specify username
    echo \-i \| --id : Specify UserID
    echo -n \-g \| --group : Specify group \(probably users\)
    echo -e "\n-e" \| --email : Specify email
    echo \-s \| --shell : Specify shell \(default bash\)
    echo \-h \| --help : Shows this help menu
    echo \-t \| --test : Use for testing environment \(not production\)
    exit 0
}

function check_exist {
    if [ `grep ":$userID:" passwd | wc -l` != 0 ]; then
        echo ERROR: userID already exists. Aborting...
        exit 1
    fi

    if [ `grep ":$uname:" passwd | wc -l` != 0 ]; then
        echo ERROR: username already exists. Aborting...
        exit 1
    fi
}

function get_input {
    if [ -z $uname ]; then
        echo -n "Username: "
        read uname
    fi
    if [ -z $group ]; then
        echo -n "Primary group (probably users): "
        read group
    fi
    if [ -z $userID ]; then
        echo -n "UID: "
        read userID
    fi
    if [ -z "$email" ]; then
        echo -n "Name, Email: "
        read email
    fi
}

function get_product {
    if [ "${bears[$i]}" = "bearbin" ]; then
        product="server_rhel6"
    elif [ "${bears[$i]}" = "snowbear" ]; then
        product="cluster_rhel6"
    else
        product="server_rhel7"
    fi
}


while test $# -gt 0; do
    case "$1" in
        -h | --help)
            call_help;;
        -u | --user)
            shift
        uname=$1
            shift;;
        -g | --group)
            shift
        group=$1
            shift;;
        -i | --id)
            shift
        userID=$1
            shift;;
        -e | --email)
            shift
        email=$1
            shift;;
        -s | --shell)
            shift
        ushell=$1
            shift;;
        -t | --test)
        basedir=`pwd -P`
        dry2="echo #"
            shift;;
        -d | --dry)
        dry="echo"
            shift;;
        *)
            break;;
    esac
done
echo "To use this tool, you need a numeric UID from www-hpcs.lbl.gov"
if [ -z "$dry2" ]; then
    printf "\033[1;31mNote: The -t option is not set. YOU ARE IN PRODUCTION.\033[0m\n"
else
    printf "\033[1;32mNote: The -t option is set. You are NOT IN PRODUCTION.\033[0m\n"
fi
get_input

group_id=$(getent group $group | cut -d ":" -f3)
passwd_tmp="$uname:x:$userID:$group_id:$email:/data/home/$uname:/bin/$ushell"

for i in {0..3}; 
do
    current=${bears[$i]}
    get_product

    cd $basedir/product_$product/${current}.lbl.gov/etc
    pwd   
    check_exist
    
    $dry2 co -l passwd
    cp passwd passwd.old
    echo $passwd_tmp >> passwd
    $dry2 rcsdiff passwd
    $dry2 ci -u -m"bear-add for $uname \($userID:$group_id\)" passwd
    $dry2 cmpush -a
    echo Added $uname to $current...


    if [ $current == "bearbin" ]; then
        echo "\"C=US/O=Globus/O=LBNL HPCS/CN=`echo $email | cut -d \",\" -f 1 | tr [a-z] [A-Z]`\" $uname"
    fi

    $dry2 ssh $current \"mkdir /data/home/$uname\; cp /etc/skel/.\[a-zA-z0-9\]* /data/home/$uname\; chown -R $uname:$group_id /data/home/$uname\"
done

