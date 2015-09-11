#!/bin/bash
KVER=`uname -a`

function print_good ()
{
    echo -e "\x1B[01;32m[*]\x1B[0m $1"
}
########################################

function print_error ()
{
    echo -e "\x1B[01;31m[*]\x1B[0m $1"
}
########################################

function print_status ()
{
    echo -e "\x1B[01;34m[*]\x1B[0m $1"
}
########################################

function install_armitage_osx
{
    if [ -e /usr/bin/curl ]; then
        print_status "Downloading latest version of Armitage"
        curl -# -o /tmp/armitage.tgz http://www.fastandeasyhacking.com/download/armitage-latest.tgz && print_good "Finished"
        if [ $? -eq 1 ] ; then
            print_error "Failed to download the latest version of Armitage make sure you"
            print_error "are connected to the internet and can reach http://www.fastandeasyhacking.com"
        else
            print_status "Decompressing package to /usr/local/share/armitage"
            tar -xvzf /tmp/armitage.tgz -C /usr/local/share
        fi

        # Check if links exists and if they do not create them
        if [ ! -e /usr/local/bin/armitage ]; then
            print_status "Linking Armitage in /usr/local/bin/armitage"
            sh -c "echo java -jar /usr/local/share/armitage/armitage.jar \$\* > /usr/local/share/armitage/armitage"
            ln -s /usr/local/share/armitage/armitage /usr/local/bin/armitage
        else
            print_good "Armitage is already linked to /usr/local/bin/armitage"
            echo java -jar /usr/local/share/armitage/armitage.jar \$\* > /usr/local/bin/armitage
        fi

        if [ ! -e /usr/local/bin/teamserver ]; then
            print_status "Copying Teamserver in /usr/local/bin/teamserver"
            ln -s /usr/local/armitage/teamserver /usr/local/bin/teamserver
            perl -pi -e 's/armitage.jar/\/usr\/local\/share\/armitage\/armitage.jar/g' /usr/local/share/armitage/teamserver
        else
            print_good "Teamserver is already linked to /usr/local/bin/teamserver"
            perl -pi -e 's/armitage.jar/\/usr\/local\/share\/armitage\/armitage.jar/g' /usr/local/share/armitage/teamserver
        fi
        print_good "Finished"
    fi
}
########################################

function install_armitage_linux
{
    if [ -e /usr/bin/curl ]; then
        print_status "Downloading latest version of Armitage"
        curl -# -o /tmp/armitage.tgz http://www.fastandeasyhacking.com/download/armitage-latest.tgz && print_good "Finished"
        if [ $? -eq 1 ] ; then
            print_error "Failed to download the latest version of Armitage make sure you"
            print_error "are connected to the internet and can reach http://www.fastandeasyhacking.com"
        else
            print_status "Decompressing package to /usr/local/share/armitage"
            sudo tar -xvzf /tmp/armitage.tgz -C /usr/local/share >>outfile 2>&1
        fi

        # Check if links exists and if they do not create them
        if [ ! -e /usr/local/bin/armitage ]; then
            print_status "Creating link for Armitage in /usr/local/bin/armitage"
            sudo sh -c "echo java -jar /usr/local/share/armitage/armitage.jar \$\* > /usr/local/share/armitage/armitage"
            sudo ln -s /usr/local/share/armitage/armitage /usr/local/bin/armitage
        else
            print_good "Armitage is already linked to /usr/local/bin/armitage"
            sudo sh -c "echo java -jar /usr/local/share/armitage/armitage.jar \$\* > /usr/local/share/armitage/armitage"
        fi

        if [ ! -e /usr/local/bin/teamserver ]; then
            print_status "Creating link for Teamserver in /usr/local/bin/teamserver"
            sudo ln -s /usr/local/share/armitage/teamserver /usr/local/bin/teamserver
            sudo perl -pi -e 's/armitage.jar/\/usr\/local\/share\/armitage\/armitage.jar/g' /usr/local/share/armitage/teamserver
        else
            print_good "Teamserver is already linked to /usr/local/bin/teamserver"
            sudo perl -pi -e 's/armitage.jar/\/usr\/local\/share\/armitage\/armitage.jar/g' /usr/local/share/armitage/teamserver
        fi
        print_good "Finished"
    fi
}

if [[ "$KVER" =~ Darwin ]]; then
    install_armitage_osx

elif [[ "$KVER" =~ buntu ]]; then
    install_armitage_linux

else
    print_error "The script does not support this platform at this moment."
    exit 1
fi
