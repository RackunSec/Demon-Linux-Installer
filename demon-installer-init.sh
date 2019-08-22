#!/bin/bash
### Update the installer EACH TIME RAN
updateMe () {
 if [ ! -d /appdev/Demon-Linux-Installer ]
  then
   mkdir -p /appdev/
   cd /appdev
   git clone https://github.com/weaknetlabs/Demon-Linux-Installer/
   rm /usr/local/sbin/demon-installer.sh # get rid of old version
 else
  cd /appdev/Demon-Linux-Installer
  git pull
 fi # does the icons directory exist?
 if [ ! -d /usr/share/demon/images/icons ]
  then
   mkdir -p /usr/share/demon/images/icons
 fi
 cp /appdev/Demon-Linux-Installer/demon-installer.sh /usr/local/sbin/demon-installer.sh
 cp /appdev/Demon-Linux-Installer/icons/* /usr/share/demon/images/icons/
 printf "[!] Updated to the latest version. \n"
}
# Step 1: UPDATE
updateMe
# Step 2: Run
/usr/local/sbin/demon-installer.sh
