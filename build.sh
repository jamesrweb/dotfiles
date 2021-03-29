#!/usr/bin/env bash

cd "$(dirname "$0")" || exit 1

EMAIL="47126579+jamesrweb@users.noreply.github.com"

function command_exists() {
	if command -v "$1" >/dev/null; then
		return 0
	else
		return 1
	fi
}

function brew_install() {
	case "$2" in
	cask) brew list --cask "$1" &>/dev/null || brew install --cask "$1" ;;
	formula) brew list "$1" &>/dev/null || brew install "$1" ;;
	*) echo "Unknown install method: $2" ;;
	esac
}

function setup_mac() {
	if ! xcode-select -p 1>/dev/null; then
		xcode-select --install
	fi

	if ! command_exists brew; then
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	fi

	# Install everything needed via brew
	brew update

	# Cask installs
	brew tap homebrew/cask-fonts
	brew_install font-fira-code cask
	brew_install iterm2 cask
	brew_install visual-studio-code cask
	brew_install virtualbox cask

	# Non-cask installs
	brew_install git formula
	brew_install zsh formula
	brew_install gpg formula
	brew_install docker formula
	brew_install docker-machine formula
	brew_install docker-compose formula
	brew_install shellcheck formula

	# Setup docker-machine
	if ! docker-machine ls -q | grep -q '^default$'; then
		docker-machine create --driver virtualbox default
	fi

	eval "$(docker-machine env default)"

	# Move vs-code settings
	cp -r ./vscode/. "$HOME/Library/Application Support/Code/User"

	# Install vs-code extensions
	code --install-extension bar9.stories
	code --install-extension benawad.VSinder

	# Configure git
	git config --global commit.gpgsign true
	git config --global init.defaultBranch master
	git config --global user.name "James Robb"
	git config --global user.email "$EMAIL"
	git config --global pull.rebase true
	git config --global push.default current
	git config --global fetch.prune true
	git config --global rebase.autosquash true
	git config --global core.ignorecase false
	git config --global core.editor 'code --wait'
	git config --global diff.tool 'code'
	git config --global difftool.code.cmd 'code --wait --diff $LOCAL $REMOTE'
	git config --global alias.history 'log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit --date=relative'

	# Setup zsh
	if command_exists compaudit; then
		compaudit | xargs chmod g-w
	else
		chmod 755 /usr/local/share/zsh
		chmod 755 /usr/local/share/zsh/site-functions
	fi

	cp ./zsh/.zshrc "$HOME/.zshrc"

	# Setup oh-my-zsh
	if ! [ -d "$HOME/.oh-my-zsh" ]; then
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	fi

	if ! [ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel9k" ]; then
		git clone https://github.com/bhilburn/powerlevel9k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel9k"
	fi

	# Setup SSH
	if ! [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
		ssh-keygen -t ed25519 -C "$EMAIL"
	fi

	if ! [ "$(pgrep -f "[s]sh-agent" | wc -l)" -gt 0 ]; then
		eval "$(ssh-agent -s)"
		if [ "$(ssh-add -l)" == "The agent has no identities." ]; then
			ssh-add -K "$HOME/.ssh/id_ed25519"
		fi
		ssh-agent -k
	fi

	cp ./ssh/config "$HOME/.ssh/config"

	# Generate GPG key if one isn't already in existence
	if [[ "$(gpg --list-secret-keys --keyid-format LONG)" != *"sec"* ]]; then
		gpg --full-generate-key
	fi

	# Move iterm settings
	cp ./iterm/com.googlecode.iterm2.plist "$HOME/Library/Preferences/com.googlecode.iterm2.plist"

	# Final manual steps
	echo "Run: 'gpg --list-secret-keys --keyid-format LONG' to get the signature id."
	echo "Run: 'gpg --armor --export {id}' and add to github."
	echo "Run: 'git config --global user.signingkey {id}' to auto-sign commits."
	echo "Run: 'pbcopy < $HOME/.ssh/id_ed25519.pub' to copy the ssh config to the clipboard and then add it to github."
	echo "Run: 'ssh -T git@github.com' to verify the ssh connection runs properly."

	# Source zsh
	zsh
	source "$HOME/.zshrc"
}

case "${OSTYPE}" in
solaris*) echo "SOLARIS" ;;
darwin*) setup_mac ;;
linux*) echo "LINUX" ;;
bsd*) echo "BSD" ;;
msys*) echo "WINDOWS" ;;
*) echo "Unknown OS: ${OSTYPE}" ;;
esac
