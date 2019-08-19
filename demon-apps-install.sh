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
  --text="$SPANFONT Installing App: $1 </span>" --width=350 --height=17 --center --title=$TITLETEXT \
  --window-icon=$WINDOWICON --percentage=13 --progress-text="Please Wait..." --image=$WINDOWICON &
}

# This function stops the loading bar message box by killing tail:
killBar () { # tail was a really good idea here, Tony :)
 killall -KILL tail 2>/dev/null
}

installApp (){
  arg=$1;
  arg=$(echo $arg|sed -r 's/TRUE\|([^|]+)\|.*/\1/');
  # Check if App is already installed (could have been pre-checked in the checklist)
  if [ $(which "${arg,,}"|wc -l) -ne 1 ] && [ $(which $arg|wc -l) -ne 1 ] # uses syntax sugar to lowercase the name
    then
      printf "Installing app: $arg\n"
      progressBar $arg
      ### Spotify
      if [ "$arg" == "Spotify" ]
        then # Install Spotify:
          apt install snapd
          snap install spotify
          echo "export PATH=$PATH:/snap/bin:/snap/sbin" >> ~/.bashrc # update our PATH
          #echo # DEBUG
      ### Cutter
      elif [ "$arg" == "Cutter" ]
        then # Install Cutter:
          wget https://github.com/radareorg/cutter/releases/download/v1.8.3/Cutter-v1.8.3-x64.Linux.AppImage -O /usr/local/sbin/Cutter
          chmod +x /usr/local/sbin/Cutter
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
$(if [[ $(which Steam|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Steam" "Steam desktop app" \
$(if [[ $(which mame|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "MAME" "MAME Arcade Emulator" \
$(if [[ $(which vlc|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "VLC Media Player" "Multimedia player and framework" \
$(if [[ $(which libreoffice|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Libre Office" "Powerful and free office suite" \
$(if [[ $(which thunderbird|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Thunderbird" "Mozilla Thuderbird mail client" \
$(if [[ $(which brave|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Brave" "Much more than a web browser" \
$(if [[ $(which google-chrome|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Chrome" "Google's web browser" \
$(if [[ $(which sublime|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Sublime Editor" "Sublime text editor" \
$(if [[ $(which audacity|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Audacity" "Audacity audio editor" \
$(if [[ $(which gimp|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "GIMP" "GNU Image Manipulation Program" \
$(if [[ $(which clementine|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Clementine" "Modern music player" \
$(if [[ $(which simplenote|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "SimpleNote" "The simplest way to keep notes" \
$(if [[ $(which kdenlive|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Kdenlive" "Video editor program" \
$(if [[ $(which shotcut|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Shotcut" "Video editor program" \
$(if [[ $(which franz|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Franz" "Messaging client app" \
$(if [[ $(which VisualStudio|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Visual Studio Code" "Microsoft's code editor" \
$(if [[ $(which stracer|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "Stracer" "System optimizer app" \
$(if [[ $(which gdebi|wc -l) -eq 1 ]]; then printf "true"; else printf "false"; fi) "GDebi" "Debian .deb GUI installer"); do installApp $app; done
