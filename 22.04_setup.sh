#! /usr/bin/env bash

VERSION="v0.1"
NAME="Setup Script $VERSION"

## helper functions

function heading1 {
    echo "###"
    echo "# $1"
    echo "###"
}

function heading2 {
    echo ""
    echo "### $1 ###"
    echo ""
}

function _exit {
    echo "exiting..."
    exit 0
}

function checkYesNo {
    echo -n "$1 (y/N): "
    read answer
    
    if [[ $answer == "y" || $answer == "Y" ]]; then
        YesNo=1
    else
        YesNo=0
    fi
}

function checkOSVersion {
    heading2 "Checking OS Version"

    source /etc/os-release
    
    if [[ $VERSION_ID != "22.04" ]]; then
        echo ""
        echo "ERROR: This script is written and tested for Kubuntu 22.04 only!"
        echo ""
        _exit
    fi
    
    heading2 "OS check complete"
}

## install functions

function installUpdates {
    heading2 "Installing all system updates and script dependencies"
    
    sudo apt update
    sudo apt dist-upgrade -y
    sudo apt install wget curl -y
}

function cleanupPackages {
    heading2 "Cleaning up"
    
    sudo apt autoclean -y
    sudo apt autoremove -y
}

function nukeFuckingSnapBullshit {
    heading2 "Removing Snap and Discover integration"
    
    sudo apt purge snapd plasma-discover-backend-snap -y
    
    checkYesNo "Would you like to freeze snap to be never installed again?"
    
    if [ $YesNo -eq 1 ]; then
        heading2 "Sending snap to hell"
        # make sure snap goes to hell and we never see it ever again
        # thanks to https://www.debugpoint.com/remove-snap-ubuntu/
        echo """Package: snapd
        Pin: release a=*
        Pin-Priority: -10
        """ >> /etc/apt/preferences.d/nosnap.pref
    fi
}

function installFlatpak {
    heading2 "Installing Flatpak"
    
    sudo apt install flatpak plasma-discover-backend-flatpak -y
    
    echo ""
    echo ""
    
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    
    checkYesNo "Would you like to install flathub-beta?"
    
    if [ $YesNo -eq 1 ]; then
        heading2 "Installing flathub-beta"
        flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
    fi
}

function installFlatseal {
    checkYesNo "Would you like to install Flatseal for managing Flatpak permissions?"
    
    if [ $YesNo -eq 1 ]; then
        heading2 "Installing Flatseal"
        flatpak install flathub com.github.tchx84.Flatseal
    fi
}

function installAppimageLauncher {
    checkYesNo "Would you like to install AppImageLauncher for easy AppImage integration?"
    
    if [ $YesNo -eq 1 ]; then
        heading2 "Installing AppImageLauncher"
        wget https://github.com/TheAssassin/AppImageLauncher/releases/download/v2.2.0/appimagelauncher_2.2.0-travis995.0f91801.bionic_amd64.deb
        sudo apt install ./appimagelauncher_2.2.0-travis995.0f91801.bionic_amd64.deb -y
        rm ./appimagelauncher_2.2.0-travis995.0f91801.bionic_amd64.deb
    fi
    
}

function _installTuxedoAptRepo {
    # from https://www.tuxedocomputers.com/de/Infos/Hilfe-und-Support/Anleitungen/TUXEDO-Software-Paketquellen-hinzufuegen.tuxedo

    # used for apt version of Firefox and Chromium
    wget -O - https://deb.tuxedocomputers.com/0x54840598.pub.asc | gpg --dearmor > 0x54840598.pub.gpg
    cat 0x54840598.pub.gpg | sudo tee -a /usr/share/keyrings/tuxedo-keyring.gpg > /dev/null
    rm 0x54840598.pub.gpg
    
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/tuxedo-keyring.gpg] https://deb.tuxedocomputers.com/ubuntu jammy main' | sudo tee -a /etc/apt/sources.list.d/tuxedocomputers.list
    
    sudo apt update
}

function installBrowser {
    heading2 "Installing Browser"
    
    choice=`kdialog --radiolist "What Browser would you like to use?" \
        1 "Firefox (PPA)" on \
        2 "Firefox (apt)" off \
        3 "Chromium (apt)" off \
        4 "Brave (apt)" off \
        5 "Ungoogled-Chromium (Flatpak)" off`
    
    if [ $? -eq 0 ]; then
        case $choice in
            1)
            heading2 "Installing Firefox (PPA)"
            sudo add-apt-repository ppa:mozillateam/ppa -y
            
            echo """Package: firefox*
            Pin: release o=LP-PPA-mozillateam
            Pin-Priority: 501
            """ >> /etc/apt/preferences.d/mozillateamppa
            
            sudo apt update
            sudo apt install -t 'o=LP-PPA-mozillateam' firefox -y
            ;;
            2)
            heading2 "Installing Firefox (apt)"
            _installTuxedoAptRepo
            sudo apt install firefox -y
            ;;
            3)
            heading2 "Installing Chromium"
            _installTuxedoAptRepo
            sudo apt install chromium-browser -y
            ;;
            4)
            heading2 "Installing Brave"
            # from https://brave.com/linux/#release-channel-installation
            sudo apt install apt-transport-https curl
            sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
            
            sudo apt update
            sudo apt install brave-browser
            ;;
            5)
            heading2 "Installing Ungoogled-Chromium"
            flatpak install flathub com.github.Eloston.UngoogledChromium
            ;;
            
        esac
    fi
}

## main

function main {

    heading1 "Kubuntu initial setup script by zocker_160 for Kubuntu 22.04 LTS $VERSION"

    checkOSVersion

    checkYesNo "Would you like to start the setup?"
    if [ $YesNo -eq 0 ]; then
        _exit
    fi

    installUpdates
    nukeFuckingSnapBullshit
    installFlatpak
    installFlatseal
    installAppimageLauncher
    installBrowser
    cleanupPackages
    
    heading2 "Setup Done!"
    
    checkYesNo "A reboot is highly recommended, would you like to reboot?"
    if [ $YesNo -eq 1 ]; then
        sudo reboot now
    fi
}

main
