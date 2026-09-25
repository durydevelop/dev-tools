##
#Defaults
$DEFAULT_DDEV_ROOT_PATH="$HOME/Dev"

#Params
$Version="0.0.1"
$ENV_DDEV_GSOAP_TEMPLATES="DDEV_GSOAP_TEMPLATES"
$ENV_DDEV_ROOT_PATH="DDEV_ROOT"
$ENV_DDEV_TOOLS_PATH="DDEV_TOOLS"


function CheckExecutionPolicy {
    # Attivazione esecuzione script ps1
    $ret=Get-ExecutionPolicy
    if ($ret -eq 'Restricted') {
        Write-Host -ForegroundColor Green "Attivo esecuzione script ps1"
        Set-ExecutionPolicy RemoteSigned -Force
    }
}

function DirCreateIfNotExists {
    Param ([Parameter(Mandatory)] [String] $DirPath)
    if (-not (Test-Path -LiteralPath $DirPath -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $DirPath
    }
}

# Clona un repository Git se la destinazione non contiene già una cartella .git.
# Esempio:
# Git-CloneIfNotExists "dest-folder" "git@github.com:user/repository.git"

function GitCloneIfNotExists {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Destination,

        [Parameter(Mandatory, Position = 1)]
        [string]$GitUrl
    )

    Write-Host "Check for " -NoNewline
    Write-Host $Destination -ForegroundColor Yellow -NoNewline
    Write-Host " repo " -NoNewline

    $gitDirectory = Join-Path -Path $Destination -ChildPath ".git"

    if (Test-Path -LiteralPath $gitDirectory -PathType Container) {
        Write-Host "OK" -ForegroundColor Green
        return
    }

    Write-Host
    Write-Host "Cloning $GitUrl" -ForegroundColor Yellow

    & git clone -- $GitUrl $Destination

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Cloned " -NoNewline
        Write-Host "OK" -ForegroundColor Green
    }
    else {
        Write-Host "ERROR $LASTEXITCODE" `
            -ForegroundColor White `
            -BackgroundColor Red
    }
}


CheckExecutionPolicy

#Check folders structure
$CURR_DDEV_ROOT_PATH=$env:ENV_DDEV_ROOT_PATH
if ($CURR_DDEV_ROOT_PATH -eq $null) {
	## No DDEV_ROOT found
	# set default
    if ($null -eq $DDEV_ROOT_PATH) {
		# No manual entered root path
        Write-Host -f Green "Seems DDEV-TOOLS are not installed, use $DEFAULT_DDEV_ROOT_PATH as $ENV_DDEV_ROOT_PATH environment?" -NoNewline
		$DDEV_ROOT_PATH=$DEFAULT_DDEV_ROOT_PATH
	}
    else {
		# Manual entered root path
		$DDEV_ROOT_PATH=Resolve-Path $DDEV_ROOT_PATH
        Write-Host -f Green "Use $DDEV_ROOT_PATH as $ENV_DDEV_ROOT_PATH environment?" -NoNewline
	}
	Write-Host " (Y/n) " -NoNewline
    $ret=Read-Host
    if ($ret -eq 'N') {
        Write-Host "Enter directory manually: " -NoNewline
        $DDEV_ROOT_PATH = Read-Host
        if (!(Test-Path $DDEV_ROOT_PATH)) {
            Write-Host -f Green "$DDEV_ROOT_PATH does not exists create it (Y/n) ?" -NoNewline
            $ret=Read-Host
            if ($ret -eq 'N') {
                exit
            }
        }
    }
	DirCreateIfNotExists $DDEV_ROOT_PATH
}
else {
    # DDEV_ROOT found
	Write-Host -f Green "DDEV_ROOT_PATH=$DDEV_ROOT_PATH"
	Write-Host -f Green "CURR_DDEV_ROOT_PATH=$CURR_DDEV_ROOT_PATH"
    if ($null -eq $DDEV_ROOT_PATH) {
		# Manual entered root path
		$DDEV_ROOT_PATH=Resolve-Path $DDEV_ROOT_PATH
		if ($DDEV_ROOT_PATH -ne $CURR_DDEV_ROOT_PATH) {
			# Different from now
			Write-Host -f Green -e -n "Current $ENV_DDEV_ROOT_PATH env is $CURR_DDEV_ROOT_PATH, you entered $DDEV_ROOT_PATH "
			Write-Host -f Green -n "use it as new $ENV_DDEV_ROOT_PATH environment."
			Write-Host "(Y/n)"
            $ret=Read-Host
            if ($ret -eq 'N') {
                exit
            }
            DirCreateIfNotExists $DDEV_ROOT_PATH
			$CURR_DDEV_ROOT_PATH=$DDEV_ROOT_PATH
		}
    }
	else {
		$DDEV_ROOT_PATH=$CURR_DDEV_ROOT_PATH
	}
}
Write-Host -f Green "DDEV_ROOT_PATH=$DDEV_ROOT_PATH"
Write-Host -f Green "CURR_DDEV_ROOT_PATH=$CURR_DDEV_ROOT_PATH"

