#!/bin/bash

# GitHub actions - Create Tesseract installer for Windows

# Author: Stefan Weil (2010-2023)

set -e
set -x

LANG=C.UTF-8

ARCH=$1

if test "$ARCH" != "i686"; then
  ARCH=x86_64
  MINGW=/mingw64
fi

ROOTDIR=$PWD
DISTDIR=$ROOTDIR/dist
HOST=$ARCH-w64-mingw32
BUILDDIR=bin/ndebug/$HOST-$TAG
PKG_ARCH=mingw64-${ARCH/_/-}

# Install packages.
sudo apt-get update --quiet
sudo apt-get install --assume-yes --no-install-recommends --quiet \
  asciidoc xsltproc docbook-xml docbook-xsl \
  automake dpkg-dev libtool pkg-config default-jdk-headless \
  mingw-w64-tools nsis g++-mingw-w64-${ARCH/_/-}

# Install pacman-package-manager and its dependencies (from Ubuntu 22.10).
sudo curl -Os http://de.archive.ubuntu.com/ubuntu/pool/universe/p/pacman-package-manager/pacman-package-manager_6.0.1-4_amd64.deb
sudo curl -Os http://de.archive.ubuntu.com/ubuntu/pool/universe/p/pacman-package-manager/libalpm13_6.0.1-4_amd64.deb
sudo curl -Os http://de.archive.ubuntu.com/ubuntu/pool/universe/p/pacman-package-manager/makepkg_6.0.1-4_amd64.deb
sudo dpkg -i *.deb || true
sudo apt-get install --fix-broken --assume-yes --no-install-recommends --quiet

# Configure pacman.

# Enable mirrorlist.
sudo sed -Ei 's/^#.*(Include.*mirrorlist)/\1/' /etc/pacman.conf
(
# Add msys key for pacman.
cd /usr/share/keyrings
sudo curl -Os https://raw.githubusercontent.com/msys2/MSYS2-keyring/master/msys2.gpg
sudo curl -Os https://raw.githubusercontent.com/msys2/MSYS2-keyring/master/msys2-revoked
sudo curl -Os https://raw.githubusercontent.com/msys2/MSYS2-keyring/master/msys2-trusted
)
(
# Add active environments for pacman.
# See https://www.msys2.org/docs/repos-mirrors/.
sudo mkdir -p /etc/pacman.d
cd /etc/pacman.d
cat <<eod | sudo tee mirrorlist >/dev/null
[mingw64]
Include = /etc/pacman.d/mirrorlist.mingw
eod
sudo curl -O https://raw.githubusercontent.com/msys2/MSYS2-packages/master/pacman-mirrors/mirrorlist.mingw
# sudo curl -O https://raw.githubusercontent.com/msys2/MSYS2-packages/master/pacman-mirrors/mirrorlist.msys
)

sudo pacman-key --init
sudo pacman-key --populate msys2
sudo pacman -Syu --noconfirm

# Install required pacman packages.
sudo pacman -S --noconfirm \
 mingw-w64-x86_64-curl-winssl \
 mingw-w64-x86_64-giflib \
 mingw-w64-x86_64-icu \
 mingw-w64-x86_64-leptonica \
 mingw-w64-x86_64-libarchive \
 mingw-w64-x86_64-libidn2 \
 mingw-w64-x86_64-openjpeg2 \
 mingw-w64-x86_64-openssl \
 mingw-w64-x86_64-pango \
 mingw-w64-x86_64-libpng \
 mingw-w64-x86_64-libtiff \
 mingw-w64-x86_64-libwebp

sudo ln -sf $PWD/.github/workflows/pkg-config-crosswrapper /usr/bin/$HOST-pkg-config

TAG=$(cat VERSION).$(date +%Y%m%d)

git config --global user.email "sw@weilnetz.de"
git config --global user.name "Stefan Weil"
git tag -a v$TAG -m "Tesseract $TAG"

# Run autogen.
./autogen.sh

# Build Tesseract installer.
mkdir -p $BUILDDIR && cd $BUILDDIR

# Run configure.
PKG_CONFIG_PATH=$MINGW/lib/pkgconfig
export PKG_CONFIG_PATH
../../../configure --disable-openmp --host=$HOST --prefix=/usr/$HOST \
  CXX=$HOST-g++-posix \
  CXXFLAGS="-fno-math-errno -Wall -Wextra -Wpedantic -g -O2 -isystem $MINGW/include" \
  LDFLAGS="-L$MINGW/lib"

make install-jars install training-install html winsetup prefix=$PWD/usr/$HOST

# Copy result for upload.
mkdir -p $DISTDIR && cp nsis/tesseract-ocr-w*-setup-*.exe $DISTDIR
