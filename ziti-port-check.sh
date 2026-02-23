# Global Variables
ASCI_WHITE='\033[01;37m'
ASCI_RESTORE='\033[0m'
ASCI_RED='\033[00;31m'
ASCI_GREEN='\033[00;32m'
ASCI_YELLOW='\033[00;33m'
ASCI_BLUE='\033[00;34m'
ASCI_PURPLE='\033[00;35m'
ZITIx_EXPRESS_COMPLETE=""

: "${GITHUB_REPO_OWNER:=openziti}"
: "${GITHUB_REPO_NAME:=ziti}"

function WHITE {
  echo "${ASCI_WHITE}${1-}${ASCI_RESTORE}"
}
function RED {  # Generally used for ERROR
  echo "${ASCI_RED}${1-}${ASCI_RESTORE}"
}
function GREEN {  # Generally used for SUCCESS messages
  echo "${ASCI_GREEN}${1-}${ASCI_RESTORE}"
}
function YELLOW { # Generally used for WARNING messages
  echo "${ASCI_YELLOW}${1-}${ASCI_RESTORE}"
}
function BLUE {   # Generally used for directory paths
  echo "${ASCI_BLUE}${1-}${ASCI_RESTORE}"
}
function PURPLE { # Generally used for Express Install milestones.
  echo "${ASCI_PURPLE}${1-}${ASCI_RESTORE}"
}

# Checks all ports intended to be used in the Ziti network
function checkZitiPorts {
    local returnCnt=0
    _portCheck "ZITI_CTRL_ADVERTISED_PORT" "Controller"
    returnCnt=$((returnCnt + $?))
    _portCheck "ZITI_ROUTER_PORT" "Edge Router"
    returnCnt=$((returnCnt + $?))
    _portCheck "ZITI_CTRL_EDGE_ADVERTISED_PORT" "Edge Controller"
    returnCnt=$((returnCnt + $?))
    if [[ "${ZITI_ROUTER_LISTENER_BIND_PORT-}" != "" ]]; then
      # This port can be explicitly set but is not always, only check if set
      _portCheck "ZITI_ROUTER_LISTENER_BIND_PORT" "Router Listener Bind Port"
      returnCnt=$((returnCnt + $?))
    fi
    if [[ "returnCnt" -gt "0" ]]; then return 1; fi
    echo -e "$(GREEN "Expected ports are all available")"
    echo ""
}

# Disable shellcheck for parameter expansion error, this function supports multiple shells
# shellcheck disable=SC2296
# Check to ensure the expected ports are available
function _portCheck {
  local portCheckResult envVar envVarValue

  if [[ "${1-}" == "" ]] || [[ "${2-}" == "" ]]; then
    echo -e "_portCheck Usage: _portCheck <port> <portName>"
    return 0
  fi

  envVar="${1-}"
  if [[ -n "$ZSH_VERSION" ]]; then
    envVarValue="${(P)envVar}"
  elif [[ -n "$BASH_VERSION" ]]; then
    envVarValue="${!envVar}"
  else
    echo -e "$(YELLOW "Unknown/Unsupported shell, cannot verify availability of ${2-}'s intended port, proceed with caution")"
    return 0
  fi

  #echo -en "Checking ${2-}'s port (${envVarValue}) "
  printf "Checking %-25s port %-8s" "${2-}" "${envVarValue}"
  portCheckResult=$(lsof -w -i :"${envVarValue}" 2>&1)
  if [[ "${portCheckResult}" != "" ]]; then
      echo -e "$(RED "The intended ${2-} port (${envVarValue}) is currently being used, the process using this port should be closed or the port value should be changed.")"
      echo -e "$(RED "To use a different port, set the port value in ${envVar}")"
      echo -e "$(RED " ")"
      echo -e "$(RED "Example:")"
      echo -e "$(RED "export ${envVar}=1234")"
      echo -e "$(RED " ")"
      return 1
  else
    echo -en "✅ $(GREEN "Open") "
	nc -zv localhost ${envVarValue} &>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "✅ $(GREEN "Available")"
    else
        echo -e "❌ ${RED "NOT available"}"
    fi
  fi
  
	
  return 0
}


checkZitiPorts
