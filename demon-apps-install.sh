#!/bin/bash
## Demon Linux App Store
## 2019 WeakNet Labs
## Douglas Berdeaux

IFS=$'\n' # required for for() loop
SPANFONT="<span font='Ubuntu Condensed 11'>"
#WINDOWICON="/usr/share/demon/images/icons/64-icon.png"
WINDOWICON="$PWD/icons/64-icon-padded.png"
WINDOWIMAGE="$PWD/icons/64-icon-padded.png"
APPNAME="Demon Linux App Store"
APPTEXT="\n\nWelcome to the Demon Linux App Store - where everything's free. Simply select an app below by checking it.\n"
# start the "installing app: XYZ" progress bar dialog:
progressBar () {
 tail -f /etc/issue |yad --progress --pulsate --auto-close --text="\n$SPANFONT $1 </span>\n" --width=350 --center\
 --title=$APPNAME --window-icon=$WINDOWICON --percentage=13 --progress-text="Please wait ..." --image=$WINDOWIMAGE --undecorated --no-buttons &
}

# This function stops the loading bar message box by killing tail:
killBar () {
 killall -KILL tail 2>/dev/null
}

downloadFile () { # pass to me "URI,Title,OutputFile" :)
  wget $1 -O $3  2>&1 | sed -u 's/^[a-zA-Z\-].*//; s/.* \{1,2\}\([0-9]\{1,3\}\)%.*/\1\n#Downloading ...\1%/; s/^20[0-9][0-9].*/#Done./'\
  | yad --progress --title="Download in Progress" --window-icon=$WINDOWICON --image=$WINDOWIMAGE --width=350 --center --text="\nDownloading $2 ... " --auto-close --no-buttons --undecorated
}

complete () { # "--fixed" actually fixes a height issue BUG here:
  # I'm aaaalll duuuhhhhh-uuuuhhhnnnnnnne!
  yad --text="\nThank you for visting the Demon Linux App Store.  " --height=10 --fixed --title=$APPNAME --image=$WINDOWIMAGE --window-icon=$WINDOWICON --button=Exit:1
}

