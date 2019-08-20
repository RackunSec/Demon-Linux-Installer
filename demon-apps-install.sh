#!/bin/bash
## Demon Linux App Store
## 2019 WeakNet Labs
## Douglas Berdeaux

IFS=$'\n' # required for for() loop
SPANFONT="<span font='Ubuntu Condensed 11'>"
WINDOWICON="/usr/share/demon/images/icons/64-icon.png"
WINDOWIMAGE="/usr/share/demon/images/icons/64-icon.png"
APPNAME="Demon Linux App Store"
APPTEXT="\n\nWelcome to the Demon Linux App Store - where everything's free. Simply select an app below by checking it.\n"
# start the "installing app: XYZ" progress bar dialog:
progressBar () {
 tail -f /etc/issue |yad --progress --pulsate --no-buttons --auto-close \
  --text="\n$SPANFONT $1 </span>\n" --width=350 --height=17 --center --title=$TITLETEXT \
  --window-icon=$WINDOWICON --percentage=13 --progress-text="Please wait ..." --image=$WINDOWICON &
}

# This function stops the loading bar message box by killing tail:
killBar () { # tail was a really good idea here, Tony :)
 killall -KILL tail 2>/dev/null
}

complete () {
  # we are done!
  yad --text="\nAll packages that you requested have been installed.  \n" --title="Thank you for visting the Demon Linux App Store" --image=$WINDOWIMAGE --window-icon=$WINDOWICON
}

installApp (){
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
              echo "export PATH=$PATH:/snap/bin:/snap/sbin" >> ~/.bashrc # update our PATH
          fi
      ### Cutter:
      elif [ "$arg" == "Cutter" ]
        then # Install Cutter:
          progressBar "Downloading $arg"
          wget https://github.com/radareorg/cutter/releases/download/v1.8.3/Cutter-v1.8.3-x64.Linux.AppImage -O /usr/local/sbin/Cutter
          killBar
          progressBar "Installing Cutter"
          chmod +x /usr/local/sbin/Cutter
      ### Atom "IDE":
      elif [ "$arg" == "Atom" ]
        then
          progressBar "Downloading $arg"
          cd /tmp/ && wget https://github.com/atom/atom/releases/download/v1.40.0/atom-amd64.deb --no-check-certificate
          killBar
          progressBar "Installing $arg"
          dpkg -i atom-amd64.deb
          apt -f install # just in case-icles
      ### Eclipse for Java Devs:
      elif [ "$arg" == "Eclipse" ]
        then
          progressBar "Downloading $arg"
          cd /tmp && wget 'http://demonlinux.com/download/packages/eclipse-jee-2019-06-R-linux-gtk-x86_64.tar.gz' --no-check-certificate
          progressBar "Installing $arg"
          tar vxzf eclipse-jee-2019-06-R-linux-gtk-x86_64.tar.gz # crack it open
          mv /tmp/eclipse /opt/ # toss it into a shared space
          if [ $(grep /opt/eclipse ~/.bashrc|wc -l) -eq 0 ]
            then # add it to the PATH
              echo "export PATH=$PATH:/opt/eclipse" >> ~/.bashrc # update the path
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
      elif [ "$arg" == "Chrome" ]
        then
          progressBar "Downloading $arg"
          cd /tmp && wget http://demonlinux.com/download/packages/google-chrome-stable_current_amd64.deb
          killBar
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
          progressBar "Downloading $arg"
          cd /tmp/ && wget https://download.sublimetext.com/sublime_text_3_build_3207_x64.tar.bz2 --no-check-certificate
          killBar
          progressBar "Installing $arg"
          tar vjxf sublime_text_3_build_3207_x64.tar.bz2
          mv sublime_text_3 /opt/sublime3
          if [ $(grep /opt/sublime3 ~/.bashrc|wc -l) -eq 0 ]
            then # create the PATH entry:
              echo PATH=$PATH:/opt/sublime3 >> ~/.bashrc
          fi
      fi
      sleep 1 # DEBUG
      killBar
  fi
}

# This may seem crazy, but it's for the UI/UX sake:
for app in $(yad --width=600 --height=400 --title=$APPNAME\
 --list --checklist --column=Install --column="App Name" --column=Description \
 --image=$WINDOWIMAGE \
 --window-icon=$WINDOWICON \
 --text=$APPTEXT \
$(if [[ $(which spotify|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Spotify" "Spotify desktop app" \
$(if [[ $(which Cutter|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Cutter" "Cutter reverse engineering tool" \
$(if [[ $(which atom|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Atom" "Atom IDE" \
$(if [[ $(which eclipse|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Eclipse" "Eclipse IDE for Java" \
$(if [[ $(which vlc|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "VLC" "Multimedia player and framework" \
$(if [[ $(which brave-browser|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Brave-Browser" "Much more than a web browser" \
$(if [[ $(which google-chrome|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Google-Chrome" "Google's web browser" \
$(if [[ $(which sublime|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Sublime" "Sublime text editor" \
$(if [[ $(which clementine|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Clementine" "Modern music player" \
$(if [[ $(which simplenote|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "SimpleNote" "The simplest way to keep notes" \
$(if [[ $(which kdenlive|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Kdenlive" "Video editor program" \
$(if [[ $(which shotcut|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Shotcut" "Video editor program" \
$(if [[ $(which franz|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Franz" "Messaging client app" \
$(if [[ $(which VisualStudio|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Visual Studio Code" "Microsoft's code editor" \
$(if [[ $(which stracer|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Stracer" "System optimizer app" \
$(if [[ $(which gdebi|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "GDebi" "Debian .deb GUI installer"); do installApp $app; done
# All done!
complete
