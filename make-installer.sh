#!/bin/sh

TAG=$(git describe | sed s/^v// | sed s/.202[3-9].*// | sed s/-.*//).$(date +%Y%m%d)

git tag -a v$TAG -m "Tesseract $TAG"

ARCHS="i686 x86_64"
ARCHS="x86_64"

SRCDIR=$PWD

./autogen.sh

for ARCH in $ARCHS; do
  HOST=$ARCH-w64-mingw32
  BUILDDIR=bin/ndebug/$HOST-$TAG

  rm -rf $BUILDDIR
  mkdir -p $BUILDDIR
  (
  cd $BUILDDIR

  MINGW=/mingw64
  MINGW_INSTALL=${PWD}${MINGW}
  PKG_CONFIG_PATH=$MINGW/lib/pkgconfig
  export PKG_CONFIG_PATH

  # Disable OpenMP (see https://github.com/tesseract-ocr/tesseract/issues/1662).
  ../../../configure --disable-openmp --host=$HOST --prefix=$MINGW CXX=$HOST-g++-posix CXXFLAGS="-fno-math-errno -Wall -Wextra -Wpedantic -g -O2 -I$MINGW/include" LDFLAGS="-L$MINGW/lib"
  make install-jars install training-install html prefix=${MINGW_INSTALL}
  (
  cd ${MINGW_INSTALL}/bin
  for file in *.exe *.dll; do
    signcode $file
  done
  )
  mkdir -p dll
  ln -sv $($SRCDIR/nsis/find_deps.py $MINGW_INSTALL/bin/*.exe $MINGW_INSTALL/bin/*.dll) dll/
  make winsetup prefix=${MINGW_INSTALL} SIGNCODE=signcode
  )
done
