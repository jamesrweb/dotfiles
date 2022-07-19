#!/usr/bin/env bash

cd "$(dirname "$0")" || exit 1

EMAIL="47126579+jamesrweb@users.noreply.github.com"
SSH_FILE_LOCATION="$HOME/.ssh/id_ed25519"

case "$OSTYPE" in
solaris*) echo "SOLARIS" ;;
darwin*) setup_mac ;;
linux*) echo "LINUX" ;;
bsd*) echo "BSD" ;;
msys*) setup_windows ;;
*) echo "Unknown OS: $OSTYPE" ;;
esac

function command_exists() {
	if command -v "$1" >/dev/null; then
		return 0
	fi

	return 1
}

function file_exists() {
	if test -f "$1"; then
		return 0
	fi

	return 1
}

function directory_exists() {
	if test -d "$1"; then
		return 0
	fi

	return 1
}

function configure_git() {
	git config --global alias.count-lines "! git log --author=\"\$1\" --pretty=tformat: --numstat | awk '{ add += \$1; subs += \$2; loc += \$1 - \$2 } END { printf \"added lines: %s, removed lines: %s, total lines: %s\n\", add, subs, loc }' #"
	git config --global alias.history 'log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit --date=relative'
	git config --global commit.gpgsign true
	git config --global core.editor 'code --wait'
	git config --global core.ignorecase false
	git config --global diff.tool 'code'
	git config --global difftool.code.cmd "code --wait --diff $LOCAL $REMOTE"
	git config --global fetch.prune true
	git config --global init.defaultBranch master
	git config --global pull.rebase true
	git config --global push.default current
	git config --global rebase.autosquash true
	git config --global user.email "$EMAIL"
	git config --global user.name "James Robb"
        git config --global --add --bool push.autoSetupRemote true
}

function install_vs_code_extensions() {
	code --install-extension elmtooling.elm-ls-vscode
	code --install-extension bmewburn.vscode-intelephense-client
	code --install-extension ronvanderheijden.phpdoc-generator
}

function generate_ssh_keys() {
	if ! file_exists "$HOME/.ssh/id_ed25519.pub"; then
		ssh-keygen -t ed25519 -C "$EMAIL"
	fi
}

function apply_global_ssh_configuration() {
	cp ./ssh/config "$HOME/.ssh/config"
}

function final_manual_steps_information() {
	echo "Run: 'gpg --list-secret-keys --keyid-format LONG' to get the signature id."
	echo "Run: 'gpg --armor --export {id}' and add to github."
	echo "Run: 'git config --global user.signingkey {id}' to auto-sign commits."
	echo "Run: 'pbcopy < $HOME/.ssh/id_ed25519.pub' to copy the ssh config to the clipboard and then add it to github."
	echo "Run: 'ssh -T git@github.com' to verify the ssh connection runs properly."
}

function generate_gpg_key() {
	if [[ "$(gpg --list-secret-keys --keyid-format LONG)" != *"sec"* ]]; then
		gpg --full-generate-key
	fi
}

function configure_zsh_permissions() {
	if command_exists compaudit; then
		compaudit | xargs chmod g-w
	else
		chmod 755 /usr/local/share/zsh
		chmod 755 /usr/local/share/zsh/site-functions
	fi
}

function setup_oh_my_zsh() {
	if ! directory_exists "$HOME/.oh-my-zsh"; then
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	fi
}

function setup_oh_my_zsh_theme() {
	brew_install_formula romkatv/powerlevel10k/powerlevel10k
	echo -e "source $(brew --prefix)/opt/powerlevel10k/powerlevel10k.zsh-theme" >>~/.zshrc
}

function source_zsh() {
	zsh

	if file_exists "$HOME/.zshrc"; then
		# The shellcheck error code SC1091 needs disabled here.
		# This is because the sourced file may not exist on the system when shellcheck is ran.
		# That means that shellcheck believes we are doing something wrong by sourcing a non-existant file.
		# As `zsh` creates a default rc file and we copy in our custom one on top of that, we know it will be there.
		# In turn, we can safely ignore this specific error in this specific use-case.
		# shellcheck disable=SC1091
		source "$HOME/.zshrc"
	else
		echo "Something went wrong. I cannot find the '.zshrc' file but it should be here: '$HOME/.zshrc'"
	fi
}

