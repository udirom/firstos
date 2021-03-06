#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/debug.sh"
bash -c "$SCRIPT_DIR/setup_btrfs.sh"

echo "Optimizing dnf"
sudo echo 'fastestmirror=1' | sudo tee -a /etc/dnf/dnf.conf
sudo echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf
sudo echo 'deltarpm=true' | sudo tee -a /etc/dnf/dnf.conf

echo "Upgrade packages"
sudo dnf upgrade --refresh -q -y
sudo dnf check
sudo dnf autoremove -y -q

echo "Upgrade device firmware"
sudo fwupdmgr get-devices
sudo fwupdmgr refresh --force
sudo fwupdmgr get-updates
sudo fwupdmgr update

echo "Enable non free repositories"
sudo dnf install -y  https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

sudo dnf upgrade --refresh -y -q
sudo dnf groupupdate -y core
sudo dnf install -y -q rpmfusion-free-release-tainted
sudo dnf install -y -q dnf-plugins-core

echo "Enable flatpak"
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak update

read -p "Do you want to install Nvidia drivers? (y/N) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Install Nvidia drivers"
    sudo dnf install -y akmod-nvidia # rhel/centos users can use kmod-nvidia instead
    sudo dnf install -y xorg-x11-drv-nvidia-cuda #optional for cuda/nvdec/nvenc support
    sudo dnf install -y xorg-x11-drv-nvidia-cuda-libs
    sudo dnf install -y vdpauinfo libva-vdpau-driver libva-utils
    sudo dnf install -y vulkan
else
    sudo bash -c "echo blacklist nouveau > /etc/modprobe.d/blacklist-nvidia-nouveau.conf"
    sudo bash -c "echo options nouveau modeset=0 >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf"
fi

computer_model=$(sudo dmidecode | grep -oP 'Version: \KThinkPad X1 Extreme')
if [ computer_model == "ThinkPad X1 Extreme" ]
then
    read -p "Do you want to fix trackpad issues for? (y/N) " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        sudo sh -c "echo 'options psmouse synaptics_intertouch=0' >> /etc/modprobe.d/trackpad.conf"
    fi
fi

echo "Install Gnome tweaks and extensions"
sudo dnf install -y -q gnome-extensions-app gnome-tweaks gnome-shell-extension-appindicator

echo "Install fonts"
sudo dnf install -y fira-code-fonts 'mozilla-fira*' 'google-roboto*'
curl -sS https://webinstall.dev/nerdfont | bash &>/dev/null

git clone https://github.com/powerline/fonts
cd fonts
./install.sh &>/dev/null
cd ..
rm -Rf fonts

sudo fc-cache -f -v &>/dev/null

echo "Install timeshift"
sudo dnf install -y timeshift

echo "Install utilities"
sudo dnf install -y \
    catfish \
    dnfdragora-gui \
    autojump-zsh \
    autojump-fish \
    jq \
    ccze \
    util-linux-user \
    git \
    git-lfs \
    unrar \
    gparted \
    fd-find \
    ca-certificates \
    gnupg \
    make \
    curl \
    flameshot \
    wget \
    easy-rsa \
    python3-testresources \
    python3-devel \
    openssl-devel \
    libffi-devel \
    zlib \
    bzip2-libs \
    readline-devel \
    sqlite-libs \
    llvm \
    ncurses-devel \
    xz \
    tk-devel \
    libxml2-devel \
    xmlsec1 \
    libffi-devel \
    lzma-sdk \
    tig \
    zsh \
    fish \
    fzf \
    tmux \
    vim \
    autojump \
    lsd \
    unzip \
    p7zip \
    p7zip-plugins \
    lsof \
    multitail \
    bat \
    ranger \
    cmake \
    glances

sudo mv /usr/bin/bat /usr/bin/batcat

echo "build essentials"
sudo dnf install -y gcc \
    gcc-g++ \
    make \
    autoconf \
    automake \
    kernel-devel \
    redhat-rpm-config

if ! command -v appimagelauncherd &> /dev/null
then
    echo "Install Appimagelauncher"
    sudo rpm -i https://github.com$(wget -q https://github.com/TheAssassin/AppImageLauncher/releases -O - | egrep "appimagelauncher.+x86_64.rpm" | head -n 1 | cut -d '"' -f 2)
fi

if ! command -v gh &> /dev/null
then
    echo "Installing Github CLI"
    sudo rpm -i https://github.com$(wget -q https://github.com/cli/cli/releases -O - | egrep "gh_.+linux_amd64.rpm" | head -n 1 | cut -d '"' -f 2)

if ! command -v rsfetch &> /dev/null
then
	echo "Installing rsfetch (fast neofetch)"
	wget https://github.com$(wget -q https://github.com/rsfetch/rsfetch/releases -O - | egrep "download/.+rsfetch" | head -n 1 | cut -d '"' -f 2) &>/dev/null
	sudo chmod +x rsfetch
	sudo mv rsfetch /usr/local/bin
