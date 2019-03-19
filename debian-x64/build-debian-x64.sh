#!/bin/bash

#Configuration Variables and Parameters

function printSignature() {
  cat ./utils/ascii_art.txt
  echo
}

function printUsage() {
  echo -e "\033[1mUsage:\033[0m"
  echo "$0 [APPLICATION_NAME] [APPLICATION_VERSION]"
  echo
  echo -e "\033[1mOptions:\033[0m"
  echo "  -h (--help)"
  echo
  echo -e "\033[1mExample::\033[0m"
  echo "$0 wso2am 2.6.0"

}

#Start the generator
printSignature

#Argument validation
if [[ "$1" == "-h" ||  "$1" == "--help" ]]; then
    printUsage
    exit 1
fi
if [ -z "$1" ]; then
    echo "Please enter a valid application name for your application"
    echo
    printUsage
    exit 1
else
    echo "Application Name : $1"
fi
if [[ "$2" == [0-9].[0-9].[0-9] ]]; then
    echo "Application Version : $2"
else
    echo "Please enter a valid version for your application (fromat [0-9].[0-9].[0-9])"
    echo
    printUsage
    exit 1
fi

#Parameters
TARGET_DIRECTORY="target"
PRODUCT=${1}
VERSION=${2}
INSTALLATION_DIRECTORY="${PRODUCT}-debian-x64-"${VERSION}
BINARY_SIZE="0 MB"

#Functions
go_to_dir() {
    pushd $1 >/dev/null 2>&1
}

log_info() {
    echo "["$(date +"%Y-%m-%d") $(date +"%T")"] [INFO]" $1
}

log_warn() {
    echo "["$(date +"%Y-%m-%d") $(date +"%T")"] "[WARN]" $1
}

log_error() {
    echo "["$(date +"%Y-%m-%d") $(date +"%T")"] "[ERROR]" $1
}

deleteInstallationDirectory() {
    log_info "Cleaning $TARGET_DIRECTORY directory."
    rm -rf $TARGET_DIRECTORY

    if [[ $? != 0 ]]; then
        log_error "Failed to clean $TARGET_DIRECTORY directory" $?
        exit 1
    fi
}

createInstallationDirectory() {
    if [ -d ${TARGET_DIRECTORY} ]; then
        deleteInstallationDirectory
    fi
    mkdir $TARGET_DIRECTORY

    if [[ $? != 0 ]]; then
        log_error "Failed to create $TARGET_DIRECTORY directory" $?
        exit 1
    fi
}

getProductSize() {
    PRODUCT_DIST_SIZE=$(du -s ./application | awk '{print $1}')
    PRODUCT_SIZE=${PRODUCT_DIST_SIZE}
}

copyDebianDirectory() {
    createInstallationDirectory
    cp -R resources ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}
    chmod -R 755 ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}/DEBIAN
    mkdir -p ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}/usr/share/${PRODUCT}
    mv ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}/copyright  ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}/usr/share/${PRODUCT}

    #Replace parameters
    sed -i -e 's/__PRODUCT_SIZE__/'${PRODUCT_SIZE}'/g' ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}/DEBIAN/control
    sed -i -e 's/__PRODUCT__/'${PRODUCT}'/g' ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}/DEBIAN/control
    sed -i -e 's/__VERSION__/'${VERSION}'/g' ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}/DEBIAN/control
}

copyBuildDirectories() {
    mkdir -p ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}/usr/lib/${PRODUCT}/${VERSION}
    cp -a ./application/. ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}/usr/lib/${PRODUCT}/${VERSION}
    chmod -R o+w ${TARGET_DIRECTORY}/${INSTALLATION_DIRECTORY}/usr/lib/${PRODUCT}/${VERSION}
}

createInstaller() {
    fakeroot dpkg-deb --build target/${INSTALLATION_DIRECTORY}
}

#Main script
log_info "Installer Generating process started."

getProductSize
copyDebianDirectory
copyBuildDirectories
createInstaller

log_info "Build completed."
exit 0
