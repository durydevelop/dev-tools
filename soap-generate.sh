#! /bin/bash

Version=1.0.2
DSOAP_H_TEMPLATE=DSoapClass.H.template
DSOAP_CPP_TEMPLATE=DSoapClass.CPP.template
CMAKELISTS_TXT_TEMPLATE=CMakeLists.TXT.template

print-usage() {
    echo "This script create a \"ready (and easy) to use\" cpp class from a wsdl file or url (using gsoap tools)."
    echo "Usage: $(basename $0) <class name> <wsdl infile or url> [-h] [-o <path>] [-n]"
    echo "<class name> is the name of the cpp class to create."
    echo "<wsdl infile or url> is wsdl file or url to read."
    echo "Options:"
    echo -e "-h, --help\t\tPrint this help."
    echo -e "-o, --output <path>\tUse <path> as output folder."
    echo -e "-n, --no-temp-clean Do not clean temp folder."
}

function generate-class() {
    echo "Generating..."
    # .req.xml file names are composed as:
    # serviceNamespace + . + $wsdlName + method
    
    # Cerca i files con estensione .req.xml
    # estrae il basename senza estensione
    # estrae la stringa tra $serviceNamespace.$wsdlName_ e .req.xml (la funzione esposta)
    reqNamespaceArray=()
    while IFS= read -r -d '' file; do
        # basename without extension
        name=$(basename ${file#*/} .req.xml)
        # retain the part after "$serviceNamespace.$wsdlName"
        name=${name##*$serviceNamespace.$wsdlName}
        # add to array
        reqNamespaceArray+=($name)
    done < <(find $tempFolder -maxdepth 1 -name '*.req.xml' -type f -print0)
    
    #echo "reqNamespaceArray founds:"
    #for value in ${reqNamespaceArray[@]}; do
    #    echo -e "\e[33m$value\e[0m"
    #done

    # Cerca i files con estensione .res.xml
    # estrae il basename senza estensione
    # estrae la stringa tra $serviceNamespace.$wsdlName_ e .req.xml (la funzione esposta)
    resNamespaceArray=()
    while IFS= read -r -d '' file; do
        # basename without extension
        name=$(basename ${file#*/} .req.xml)
        # retain the part after "$serviceNamespace.$wsdlName"
        name=${name##*$serviceNamespace.$wsdlName}
        # add to array
        resNamespaceArray+=($name)
    done < <(find $tempFolder -maxdepth 1 -name '*.req.xml' -type f -print0)
    
    #echo "resNamespaceArray founds:"
    #for value in ${resNamespaceArray[@]}; do
    #    echo -e "\e[33m$value\e[0m"
    #done
    
    # Create all
    for (( n=0; n < ${#reqNamespaceArray[*]}; n++)); do
        functionName=${reqNamespaceArray[n]};
        requestName=${serviceNamespace%WSPortBinding*}${reqNamespaceArray[n]//_/_USCORE}
        responseName=${serviceNamespace%WSPortBinding*}${resNamespaceArray[n]//_/_USCORE}
        className=$classNamespace$functionName
        #echo -e "Class \e[33m$className\e[33m\e[0m"
        if [[ ! -d $className ]]; then
            echo -e "Creating folder \e[33m$outputFolder/$className\e[33m\e[0m"
            create_if_not_exists $outputFolder/$className
        fi
        echo -e "In folder \e[33m$outputFolder/$className\e[0m:"
        
        # Replace tags and save $className.h
        echo -e "Generating \e[33m$className.h\e[0m"
        sed "s/<classNamespace>/$classNamespace/g; s/<className>/$className/g; s/<functionName>/$functionName/g; s/<serviceNamespace>/$serviceNamespace/g; s/<requestName>/$requestName/g; s/<responseName>/$responseName/g" $templatesFolder/$DSOAP_H_TEMPLATE > $outputFolder/$className/$className.h
        
        # Replace tags and save $className.cpp
        echo -e "Generating \e[33m$className.cpp\e[0m"
        sed "s/<classNamespace>/$classNamespace/g; s/<className>/$className/g; s/<functionName>/$functionName/g; s/<serviceNamespace>/$serviceNamespace/g; s/<requestName>/$requestName/g; s/<responseName>/$responseName/g;" $templatesFolder/$DSOAP_CPP_TEMPLATE > $outputFolder/$className/$className.cpp
        
		# Replace also <wsdlUrl> with $wsdlUrl in $className.h
		gawk -i inplace -v wsdlUrl=$wsdlUrl '{gsub(/<wsdlUrl>/,wsdlUrl)}1' $outputFolder/$className/$className.cpp
		
		# Replace tags and save CMakeLists..txt
		echo -e "Generating \e[33m"CMakeLists.txt"\e[0m"
        sed "s/<classNamespace>/$classNamespace/g; s/<functionName>/$functionName/g; s/<serviceNamespace>/$serviceNamespace/g; s/<requestName>/$requestName/g; s/<responseName>/$responseName/g" $templatesFolder/$CMAKELISTS_TXT_TEMPLATE > $outputFolder/$className/CMakeLists.txt
        
        # Copy files to folder
        echo -e "Adding lib files"
        cp $tempFolder/{soapC.cpp,soapH.h,soapStub.h,$serviceNamespace.nsmap,soap"$serviceNamespace"Proxy.cpp,soap"$serviceNamespace"Proxy.h} $outputFolder/$className
		cp $templatesFolder/$gsoapVersion/stdsoap2.cpp $templatesFolder/$gsoapVersion/stdsoap2.h $outputFolder/$className
    done
}

# Create $1 folder if does not exists
function create_if_not_exists() {
    if [[ ! -d "$1" ]]; then
        mkdir -p $1
    fi
}

#################################### entry-point ####################################
cleanTemp=true
# Parse command line
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -o|--output)
                outputFolder="$2"
                shift # past argument
                shift # past value
                ;;
        -t|--templates-folder)
                templatesFolder="$2"
                shift # past argument
                shift # past value
                ;;
        -n|--no-temp-clean)
            cleanTemp=false
            shift # past argument
        ;;
        -h|--help)
            print-usage
            exit
        ;;
        *)    # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ $# < 2 ]]; then
    echo -e "\e[1;41mError: missing arguments...\e[0m"
    print-usage
    exit
fi

# Output folder
if [[ ${outputFolder} == "" ]]; then
    outputFolder=$(pwd)
fi

# Templates folder
if [[ ${templatesFolder} == "" ]]; then
    templatesFolder=$(printenv DDEV_GSOAP_TEMPLATES)
fi
if [[ ! -d $templatesFolder ]]; then
	echo -e "\e[1;41mError: template folder not set. Use -t to specifiy folder or set DDEV_GSOAP_TEMPLATES environment variable to folder.\e[0m"
	exit
fi

# Temp folder
tempFolder=$(pwd)/temp
    

echo "-- $(basename "$0") Ver. $Version --"
create_if_not_exists $tempFolder

# wsdl2h
if ! command -v wsdl2h &> /dev/null; then
	echo -e "\e[1;41mError: wsdl2h not found, please install gsoap. Try sudo apt-get install gsoap\e[0m"
	exit
fi
echo -e "Executing \e[33mwsdl2h\e[0m"
wsdl2h -o $tempFolder/wsdl.h $2 2>&1 | grep -i "error"

# soapcpp2
if ! command -v soapcpp2 &> /dev/null; then
	echo -e "\e[1;41mError: soapcpp2 not found, please install gsoap. Try sudo apt-get install gsoap\e[0m"
	exit
fi
echo -e "Executing \e[33msoapcpp2\e[0m"
soapcpp2 -j -CL $tempFolder/wsdl.h -d $tempFolder 2>&1 | grep -i "success\|error"

if [[ ! -f $tempFolder/wsdl.h ]]; then
	echo -e "\e[1;41mError: $tempFolder/wsdl.h has not been created\e[0m"
	exit
fi

classNamespace=$1
wsdlUrl=$2
# Read only first occurence found
readarray -t res <<< $(find $tempFolder -maxdepth 1 -type f -name *.nsmap)
if [[ ${res[0]} == "" ]]; then
	echo -e "\e[1;41mError: $tempFolder/wsdl.h has not been created\e[0m"
	exit
fi
serviceNamespace=$(basename ${res[0]} .nsmap)
wsdlName=$(basename $2 "?wsdl")
wsdlName=${wsdlName//_/_USCORE}
gsoapVersion=$(grep '#if GSOAP_VERSION != ' $tempFolder/soapStub.h)
gsoapVersion=${gsoapVersion##*'#if GSOAP_VERSION != '}

echo "GSoap generated namespaces:"
echo -e "gsoapVersion=\e[33m$gsoapVersion\e[0m"
echo -e "wsdlUrl=\e[33m$wsdlUrl\e[0m"
echo -e "serviceNamespace=\e[33m$serviceNamespace\e[0m"
echo -e "wsdlName=\e[33m$wsdlName\e[0m"
echo -e "classNamespace=\e[33m$classNamespace\e[0m"
echo -e "tempFolder=\e[33m$tempFolder\e[0m"
echo -e "outputFolder=\e[33m$outputFolder\e[0m"
read -p "Continue (Y/n)" -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Nothing done"
    exit 1
fi

# Generate class files
generate-class

if [[ $cleanTemp == true ]]; then
    echo "Deleting all temp files..."
    rm -rf $tempFolder
fi

echo -e "\e[32mDone\e[0m"
echo -e "\e[32mYour classes are in $outputFolder\e[0m"
