#!/usr/bin/env bash
#  Douglas Berdeaux, 2021
#  RackunSec
#  Version 3.4.17 - for Demon LINUX

# Check UID:
if [ "$(whoami)" != "root" ]; then
 printf "[!] You need to run the installer as root, as we will be performing disk operations.\n[!] Exiting.";
 exit 1
fi

# move the installer app out of the menu temporarily:
mv /usr/share/applications/demon-installer.desktop /tmp

### CONSTANTS:
# OS Specific:
#export KERNEL=linux-image-amd64 # update this. Do not put the "linux-image-" part.
#export KERNEL=linux-image-4.19.0-5-amd64
export KERNELVERSION=4.19.0-16-amd64
export OS="Demon Linux 3.4"
export WORKINGDIR=/mnt/demon
export LOCALICONS=/usr/share/demon/images/icons/
export TITLETEXT="Demon Linux - Advanced Live Installer"
export WINDOWICON="${LOCALICONS}demon-64-white.png"
export WINDOWIMAGE="${LOCALICONS}demon-install-icon.png"
export SECICON="${LOCALICONS}sec-installer.png"
export GEARICON="${LOCALICONS}demon-config-small.png"

# App specific:
export TITLE="--title "
export ENTRY="--inputbox "
export MENU="--menu"
export YESNO="--yesno "
export MSGBOX="--msgbox "
export PASSWORD="--passwordbox "
export DIALOGMENU="$(which yad) --window-icon=$WINDOWICON --width=500 --height=200 --center"
export DIALOG="$(which yad) --window-icon=$WINDOWICON --center"
export SECDIALOG="$(which yad) --window-icon=$SECICON --center"
export TITLE="--always-print-result --dialog-sep --image=$WINDOWIMAGE --title="
export SECTITLE="--always-print-result --dialog-sep --image=$SECICON --title="
export GEARTITLE="--always-print-result --dialog-sep --image=$GEARICON --title="
export TEXT="--text="
export ENTRY="--entry "
export ENTRYTEXT="--entry-text "
export MENU="--list --column=Pick --column=Info"
export YESNO=" --button=Yes:0 --button=No:1 "
export MSGBOX=" --button=Ok:0 "
export PASSWORD="--entry --hide-text "
export TITLETEXT='"Demon Linux - HDD Installation Tool"'
export PARTITIONPROG="gparted"
export SPANFONT="<span font='Ubuntu Condensed 11'>" # Damn, this is a sexy font.
export INSTALLDISK=""
export ROOTPASS=""

### This function forks the loading bar message box using "tail":
progressBar () {
 tail -f /etc/issue |yad --progress --pulsate --no-buttons --auto-close \
  --text="\n$SPANFONT $1 </span>" --width=350 --height=17 --center --title=$TITLETEXT \
  --window-icon=$WINDOWICON --percentage=13 --progress-text=" Grinding things up. Please Wait... " --image=$GEARICON
}