installApp () {
  arg=$1;
  arg=$(echo $arg|sed -r 's/TRUE\|([^|]+)\|.*/\1/');
  # Check if App is already installed (could have been pre-checked in the checklist)
  printf "Looking for "$arg"\n";
  if [ $(which "${arg,,}"|wc -l) -ne 1 ] && [ $(which $arg|wc -l) -ne 1 ] # uses syntax sugar to lowercase the name
    then
      ### Spotify:
      if [ "$arg" == "Spotify" ]
        then # Install Spotify:
          progressBar "Installing $arg"
          apt install snapd
          snap install spotify
          if [ $(grep /snap/bin ~/.bashrc|wc -l) -eq 0 ]
            then
              echo "export PATH=\$PATH:/snap/bin:/snap/sbin" >> ~/.bashrc # update our PATH
          fi
      ### Pentester's Framework from TrustedSec:
      elif [ "$arg" == "PTF" ]
        then
          progressBar "Installing PenTesters Framework"
          apt install python-pip
          apt install python-pexpect
          cd /infosec && git clone https://github.com/trustedsec/ptf
          echo "PATH=\$PATH:/infosec/ptf"
      ### TorBrowser
      elif [ "$arg" == "Tor-Browser" ]
        then
          downloadFile https://www.torproject.org/dist/torbrowser/8.5.4/tor-browser-linux64-8.5.4_en-US.tar.xz "Tor-Browser" "/opt/tor-browser-linux64-8.5.4_en-US.tar.xz"
          cd /opt
          progressBar "Installing $arg"
          xz -d tor-browser-linux64-8.5.4_en-US.tar.xz
          tar vxf tor-browser-linux64-8.5.4_en-US.tar
          #echo "PATH=\$PATH:/opt/tor-browser_en-US/Browser" >> ~/.bashrc
          rm tor-browser-linux64-8.5.4_en-US.tar
          sed -ie 's/`" -eq 0/`" -ne 0/' tor-browser_en-US/Browser/start-tor-browser # whoopsey daisey!
          echo "cd /opt/tor-browser_en-US/Browser && ./start-tor-browser" > /usr/local/sbin/tor-browser
          chmod +x /usr/local/sbin/tor-browser
      ### Cutter
      elif [ "$arg" == "Cutter" ]
        then # Install Cutter:
          downloadFile https://github.com/radareorg/cutter/releases/download/v1.8.3/Cutter-v1.8.3-x64.Linux.AppImage $arg /usr/local/sbin/Cutter
          killBar
          progressBar "Installing Cutter"
          chmod +x /usr/local/sbin/Cutter
      ### Atom "IDE":
      elif [ "$arg" == "Atom" ]
        then
          downloadFile https://github.com/atom/atom/releases/download/v1.40.0/atom-amd64.deb $arg /tmp/atom-amd64.deb
          killBar
          progressBar "Installing $arg"
          cd /tmp
          dpkg -i atom-amd64.deb
          apt -f install # just in case-icles
      ### Eclipse for Java Devs:
      elif [ "$arg" == "Eclipse" ]
        then
          downloadFile 'http://demonlinux.com/download/packages/eclipse-jee-2019-06-R-linux-gtk-x86_64.tar.gz' $arg /tmp/eclipse-jee-2019-06-R-linux-gtk-x86_64.tar.gz
          progressBar "Installing $arg"
          cd /tmp
          tar vxzf eclipse-jee-2019-06-R-linux-gtk-x86_64.tar.gz # crack it open
          mv /tmp/eclipse /opt/ # toss it into a shared space
          if [ $(grep /opt/eclipse ~/.bashrc|wc -l) -eq 0 ]
            then # add it to the PATH
              echo "export PATH=\$PATH:/opt/eclipse" >> ~/.bashrc # update the path
          fi
          bash -c # new shell
      ### VLC Media Player:
      elif [ "$arg" == "VLC Media Player" ]
        then
          progressBar "Installing $arg"
          apt install vlc -y
          sed -i 's/geteuid/getppid/' /usr/bin/vlc
      ### Brave little web browser:
      elif [ "$arg" == "Brave" ]
        then
          progressBar "Installing $arg"
          sudo apt install apt-transport-https curl
          curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -
          echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ trusty main" | sudo tee /etc/apt/sources.list.d/brave-browser-release-trusty.list
          apt update
          apt install brave-browser -y
          # aaaand finally, a little clean up:
          mv /usr/bin/brave-browser /usr/bin/brave-browser-script
          echo "brave-browser-script --no-sandbox" > /usr/bin/brave-browser
          chmod +x /usr/bin/brave-browser
          mv /usr/bin/brave-browser-stable /usr/bin/brave-browser-script
          echo "brave-browser-script --no-sandbox" > /usr/bin/brave-browser-stable
          chmod +x /usr/bin/brave-browser-stable
      ### Googlefornia's shitty browser:
      elif [ "$arg" == "Google-Chrome" ]
        then
          downloadFile 'http://demonlinux.com/download/packages/google-chrome-stable_current_amd64.deb' 'Google-Chrome' '/tmp/google-chrome-stable_current_amd64.deb'
          cd /tmp
          progressBar "Installing $arg"
          dpkg -i google-chrome-stable_current_amd64.deb
          apt -f install -y
          # great. Now we have a lot of cleaning up to do for Googlefornia.
          mv /usr/bin/google-chrome /usr/bin/google-chrome-script
          echo "google-chrome-script --no-sandbox" > /usr/bin/google-chrome
          chmod +x /usr/bin/google-chrome
          mv /usr/bin/google-chrome-stable /usr/bin/google-chrome-script
          echo "google-chrome --no-sandbox" > /usr/bin/google-chrome-stable
          chmod +x /usr/bin/google-chrome-stable
      ### Sublime text editor:
      elif [ "$arg" == "Sublime" ]
        then
          downloadFile "https://download.sublimetext.com/sublime_text_3_build_3207_x64.tar.bz2 --no-check-certificate" $arg "/tmp/sublime_text_3_build_3207_x64.tar.bz2"
          cd /tmp
          progressBar "Installing $arg"
          tar vjxf sublime_text_3_build_3207_x64.tar.bz2
          mv sublime_text_3 /opt/sublime3
          if [ $(grep /opt/sublime3 ~/.bashrc|wc -l) -eq 0 ]
            then # create the PATH entry:
              echo "PATH=\$PATH:/opt/sublime3" >> ~/.bashrc
          fi
      ### SimpleNote
      elif [ "$arg" == "SimpleNote" ]
        then
          downloadFile 'https://github.com/Automattic/simplenote-electron/releases/download/v1.7.0/Simplenote-linux-1.7.0-amd64.deb' $arg "/tmp/Simplenote-linux-1.7.0-amd64.deb"
          cd /tmp
          progressBar "Installing $arg"
          dpkg -i Simplenote-linux-1.7.0-amd64.deb
      ### KdenLive:
      elif [ "$arg" == "Kdenlive" ]
        then
          LOCALAREA=/usr/local/bin/kdenlive
          downloadFile 'https://files.kde.org/kdenlive/release/Kdenlive-16.12.2-x86_64.AppImage --no-check-certificate' $arg $LOCALAREA
          cd /tmp
          progressBar "Installing $arg"
          apt install -y ffmpeg libav-tools dvdauthor genisoimage
          chmod +x $LOCALAREA
      ### ShotCut:
      elif [ "$arg" == "Shotcut" ]
        then
          LOCALAREA=/usr/local/bin/shotcut
          downloadFile https://github.com/mltframework/shotcut/releases/download/v19.08.16/Shotcut-190816.glibc2.14-x86_64.AppImage $arg $LOCALAREA
          progressBar "Installing $arg"
          chmod +x $LOCALAREA
      ### Franz Messaging:
      elif [ "$arg" == "Franz" ]
        then
          LOCALAREA=/usr/local/bin/franz
          downloadFile https://github.com/meetfranz/franz/releases/download/v5.2.0/franz-5.2.0-x86_64.AppImage $arg $LOCALAREA
          progressBar "Installing $arg"
          chmod +x $LOCALAREA
      ### Visual Studio:
      elif [ "$arg" == "VisualStudio" ]
        then
          progressBar "Installing $arg"
          apt install software-properties-common apt-transport-https curl software-properties-common -y
          curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
          add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
          apt update
          apt install code -y
      ### Maltego CE:
      elif [ "$arg" == "Maltego" ]
        then
          LOCALAREA=/tmp/Maltego.v4.2.6.12502.deb
          downloadFile http://www.demonlinux.com/download/packages/Maltego.v4.2.6.12502.deb $arg $LOCALAREA
          progressBar "Installing $arg ... "
          cd /tmp
          dpkg -i Maltego.v4.2.6.12502.deb
          apt -f install -y
      ### Stacer:
      elif [ "$arg" == "Stacer" ]
        then
          LOCALAREA=/tmp/stacer_1.1.0_amd64.deb
          downloadFile 'https://github.com/oguzhaninan/Stacer/releases/download/v1.1.0/stacer_1.1.0_amd64.deb --no-check-certificate' $arg $LOCALAREA
          cd /tmp
          progressBar "Installing $arg"
          dpkg -i stacer_1.1.0_amd64.deb
          apt -f install -y
      else
          printf "[!] Unknown app was requested! $arg\n\n"
      fi
      sleep 1 # DEBUG
      killBar
  fi
}

