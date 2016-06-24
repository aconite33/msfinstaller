# msfinstaller
Metasploit Framework Installer from source

Originally created by DarkOperator [https://github.com/darkoperator]. 
Forked for updates to installing Metasploit, Ruby, and Armitage on a base Ubuntu install.

Usage:
msfinstaller -i -p <password> -r [-h]
* -i Installs Metasploit Framework with Armitage
* -p Initital password for postgresql database of Metasploit
* -r Install latest Ruby RVM (Metasploit requires ruby version => 2.0
* -h Help Message

Examples:
msfinstaller -i -p msf -r

***Current Bugs***
You will need a restart. Ruby isn't sourcing bashrc correctly and requires you to bounce the box.

If you get:
"Could not find XXXX in any of the sources
Run `bundle install` to install missing gems."
Then do the following:
#>cd /usr/local/share/metasploit-framework/
#>bundle install

You may need to logout and log back in to properly set your bashrc settings.

All Credit goes to Dark Operator for original script
