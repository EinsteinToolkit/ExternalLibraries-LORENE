#! /bin/bash

################################################################################
# Prepare
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors



################################################################################
# Search
################################################################################

if [ -z "${LORENE_DIR}" ]; then
    echo "BEGIN MESSAGE"
    echo "LORENE selected, but LORENE_DIR not set."
    echo "END MESSAGE"
else
    echo "BEGIN MESSAGE"
    echo "Using LORENE in ${LORENE_DIR}"
    echo "END MESSAGE"
fi



################################################################################
# Build
################################################################################

if [ -z "${LORENE_DIR}"                                                 \
     -o "$(echo "${LORENE_DIR}" | tr '[a-z]' '[A-Z]')" = 'BUILD' ]
then
    echo "BEGIN MESSAGE"
    echo "Using bundled LORENE..."
    echo "END MESSAGE"
    
    # Check for required tools. Do this here so that we don't require
    # them when using the system library.
    if [ "x$TAR" = x ] ; then
        echo 'BEGIN ERROR'
        echo 'Could not find tar command.'
        echo 'Please make sure that the (GNU) tar command is present,'
        echo 'and that the TAR variable is set to its location.'
        echo 'END ERROR'
        exit 1
    fi
    if [ "x$PATCH" = x ] ; then
        echo 'BEGIN ERROR'
        echo 'Could not find patch command.'
        echo 'Please make sure that the patch command is present,'
        echo 'and that the PATCH variable is set to its location.'
        echo 'END ERROR'
        exit 1
    fi

    # Set locations
    THORN=LORENE
    NAME=Lorene
    SRCDIR="$(dirname $0)"
    BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
    if [ -z "${LORENE_INSTALL_DIR}" ]; then
        INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
    else
        echo "BEGIN MESSAGE"
        echo "Installing LORENE into ${LORENE_INSTALL_DIR}"
        echo "END MESSAGE"
        INSTALL_DIR=${LORENE_INSTALL_DIR}
    fi
    DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
    LORENE_DIR=${INSTALL_DIR}
else
    THORN=LORENE
    DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
    if [ ! -e ${DONE_FILE} ]; then
        mkdir ${SCRATCH_BUILD}/done 2> /dev/null || true
        date > ${DONE_FILE}
    fi
fi



################################################################################
# Configure Cactus
################################################################################

# Pass configuration options to build script
echo "BEGIN MAKE_DEFINITION"
echo "LORENE_EXTRA_LIB_DIRS = ${LORENE_EXTRA_LIB_DIRS}"
echo "LORENE_EXTRA_LIBS     = ${LORENE_EXTRA_LIBS}"
echo "LORENE_INSTALL_DIR    = ${LORENE_INSTALL_DIR}"
echo "END MAKE_DEFINITION"

# Set options
LORENE_INC_DIRS="${LORENE_DIR}/Export/C++/Include ${LORENE_DIR}/C++/Include"
LORENE_LIB_DIRS="${LORENE_DIR}/Lib ${LORENE_EXTRA_LIB_DIRS}"
LORENE_LIBS="lorene_export lorene lorenef77 ${LORENE_EXTRA_LIBS}"

LORENE_INC_DIRS="$(${CCTK_HOME}/lib/sbin/strip-incdirs.sh ${LORENE_INC_DIRS})"
LORENE_LIB_DIRS="$(${CCTK_HOME}/lib/sbin/strip-libdirs.sh ${LORENE_LIB_DIRS})"

# Pass options to Cactus
echo "BEGIN MAKE_DEFINITION"
echo "LORENE_DIR      = ${LORENE_DIR}"
echo "LORENE_INC_DIRS = ${LORENE_INC_DIRS}"
echo "LORENE_LIB_DIRS = ${LORENE_LIB_DIRS}"
echo "LORENE_LIBS     = ${LORENE_LIBS}"
# echo "HOME_LORENE     = ${LORENE_DIR}"
echo "END MAKE_DEFINITION"

echo 'INCLUDE_DIRECTORY $(LORENE_INC_DIRS)'
echo 'LIBRARY_DIRECTORY $(LORENE_LIB_DIRS)'
echo 'LIBRARY           $(LORENE_LIBS)'