function setup_brew() {
	if ! command_exists brew; then
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	fi

	brew update
	brew tap homebrew/cask-fonts
}

function setup_choco() {
	if ! command_exists choco; then
		powershell "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
	fi

	# Allow default -y flag to be set for installs and upgrades
	choco feature enable -n allowGlobalConfirmation
}

function brew_install_cask() {
	brew list --cask "$1" &>/dev/null || brew install --cask "$1"
}

function brew_install_formula() {
	brew list "$1" &>/dev/null || brew install "$1"
}

function choco_install() {
	choco install "$1"
}

function setup_mac() {
	if ! xcode-select -p 1>/dev/null; then
		xcode-select --install
	fi

	setup_brew

	brew_install_cask docker
	brew_install_cask font-fira-code
	brew_install_cask iterm2
	brew_install_cask postman
	brew_install_cask powershell
	brew_install_cask spotify
	brew_install_cask steam
	brew_install_cask vscode

	brew_install_formula composer
	brew_install_formula dotnet
	brew_install_formula elm
	brew_install_formula git
	brew_install_formula gpg
	brew_install_formula nodejs
	brew_install_formula php
	brew_install_formula python3
	brew_install_formula shellcheck
	brew_install_formula shfmt
	brew_install_formula vscode
	brew_install_formula zsh

	# Configure installed applications
	install_vs_code_extensions
	configure_git
	configure_zsh_permissions

	# Move vs-code settings
	cp -r ./vscode/. "$HOME/Library/Application Support/Code/User"

	# Copy over ZSH settings
	cp ./zsh/.zshrc "$HOME/.zshrc"

	setup_oh_my_zsh
	setup_oh_my_zsh_theme

	# Install zsh plugins
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"/plugins/zsh-syntax-highlighting
	git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"/plugins/zsh-autosuggestions

	generate_ssh_keys

	if ! [ "$(pgrep -f "[s]sh-agent" | wc -l)" -gt 0 ]; then
		ssh-agent -s
		if [ "$(ssh-add -l)" == "The agent has no identities." ]; then
			# The -K option is OSX specific.
			# It adds the private key password into the OSX keychain.
			# This allows your normal login info to unlock it for use with SSH.
			ssh-add -K "$SSH_FILE_LOCATION"
		fi
		ssh-agent -k
	fi

	apply_global_ssh_configuration
	generate_gpg_key

	# Move iterm settings
	cp ./iterm/com.googlecode.iterm2.plist "$HOME/Library/Preferences/com.googlecode.iterm2.plist"

	source_zsh
	final_manual_steps_information
}

function setup_windows() {
	setup_choco

	# Install everything needed via choco
	choco_install composer
	choco_install docker-desktop
	choco_install dotnet-sdk
	choco_install elm-platform
	choco_install firacode
	choco_install git
	choco_install gnupg
	choco_install microsoft-windows-terminal
	choco_install nodejs
	choco_install ntop.portable # htop for windows
	choco_install php
	choco_install postman
	choco_install powershell-core
	choco_install python3
	choco_install shellcheck
	choco_install spotify
	choco_install steam
	choco_install vscode

	# Move vs-code settings
	cp -r ./vscode/. "$HOME/AppData/Roaming/Code/User"

	# Configure installed applications
	install_vs_code_extensions
	configure_git
	generate_ssh_keys

	if ! [ "$(ps | findstr "[s]sh-agent" | Measure-Object -line | Select-Object -expand Lines)" -gt 0 ]; then
		# Set the ssh-agent to be non-disabled by default and require manual starts
		Get-Service -Name ssh-agent | Set-Service -StartupType Manual

		ssh-agent -s

		if [ "$(ssh-add -l)" == "The agent has no identities." ]; then
			ssh-add "$SSH_FILE_LOCATION"
		fi

		ssh-agent -k
	fi

	apply_global_ssh_configuration
	generate_gpg_key
	final_manual_steps_information
}
