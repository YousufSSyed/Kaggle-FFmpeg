#!/bin/bash

# This script will compile and install a static ffmpeg build with support for nvenc in ubuntu.
# See the prefix path and compile options if edits are needed to suit your needs.

# NOTE: This build is made to target Ubunutu 16.04 Data-Science Azure VMs - With nVidia 418.xx drivers and CUDA SDK 9.0.
#       It also relies on a hack described in https://trac.ffmpeg.org/ticket/6431#comment:7 to make glibc dynamic still.
#       Long story short, you need to edit your ffmepg's configure script to avoid failures on libm and libdl.
#         in function probe_cc, replace the _flags_filter line to: _flags_filter='filter_out -lm|-ldl'

#install required things from apt
installLibs(){
echo "Installing prerequisites"
apt-get update
apt-get -y --force-yes install autoconf automake build-essential libfreetype6-dev libgpac-dev \
  libsdl1.2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev \
  libxcb-xfixes0-dev pkg-config texi2html zlib1g-dev libvpx-dev \
  libharfbuzz-dev libfontconfig-dev
}

# Not currently enabled as it will update the SDK level and drivers and require newer ones than what the DSVM VM Image on Azure currently has.
installCUDA(){
echo "Installing the CUDA SDK."
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-ubuntu1604.pin
mv cuda-ubuntu1604.pin /etc/apt/preferences.d/cuda-repository-pin-600
apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub
add-apt-repository "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/ /"
apt-get update
apt-get -y install cuda
}

#Install nvidia SDK
installSDK(){
echo "Installing the nVidia NVENC SDK using the latest supported 9.0 tag."
cd ~/ffmpeg_sources
git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
cd nv-codec-headers
git checkout -b sdk90 n9.0.18.3
make
make install
}

#Compile nasm
compileNasm(){
echo "Compiling nasm"
cd ~/ffmpeg_sources
wget http://www.nasm.us/pub/nasm/releasebuilds/2.14rc0/nasm-2.14rc0.tar.gz
tar xzvf nasm-2.14rc0.tar.gz
cd nasm-2.14rc0
./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static --disable-shared
make -j$(nproc)
make -j$(nproc) install
make -j$(nproc) distclean
}

#Compile libx264
compileLibX264(){
echo "Compiling libx264"
cd ~/ffmpeg_sources
git clone https://code.videolan.org/videolan/x264.git
cd x264
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static --disable-shared
PATH="$HOME/bin:$PATH" make -j$(nproc)
make -j$(nproc) install
make -j$(nproc) distclean
}

#Compile libfdk-acc
compileLibfdkcc(){
echo "Compiling libfdk-cc"
apt-get install unzip
cd ~/ffmpeg_sources
wget -O fdk-aac.zip https://github.com/mstorsjo/fdk-aac/zipball/master
unzip -o fdk-aac.zip
cd mstorsjo-fdk-aac*
autoreconf -fiv
./configure --prefix="$HOME/ffmpeg_build" --enable-static --disable-shared
make -j$(nproc)
make -j$(nproc) install
make -j$(nproc) distclean
}

#Compile libmp3lame
compileLibMP3Lame(){
echo "Compiling libmp3lame"
apt-get install nasm
cd ~/ffmpeg_sources
wget http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz
tar xzvf lame-3.99.5.tar.gz
cd lame-3.99.5
./configure --prefix="$HOME/ffmpeg_build" --enable-nasm --enable-static --disable-shared
make -j$(nproc)
make -j$(nproc) install
make -j$(nproc) distclean
}

#Compile libopus
compileLibOpus(){
echo "Compiling libopus"
cd ~/ffmpeg_sources
wget http://downloads.xiph.org/releases/opus/opus-1.2.1.tar.gz
tar xzvf opus-1.2.1.tar.gz
cd opus-1.2.1
./configure --prefix="$HOME/ffmpeg_build" --enable-static --disable-shared
make -j$(nproc)
make -j$(nproc) install
make -j$(nproc) distclean
}

#Compile libvpx
compileLibPvx(){
echo "Compiling libvpx"
cd ~/ffmpeg_sources
git clone https://chromium.googlesource.com/webm/libvpx
cd libvpx
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --disable-examples --enable-runtime-cpu-detect --enable-vp9 --enable-vp8 \
--enable-postproc --enable-vp9-postproc --enable-multi-res-encoding --enable-webm-io --enable-better-hw-compatibility --enable-vp9-highbitdepth --enable-onthefly-bitpacking --enable-realtime-only \
--cpu=native --as=nasm --enable-static --disable-shared
PATH="$HOME/bin:$PATH" make -j$(nproc)
make -j$(nproc) install
make -j$(nproc) clean
}

#Compile libgmp
compileLibGmp(){
echo "Compiling libgmp"
cd ~/ffmpeg_sources
wget https://gmplib.org/download/gmp/gmp-6.1.0.tar.xz
tar xvf gmp-6.1.0.tar.xz
cd gmp-6.1.0
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static --disable-shared
PATH="$HOME/bin:$PATH" make -j$(nproc)
make -j$(nproc) install
make -j$(nproc) distclean
}

#Compile libnettle
compileLibNettle(){
echo "Compiling libnettle"
cd ~/ffmpeg_sources
wget https://ftp.gnu.org/gnu/nettle/nettle-3.2.tar.gz
tar xzvf nettle-3.2.tar.gz
cd nettle-3.2
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static --disable-shared
PATH="$HOME/bin:$PATH" make -j$(nproc)
make -j$(nproc) install
make -j$(nproc) distclean
}

#Compile libgnutls
compileLibGnutls(){
echo "Compiling libgnutls"
cd ~/ffmpeg_sources
wget https://www.gnupg.org/ftp/gcrypt/gnutls/v3.4/gnutls-3.4.10.tar.xz
tar xvf gnutls-3.4.10.tar.xz
cd gnutls-3.4.10
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static --disable-shared --with-included-libtasn1 --with-included-unistring --without-p11-kit --disable-doc \
  --disable-cxx --disable-tools
PATH="$HOME/bin:$PATH" make -j$(nproc)
make -j$(nproc) install
make -j$(nproc) distclean
}

#Compile ffmpeg
compileFfmpeg(){
echo "Compiling ffmpeg"
cd ~/ffmpeg_sources
git clone https://github.com/FFmpeg/FFmpeg -b master
cd FFmpeg

PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --extra-cflags="-I$HOME/ffmpeg_build/include -I/usr/local/cuda/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib -L/usr/local/cuda/lib64" \
  --extra-ldexeflags="-Wl,-Bstatic" \
  --extra-libs="-Wl,-Bdynamic -lm -ldl" \
  --pkg-config-flags="--static" \
  --bindir="$HOME/bin" \
  --disable-debug \
  --disable-ffplay \
  --disable-indev=sndio \
  --disable-outdev=sndio \
  --enable-static \
  --enable-gpl \
  --enable-nonfree \
  --enable-version3 \
  --enable-libmp3lame \
  --enable-libfdk-aac \
  --enable-libopus \
  --enable-libvpx \
  --enable-libx264 \
  --enable-nvenc \
  --enable-cuda-nvcc \
  --enable-cuda \
  --enable-cuda-sdk \
  --enable-cuda-llvm
PATH="$HOME/bin:$PATH" make -j$(nproc)
make -j$(nproc) install
make -j$(nproc) distclean
hash -r
}

#The process
cd ~
mkdir ffmpeg_sources
compileFfmpeg
echo "Complete!"
