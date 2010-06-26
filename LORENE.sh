#! /bin/bash

################################################################################
# Prepare
################################################################################

# Set up shell
set -x                          # Output commands
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

if [ -z "${LORENE_DIR}" ]; then
    echo "BEGIN MESSAGE"
    echo "Building LORENE..."
    echo "END MESSAGE"
    
    # Set locations
    NAME=Lorene
    SRCDIR=$(dirname $0)
    INSTALL_DIR=${SCRATCH_BUILD}
    LORENE_DIR=${INSTALL_DIR}/build-${NAME}/${NAME}
    
    # Clean up environment
    unset LIBS
    
(
    exec >&2                    # Redirect stdout to stderr
    set -x                      # Output commands
    set -e                      # Abort on errors
    cd ${INSTALL_DIR}
    if [ -e done-${NAME} -a done-${NAME} -nt ${SRCDIR}/dist/${NAME}.tar.gz \
                         -a done-${NAME} -nt ${SRCDIR}/LORENE.sh ]
    then
        echo "LORENE: The enclosed LORENE library has already been built; doing nothing"
    else
        echo "LORENE: Building enclosed LORENE library"
        
        # Should we use gmake or make?
        MAKE=$(gmake --help > /dev/null 2>&1 && echo gmake || echo make)
        # Should we use gpatch or patch?
        if [ -z "$PATCH" ]; then
          PATCH=$(gpatch -v > /dev/null 2>&1 && echo gpatch || echo patch)
        fi
        # Should we use gtar or tar?
        TAR=$(gtar --help > /dev/null 2>&1 && echo gtar || echo tar)
        
        echo "LORENE: Unpacking archive..."
        rm -rf build-${NAME}
        mkdir build-${NAME}
        pushd build-${NAME}
        ${TAR} xzf ${SRCDIR}/dist/${NAME}.tar.gz
        ${PATCH} -p0 < ${SRCDIR}/dist/des.patch
        ${PATCH} -p0 < ${SRCDIR}/dist/makesystem.patch
        ${PATCH} -p0 < ${SRCDIR}/dist/pgplot.patch
        # Some (ancient but still used) versions of patch don't support the
        # patch format used here but also don't report an error using the
        # exit code. So we use this patch to test for this
        ${PATCH} -p0 < ${SRCDIR}/dist/patchtest.patch
        if [ ! -e Lorene/.patch_tmp ]; then
          echo 'BEGIN ERROR'
          echo 'The version of patch is too old to understand this patch format.'
          echo 'Please set the PATCH environment variable to a more recent '
          echo 'version of the patch command.'
          echo 'END ERROR'
          exit 1
        fi
        rm -f Lorene/.patch_tmp
        # Prevent overly long lines
        for file in $(find ${NAME} -name '*.f'); do
            # Remove CVS Header comments
            perl -pi -e 's{\$Header.*\$}{\$Header\$}g' $file
            # Replace tabs with eight blanks
            perl -pi -e 's{\t}{        }' $file
            # Remove in-line comments (in lines without quotes)
            perl -pi -e 's{^([^'\''"]*?)!.*$}{$1}' $file
            # Break long lines
            perl -pi -e 's{^([ 0-9].{71})(.+)}{$1\n     \$$2}' $file
        done
        popd
        
        echo "LORENE: Configuring..."
        pushd build-${NAME}/${NAME}
        cat > local_settings <<EOF
CXX = ${CXX}
CXXFLAGS = ${CXXFLAGS}
CXXFLAGS_G = ${CXXFLAGS}
F77 = ${F77}
F77FLAGS = ${F77FLAGS} $($(echo ${F77} | grep -i xlf > /dev/null 2>&1) && echo '' -qfixed)
F77FLAGS_G = ${F77FLAGS} $($(echo ${F77} | grep -i xlf > /dev/null 2>&1) && echo '' -qfixed)
INC = -I\$(HOME_LORENE)/C++/Include -I\$(HOME_LORENE)/C++/Include_extra $(echo ${GSL_INC_DIRS} | xargs -n 1 -I @ echo -I@)
$($(echo '' ${ARFLAGS} | grep 64 > /dev/null 2>&1) && echo "export OBJECT_MODE=64")
RANLIB = ${RANLIB}
# We don't need dependencies since we always build from scratch
#MAKEDEPEND = ${CXX_DEPEND} \$(INC) \$< ${CXX_DEPEND_OUT} && mv \$@ \$(df).d
MAKEDEPEND = : > \$(df).d
DEPDIR = .deps
FFT_DIR = FFT991
LIB_CXX = ${LIBS}
LIB_LAPACK = ${LAPACK_LIBS} ${BLAS_LIBS}
LIB_PGPLOT =
LIB_GSL = ${GSL_LIBS}
DONTBUILDDEBUGLIB = yes
EOF
        if [ -n "$XARGS" ]; then echo "XARGS = $XARGS" >> local_settings; fi
        if [ -n "$FIND"  ]; then echo "FIND = $FIND"   >> local_settings; fi
        
        echo "LORENE: Building..."
        export HOME_LORENE=${LORENE_DIR}
        # Note that this builds two versions of the library, a
        # "regular" version and a "debug" version.  Both are identical
        # (since we specified identical build options above), and we
        # ignore the "debug" version.
        ${MAKE} cpp fortran export
        popd
        
        echo 'done' > done-${NAME}
        echo "LORENE: Done."
    fi
)
    
    if (( $? )); then
        echo 'BEGIN ERROR'
        echo 'Error while building LORENE.  Aborting.'
        echo 'END ERROR'
        exit 1
    fi
    
fi



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
