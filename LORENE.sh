#! /bin/bash

################################################################################
# Prepare
################################################################################

# Set up shell
set -x                          # Output commands
set -e                          # Abort on errors

# Set locations
NAME=LORENE
SRCDIR=$(dirname $0)
INSTALL_DIR=${SCRATCH_BUILD}
LORENE_DIR=${INSTALL_DIR}/build-${NAME}/${NAME}

# Clean up environment
unset LIBS
unset MAKEFLAGS



################################################################################
# Build
################################################################################

(
    exec >&2                    # Redirect stdout to stderr
    set -x                      # Output commands
    set -e                      # Abort on errors
    cd ${INSTALL_DIR}
    if [ -e done-${NAME} -a done-${NAME} -nt ${SRCDIR}/dist/${NAME}.tar.gz ]; then
        echo "LORENE: The enclosed LORENE library has already been built; doing nothing"
    else
        echo "LORENE: Building enclosed LORENE library"
        
        echo "LORENE: Unpacking archive..."
        rm -rf build-${NAME}
        mkdir build-${NAME}
        pushd build-${NAME}
        # Should we use gtar or tar?
        TAR=$(gtar --help > /dev/null 2> /dev/null && echo gtar || echo tar)
        ${TAR} xzf ${SRCDIR}/dist/${NAME}.tar.gz
        patch -p0 < ${SRCDIR}/dist/darwin.patch
        popd
        
        echo "LORENE: Configuring..."
        pushd build-${NAME}/${NAME}
        cat > local_settings <<EOF
CXX = ${CXX}
CXXFLAGS ${CXXFLAGS}
CXXFLAGS_G = ${CXXFLAGS}
F77 = ${F77}
F77FLAGS = ${F77FLAGS}
F77FLAGS_G = ${F77FLAGS}
INC = -I\$(HOME_LORENE)/C++/Include -I\$(HOME_LORENE)/C++/Include_extra 
RANLIB = ${RANLIB}
MAKEDEPEND = ${CPP} \$(INC) -M >> \$(df).d \$<
DEPDIR = .deps
FFT_DIR = FFT991
LIB_CXX = ${LIBS}
LIB_LAPACK = ${LAPACK_LIBS} ${BLAS_LIBS}
LIB_PGPLOT =
LIB_GSL = ${GSL_LIBS}
EOF
        
        echo "LORENE: Building..."
        export HOME_LORENE=${LORENE_DIR}
        # Note that this builds two versions of the library, a
        # "regular" version and a "debug" version.  Both are identical
        # (since we specified identical build options above), and we
        # ignore the "debug" version.
        make cpp fortran export
        popd
        
        echo 'done' > done-${NAME}
        echo "LORENE: Done."
    fi
)

# TODO: check $?



################################################################################
# Configure Cactus
################################################################################

# Set options
LORENE_INC_DIRS="${LORENE_DIR}/Export/C++/Include ${LORENE_DIR}/C++/Include"
LORENE_LIB_DIRS="${LORENE_DIR}/Lib"
LORENE_LIBS='lorene_export lorene lorenef77'

# Pass options to Cactus
echo "BEGIN MAKE_DEFINITION"
echo "HAVE_LORENE     = 1"
echo "LORENE_DIR      = ${LORENE_DIR}"
echo "LORENE_INC_DIRS = ${LORENE_INC_DIRS}"
echo "LORENE_LIB_DIRS = ${LORENE_LIB_DIRS}"
echo "LORENE_LIBS     = ${LORENE_LIBS}"
echo 'HOME_LORENE     = $(LORENE_DIR)'
echo "END MAKE_DEFINITION"

echo 'INCLUDE_DIRECTORY $(LORENE_INC_DIRS)'
echo 'LIBRARY_DIRECTORY $(LORENE_LIB_DIRS)'
echo 'LIBRARY           $(LORENE_LIBS)'
