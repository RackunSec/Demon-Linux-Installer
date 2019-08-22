#!/bin/bash
#  Douglas Berdeaux, 2019
#  weaknetlabs@gmail.com
#  Version 1.8.19a - for Demon LINUX

# Check UID:
if [ "$(whoami)" != "root" ]; then
 printf "[!] You need to run the installer as root, as we will be performing disk operations.\n[!] Exiting.";
 exit 1
fi

### CONSTANTS:
# OS Specific:
export KERNEL=linux-image-amd64 # update this. Do not put the "linux-image-" part.
export OS="Demon Linux"
export WORKINGDIR=/mnt/demon
export TITLETEXT="Demon Linux - Live Installer"
export WINDOWICON="/usr/share/demon/images/icons/demon-64-white.png"
export WINDOWIMAGE="/usr/share/demon/images/icons/demon-64-padded-white.png"
# App specific:
export TITLE="--title "
export ENTRY="--inputbox "
export MENU="--menu"
export YESNO="--yesno "
export MSGBOX="--msgbox "
export PASSWORD="--passwordbox "
export DIALOGMENU="$(which yad) --window-icon=$WINDOWICON --width=500 --height=200 --center"
export DIALOG="$(which yad) --window-icon=$WINDOWICON --center"
export TITLE="--always-print-result --dialog-sep --image=$WINDOWIMAGE --title="
export TEXT="--text="
export ENTRY="--entry "
export ENTRYTEXT="--entry-text "
export MENU="--list --column=Pick --column=Info"
export YESNO=" --button=Yes:0 --button=No:1 "
export MSGBOX=" --button=Ok:0 "
export PASSWORD="--entry --hide-text "
export TITLETEXT="Demon Linux - HDD Installation Tool"
export PARTITIONPROG="gparted"
export SPANFONT="<span font='Ubuntu Condensed 11'>" # Damn, this is a sexy font.

