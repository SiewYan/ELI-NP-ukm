#! /usr/bin/env bash

## OpenMPI, EPOCH, VISIT installation
# installation path
test -z "$BUILD_PREFIX" && BUILD_PREFIX="$PWD"
test -z "$INSTALL_PREFIX" && INSTALL_PREFIX="$PWD/local"
test -z "$MAKE" && MAKE="make -j`nproc`"

# installation switches
test -z "$INSTALL_OPENMPI" && INSTALL_OPENMPI="1"
test -z "$INSTALL_EPOCH" && INSTALL_EPOCH="1"
test -z "$INSTALL_VISIT" && INSTALL_VISIT="1"

# packages version
test -z "$OPENMPI_VERSION" && OPENMPI_VERSION="3.1.4"
test -z "$EPOCH_VERSION" && EPOCH_VERSION="1.8.1"
test -z "$VISIT_VERSION" && VISIT_VERSION="3.2.2"

## Disable asserts for production running
#export CPPFLAGS="$CPPFLAGS -DNDEBUG"

###############

## Immediate exit on a command (group) failure and optional debug mode
set -e
test -n "$DEBUG" && set -x
export PATH=$INSTALL_PREFIX/bin:$PATH

function wget_untar { wget --progress=bar:force --no-check-certificate $1 -O- | tar xz; }
function conf { ./configure --prefix=$INSTALL_PREFIX "$@"; }
function mmi { $MAKE "$@" && $MAKE install; }
function mmk { $MAKE "$@"; }

echo "Boostraping..."
echo "Package installation summary"
echo "OpenMPI : $INSTALL_OPENMPI ; v${OPENMPI_VERSION}"
echo "Visit   : $INSTALL_VISIT   ; v${VISIT_VERSION}"
echo "Epoch   : $INSTALL_EPOCH   ; v${EPOCH_VERSION}"

## Make installation directory, with an etc subdir so EPOCH etc. will install bash completion scripts
mkdir -p $INSTALL_PREFIX/etc/bash_completion.d

## Install OpenMPI
if [[ "$INSTALL_OPENMPI" -eq "1" ]]; then
    echo "Installing OpenMPI : v${OPENMPI_VERSION}"; sleep 3
    cd $BUILD_PREFIX
    test -d openmpi-$OPENMPI_VERSION || wget_untar https://download.open-mpi.org/release/open-mpi/v${OPENMPI_VERSION%??}/openmpi-$OPENMPI_VERSION.tar.gz
    cd openmpi-$OPENMPI_VERSION
    mkdir build
    cd build
    conf
    mmi
    echo "Done."; sleep 3
fi

## Install visit
if [[ "INSTALL_VISIT" -eq "1" ]]; then
    echo "Installing VISIT : v${VISIT_VERSION}"; sleep 3
    cd $BUILD_PREFIX
    VISIT_VER=$(echo ${VISIT_VERSION} | tr "." _)
    SYSVER=$(uname -v | awk -F " " '{print $1}' | awk -F "~|-" '{print $3$2}' ); SYSVER=${SYSVER%.*.*}

    # hardcoded to linux x86_64 system
    test -d visit$VISIT_VER.linux-x86_64 || wget_untar https://github.com/visit-dav/visit/releases/download/v$VISIT_VERSION/visit$VISIT_VER.linux-x86_64-${SYSVER,,}.tar.gz

    # append to bash
    TEST=$(grep -q "visit" ${HOME}/.bashrc; echo $?)
    if [[ "$TEST" -eq "1" ]]; then
        echo "export PATH=$BUILD_PREFIX/visit$VISIT_VER.linux-x86_64/bin:PATH" >> ~/.bashrc
    fi

    echo "Done."; sleep 3
fi

## Install EPOCH
# https://github.com/Warwick-Plasma/EPOCH_manuals/releases/download/v4.17.0/epoch_user.pdf
if [[ "$INSTALL_EPOCH" -eq "1" ]]; then
    echo "Installing EPOCH : v${EPOCH_VERSION}"; sleep 3
    cd $BUILD_PREFIX
    test -d epoch-$EPOCH_VERSION || wget_untar https://github.com/Warwick-Plasma/epoch/releases/download/v$EPOCH_VERSION/epoch-$EPOCH_VERSION.tar.gz
    cd epoch-$EPOCH_VERSION
    for i in 1 2 3; do
	cd epoch${i}d
	mmk COMPILER=gfortran
    done
    
    # append to bashrc
    TEST=$(grep -q "COMPILER=" ${HOME}/.bashrc; echo $?)
    if [[ "$TEST" -eq "1" ]]; then
	echo "COMPILER=gfortran" >> ~/.bashrc
    fi
    
    echo "Done."; sleep 3
fi

## Announce the build success
echo "All done."