getRootPasswd () {
  PASSWD1=1
  PASSWD2=2
  while [[ "$PASSWD1" != "$PASSWD2" ]]
  do
    PASSWD1=$($DIALOG $TITLE"$TITLETEXT" $MSGBOX --text="\nPlease enter a STRONG <b>root</b> user password: "  --entry  --hide-text)
    PASSWD2=$($DIALOG $TITLE"$TITLETEXT" $MSGBOX --text="\nPlease re-enter the <b>root</b> user password: "  --entry  --hide-text)
    if [[ "$PASSWD1" != "$PASSWD2" ]]
    then
      $DIALOG $TITLE"$TITLETEXT" $MSGBOX --text="\nThe passwords entered do not match.\nPlease try again."
    else
      # Check password complexity:
      numcheck=$(echo $PASSWD1|egrep -E '[0-9]'|wc -l)
      lengthcheck=$(echo $PASSWD1|wc -c)
      specialcharcheck=$(echo $PASSWD1|egrep -E '[^0-9A-Za-z]'|wc -l)
      upcasecheck=$(echo $PASSWD1|egrep '[A-Z]'|wc -l)
      lcasecheck=$(echo $PASSWD1|egrep '[a-z]'|wc -l)

      numcheck=$(echo $numcheck|sed -r 's/1/True/g')
      numcheck=$(echo $numcheck|sed -r 's/0/False/g')
      specialcharcheck=$(echo $specialcharcheck|sed -r 's/1/True/g')
      specialcharcheck=$(echo $specialcharcheck|sed -r 's/0/False/g')
      upcasecheck=$(echo $upcasecheck|sed -r 's/1/True/g')
      upcasecheck=$(echo $upcasecheck|sed -r 's/0/False/g')
      lcasecheck=$(echo $lcasecheck|sed -r 's/1/True/g')
      lcasecheck=$(echo $lcasecheck|sed -r 's/0/False/g')

      $DIALOG $TITLE"$TITLETEXT" --text="\nAre you 100% sure that you want this as your <b>root</b> password?\t\n\n<b>Length:</b>\t${lengthcheck}\n<b>Special Character:</b>\t$specialcharcheck\n<b>Upper Case:</b>\t$upcasecheck\n<b>Lower case:\t</b>$lcasecheck\n<b>Number:</b>\t${numcheck}" --button=Yes:0 --button=No:1
      passwdans=$?
      if [[ "$passwdans" -eq 1 ]]
      then
        printf "[log] passwdans: ${passwdans}\n"
        getRootPasswd
      else
        ROOTPASS=$PASSWD1
        printf "[log] passwdans: ${passwdans}\n"
      fi
    fi
  done
}


### This function stops the loading bar message box by killing tail:
killBar () { # tail was a really good idea here, Tony :)
 killall -KILL tail 2>/dev/null
}

### This function quits the installer:
quit (){
  $DIALOG $TITLE"$TITLETEXT" $MSGBOX $TEXT"$SPANFONT \nQuitting the installer now.   </span>"
  exit 1
}

