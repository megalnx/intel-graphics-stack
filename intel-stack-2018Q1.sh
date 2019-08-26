#!/bin/bash
#
# Build Intel Graphics Stack 2018Q1
#
# It was tested at Slackware64 14.2
# It requires about 2GB for temporary files
# 

PKGS="mesa\|libdrm\|libva\|intel-vaapi-driver\|cairo\|intel-gpu-tools\|xorg-server"

SAVEAT=~/Downloads/IGS-2018Q1

#SLACKWARE_MIRROR=https://mirrors.slackware.com/slackware  # WGET
#SLACKWARE_MIRROR=ftp://ftp.slackware.com/pub/slackware  # FTP
SLACKWARE_MIRROR=rsync://ftp.slackware.com/slackware
SLACKWARE_VERSION=slackware64-14.2


###############################
## Package list for IGS-2018Q1
###############################

MESA_VERSION=18.0.0
LIBDRM_VERSION=2.4.91
LIBVA_VERSION=2.1.0
LIBVAAPI_VERSION=2.1.0
CAIRO_VERSION=1.16.0 #1.15.10
INTELGPUTOOLS_VERSION=1.22
XORG_VERSION=1.19.99.901

mesa_download="ftp://ftp.freedesktop.org/pub/mesa/mesa-$MESA_VERSION.tar.xz"
libdrm_download="https://dri.freedesktop.org/libdrm/libdrm-$LIBDRM_VERSION.tar.gz"
libva_download="https://github.com/01org/libva/releases/download/2.1.0/libva-$LIBVA_VERSION.tar.bz2"
libvaapi_download="https://github.com/intel/intel-vaapi-driver/releases/download/2.1.0/intel-vaapi-driver-$LIBVAAPI_VERSION.tar.bz2"
cairo_download="http://cairographics.org/releases/cairo-$CAIRO_VERSION.tar.xz"
intelgputools_download="https://www.x.org/archive/individual/app/intel-gpu-tools-$INTELGPUTOOLS_VERSION.tar.xz"
xorg_download="https://www.x.org/releases/individual/xserver/xorg-server-$XORG_VERSION.tar.gz"

###############################

SLACKWARE_URL=$SLACKWARE_MIRROR/$SLACKWARE_VERSION

slackpkg search $PKGS
exit

mkdir -p $SAVEAT

TMP=${TMP:-/tmp/INTELGS-2018Q1}

mkdir -p $TMP

ARCH=$(uname -m)

function build(){
  PKGNAM=$1
  VERSION=$2
  BUILD=$3

  cd $SAVEAT/$PKGNAM

  [ -f $SAVEAT/patches/$PKGNAM.patch ] && patch -p0 < $SAVEAT/patches/$PKGNAM.patch

  TMP=$TMP VERSION=$VERSION sh ./$PKGNAM.SlackBuild || exit 1

  upgradepkg --install-new --reinstall $TMP/$PKGNAM-$VERSION-$ARCH-$BUILD.txz || exit 1
}

function mesa(){
  PKGNAM=mesa
  VERSION=$MESA_VERSION
  BUILD=1

  download_sources $PKGNAM
  build $PKGNAM $VERSION $BUILD
}

function libdrm(){
  PKGNAM=libdrm
  VERSION=$LIBDRM_VERSION
  BUILD=1

  download_sources $PKGNAM
  build $PKGNAM $VERSION $BUILD
}

function libva(){
  PKGNAM=libva
  VERSION=$LIBVA_VERSION
  BUILD=1

  download_sources $PKGNAM
  build $PKGNAM $VERSION $BUILD
}

function libvaapi(){
  PKGNAM=intel-vaapi-driver
  VERSION=$LIBVAAPI_VERSION
  BUILD=1

  rsync -avR $SLACKWARE_MIRROR/slackware64-current/source/x/./$PKGNAM/{$PKGNAM.SlackBuild,slack-desc} $SAVEAT
  wget -c $libvaapi_download -O $SAVEAT/$PKGNAM/$(basename $libvaapi_download)

  # patch for the source filename
  sed -i 's/$PKGNAM-$VERSION.tar.?z/$PKGNAM-$VERSION.tar.?z2/' $SAVEAT/$PKGNAM/$PKGNAM.SlackBuild

  build $PKGNAM $VERSION $BUILD
}

function cairo(){
  PKGNAM=cairo
  VERSION=$CAIRO_VERSION
  BUILD=2
  
  download_sources $PKGNAM
  build $PKGNAM $VERSION $BUILD
}

