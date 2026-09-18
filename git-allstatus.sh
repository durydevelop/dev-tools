#! /bin/bash
# TODO:
#       _Se -y e need-... ricontrollare
#       _Opzione -x multiple

Version=1.0.5

# Include script library ('Dot' means 'source', i.e. 'include':)
#. "$DIR/lib.sh"

print-usage() {
    echo "Automate some git operations on all repositories in current folder."
    echo "It execute fetch and stauts and, if needed, ask you for commit, push, pull."
    echo "Without options, only first level of folders are scanned. Use -r option to recurse in sub-folders."
    echo
    echo "Usage: $0 [-p <path>] [-r] [-c] [-h] [-y] [-s] [-x <folder name>]"
    echo "Options:"
    echo -e "-h, --help\t\tPrint this help."
    echo -e "-p, --path <path>\tStart from <path> folder."
    echo -e "-r, --recurse\t\tLook in subdirectories."
    echo -e "-c, --commit-nightly\tForce a nightly commit (if needed)."
    echo -e "\t\t\tThis push a commit on a branch called \"master-nightly\"."
    echo -e "\t\t\tif the branch does not exist, will be created."
    echo -e "\t\t\tN.B. Current branch remains the same."
    echo -e "-x, --exclude <folder name> \tExclude <folder name> folder from git check."
    echo -e "\t\t\tOnly on repositories that are \"not up to date\"."
    echo -e "\t\t\tBranch \"master-nightly\"will be created if missing."
    echo -e "-y, --yes-to-all\tYes to all: don't ask for confermation."
    echo -e "-s, --sync-cmake-helper\tSync cmake helper scripts in /cmake folder before commit."
    echo -e "-v, --verbose\t\tVerbose output only."
}

commit-nightly() {
    git add .
    git commit -am"Nightly Commit"
    
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    
    #Test if master-nightly exists
    if [[ $(git branch | grep "master-nightly") == "" ]]; then
        # does't exists, create it
        echo -e "$f \e[31mmaster-nightly non esiste\e[0m"
        echo -e "$f: \e[33mCreazione...\e[0m"
        if [[ $(git checkout -b master-nightly) == "" ]]; then
            echo -e "$f \e[31mmaster-nightly non è stato creato\e[0m"
            exit
        fi
        echo -e "$f: \e[32m...creato\e[0m"
        # return to current
        git checkout current_branch
    fi
    
    # push on nigthy branch
    git push origin master-nightly
}

