#!/bin/bash

file_remove='./remove.txt'
file_install='./install.txt'
pre_install_tweaks='./pre-tweaks.sh'
post_install_tweaks='./post-tweaks.sh'
local_debs_dir='./deb'

remove=1;
install=1;
install_local=1;
tweaks=1;
update=1;

read_file_without_comments() {
    cat "$1" | sed s/'#.*$'//
}

add_repo() {
    echo "Adding repository: $ppa"
    local command="add-apt-repository -y $1"
    $command;
}

update_repos() {
    echo "Updating repository cache..."
    local command="apt-get update"
    $command;
}

install_apps() {
    local command="apt-get install -y -m --force-yes $1"
    $command;
}

install_local_debs() {
    local command="dpkg -i -R $1"
    $command;
}

remove_apps() {
    local command="apt-get remove -y $(read_file_without_comments $1)"
    $command;
}

update_apps() {
    local command="apt-get upgrade -y"
    $command;
}

clean() {
    local command="apt-get autoremove -y"
    $command;
}


do_tweaks() {
    echo "Doing the tweaks specified in \"$1\"..."
    local command="$1"
    $command;
}

# Remove unwanted apps
if [ $remove -eq 1 ]; then
    remove_apps "$file_remove"
fi

# Install apps
if [ $install -eq 1 ]; then
    # Do the pre-install tweaks
    if [ $tweaks -a "$pre_install_tweaks" ]; then
        do_tweaks "$pre_install_tweaks"
    fi

    ppas=`grep -o "^\s*ppa:\S*\s" "$file_install"`

    for ppa in $ppas; do
        add_repo "$ppa"
    done

    apps=$(read_file_without_comments $file_install | sed s/'ppa:\S*\s'//)
    update_repos
    install_apps "$apps"
    if [ $install_local ]; then
        install_local_debs $local_debs_dir
    fi
fi

# Do the post-install tweaks
if [ $tweaks -eq 1 -a "$post_install_tweaks" ]; then
    do_tweaks "$post_install_tweaks"
fi

# Run system update
if [ $update -eq 1 ]; then
    update_apps
fi

clean