### Ensure insternet connection
progressBar "Creating an active internet connection.\n" &
#/etc/init.d/network-manager start
dhclient -v # this should be fine.
HTTPTEST=$(curl -sIL https://demonlinux.com/index.php | head -n 1 | awk '{print $2}')
if [ "$HTTPTEST" != "200" ];
 then
  yad --text="You do not have an active internet connection.\nThis means we cannot install a new kernel or proceed.\n\nExiting." --center --window-icon=$GEARICON --title=$TITLETEXT
  exit;
fi
killBar

### Update YAD
progressBar "Updating software respositories\n and installing dependencies \n" &
  apt update
  apt install cryptsetup yad lvm2 -y
killBar;

### Run the workflow:
$DIALOG $TITLE"$TITLETEXT" --button=Yes:0 --button=No:1 --button=Help:2 \
 --text="${SPANFONT}\nThis is the <b>$OS</b> Disk Installation Utility.\nIt is <b>HIGHLY RECOMMENDED</b> that <b>$OS</b>\n\
is installed in a <u>virtualized environment</u> to ensure the best,\nuniform experience for all users.\n\nRackünSec cannot \
support every piece of hardware\nas he is has a day job :( \n\nDo you want to continue?</span>  \n" --height=35 --fixed

getRootPasswd;

ans=$?
if [ $ans = 1 ]; then
 exit 0
elif [ $ans = 2 ];then # Awe, snacks!
 $DIALOG $TITLE"$TITLETEXT" $MSGBOX $TEXT"$SPANFONT Firefox is now going to start and direct you to the video tutorial.  \nPlease wait.</span>"
 firefox-esr 'https://demonlinux.com/tutorials.php' &
fi

## Disk Encryption?
$SECDIALOG $SECTITLE"$TITLETEXT" --button=Yes:1 --button=No:0 \
 --text="${SPANFONT}\nWould you like to enable full disk encryption? </span>  \n" --height=35 --fixed
ans=$?
if [ $ans = 1 ]; then
 export DISKENC=1
 printf "[log] Enabling full disk encryption.\n"
elif [ $ans = 0 ];then # Awe, snacks!
 export DISKENC=0
 printf "[log] Full disk encryption declined.\n"
fi

### Create time adjustment file:
echo "0.0 0 0.0" > /etc/adjtime
echo "0" >> /etc/adjtime
echo "LOCAL" >> /etc/adjtime

### Fix for gparted being inhibited by udisks-daemon:
killall -KILL udisks-daemon 2>/dev/null

### Choose the drive to install to:
yad --text="$SPANFONT \nLet's select a disk to install $OS to and start up \
  <b>$PARTITIONPROG</b>.\nIn $PARTITIONPROG create one root partition labeled \
  <b>/</b> with the   \nFS format of your choice.   \nPay attention to \
  the drive names in the \"Partition\" column,\n\n E.g.:<b>sda1</b>, \
  <b>sda2</b>.\n\nWhen done with $PARTITIONPROG, hit the <b>X</b> button \
  and this installation will continue.</span>  \n " \
  --center --window-icon=$WINDOWICON --no-wrap --title="$OS Installer" --image=$WINDOWIMAGE --fixed
# This is important to chnage back, so, OFS is the original.
OFS=$IFS # Field Separator for loops.
IFS=$"\n" # change to newline from \s and we will revert later.
# ONLY SHOW PARTITIONS:
#DRIVES=$(cat /proc/partitions | grep sd | egrep -v 'sd[a-z][0-9]')
DRIVES=$(cat /proc/partitions | egrep -E 'sd.$')
# E.g.:
#   8        0   20971520 sda
#   8        1   19456000 sda1
#   8        2    1514496 sda2
for i in $DRIVES; do
 partdrive=$(echo $i|awk '{print $4}');
 partdrivesize=$(echo $i|awk '{print $3}');
 partdrivemenu="$partdrive $partdrivesize"
 printf "PARTDRIVE: $partdrive, PARTDRIVESIZE: $partdrivesize, PARTDRIVEMENU: $partdrivemenu\n";
done

# return the field separator. If not, this could cause undefinied behavior or crashes:
IFS=$OFS
PARTDRIVE=$($DIALOGMENU $TITLE"$TITLETEXT" $MENU  $TEXT"\nPlease select a drive to partition.   \n" $partdrivemenu)
PARTDRIVE=$(echo $PARTDRIVE |sed -re 's/\|.*//')
if [ "$PARTDRIVE" = "Exit" ]; then
 quit;
fi
printf "[log] Part: $PARTITIONPROG /dev/$PARTDRIVE\n"
$PARTITIONPROG /dev/$PARTDRIVE


### Choosing the Install (/) Partition:
OFS=$IFS # Field Separator for loops.
IFS="\n" # change to newline from \s and we will revert later.
PARTINST=$(cat /proc/partitions | egrep "${partdrive}[0-9]+");

for i in $PARTINST; do
 tempsize=$(echo $PARTINST | awk '{print $3}')
 if [ "$tempsize" = "1" ]; then
  PARTINST=$(echo $PARTINST | sed -r "s/$i//")
 fi
done
for i in $PARTINST; do
 part=$(echo $i | awk '{print $4}')
 partsize=$(echo $i| awk '{print $3}')
 partmenu="$partmenu $part $partsize"
done
TARGETPART=""
IFS=$OFS # revert field separator
while [ "$TARGETPART" = "" ]
do
  TARGETPART=$($DIALOGMENU $TITLE"$TITLETEXT" $MENU  $TEXT"\n Please select a partition to install the <b>root</b> system to.   " $partmenu)
done
TARGETPART=`echo $TARGETPART | cut -d "|" -f 1`

if [ "$TARGETPART" = "Exit" ]; then
 quit;
fi

## ENCRYPT THE DRIVE:
if [ "$DISKENC" == "1" ]; then
  umount $TARGETPART # bring it offline.
  $SECDIALOG $SECTITLE"$TITLETEXT" --button="I Promise!":1 \
  --text="${SPANFONT}\nPlease choose a strong passphrase to encrypt your disk in the following window. </span>  \n" --height=35 --fixed
  ## Step one: encrypt the partition:
  tilix -e "/bin/bash -c \"while ! cryptsetup luksFormat --type luks1 /dev/$TARGETPART;do echo 'LUKS Setup failed, try again ... ';done\""
  pid=$(ps aux | egrep -Ei 'while.*[c]ryptsetup' | awk '{print $2}')
  while [ "$(ps aux | egrep 'while...cryptsetup.luks[F]'|wc -l)" == "1" ]
  do # sleep until this prcess is done:
    sleep 1
  done
  ## Step 2: unlock and mount the encrypted partition:
  tilix -e "/bin/bash -c \"while ! cryptsetup luksOpen /dev/$TARGETPART demonluks;do echo 'Bad passphrase or disk not found ... '; done\""
  while [ "$(ps aux | egrep 'while...cryptsetup.luks[O]'|wc -l)" == "1" ]
  do # sleep until this process is done:
    sleep 1
  done
  printf "[log] Creating mapper objects ... "
  pvcreate /dev/mapper/demonluks
  vgcreate cryptvg /dev/mapper/demonluks
  lvcreate -n lvroot -l 100%FREE cryptvg
  printf "[log] Done completing mapper objects."
  ## mount the encrypted drive:
  if [[ "$DISKENC" == "1" ]]
  then
    sleep 1
    mkfs.ext4 /dev/mapper/cryptvg-lvroot
    sleep 1
    mkdir /mnt/demon 2>/dev/null
    mount /dev/mapper/cryptvg-lvroot /mnt/demon
  fi
else
  # Simply mount /dev/$PARTINST to /mnt/demon
  printf "[log] Mounting /dev/$TARGETPART to /mnt/demon"
  mkdir /mnt/demon 2>/dev/null
  mount /dev/$TARGETPART /mnt/demon
fi

export FSTYPE=$(mount | grep /dev/$TARGETPART|awk '{print $5}')
printf "[log] FSTYPE of /dev/$TARGETPART is $FSTYPE\n"

HOMEINST=`echo $PARTINST | sed -r "s/$TARGETPART//"`
for i in $HOMEINST; do
  homepart="$i"
  homepartsize=`grep -m 1 "$i" /proc/partitions | awk '{print $3}'`
  homepartmenu="$homepartmenu $homepart $homepartsize"
done
HOMEPART="root" # install the /home into the /

### Get the chosen hostname of the new system:
TARGETHOSTNAME=$($DIALOG $TITLE"$TITLETEXT" $ENTRY $TEXT"$SPANFONT Please enter the <b>hostname</b> for this newly installed system.</span>   ")

### Get the kernel from the user:
for kernel in $(apt-cache search linux-image|egrep -E '^linux-image.+[0-9]\..+64'|grep -v dbg|sort -u|awk '{print $1}'); do KERNELS="$KERNELS $kernel"; done
KERNEL=$(yad --list --column="New Kernel" $KERNELS \
  --width=500 --height=300 --window-icon=64-icon.png\
   --text="\nPlease choose a kernel to use on your installed Demon.\n"\
    --image=${WINDOWIMAGE})
KERNEL=$(echo $KERNEL|sed -r 's/\|//g'); # drop the pipe made from yad
printf "[log] KERNEL: $KERNEL"

### Timezone Setting
$DIALOG $TITLE"$TITLETEXT" $YESNO $TEXT"$SPANFONT Is your system clock set to your current local time?   \n\nAnswering no will indicate it is set to UTC</span>"
if [ $? = 0 ]; then
  if [ "$(grep "UTC" /etc/adjtime)" != "" ]; then
   sed -i -e "s|UTC|LOCALTIME|g" /etc/adjtime
  fi
else
  if [ "$(grep "LOCALTIME" /etc/adjtime)" != "" ]; then
   sed -i -e "s|LOCALTIME|UTC|g" /etc/adjtime
  fi
fi
cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "/" | sort > /tmp/demon-installer-script.zoneinfo
for i in `cat /tmp/demon-installer-script.zoneinfo`; do
  ZONES="$ZONES $i Timezone"
done
rm /tmp/demon-installer-script.zoneinfo
ZONESINFO=""
while [ "$ZONESINFO" = "" ]
do
  ZONESINFO=`$DIALOGMENU $TITLE"$TITLETEXT" $MENU  $TEXT"Please select a <b>timezone</b> for your system" "America/New_York" "America/New_York" $ZONES`
done
ZONESINFO=`echo $ZONESINFO | cut -d "|" -f 1`
if [ "$ZONESINFO" = "Exit" ]; then
 quit;
fi
echo "$ZONESINFO" > /etc/timezone
cp /usr/share/zoneinfo/$ZONESINFO /etc/localtime

### Final Confirmation:
if [[ "$DISKENC" == "1" ]]
then
  export diskenc="True"
else
  export diskenc="False"
fi
$DIALOG $TITLE"$TITLETEXT" $YESNO $TEXT"$SPANFONT <b>\nPlease <u>verify</u> that the information below is correct.\
</b>\n\nOperating System: <b>$OS</b>\nTimezone: <b>$ZONESINFO</b>\nFilesystem: <b>$FSTYPE</b>\nPartition: <b>$TARGETPART</b>\nDisk Encryption: <b>$diskenc</b>\nKernel: <b>$KERNEL</b>\nHostname: <b>$TARGETHOSTNAME</b>\n\nDo you want to continue?</span>" --width=600 --fixed
if [ $? != 0 ]; then
 quit;
fi

### RSYNC the OS/Live files to HDD:
killBar;
progressBar "Copying the files to <b>/dev/$TARGETPART</b>.   \nThis <u>will</u> take a long time - ($(df -h 2>/dev/null | awk '$1 ~ /overlay|sr0|loop/ {gsub(/[.,]/,"",$2); gsub(/G/,"00",$2); gsub(/M/,"",$2); size+=$2}END{print size}')MB).   " &
  # First update the root password to what the user typed :
  printf "[log] Updating root password locally before syncing disks.\n"
  echo "root:${ROOTPASS}" | chpasswd
  printf "[log] Starting RSYNC ... \n"
  rsync -a / $WORKINGDIR --ignore-existing --exclude=/{lib/live,usr/lib/live,live,cdrom,mnt,proc,run,sys,media,appdev,demon-dev,tmp}
  # Remove the auto start of startx from boot up (force login with new password)
  printf "[log] Removing startx from rc.local ... \n"
  sed -ir 's/^su.*startx.*//' $WORKINGDIR/etc/rc.local
  # install lightdm:
  printf "[log] Installing LightDM ... \n"
  chroot $WORKINGDIR apt update
  chroot $WORKINGDIR apt install lightdm -y
  if [[ "$DISKENC" == "1" ]]
  then
    # get UUID of disk
    export DISKUUID=$(blkid | grep crypto_LUKS|awk -F\" '{print $2}')
    echo "demonluks UUID=$DISKUUID  none  luks" >> ${WORKINGDIR}/etc/crypttab
    export EXT4UUID=$(blkid | grep -i ext4 | awk -F\" '{print $2}')
    echo "UUID=$EXT4UUID  / ext4  errors=remount-rw 0 1" >> ${WORKINGDIR}/etc/fstab
    chroot $WORKINGDIR apt install cryptsetup-initramfs -y
    cp ${WORKINGDIR}/sbin/e2fsck ${WORKINGDIR}/mnt/demon/sbin/fsck.luks
    chroot $WORKINGDIR update-initramfs -u -k all
  fi
  printf "[log] RSYNC Complete, making new directories ... \n"
  mkdir -p $WORKINGDIR/{proc,mnt,run,sys,media/cdrom,tmp}
  chmod a+rxw $WORKINGDIR/tmp # This is required for APT later ...
  # Remove live hooks:
  printf "[log] Removing initRAMFS from live ... \n"
  rm $WORKINGDIR/usr/share/initramfs-tools/hooks/live
  printf "[log] Removing /etc/live ... \n"
  rm -rf $WORKINGDIR/etc/live
killBar;

progressBar "Performing post-install steps now. " &
  printf "[log] Mounting /proc, /dev/, /sys, /run\n"
  printf "[log] WORKINGDIR currently mounted as: $(mount | grep $WORKINGDIR)\n"
  #prepare the chroot environment for some post install changes
  mount -o bind /proc $WORKINGDIR/proc
  mount -o bind /dev $WORKINGDIR/dev
  mount -o bind /dev/pts $WORKINGDIR/dev/pts
  mount -o bind /sys $WORKINGDIR/sys
  mount -o bind /run $WORKINGDIR/run
  if [[ "$DISKENC" == 0 ]]
  then
    rm -f $WORKINGDIR/etc/fstab
  fi
  rm -f $WORKINGDIR/etc/profile.d/zz-live.sh

  #create the new fstab for the chrooted env:
  if [[ "$DISKENC" == "0" ]]
  then
    printf "[log] Making encrypted disk FSTAB entries on the new FS ... \n"
    cat > $WORKINGDIR/etc/fstab <<FOO
# /etc/fstab: static file system information.
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>

proc /proc proc defaults 0 0
# /dev/$TARGETPART
/dev/$TARGETPART / $FSTYPE relatime,errors=remount-ro 0 1
FOO
  fi
killBar;

### Clean up Fresh Install:
printf "[log] Fixing initRAMFS tools ... \n"
progressBar "Fixing initram-fs tools. " &
  # get rid of the "live" initramfs:
  rm $WORKINGDIR/usr/sbin/update-initramfs
  cp $WORKINGDIR/usr/sbin/update-initramfs.orig.initramfs-tools $WORKINGDIR/usr/sbin/update-initramfs
killBar;

printf "[log] Removing some live-OS diversions. \n"
progressBar "Removing some live-OS diversions. " &
  rm -rf $WORKINGDIR/usr/lib/update-notifier/apt-check
  rm -rf $WORKINGDIR/usr/sbin/anacron
killBar;
# Run  the GRUB2 installer in a new Terminal window:
progressBar "Installing <b>GRUB2</b> and the <b>kernel</b> on your new system." &
  # This is done this way because of the captive Grub2 apt-get installation
  printf "[log] Updating APT in the chrooted $WORKINGDIR ... \n"
  chroot $WORKINGDIR apt update
  printf "[log] Installing GRUB in the chroot, $WORKINGDIR\n"
  mkdir $WORKINGDIR/tmp 2>/dev/null
  chmod a+rxw $WORKINGDIR/tmp
  cat > $WORKINGDIR/tmp/grub-install.sh << GRUB
  #!/bin/bash
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install grub2 grub-pc grub-common;
GRUB
  chroot $WORKINGDIR chmod +x /tmp/grub-install.sh
  chroot $WORKINGDIR /tmp/grub-install.sh
  if [[ "$DISKENC" == "1" ]]
  then # add a line into GRUB for decryption of drive:
    echo "GRUB_ENABLE_CRYPTODISK=y" >> $WORKINGDIR/etc/default/grub
    #printf "[log] catting \"$WORKINGDIR/etc/default/grub\"\n"
    #cat $WORKINGDIR/etc/default/grub
  fi
  printf "[log] Installing Grub to /dev/$PARTDRIVE\n";
  chroot $WORKINGDIR grub-install --root-directory=/ --no-floppy /dev/$PARTDRIVE;
  # I know that this is very specific as to what OS/kernel to install, but I am still working this aht:
  printf "[log] Re-installing kernel $KERNEL \n"
  chroot $WORKINGDIR apt -y -V install $KERNEL --reinstall # this will generate a new /boot/vmlinuz, hopefully.

  printf "[log] update-initramfs: -c -k all \n"
  if [[ "$DISKENC" == "0" ]]
  then
    chroot $WORKINGDIR update-initramfs -c -k $KERNELVERSION # create a new symlink for /initrd
  fi
  printf "[log] update-grub: \n" # Set up GRUB for pretty:
  echo "GRUB_GFXMODE=1024x768" >> $WORKINGDIR/etc/default/grub
  echo "GRUB_BACKGROUND=\"/usr/share/demon/images/splash.png\"" >> $WORKINGDIR/etc/default/grub
  printf "[log] copying GRUB splash.png image to $WORKINGDIR/boot/grub\n"
  chroot $WORKINGDIR update-grub # required to make grub.cfg!
killBar;
printf "[log] Setting up hostname in the chrooted environment ... \n"
progressBar "Setting up <b>$TARGETHOSTNAME</b>.   " &
  echo $TARGETHOSTNAME > $WORKINGDIR/etc/hostname
  echo "127.0.0.1 localhost" >> $WORKINGDIR/etc/hosts
  echo "127.0.0.1 $TARGETHOSTNAME" >> $WORKINGDIR/hosts
  touch $WORKINGDIR/etc/resolv.conf
killBar;
# Clean up system:
progressBar "Cleaning your fresh, new environment. " &
  sleep 1
  printf "[log] Clearing our Xsession-errors ... \n"
  chroot $WORKINGDIR echo "" > /root/.xsession-errors
  printf "[log] Doing APT-Clean in the chroot ... \n"
  chroot $WORKINGDIR apt clean # These will not remove directories:
  chroot $WORKINGDIR rm /var/lib/apt/lists/ftp* 2>/dev/null
  chroot $WORKINGDIR rm /var/lib/apt/lists/http* 2>/dev/null
  chroot $WORKINGDIR rm /root/.bash_history 2>/dev/null
  chroot $WORKINGDIR rm /root/.ssh/known_hosts 2>/dev/null
  chroot $WORKINGDIR rm -rf /root/Downloads/* 2>/dev/null
  chroot $WORKINGDIR rm -rf /root/Desktop/* 2>/dev/null
  chroot $WORKINGDIR rm -rf /root/Videos/* 2>/dev/null
killBar;
progressBar "Unmounting system. Preparing for landing." &
  printf "[log] Unountinf FS ... \n"
  umount $WORKINGDIR/proc
  sleep 1
  umount $WORKINGDIR/dev/pts
  sleep 1
  umount $WORKINGDIR/dev
  sleep 1
  umount $WORKINGDIR/sys
  sleep 1
  umount $WORKINGDIR/run
  sleep 1
  umount $WORKINGDIR
  sleep 1
killBar;
# TODO Make sure by checking files/dirs before saying it was a success!
$DIALOG $TITLE"$TITLETEXT" --button=Yes:0 --button=No:1 --button=Help:2 --text="$SPANFONT $OS has been\nsuccessfully installed on your system, $TARGETHOSTNAME.   \n\nWould you like to reboot now and test it out?  </span>" --image=$WINDOWIMAGE --window-image=$WINDOWIMAGE;
ans=$?
if [ $ans = 0 ]; then
 $DIALOG $TITLE"$TITLETEXT" $MSGBOX $TEXT"$SPANFONT Thank you for choosing <b>Demon Linux.</b>   \n\n~Douglas Berdeaux\nWeakNetLabs@Gmail.com</span>" --image=$WINDOWIMAGE --window-image=$WINDOWIMAGE;
 sleep 5; # so that you can see.
 reboot;
 exit 0
elif [ $ans = 1 ];then # Awe, snacks!
 $DIALOG $TITLE"$TITLETEXT" $MSGBOX $TEXT"$SPANFONT Thank you for choosing <b>Demon Linux.</b>   \n\n~Douglas Berdeaux\nWeakNetLabs@Gmail.com</span>" --image=$WINDOWIMAGE --window-image=$WINDOWIMAGE;
fi

# move the installer app back into the menu:
mv /tmp/demon-installer.desktop /usr/share/applications/
exit 0;