### This function forks the loading bar message box using "tail":
progressBar () {
 tail -f /etc/issue |yad --progress --pulsate --no-buttons --auto-close \
  --text="$SPANFONT $1 </span>" --width=350 --height=17 --center --title=$TITLETEXT \
  --window-icon=$WINDOWICON --percentage=13 --progress-text="Please Wait..." --image=$WINDOWIMAGE
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
/etc/init.d/network-manager start
dhclient -v
HTTPTEST=$(curl -sIL https://demonlinux.com/index.php | head -n 1 | awk '{print $2}')
if [ "$HTTPTEST" != "200" ];
 then
  yad --text="You do not have an active internet connection.\nThis means we cannot install a new kernel or proceed.\n\nExiting." --center --window-icon=$WINDOWICON --title=$TITLETEXT
  exit;
fi
killBar

### Get the latest version of me :) self-maintaining
progressBar "Updating this installer. Please wait ... " &
killBar

### Update YAD
progressBar "Updating respositories and YAD ..." &
apt update
apt install yad -y
killBar;

### Run the workflow:
$DIALOG $TITLE"$TITLETEXT" --button=Yes:0 --button=No:1 --button=Help:2 \
 --text="${SPANFONT}\nThis is the <b>$OS</b> Disk Installation Utility.\nIt is <b>HIGHLY RECOMMENDED</b> that <b>$OS</b>\n\
is installed in a <u>virtualized environment</u> to ensure the best,\nuniform experience for all users.\n\nWeakNet Labs cannot \
support every piece of hardware\nas I am only a single person.\n\nDo you want to continue?\n\nFor a complete video tutorial hit \
<b>Help</b> below.</span>  " --height=35 --fixed

ans=$?
if [ $ans = 1 ]; then
 exit 0
elif [ $ans = 2 ];then # Awe, snacks!
 $DIALOG $TITLE"$TITLETEXT" $MSGBOX $TEXT"$SPANFONT Firefox is now going to start and direct you to the video tutorial.  \nPlease wait.</span>"
 firefox-esr 'https://demonlinux.com/tutorials.php' &
fi

### Create time adjustment file:
echo "0.0 0 0.0" > /etc/adjtime
echo "0" >> /etc/adjtime
echo "LOCAL" >> /etc/adjtime

### Fix for gparted being inhibited by udisks-daemon:
killall -KILL udisks-daemon 2>/dev/null

### Choose the drive to install to:
yad --text="$SPANFONT Let's select a disk to install $OS to and start up <b>$PARTITIONPROG</b>.\nIn GParted create one Root partition labeled <b>/</b> with the   \nFS format of your choice and one Linux-Swap partition labeled <b>swap</b>.   \nPay attention to the drive names in the \"Partition\" column,\n\n E.g.:<b>sda1</b>, <b>sda2</b>.\n\nWhen done with $PARTITIONPROG, hit the <b>X</b> button and this installation will continue.</span>   " --center --window-icon=$WINDOWICON --no-wrap --title="$OS Installer" --image=$WINDOWIMAGE --fixed
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
PARTDRIVE=$($DIALOGMENU $TITLE"$TITLETEXT" $MENU  $TEXT"Please select a drive to partition.   \n" Exit "Quit the installer." $partdrivemenu)
PARTDRIVE=$(echo $PARTDRIVE |sed -re 's/\|.*//')
if [ "$PARTDRIVE" = "Exit" ]; then
 quit;
fi
printf "[!] Part: $PARTITIONPROG /dev/$PARTDRIVE\n"
$PARTITIONPROG /dev/$PARTDRIVE

### Choose the swap partition:
TARGETSWAP=$(fdisk -l | awk '/swap/ {sub(/\/[^\/]+\//,"",$1); print $1}')
for i in $TARGETSWAP; do
 swappart="$i"
 swappartsize=$(awk '/sda2/ { print $3 }' /proc/partitions)
 swappartmenu="$swappartmenu $swappart $swappartsize"
done
SWAP=""
while [ "$SWAP" = "" ]
do
 SWAP=$($DIALOGMENU $TITLE"$TITLETEXT" $MENU  $TEXT"Please select a <b>swap</b> partition to use.   " Exit "Quit the installer." $swappartmenu)
done
SWAP=$(echo $SWAP |sed -re 's/\|.*//')
if [ "$SWAP" = "Exit" ]; then
 quit;
fi

### Choosing the Install (/) Partition:
OFS=$IFS # Field Separator for loops.
IFS="\n" # chnage to newline from \s and we will revert later.
PARTINST=$(cat /proc/partitions | egrep "${partdrive}[0-9]+" | grep -v $SWAP);

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
TARGETPART=`$DIALOGMENU $TITLE"$TITLETEXT" $MENU  $TEXT"Please select a partition to install the <b>root</b> system to.   " Exit "Quit the installer." $partmenu`
done
TARGETPART=`echo $TARGETPART | cut -d "|" -f 1`

if [ "$TARGETPART" = "Exit" ]; then
 quit;
fi
FSTYPE=""
while [ "$FSTYPE" = "" ]
do
FSTYPE=`$DIALOGMENU $TITLE"$TITLETEXT" $MENU  $TEXT"Please select <b>filesystem</b> type for the root partition." ext2 "Ext2 filesystem." ext3 "Ext3 filesystem." ext4 "Ext4 filesystem."`
done
FSTYPE=`echo $FSTYPE | cut -d "|" -f 1`
HOMEINST=`echo $PARTINST | sed -r "s/$TARGETPART//"`
for i in $HOMEINST; do
  homepart="$i"
  homepartsize=`grep -m 1 "$i" /proc/partitions | awk '{print $3}'`
  homepartmenu="$homepartmenu $homepart $homepartsize"
done
HOMEPART="root" # install the /home into the /
HFSTYPE=""
HFSTYPE=`echo $HFSTYPE | cut -d "|" -f 1`

### Get the chosen hostname of the new system:
TARGETHOSTNAME=$($DIALOG $TITLE"$TITLETEXT" $ENTRY $TEXT"$SPANFONT Please enter the <b>hostname</b> for this newly installed system.</span>   ")

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
cat /usr/share/zoneinfo/zone.tab | awk '{print $3}' | grep "/" | sort > /tmp/wt7-installer-script.zoneinfo
for i in `cat /tmp/wt7-installer-script.zoneinfo`; do
ZONES="$ZONES $i Timezone"
done
rm /tmp/wt7-installer-script.zoneinfo
ZONESINFO=""
while [ "$ZONESINFO" = "" ]
do
ZONESINFO=`$DIALOGMENU $TITLE"$TITLETEXT" $MENU  $TEXT"Please select a <b>timezone</b> for your system" Exit "Quit the installer" $ZONES`
done
ZONESINFO=`echo $ZONESINFO | cut -d "|" -f 1`
if [ "$ZONESINFO" = "Exit" ]; then
 quit;
fi
echo "$ZONESINFO" > /etc/timezone
cp /usr/share/zoneinfo/$ZONESINFO /etc/localtime

## Confirmation:
$DIALOG $TITLE"$TITLETEXT" $YESNO $TEXT"$SPANFONT <b>Please <u>verify</u> that this information is correct.\
</b>\n\nYour $OS system will be installed on an<b> $FSTYPE</b> formatted <b>$TARGETPART</b> partition<b>\
$HOMETEXT</b>   \n\nDo you want to continue?</span>" --fixed
if [ $? != 0 ]; then
 quit;
fi

### HDD Partition and Setup:
progressBar "Setting up SWAP now. " &
sleep 1 # because of the "&" above
mkswap /dev/$SWAP
swapon /dev/$SWAP
killBar;
progressBar "Formatting $TARGETPART now. " &
# Make the filesystem and mount the partition on $WORKINGDIR
if [ "`mount | grep $TARGETPART`" ]; then
umount /dev/$TARGETPART
fi
mke2fs -F -t $FSTYPE /dev/$TARGETPART
mkdir -p $WORKINGDIR
sleep 1
mount /dev/$TARGETPART $WORKINGDIR -o rw
sleep 1
tune2fs -c 0 -i 0 /dev/$TARGETPART
rm -rf "$WORKINGDIR/lost+found"
killBar;

### RSYNC the OS/Live files to HDD:
TARGETCDROM="/dev/cdrom" # For FSTAB
killBar;
progressBar "Copying the files to <b>/dev/$TARGETPART</b>.   \nThis <u>will</u> take a long time - ($(df -h 2>/dev/null | awk '$1 ~ /overlay|sr0|loop/ {gsub(/[.,]/,"",$2); gsub(/G/,"00",$2); gsub(/M/,"",$2); size+=$2}END{print size}')MB).   " &

rsync -a / $WORKINGDIR --ignore-existing --exclude=/{lib/live,usr/lib/live,live,cdrom,mnt,proc,run,sys,media,appdev,demon-dev,tmp}
printf "[log] RSYNC Complete, making new directories ... \n"
mkdir -p $WORKINGDIR/{proc,mnt,run,sys,media/cdrom,tmp}
chmod 7777 $WORKINGDIR/tmp # This is required for APT later ...
# Remove live hooks:
printf "[log] Removing initRAMFS from live ... \n"
rm $WORKINGDIR/usr/share/initramfs-tools/hooks/live
printf "[log] Removing /etc/live ... \n"
rm -rf $WORKINGDIR/etc/live # WTF is Debian doing these days? Why so convoluted?
killBar;

printf "[log] Mounting /proc, /dev/, /sys, /run\n"
printf "[log] WORKINGDIR currently mounted as: $(mount | grep $WORKINGDIR)"
progressBar "Performing post-install steps now. " &
#prepare the chroot environment for some post install changes
mount -o bind /proc $WORKINGDIR/proc
mount -o bind /dev $WORKINGDIR/dev
mount -o bind /dev/pts $WORKINGDIR/dev/pts
mount -o bind /sys $WORKINGDIR/sys
mount -o bind /run $WORKINGDIR/run
rm -f $WORKINGDIR/etc/fstab
rm -f $WORKINGDIR/etc/profile.d/zz-live.sh

#create the new fstab for the chrooted env:
printf "[log] Making FSTAB entries on the new FS ... \n"
cat > $WORKINGDIR/etc/fstab <<FOO
# /etc/fstab: static file system information.
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>

proc /proc proc defaults 0 0
# /dev/$TARGETPART
/dev/$TARGETPART / $FSTYPE relatime,errors=remount-ro 0 1
# /dev/$SWAP
/dev/$SWAP none swap sw 0 0
FOO

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
cat > $WORKINGDIR/tmp/grub-install.sh << GRUB
#!/bin/bash
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install grub2 grub-pc grub-common;
GRUB
chroot $WORKINGDIR chmod +x /tmp/grub-install.sh
chroot $WORKINGDIR /tmp/grub-install.sh
printf "[log] Installing Grub to /dev/$PARTDRIVE\n";
chroot $WORKINGDIR grub-install --root-directory=/ --no-floppy /dev/$PARTDRIVE;
# I know that this is very specific as to what OS/kernel to install, but I am still working this aht:
chroot $WORKINGDIR apt -y -V install $KERNEL --reinstall # this will generate a new /boot/vmlinuz, hopefully.
chroot $WORKINGDIR update-initramfs -c -k $KERNEL # create a new symlink for /initrd
chroot $WORKINGDIR update-grub # required to make grub.cfg!
killBar;
#$DIALOG $TITLE"$TITLETEXT" --button="I have completed Installing GRUB2":0 \
# --text="$SPANFONT GRUB2 needs to be installed on the new system.   Follow the directions in the newly opened terminal and hit the button below <u><b>ONLY</b></u> when completed.\n</span>  ";
# Set up the chosen hostname: (Done last to prevent apt-get from failing to resolve hosts)
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
 $DIALOG $TITLE"$TITLETEXT" $MSGBOX $TEXT"$SPANFONT Thank you for choosing <b>WeakNet Laboratories!</b>   \n\n~Douglas Berdeaux\nWeakNetLabs@Gmail.com</span>" --image=$WINDOWIMAGE --window-image=$WINDOWIMAGE;
 sleep 5; # so that you can see.
 reboot;
 exit 0
elif [ $ans = 1 ];then # Awe, snacks!
 $DIALOG $TITLE"$TITLETEXT" $MSGBOX $TEXT"$SPANFONT Thank you for choosing <b>WeakNet Laboratories!</b>   \n\n~Douglas Berdeaux\nWeakNetLabs@Gmail.com</span>" --image=$WINDOWIMAGE --window-image=$WINDOWIMAGE;
fi
