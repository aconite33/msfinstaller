#!/bin/bash
KVER=`uname -a`
# Variable to know if Homebrew should be installed
MSFPASS=`openssl rand -hex 16`
#Variable with time of launch used for log names
NOW=$(date +"-%b-%d-%y-%H%M%S")
IGCC=1
INSTALL=1
RVM=1

function check_root
{
    if [ "$(id -u)" != "0" ]; then
        print_error "This step must be ran as root"
        exit 1
    fi
}
########################################
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
function check_postgresql
{
  if [ -d /usr/local/share/postgresql ]; then
    print_error "A previous version of PostgreSQL was found on the system."
    print_error "remove the prevous version and files and run script again."
    exit 1
  fi
}
########################################
function install_deps_deb
{
    print_status "Installing dependencies for Metasploit Framework"
    sudo apt-get -y update  >> $LOGFILE 2>&1
    sudo apt-get -y install build-essential libreadline-dev libssl-dev libpq5 libpq-dev libreadline5 libsqlite3-dev libpcap-dev openjdk-7-jre subversion git-core autoconf postgresql pgadmin3 curl zlib1g-dev libxml2-dev libxslt1-dev vncviewer libyaml-dev sqlite3 libgdbm-dev libncurses5-dev libtool bison libffi-dev nmap >> $LOGFILE 2>&1
    if [ $? -eq 1 ] ; then
        echo "---- Failed to download and install dependencies ----" >> $LOGFILE 2>&1
        print_error "Failed to download and install the dependencies for running Metasploit Framework"
        print_error "Make sure you have the proper permissions and able to download and install packages"
        print_error "for the distribution you are using."
        exit 1
    fi
#    print_status "Finished installing the dependencies."
#    print_status "Installing base Ruby Gems"
#    sudo gem install wirble sqlite3 bundler >> $LOGFILE 2>&1
#    if [ $? -eq 1 ] ; then
#        echo "---- Failed to download and install base Ruby Gems ----" >> $LOGFILE 2>&1
#        print_error "Failed to download and install Ruby Gems for running Metasploit Framework"
#        exit 1
#    fi
#    print_status "Finished installing the base gems."
}
#######################################

function configure_psql_deb
{
    print_status "Creating the MSF Database user msf with the password provided"
    if [ "$(id -u)" != "0" ]; then
        MSFEXIST="$(sudo su - postgres -c "psql postgres -tAc \"SELECT 1 FROM pg_roles WHERE rolname='msf'\"")"
    else
        MSFEXIST="$(su - postgres -c "psql postgres -tAc \"SELECT 1 FROM pg_roles WHERE rolname='msf'\"")"
    fi
    if [[ ! $MSFEXIST -eq 1 ]]; then
        if [ "$(id -u)" != "0" ]; then
            sudo -u postgres psql postgres -c "create role msf login password '$MSFPASS'"  >> $LOGFILE 2>&1
        else
            su - postgres -c "psql postgres -c \"create role msf login password '$MSFPASS'\""  >> $LOGFILE 2>&1
        fi

        if [ $? -eq 0 ]; then
            print_good "Metasploit Role named msf has been created."
        else
        print_error "Failed to create the msf role"
        fi
    else
        print_status "The msf role already exists."
    fi

    if [ "$(id -u)" != "0" ]; then
        DBEXIST="$(sudo su postgres -c "psql postgres -l | grep msf")"
    else
        DBEXIST="$(su - postgres -c "psql postgres -l | grep msf")"
    fi

    if [[ ! $DBEXIST ]]; then
        print_status "Creating msf database and setting the owner to msf user"
        if [ "$(id -u)" != "0" ]; then
            sudo -u postgres psql postgres -c "CREATE DATABASE msf OWNER msf;" >> $LOGFILE 2>&1
        else
            su - postgres -c "psql postgres -c \"CREATE DATABASE msf OWNER msf;\"" >> $LOGFILE 2>&1
        fi

        if [ $? -eq 0 ]; then
            print_good "Metasploit database named msf has been created."
        else
            print_error "Failed to create the msf database."
        fi
    else
        print_status "The msf database already exists."
    fi
}
#######################################

