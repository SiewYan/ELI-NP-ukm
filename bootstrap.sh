#! /usr/bin/env bash

# where are we:
NODE_NAME=$(uname -n | grep -q "dicc.um.edu.my"; echo $?)
NODE=$(uname -n | awk -F "." '{print $1}')

## OpenMPI, EPOCH, VISIT installation
# installation path
test -z "$BUILD_PREFIX" && BUILD_PREFIX="$PWD"
test -z "$INSTALL_PREFIX" && INSTALL_PREFIX="$PWD/local"
test -z "$MAKE" && MAKE="make -j`nproc`"

# installation switches
test -z "$INSTALL_OPENMPI" && INSTALL_OPENMPI="1"
test -z "$INSTALL_VISIT" && INSTALL_VISIT="0" # require gcc 9.0 X to work, skip
test -z "$INSTALL_EPOCH" && INSTALL_EPOCH="1"

# packages version
test -z "$OPENMPI_VERSION" && OPENMPI_VERSION="4.1.4"
test -z "$VISIT_VERSION" && VISIT_VERSION="3.3.1"
test -z "$EPOCH_VERSION" && EPOCH_VERSION="4.18.0"

## Disable asserts for production running
#export CPPFLAGS="$CPPFLAGS -DNDEBUG"

## turn-off OpenMPI and Visit in DICC
if [[ "$NODE_NAME" -eq "0" ]]; then
    INSTALL_VISIT="0"
    INSTALL_OPENMPI="0"
fi

###############

## Immediate exit on a command (group) failure and optional debug mode
set -e
test -n "$DEBUG" && set -x
export PATH=$INSTALL_PREFIX/bin:$PATH

function wget_untar { wget --progress=bar:force --no-check-certificate $1 -O- | tar xz; }
function conf { ../configure --prefix=$INSTALL_PREFIX "$@"; }
function mmi { $MAKE "$@" && $MAKE install; }
function mmk { $MAKE "$@"; }
function sysinfo {
    ## ONLY TEST FOR
    ## 1.) Ubuntu20
    ## 2.) Centos8
    ## 3.) Centos7
    ## 4.) Debian10 (Default)
    TEST=$(uname -a | grep -q "Ubuntu"; echo $?)
    if [[ "$TEST" -eq "0" ]]; then
	SYSVER=$(uname -v | awk -F " " '{print $1}' | awk -F "~|-" '{print $3$2}' ); SYSVER=${SYSVER%.*.*}
    else
	OSTEST=$(uname -r | grep -q "el"; echo $?)
	if [[ "$OSTEST" -eq 0 ]]; then
	    ELTEST=$(uname -r | grep -q "el8"; echo $?)
	    if [[ "$ELTEST" -eq 0 ]]; then
		SYSVER="centos8"
	    else
		SYSVER="centos7"
	    fi
	else
	    SYSVER="debian10"
	fi
    fi
    SYSVER=${SYSVER,,}
}
function addbashrc {
    TEST=$(grep -q "$@" ${HOME}/.bashrc; echo $?)
    if [[ "$TEST" -eq "1" ]]; then
        echo "$@" >> ~/.bashrc
    fi
    }

################################
echo "Bootstrapping..."
echo "Package installation summary"
echo "OpenMPI : $INSTALL_OPENMPI ; v${OPENMPI_VERSION}"
echo "Visit   : $INSTALL_VISIT ; v${VISIT_VERSION}"
echo "Epoch   : $INSTALL_EPOCH ; v${EPOCH_VERSION}"
echo "####################################################"
echo ""
## Install OpenMPI
if [[ "$INSTALL_OPENMPI" -eq "1" ]]; then
    echo "Installing OpenMPI : v${OPENMPI_VERSION}"; sleep 3
    ## Make installation directory, with an etc subdir so EPOCH etc. will install bash completion scripts
    #mkdir -p $INSTALL_PREFIX/etc/bash_completion.d
    cd $BUILD_PREFIX
    test -d openmpi-$OPENMPI_VERSION || wget_untar https://download.open-mpi.org/release/open-mpi/v${OPENMPI_VERSION%??}/openmpi-$OPENMPI_VERSION.tar.gz
    cd openmpi-$OPENMPI_VERSION
    mkdir build; cd build
    conf
    mmi

    # append to bash
    addbashrc "export PATH=$INSTALL_PREFIX/bin:\$PATH"
    
    echo "Done."; sleep 3
fi

## Install visit
if [[ "INSTALL_VISIT" -eq "1" ]]; then
    echo "Installing VISIT : v${VISIT_VERSION}"; sleep 3
    cd $BUILD_PREFIX
    VISIT_VER=$(echo ${VISIT_VERSION} | tr "." _)
    sysinfo

    # hardcoded to linux x86_64 system
    echo "https://github.com/visit-dav/visit/releases/download/v$VISIT_VERSION/visit$VISIT_VER.linux-x86_64-${SYSVER}20.tar.gz"
    test -d visit$VISIT_VER.linux-x86_64 || wget_untar https://github.com/visit-dav/visit/releases/download/v$VISIT_VERSION/visit$VISIT_VER.linux-x86_64-${SYSVER}20.tar.gz

    # append to bash
    addbashrc "export PATH=$BUILD_PREFIX/visit$VISIT_VER.linux-x86_64/bin:\$PATH"
    
    echo "Done."; sleep 3
fi

## Install EPOCH
# https://github.com/Warwick-Plasma/EPOCH_manuals/releases/download/v4.17.0/epoch_user.pdf
if [[ "$INSTALL_EPOCH" -eq "1" ]]; then
    echo "Installing EPOCH : v${EPOCH_VERSION}"; sleep 3
    cd $BUILD_PREFIX
    test -d epoch || wget_untar https://github.com/Warwick-Plasma/epoch/releases/download/v$EPOCH_VERSION/epoch-$EPOCH_VERSION.tar.gz
    cd epoch-$EPOCH_VERSION
    for i in 1 2 3; do
	cd epoch${i}d
	mmk COMPILER=gfortran
	cd ..
    done
    
    # append to bashrc
    addbashrc "export COMPILER=gfortran"

    # run test
    for ipkg in matplotlib nose; do
	PKG_TEST=$(python -c 'import pkgutil; print(0 if pkgutil.find_loader("${ipkg}") else 1)')
	if [[ "${PKG_TEST}" -eq "1" ]]; then
	    pip install ${ipkg} --user
	fi
    done
    cd scripts
    export COMPILER=gfortran; ./run-tests-epoch-all.sh
    
    echo "Done."; sleep 3
fi

## Announce the build success
source ${HOME}/.bashrc
echo "All done."