status() {
    msg=""
    curr_dir="$1/"
    git_file="$1/.git"
    if [[ ! -e "$git_file" ]]; then
        # no .git
        return;
    fi
    echo -n "Found repo in $curr_dir -> "
    ((repo_count++))
    cd $curr_dir
    if [[ -d cmake ]]; then
        if [[ $UPDATE_CMAKE_HELPER == true ]]; then
            if [[ -d "$DDEV_ROOT/cpp/helpers_cmake" ]]; then
                echo -e "\e[33mUpdate cmake helpers\e[0m"
                res=$(rsync -q $DDEV_ROOT/cpp/helpers_cmake/* ./cmake 2>&1 1>/dev/null)
                if [[ $res == "" ]] ; then
                    echo -e "\e[32mDone\e[0m"
                else
                    echo -e "\e[31mCannot update: $res\e[0m"
                fi
            fi
        fi
    fi
    fetch=$(LC_ALL=C git fetch) # 2>&1 >/dev/null)
    #echo fetch=$fetch
    status=$(LC_ALL=C git status) # 2>&1 >/dev/null)
    #echo status=$status
    if [[ $status == "" ]]; then
        status=$(git status)
    fi
    
    res=$(echo $status | grep "have diverged")
    if [[ $res != "" ]] ; then
        #Need merge
        echo -e "\e[33mMerge da eseguire\e[0m"
        return
    fi
    
    res=$(echo $status | grep "not a git repository")
    if [[ $res != "" ]] ; then
        #Not a git repository
        echo -e "\e[31mNon git\e[0m"
        echo return
        return
    fi
    
    res=$(echo $status | grep "Untracked files")
    if [[ $res != "" ]] ; then
        #Untracked files
        msg="\e[33mNuovi files da aggiungere\e[0m"
        pending_commit=true
    fi
    
    ## Cumulative answers
    res=$(echo $status | grep "Changes not staged")
    if [[ $res != "" ]] ; then
        #Changes not staged for commit
        if [[ $msg != "" ]] ; then
            msg="$msg + "
        fi
        msg="$msg \e[33mCommit da eseguire\e[0m"
        pending_commit=true
    fi
    
    res=$(echo $status | grep "Your branch is behind")
    if [[ $res != "" ]] ; then
        #Need pull
        if [[ $msg != "" ]] ; then
            msg="$msg + "
        fi
        msg="$msg \e[33mPull da eseguire\e[0m"
        pending_pull=true
    fi
    
    res=$(echo $status | grep "Your branch is ahead")
    if [[ $res != "" ]] ; then
        #Need push
        if [[ $msg != "" ]] ; then
            msg="$msg + "
        fi
        msg="$msg \e[33mPush da eseguire\e[0m"
        pending_push=true
    fi
    
    if [[ $msg == "" ]]; then
        res=$(echo $status | grep "nothing to commit")
        if [[ $res != "" ]] ; then
            #Nothing to commit
            echo -e "\e[32mAggiornato\e[0m"
            return
        fi
    else
        ## Show answers
        echo -e $msg
        
        ## Actions
        if [[ $pending_commit ]]; then
            if [[ $FORCE_NIGHTLY_COMMIT == true ]]; then
                echo -e "\e[33mEseguo nightly commit\e[0m"
                commit-nightly
                return
            fi
    
            if [[ $ONLY_VERBOSE == true ]]; then
                return
            fi
            
            if [[ $ASK_TO_EXECUTE == true ]]; then
                echo -n -e "\e[32mCommit and push now (Y/n)\e[0m"
                read -n 1 -r;echo
            else
                echo -e "\e[32mEseguo\e[0m"
                REPLY=Y
            fi
            
            if [[ $REPLY =~ ^[Yy]$ ]] || [[ $REPLY == "" ]]; then
                git add .
                git commit -a -m"$(date)"
                git push
                pending_commit=false
            fi
            return
        fi
        
        if [[ $pending_push ]]; then
            if [[ $ONLY_VERBOSE == true ]]; then
                return
            fi
            
            if [[ $ASK_TO_EXECUTE == true ]]; then
                echo -n -e "\e[32mPush now (Y/n)\e[0m"
                read -n 1 -r; echo
            else
                echo -e "\e[32mEseguo\e[0m"
                REPLY=Y
            fi
            
            if [[ $REPLY =~ ^[Yy]$ ]] || [[ $REPLY == "" ]]; then
                git push
                pending_push=false
            fi
            
            return
        fi
        
        if [[ $pending_pull ]]; then
            if [[ $ONLY_VERBOSE == true ]]; then
                return
            fi
            
            if [[ $ASK_TO_EXECUTE == true ]]; then
                echo -n -e "\e[32mPull now (Y/n)\e[0m"
                read -n 1 -r; echo
            else
                echo -e "\e[32mEseguo\e[0m"
                REPLY=Y
            fi
            
            if [[ $REPLY =~ ^[Yy]$ ]] || [[ $REPLY == "" ]]; then
                git pull
                pending_pull=false
            fi
            
            return
        fi
    fi
}

scan-folder-recurse() {
    for i in "$1"/*;do
        if [ -d "$i" ];then
            if [[ $(basename "$i") == $EXCLUDE_FOLDER ]]; then
                echo -e "Dir $i -> \e[32m esclusa\e[0m"
                continue
            fi
            status $i
            if [[ $RECURSE == true ]]; then
                scan-folder-recurse "$i"
            fi
        #elif [ -f "$i" ]; then
            #echo "file: $i"
        fi
    done
}

#################################### entry-point ####################################
# set default options
START_PATH=$(pwd)
FORCE_NIGHTLY_COMMIT=false
RECURSE=false
ONLY_VERBOSE=false
ASK_TO_EXECUTE=true
repo_count=0

echo "-- $(basename "$0") Ver. $Version --"
# parse command line
POSITIONAL=()
    while [[ $# -gt 0 ]]; do
        key="$1"

        case $key in
            -r|--recurse)
                RECURSE=true
                shift # past argument
                ;;
            -y|--yes-to-all)
                ASK_TO_EXECUTE=false
                shift # past argument
                ;;
            -v|--verbose)
                ONLY_VERBOSE=true
                shift # past argument
                ;;
            -p|--path)
                START_PATH="$2"
                shift # past argument
                shift # past value
                ;;
            -f|--force-commit-nightly)
                FORCE_NIGHTLY_COMMIT=true
                shift # past argument
                ;;
            -x|--exclude)
                EXCLUDE_FOLDER="$2"
                shift # past argument
                shift # past value
                ;;
            -s|--sync-cmake-helper)
                UPDATE_CMAKE_HELPER=true
                shift # past argument
                ;;
            -h|--help)
                print-usage
                exit
                ;;
            *)        # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
        esac
    done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ $POSITIONAL ]]; then
	echo -e "\e[31mUnknown option: ${POSITIONAL[@]}\e[0m"
	print-usage
	exit
fi

#echo START_PATH=$START_PATH
#echo FORCE_NIGHTLY_COMMIT=$FORCE_NIGHTLY_COMMIT
#echo RECURSE=$RECURSE
#echo ASK_TO_EXECUTE=$ASK_TO_EXECUTE
#echo ONLY_VERBOSE=$ONLY_VERBOSE
#echo EXCLUDE_FOLDER=$EXCLUDE_FOLDER

if [[ $FORCE_NIGHTLY_COMMIT == true ]]; then
    ASK_TO_EXECUTE=false
fi

if [[ $ASK_TO_EXECUTE == false ]];then
    if [[ $ONLY_VERBOSE == true ]]; then
        echo -e "\e[33mConflitto di opzioni: l'opzione -v verrà ignotata.\e[0m"
        ONLY_VERBOSE=false
    fi
    
fi

# First this folder
status $START_PATH

# Then 1 level deep (or recurse if -r is set)
scan-folder-recurse $START_PATH
if [[ $repo_count == 0 ]]; then
    if [[ $RECURSE == false ]]; then
        echo "No repo found, try to use -r option"
    fi
else
    echo "-- Processed $repo_count repo --"
fi
