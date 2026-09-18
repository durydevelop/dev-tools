#!/usr/bin/env bash
set -e			# Exit on error
set -u			# No empty variables ("${VAR:-}" to fix)
set -o pipefail	# Secure pipes
IFS=$'\n\t'		# fix spaces in filenames

### =========================
### Helpers
### =========================
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'
BOLD='\033[1m'
NC='\033[0m' # No Color
BG_RED='\033[41m'

echo_info()  { echo -e "${BOLD}${GREEN}$1${NC}"; }
echo_ask()   { echo -e "${BOLD}${WHITE}$1${NC}"; }
echo_warn()  { echo -e "${BOLD}${YELLOW}$1${NC}"; }
echo_error() { echo -e "${BOLD}${WHITE}${BG_RED}$1${NC}"; }

function install_if_not_exists() {
	local PKG="$1"
    	local CMD="${2:-}"
	local MISSING=0
	if [[ -z "$CMD" ]]; then
		# 2nd argument not found use dpkg
		# search for "$PKG " or "$PKG:" (for lib like libboost-dev:amd64)
		#RET=$(dpkg -l | grep "$1 \|$1:")
		RET=$(dpkg -s "$PKG")
		#echo "RET=$RET"
		if [[ -z $RET ]];then
		# pkg not found
		MISSING=1
	    fi
	else
	    if ! command -v "$CMD" &> /dev/null; then
		# command not found
		MISSING=1
	    fi
	fi
	
	if [[ $MISSING == 1 ]]; then
		echo ""
		if prompt_yes_no "is not installed, install it?"; then
			sudo apt-get install -y $PKG;
			if [ $? -eq 0 ]; then
				echo_info "install done\e[0m"
			else
				return 0
			fi

			sudo apt-get install -y -f
			if [ ! $? -eq 0 ]; then
				echo_error "Missed dependency install failed"
				return 0
			fi
		fi
		return 1
	fi
}

write_line_in_file_if_not_exists() {
    local file="$1"
    local line="$2"

    if [[ -f "$file" ]]; then
        grep -qxF "$line" "$file" || echo "$line" >> "$file"
    else
        echo_error "$file non trovato"
    fi
}

prompt_yes_no() {
    local msg=$(echo_ask $1)
    read -r -p "$msg (Y/n) " reply
    [[ ! "$reply" =~ ^[Nn]$ ]]
}

### =========================================================================================
### ====================================== Entry-point ======================================
### =========================================================================================
if [[ $EUID -eq 0 ]]; then
  echo_error "Non eseguire lo script come root"
  exit 1
fi

### =========================
### Load OpenZiti functions
### =========================
wget -qO /tmp/ziti-cli-functions.sh https://get.openziti.io/ziti-cli-functions.sh
source /tmp/ziti-cli-functions.sh

### =========================
### OpenZiti install check
### =========================
if [[ -d "$HOME/.ziti" ]]; then
    if prompt_yes_no "Seems open-ziti is already installed, remove it?"; then
	
		set +e
        echo_info "Stopping services..."
        sudo systemctl stop ziti-controller 2>/dev/null
        sudo systemctl disable ziti-controller 2>/dev/null

        sudo systemctl stop ziti-router 2>/dev/null
        sudo systemctl disable ziti-router 2>/dev/null

        echo_info "Removing systemd services..."
        sudo rm -f /etc/systemd/system/ziti-controller.service
        sudo rm -f /etc/systemd/system/ziti-router.service

        sudo systemctl daemon-reload

		echo_info "Removing $HOME/.ziti"
		sudo rm -rf "$HOME/.ziti"

        echo_info "Removing binaries..."
        sudo rm -f /usr/local/bin/ziti*
        sudo rm -f /usr/bin/ziti*

        echo_info "Removing ~/.ziti"
        rm -rf "$HOME/.ziti"
		
		if [[ ! -z "${ZITI_HOME:-}" ]]; then
			echo "Unset ziti env"
			unsetZitiEnv
		fi
		
        echo_info "OpenZiti removed."
		
		if [[ ! -z $(which ziti) ]]; then
			echo_error "Ziti not removed"
			exit
		fi
		
		if [[ ! -z $(systemctl list-unit-files | grep ziti) ]]; then
			echo_error "Ziti not removed"
			exit
		fi
		set -e
    fi
fi

### =========================
### Firewall (Ubuntu-friendly)
### =========================
if prompt_yes_no "Configure firewall (ufw)?"; then
	echo_info "Configurazione firewall (ufw)"
	install_if_not_exists ufw

	for port in 8440 8441 8442 8443 10080; do
	  sudo ufw allow "${port}/tcp"
	done

	sudo ufw reload || true