# This may seem crazy, but it's for the UI/UX sake:
for app in $(yad --width=600 --height=400 --title=$APPNAME\
  --button=Exit:1 --button=Install:0\
 --list --checklist --column=Install --column="App Name" --column=Description \
 --image=$WINDOWIMAGE \
 --window-icon=$WINDOWICON \
 --text=$APPTEXT \
 $(if [[ $(which spotify|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Spotify" "Spotify desktop app" \
 $(if [[ $(which tor-browser|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Tor-Browser" "The Tor Project Browser"  \
 $(if [[ $(which ptf|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "PTF" "TrustedSec's Pentester's Framework" \
 $(if [[ $(which maltego|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Maltego" "Paterva's information gathering tool" \
 $(if [[ $(which Cutter|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Cutter" "Cutter reverse engineering tool" \
 $(if [[ $(which atom|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Atom" "Atom IDE" \
 $(if [[ $(which eclipse|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Eclipse" "Eclipse IDE for Java" \
 $(if [[ $(which vlc|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "VLC" "Multimedia player and framework" \
 $(if [[ $(which brave-browser|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Brave-Browser" "Much more than a web browser" \
 $(if [[ $(which google-chrome|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Google-Chrome" "Google's web browser" \
 $(if [[ $(which sublime_text|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Sublime_Text" "Sublime text editor" \
 $(if [[ $(which simplenote|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "SimpleNote" "The simplest way to keep notes" \
 $(if [[ $(which kdenlive|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Kdenlive" "Video editor program" \
 $(if [[ $(which shotcut|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Shotcut" "Video editor program" \
 $(if [[ $(which franz|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Franz" "Messaging client app" \
 $(if [[ $(which VisualStudio|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Visual Studio Code" "Microsoft's code editor" \
 $(if [[ $(which stacer|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Stacer" "System optimizer app" ); do installApp $app; done
# All done!
complete