if ($null -eq $DDEV_ROOT_PATH) {
    Write-Host "Something was wrong, folder <$DDEV_ROOT_PATH> does not exist. Try to use -p option to set new path.\e[0m"
    exit 2
}

#Set-Location $DDEV_ROOT_PATH
Write-Host "DDEV_ROOT is $DDEV_ROOT_PATH"

$DDEV_TOOLS_PATH=Join-Path $DDEV_ROOT_PATH dev-tools

## Create folder structure
Write-Host "Create folder structure..."
# cpp
DirCreateIfNotExists "$DDEV_ROOT_PATH/cpp"

# cpp/helpers_cmake
DirCreateIfNotExists "$DDEV_ROOT_PATH/cpp/helpers_cmake"

# cpp/lib
DirCreateIfNotExists "$DDEV_ROOT_PATH/cpp/lib"

# cpp/src
DirCreateIfNotExists "$DDEV_ROOT_PATH/cpp/src"

# cpp/lib-mcu
DirCreateIfNotExists "$DDEV_ROOT_PATH/cpp/lib-mcu"

# cpp/src-mcu
DirCreateIfNotExists "$DDEV_ROOT_PATH/cpp/src-mcu"

## Clone repositories
Write-Host "Clone repositories..."

# Clone dev-tools
GitCloneIfNotExists $DDEV_TOOLS_PATH https://github.com/durydevelop/dev-tools.git

# Clone helpers_cmake
GitCloneIfNotExists "$DDEV_ROOT_PATH/cpp/helpers_cmake" https://github.com/durydevelop/helpers_cmake.git

## cpp/lib
# Clone dpplib
GitCloneIfNotExists "$DDEV_ROOT_PATH/cpp/lib/dpplib" https://github.com/durydevelop/dpplib.git
# Clone dwebsocket
GitCloneIfNotExists "$DDEV_ROOT_PATH/cpp/lib/dwebsocket" https://github.com/durydevelop/dwebsocket.git
# Clone Qt Advanced Docking
GitCloneIfNotExists "$DDEV_ROOT_PATH/cpp/lib/Qt-Advanced-Docking-System" https://github.com/githubuser0xFFFF/Qt-Advanced-Docking-System.git

## cpp/lib-mcu
# Clone dpplibmcu
GitCloneIfNotExists "$DDEV_ROOT_PATH/cpp/lib-mcu/dpplibmcu" https://github.com/durydevelop/dpplibmcu.git
# Clone raywui
GitCloneIfNotExists "$DDEV_ROOT_PATH/cpp/lib-mcu/raywui" https://github.com/durydevelop/raywui.git

# Update environments
echo "Update environments..."

# Create ddev-env
dir_create_if_not_exists $HOME/.ddev
echo "
export PATH=$DDEV_TOOLS_PATH:\$PATH 
export $ENV_DDEV_ROOT_PATH=$DDEV_ROOT_PATH
export $ENV_DDEV_TOOLS_PATH=$DDEV_TOOLS_PATH
export $ENV_DDEV_GSOAP_TEMPLATES=$DDEV_TOOLS_PATH/gsoap/templates
" > $HOME/.ddev/ddev-env