function intelgputools(){
  PKGNAM=intel-gpu-tools
  VERSION=$INTELGPUTOOLS_VERSION
  BUILD=1

#  part of xorg
  cd $SAVEAT/x11
#  wget -c $SLACKWARE_URL/source/l/$PKGNAM/$PKGNAM.SlackBuild -O $SAVEAT/$PKGNAM.SlackBuild
  wget -c $intelgputools_download -O $SAVEAT/x11/src/app/$PKGNAM-$VERSION.tar.xz

  # Download the required libunwind
  wget -c "http://download.savannah.nongnu.org/releases/libunwind/libunwind-1.2.tar.gz" \
	  -O $SAVEAT/x11/src/lib/libunwind-1.2.tar.gz
  ./x11.SlackBuild lib libunwind

  patch -p0 < $SAVEAT/patches/configure-intel-gpu-tools.patch
  UPGRADE_PACKAGES=always ./x11.SlackBuild app intel-gpu-tools
}

function xorg(){
  wget -c $xorg_download -O $SAVEAT/x11/src/xserver/xorg-server-$XORG_VERSION.tar.gz

  cd $SAVEAT/x11

  [ -f $SAVEAT/patchs/x11.patch ] && patch -p0 < $SAVEAT/patchs/x11.patch

  # Now Xorg uses xorg-proto, remove proto packages
  cat ~/Downloads/slackware/slackware64-14.2/x11/modularize | removepkg $(grep proto)
  wget "https://www.x.org/releases/individual/proto/xorg-proto-2019.1.tar.gz" -O $SAVEAT/x11/src/proto/xorg-proto-2019.1.tar.gz

  # Xorg 1.19 requirement
  wget "https://www.x.org/releases/individual/lib/libXfont2-2.0.3.tar.gz" -O $SAVEAT/x11/src/lib/libXfont2-2.0.3.tar.gz   ./x11.SlackBuild lib libXfont2

  UPGRADE_PACKAGES=always ./x11.SlackBuild
}

# Keep it for using with Slackware 14.1
#  wget -c $SLACKWARE_URL/source/x/$PKGNAM/$PKGNAM.SlackBuild -O $SAVEAT/$PKGNAM.SlackBuild
#  wget -c $SLACKWARE_URL/source/l/$PKGNAM/$PKGNAM.SlackBuild -O $SAVEAT/$PKGNAM.SlackBuild

#  wget "https://www.x.org/releases/individual/proto/xproto-7.0.31.tar.gz" -O $SAVEAT/xproto-7.0.31.tar.gz
#  ln -sf $SAVEAT/xproto-7.0.31.tar.gz src/proto/xproto-7.0.31.tar.gz
#  UPGRADE_PACKAGES=always VERSION=7.0.31 ./x11.SlackBuild proto xproto

#  wget "https://www.x.org/releases/individual/proto/randrproto-1.6.0.tar.gz" -O $SAVEAT/randrproto-1.6.0.tar.gz
#  ln -sf $SAVEAT/randrproto-1.6.0.tar.gz src/proto/randrproto-1.6.0.tar.gz
#  UPGRADE_PACKAGES=always VERSION=1.6.0 ./x11.SlackBuild proto randrproto

#for pkg in $(echo $PKGS | sed "s#\\\|# #g" | sed "s/xorg-server//") ; do
#  echo $pkg
#  RELEASE=14.2 build-slackware-custom-pkg.sh $pkg
#done


# Download Slackware sources
function download_slackbuilds() {
  rsync -avr \
    --exclude="libdrm-2.4.68.tar.xz" \
    --exclude="libva-1.6.2.tar.xz" \
    --exclude="mesa-11.2.2.tar.?z*" \
    --exclude="cairo-1.14.6.tar.xz" --exclude="cairo.*.diff.gz" \
	$SLACKWARE_URL/source/./{x/{mesa,libdrm,libva},l/cairo} $SAVEAT

  ls $SAVEAT/{libdrm,libva,intel-vaapi-driver,mesa,cairo}

  # Now Xorg uses xorg-proto, exclude sync of proto
  rsync -avr \
    --exclude="src/proto/*.*" \
    --exclude="src/app/intel-gpu-tools-1.9.tar.xz" \
    --exclude="src/xserver/xorg-server-1.8.3.tar.xz" \
	$SLACKWARE_URL/source/./x/x11 $SAVEAT
}

function download_sources(){
  case $1 in
	libdrm|libva|mesa|cairo)
		DOWNLOAD="$(eval echo \$$1_download)"
		echo $DOWNLOAD
                wget -c $DOWNLOAD -O $SAVEAT/$PKGNAM/$(basename $DOWNLOAD)
	;;
  esac
}

download_slackbuilds
download_sources

case $1 in
	libdrm|libva|libvaapi|mesa|cairo|intelgputools|xorg)
	$1
	;;
	*)
        libdrm
	libva
	libvaapi
	mesa
	cairo
	intelgputools
	xorg
	;;
esac
