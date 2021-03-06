#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Add user to the docker group
sudo usermod -aG docker $USER

if command -v gnome-shell &> /dev/null
then
  echo "Installing gnome shell extentions"
  mkdir -p ~/.local/share/gnome-shell/extensions
  cp -R $SCRIPT_DIR/gnome-shell-extensions/* ~/.local/share/gnome-shell/extensions/
fi

echo "TBD: install firefox addons"


echo "Install oh-my-zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
mv ~/.zshrc ~/.old-zshrc
ln -s $SCRIPT_DIR/dotfiles/.zshrc ~/.zshrc

echo "Install oh-my-zsh plugins"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

chsh -s $(which zsh)

#echo "Install Jetbrains dotfiles"
#mv ~/.config/JetBrains ~/.config/JetBrains_bck
#ln -s $SCRIPT_DIR/dotfiles/.config/JetBrains ~/.config/

echo "Installing asdf dev env"
zsh -c "$SCRIPT_DIR/asdf.sh"