fi

### =========================
### OpenZiti environment
### =========================
echo_info "Impostazione variabili ambiente OpenZiti"
export EXTERNAL_IP="$(curl -fsSL eth0.me)"
export ZITI_CTRL_EDGE_IP_OVERRIDE="$EXTERNAL_IP"
export ZITI_CTRL_ADVERTISED_ADDRESS="${EXTERNAL_DNS:-$EXTERNAL_IP}"
export ZITI_CTRL_ADVERTISED_PORT=8440
export ZITI_CTRL_EDGE_ADVERTISED_ADDRESS="${EXTERNAL_DNS:-$EXTERNAL_IP}"
export ZITI_CTRL_EDGE_ADVERTISED_PORT=8441
export ZITI_ROUTER_ADVERTISED_ADDRESS="${EXTERNAL_DNS:-$EXTERNAL_IP}"
export ZITI_ROUTER_IP_OVERRIDE="$EXTERNAL_IP"
export ZITI_ROUTER_PORT=8442

### =========================
### Install OpenZiti
### =========================
echo_info "Avvio expressInstall"
expressInstall

### =========================
### Systemd units
### =========================
echo_info "Creazione unità systemd"
createControllerSystemdFile
createRouterSystemdFile "${ZITI_ROUTER_NAME}"

echo_info "Stop temporaneo controller/router"
stopController || true
stopRouter || true

echo_info "Installazione servizi systemd"
sudo cp "${ZITI_HOME}/${ZITI_CTRL_NAME}.service" /etc/systemd/system/ziti-controller.service
sudo cp "${ZITI_HOME}/${ZITI_ROUTER_NAME}.service" /etc/systemd/system/ziti-router.service

sudo sudo systemctl daemon-reexec
sudo sudo systemctl daemon-reload
sudo sudo systemctl enable --now ziti-controller ziti-router

### =========================
### Status
### =========================
echo_info "Stato servizi"
sudo sudo systemctl --no-pager status ziti-controller
sudo sudo systemctl --no-pager status ziti-router

### =========================
### Shell environment
### =========================
ENV_FILE="$HOME/.ziti/quickstart/$(hostname -s)/$(hostname -s).env"

if prompt_yes_no "Vuoi aggiornare il tuo file di shell (.bashrc/.zshrc/.profile)?"; then
  if [[ -f "$HOME/.bashrc" ]]; then
    TARGET="$HOME/.bashrc"
  elif [[ -f "$HOME/.zshrc" ]]; then
    TARGET="$HOME/.zshrc"
  else
    TARGET="$HOME/.profile"
  fi

  LINE=". \"$ENV_FILE\""
  write_line_in_file_if_not_exists "$TARGET" "$LINE"
  # shellcheck source=/dev/null
  source "$TARGET"
fi

### =========================
### ZAC (Ziti Admin Console)
### =========================
if prompt_yes_no "Installare ZAC (Ziti Admin Console)?"; then

    # carica env se necessario
    if [[ -z "${ZITI_HOME:-}" ]]; then
        # shellcheck source=/dev/null
        source "$ENV_FILE"
    fi

    if [[ -z "${ZITI_HOME:-}" ]]; then
        echo_error "ZITI_HOME non impostato, abort"
        exit 1
    fi

    ZAC_DIR="${ZITI_HOME}/zac"
    YAML_FILE="${ZITI_HOME}/$(hostname -s).yaml"
	
	if [[ -n "$ZAC_DIR" ]]; then
		echo_info "Download ZAC"
		wget -qO /tmp/ziti-console.zip \
			https://github.com/openziti/ziti-console/releases/latest/download/ziti-console.zip

		echo_info "Unzip in ${ZAC_DIR}"
		mkdir -p "$ZAC_DIR"
		unzip -oq /tmp/ziti-console.zip -d "$ZAC_DIR"
	fi

	echo "📝 Update YAML_FILE"

if grep -Eq '^[[:space:]]*#[[:space:]]*-?[[:space:]]*binding:[[:space:]]*zac' "$YAML_FILE"; then
    echo "⚠️  binding zac trovato ma commentato"
fi

if ! grep -Eq '^[[:space:]]*-[[:space:]]*binding:[[:space:]]*zac' "$YAML_FILE"; then
cat <<EOF >> "$YAML_FILE"
      - binding: zac
        options:
          location: ./zac
          indexFile: index.html
EOF
    echo "✅ binding zac aggiunto"
else
    echo "✔ binding zac già attivo"
fi

    echo_info "Restart ziti-controller"
    sudo systemctl restart ziti-controller
fi

ziti-port-check.sh
echo_info "Installazione OpenZiti completata con successo"
