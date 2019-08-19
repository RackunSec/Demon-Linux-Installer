#!/bin/bash
IFS=$'\n' # required for for() loop

installApp (){
  arg=$1;
  arg=$(echo $arg|sed -r 's/TRUE\|([^|]+)\|.*/\1/');
  #printf "Installing app: $arg\n"
  if [ "$arg" == "Spotify" ]
    then # Install Spotify:
      echo "[+] Spots"
  elif [ "$arg" == "Cutter" ]
    then # Install Cutter:
      echo "[+] Cuts"
  fi
}

for app in $(yad --width=600 --height=400 --title="Demon Linux - Install Extra Apps"\
 --list --checklist --column=Install --column="App Name" --column=Description \
 --image=/usr/share/demon/images/icons/128-icon-color.png \
 --window-icon=/usr/share/demon/images/icons/128-icon.png \
 --text="\n\nPlease choose any additional apps that you would like installed from the choices below.\n" \
false "Spotify" "Spotify desktop app" \
false "Cutter" "Cutter reverse engineering tool" \
false "Atom" "Atom IDE" \
false "Eclipse" "Eclipse IDE for Java" \
false "Steam" "Steam desktop app" \
false "MAME" "MAME Arcade Emulator" \
false "VLC Media Player" "Multimedia player and framework" \
false "Libre Office" "Powerful and free office suite" \
false "Thunderbird" "Mozilla Thuderbird mail client" \
false "Brave" "Much more than a web browser" \
false "Chrome" "Google's web browser" \
false "Sublime Editor" "Sublime text editor" \
false "Audacity" "Audacity audio editor" \
false "GIMP" "GNU Image Manipulation Program" \
false "Clementine" "Modern music player" \
false "SimpleNote" "The simplest way to keep notes" \
false "Kdenlive" "Video editor program" \
false "Shotcut" "Video editor program" \
false "Franz" "Messaging client app" \
false "Visual Studio Code" "Microsoft's code editor" \
false "Stracer" "System optimizer app" \
false "GDebi" "Debian .deb GUI installer"); do installApp $app; done