function install_msf_linux
{
    print_status "Installing Metasploit Framework from the GitHub Repository"

    if [[ ! -d /usr/local/share/metasploit-framework ]]; then
        print_status "Cloning latest version of Metasploit Framework"
        if [ "$(id -u)" != "0" ]; then
            sudo git clone https://github.com/rapid7/metasploit-framework.git /usr/local/share/metasploit-framework >> $LOGFILE 2>&1
        else
            git clone https://github.com/rapid7/metasploit-framework.git /usr/local/share/metasploit-framework >> $LOGFILE 2>&1
        fi
		print_status "Modifying local PATH variable"
		echo "export PATH=/usr/local/share/metasploit-framework:${PATH}" >> ~/.bashrc
		source ~/.bashrc >> $LOGFILE 2>&1
        print_status "Linking metasploit commands."
        cd /usr/local/share/metasploit-framework
        for MSF in $(ls msf*); do
            print_status "linking $MSF command"
            if [ "$(id -u)" != "0" ]; then
                sudo ln -s /usr/local/share/metasploit-framework/$MSF /usr/local/bin/$MSF
            else
                ln -s /usr/local/share/metasploit-framework/$MSF /usr/local/bin/$MSF
            fi
        done
        print_status "Creating Database configuration YAML file."
        if [ "$(id -u)" != "0" ]; then
            sudo sh -c "echo 'production:
  adapter: postgresql
  database: msf
  username: msf
  password: $MSFPASS
  host: 127.0.0.1
  port: 5432
  pool: 75
  timeout: 5' > /usr/local/share/metasploit-framework/database.yml"
        else
            sh -c "echo 'production:
  adapter: postgresql
  database: msf
  username: msf
  password: $MSFPASS
  host: 127.0.0.1
  port: 5432
  pool: 75
  timeout: 5' > /usr/local/share/metasploit-framework/database.yml"
        fi
        print_status "setting environment variable in system profile. Password will be requiered"
        sudo sh -c "echo export MSF_DATABASE_CONFIG=/usr/local/share/metasploit-framework/database.yml >> /etc/environment"
        echo "export MSF_DATABASE_CONFIG=/usr/local/share/metasploit-framework/database.yml" >> ~/.bashrc
        PS1='$ '
        source ~/.bashrc >> $LOGFILE 2>&1

        cd /usr/local/share/metasploit-framework
        #if [[ $RVM -eq 0 ]]; then
        #    print_status "Installing required ruby gems by Framework using bundler on RVM Ruby"
        #    ~/.rvm/bin/rvm 1.9.3 do bundle install  >> $LOGFILE 2>&1
        if [[ $RVM -eq 0 ]]; then
            print_status "Installing required ruby gems by Framework using bundler on System Ruby"
			/usr/local/rvm/gems/ruby-2.2.1@global/bin/bundle install >> $LOGFILE 2>&1
        fi
        print_status "Starting Metasploit so as to populate the database."
        if [[ $RVM -eq 0 ]]; then
            /usr/local/share/metasploit-framework/msfconsole -q -x "exit" >> $LOGFILE 2>&1
        else
            /usr/local/share/metasploit-framework/msfconsole -q -x "exit" >> $LOGFILE 2>&1
            print_status "Finished Metasploit installation"
        fi
    else
        print_status "Metasploit already present."
    fi
}
#######################################

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
            sudo tar -xvzf /tmp/armitage.tgz -C /usr/local/share >> $LOGFILE 2>&1
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
#######################################

function usage ()
{
    echo "Script for Installing Metasploit Framework, Ruby, and Armitage"
    echo "Originally by Carlos_Perez[at]darkoperator.com"
    echo "Modified and updated by Micheal Reski"
    echo "Ver 0.0.1"
    echo ""
    echo "-i                :Install Metasploit Framework."
    echo "-p <password>     :password for Metasploit databse msf user. If not provided a random one is generated for you."
    echo "-r                :Installs Ruby using Ruby Version Manager."
    echo "-h                :This help message"
}
#######################################
function install_ruby_rvm ()
{
    print_status "Installing GPG For Ruby..."
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 >> $LOGFILE 2>&1
    print_status "Installing stable version of latest ruby..."
    curl -sSL https://get.rvm.io | bash -s stable --ruby >> $LOGFILE 2>&1
	#sleep 30
	source /usr/local/rvm/scripts/rvm >> $LOGFILE 2>&1
	ruby -v >> $LOGFILE 2>&1
	if [ $? -eq 1 ] ; then
		echo "Ruby install failed! Pleae check your ruby install and rerun."
		exit 1
	fi
}
#### MAIN ###
[[ ! $1 ]] && { usage; exit 0; }
#Variable with log file location for trobleshooting
LOGFILE="/tmp/msfinstall$NOW.log"
while getopts "irp:h" options; do
    case $options in
        p ) MSFPASS=$OPTARG;;
        i ) INSTALL=0;;
        h ) usage;;
        r ) RVM=0;;
        \? ) usage
        exit 1;;
        * ) usage
        exit 1;;

    esac
done

if [ $INSTALL -eq 0 ]; then
    print_status "Log file with command output and errors $LOGFILE"
    if [[ "$KVER" =~ buntu ]]; then
        install_deps_deb

        if [[ $RVM -eq 0 ]]; then
            install_ruby_rvm
        fi

        configure_psql_deb
        install_msf_linux
        install_armitage_linux
        print_status "##################################################################"
        print_status "### YOU NEED TO RELOAD YOUR PROFILE BEFORE USE OF METASPLOIT!  ###"
        print_status "### RUN source ~/.bashrc                                       ###"
        if [[ $RVM -eq 0 ]]; then
            print_status "###                                                            ###"
            print_status "### INSTALLATION USED THE LATEST RUBY RVM INSTALL		 ###"
        fi
        print_status "### When launching teamserver and armitage with sudo use the   ###"
        print_status "### use the -E option to make sure the MSF Database variable   ###"
        print_status "### is properly set.                                           ###"
        print_status "###                                                            ###"
        print_status "##################################################################"
    else
	print_error "The script does not support this platform at this moment."
	exit 1
    fi
fi