fi

if ! command -v mailspring &> /dev/null
then
	echo "Installing Mailspring email client"
	sudo dnf install -y lsb-core-noarch
	sudo rpm -i "https://github.com$(wget -q https://github.com/Foundry376/Mailspring/releases -O - | egrep "mailspring.+x86_64.rpm" | head -n 1 | cut -d '"' -f 2)"
fi

echo "Install mscore fonts"
sudo dnf install -y curl cabextract xorg-x11-font-utils fontconfig
sudo rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm

echo "Install multimedia codecs"
sudo dnf install -y vlc
sudo dnf groupupdate -y sound-and-video
sudo dnf install -y libdvdcss
sudo dnf install -y gstreamer1-plugins-{bad-\*,good-\*,ugly-\*,base} gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel ffmpeg gstreamer-ffmpeg 
sudo dnf install -y lame\* --exclude=lame-devel
sudo dnf group upgrade -y --with-optional Multimedia

read -p "Do you want to install lenovo power optimizations? (y/N) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Power management optimization"
    sudo dnf install -y tlp tlp-rdw
    sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf install -y https://repo.linrunner.de/fedora/tlp/repos/releases/tlp-release.fc$(rpm -E %fedora).noarch.rpm
    sudo dnf install -y kernel-devel akmod-acpi_call akmod-tp_smapi
fi

if ! command -v docker &> /dev/null
then
    echo "Install Docker"

    sudo dnf -y install dnf-plugins-core

    sudo dnf config-manager -y \
        --add-repo \
        https://download.docker.com/linux/fedora/docker-ce.repo


    sudo dnf install -y docker-ce docker-ce-cli containerd.io
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo groupadd docker
    sudo systemctl start docker
    #dockerd-rootless-setuptool.sh install --force
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service

    sudo dnf autoremove -y
fi

if ! command -v dive &> /dev/null
then
    sudo rpm -i https://github.com$(wget -q https://github.com/wagoodman/dive/releases -O - | egrep "dive.+linux_amd64.rpm" | head -n 1 | cut -d '"' -f 2)
fi

# Install nonfree apps
git clone https://github.com/rpmfusion-infra/fedy.git

if ! command -v jetbrains-toolbox &> /dev/null
then
    echo "Install Jetbrains toolbox"
    chmod +x fedy/plugins/jetbrains-toolbox.plugin/install.sh
    (cd fedy/plugins/jetbrains-toolbox.plugin/ && sudo su root bash -c ./install.sh)
    # Handle change sync slowness
    sudo sh -c "echo fs.inotify.max_user_watches=524288 >> /etc/sysctl.conf"
fi


if ! command -v postman &> /dev/null
then
    echo "Install Postman"
    chmod +x fedy/plugins/postman.plugin/install.sh
    (cd fedy/plugins/postman.plugin/ && sudo su root bash -c ./install.sh)
fi

if ! command -v simplenote &> /dev/null
then
    echo "Install Simplenote"
    chmod +x fedy/plugins/simplenote.plugin/install.sh
    (cd fedy/plugins/simplenote.plugin/ && sudo su root bash -c ./install.sh)
fi

# Cleanup Fedy
sudo rm -rf fedy

if ! command -v slack &> /dev/null
then
    echo "Install Slack"
    sudo dnf copr enable jdoss/slack-repo -y
    sudo dnf install slack-repo -y
    sudo dnf install slack -y
fi

if ! command -v spotify &> /dev/null
then
    echo "Install spotify"
    sudo dnf config-manager --add-repo=https://negativo17.org/repos/fedora-spotify.repo  
    sudo dnf -y install spotify-client 
fi

if ! command -v brave-browser &> /dev/null
then
    echo "Install Brave browser"
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/x86_64/
    sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
    sudo dnf install -y brave-browser
fi

if ! command -v code &> /dev/null
then
    echo "Install Vscode"
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf check-update
    sudo dnf install -y code
fi


if ! command -v zoom &> /dev/null
then
    echo "Install Zoom"
    sudo dnf install -y ibus-m17n
    sudo rpm -i https://zoom.us/client/latest/zoom_$(uname -m).rpm
fi


# Install Appimages
mkdir -p ~/Applications

echo "Install walc Appimage to Applications"
wget -c https://github.com/$(wget -q https://github.com/cstayyab/WALC/releases -O - | grep "walc.AppImage" | head -n 1 | cut -d '"' -f 2) -P ~/Applications/
chmod +x ~/Applications/walc.AppImage


if ! command -v telegram-desktop &> /dev/null
then
    echo "Install Telegram"
    sudo dnf copr enable -y rommon/telegram
    sudo dnf install -y telegram-desktop
fi

if ! command -v starship &> /dev/null
then
	echo "Installing starship prompt"
	sudo sh -c "$(curl -fsSL https://starship.rs/install.sh)" "" -y
fi

zsh -c "$SCRIPT_DIR/user_setup.sh"
