#!/bin/bash
######################################################################
## NDK
######################################################################
## NDK
if [ "$NDK" = "" ]; then
    echo NDK variable not set, assuming ${HOME}/android-ndk-r10c
    export NDK=${HOME}/android-ndk-r8e
fi
######################################################################
## Download library and source.

# echo "Fetching Android system headers"
# git clone --depth=1 --branch gingerbread-release git://github.com/CyanogenMod/android_frameworks_base.git ../android-source/frameworks/base
# git clone --depth=1 --branch gingerbread-release git://github.com/CyanogenMod/android_system_core.git ../android-source/system/core

# echo "Fetching Android libraries for linking"
# # Libraries from any froyo/gingerbread device/emulator should work
# # fine, since the symbols used should be available on most of them.
# if [ ! -d "../android-libs" ]; then
    # if [ ! -f "../update-cm-7.0.3-N1-signed.zip" ]; then
        # wget http://download.cyanogenmod.com/get/update-cm-7.0.3-N1-signed.zip -P../
    # fi
    # unzip ../update-cm-7.0.3-N1-signed.zip system/lib/* -d../
    # mv ../system/lib ../android-libs
    # rmdir ../system
# fi

echo $NDK
SYSROOT=$NDK/platforms/android-21/arch-arm
# Expand the prebuilt/* path into the correct one
TOOLCHAIN=`echo $NDK/toolchains/arm-linux-androideabi-4.8/prebuilt/linux-x86_64`
export PATH=$TOOLCHAIN/bin:$PATH


######################################################################
## build_configure
#--disable-decoder=h264 \
function build_configure
{

rm -rf $DEST
mkdir -p $DEST

#FLAGS="--target-os=linux --cross-prefix=arm-linux-androideabi- --arch=arm --cpu=$CPU"
FLAGS="--target-os=linux --cross-prefix=arm-linux-androideabi- --arch=arm"
FLAGS="$FLAGS --sysroot=$SYSROOT"
EXTRA_CFLAGS="$EXTRA_CFLAGS -I$NDK/sources/cxx-stl/system/include"


#EXTRA_CFLAGS="$EXTRA_CFLAGS -march=armv7-a -mfloat-abi=softfp -mfpu=neon"
#EXTRA_CFLAGS="$EXTRA_CFLAGS $BUILD_CFLAGS"
EXTRA_CFLAGS="$EXTRA_CFLAGS"
EXTRA_LDFLAGS="$BUILD_LDFLAGS -L$SYSROOT/usr/lib -Wl,-rpath-link,$SYSROOT/usr/lib -nostdlib -lc -lm -ldl -llog"
EXTRA_CXXFLAGS="-Wno-multichar -fno-exceptions -fno-rtti"

mkdir -p $DEST
    #--extra-cflags="-O3 -fpic -DANDROID -DHAVE_SYS_UIO_H=1 Dipv6mr_interface=ipv6mr_ifindex -fasm -Wno-psabi -fno-short-enums  -fno-strict-aliasing -finline-limit=300 $EXTRA_CFLAGS" \

echo $FLAGS --extra-cflags="-O3 -fpic -DANDROID $EXTRA_CFLAGS" --extra-ldflags="$EXTRA_LDFLAGS" --extra-cxxflags="$EXTRA_CXXFLAGS" > $DEST/${BUILD}_info.txt
./configure --prefix=$DEST \
    $FLAGS \
    --extra-cflags="-O3 -fpic -DANDROID -DHAVE_SYS_UIO_H=1 -Dipv6mr_interface=ipv6mr_ifindex -fasm -Wno-psabi -fno-short-enums  -fno-strict-aliasing -finline-limit=300 $EXTRA_CFLAGS" \
    --extra-ldflags="$EXTRA_LDFLAGS" \
    --extra-cxxflags="$EXTRA_CXXFLAGS" \
    --extra-libs="-lgcc" \
    --cc=$TOOLCHAIN/bin/arm-linux-androideabi-gcc \
    --disable-doc \
    --disable-ffmpeg \
    --disable-ffplay \
    --disable-ffprobe \
    --disable-ffserver \
    --disable-devices \
    --disable-encoders  \
    --disable-muxers \
    --enable-shared \
    --disable-static \
    --enable-parsers \
    --enable-decoders \
    --enable-demuxers \
    --enable-network \
    --disable-indevs \
    --disable-protocols  \
 --enable-protocol=file \
 --disable-protocol=http \
 --disable-protocol=rtp \
 --disable-protocol=tcp \
 --disable-protocol=udp \
 --disable-postproc \
 --enable-avfilter \
 --disable-swscale-alpha \
 --disable-demuxer=srt \
 --disable-demuxer=microdvd \
    --disable-demuxer=jacosub \
    --disable-decoder=ass \
    --disable-decoder=srt \
    --disable-decoder=microdvd \
    --disable-decoder=jacosub \
 --disable-asm \
 --enable-zlib \
 --enable-optimizations \
 --enable-pic \
 $ADDITIONAL_CONFIGURE_FLAG \
    | tee $DEST/${BUILD}_configuration.txt
[ $PIPESTATUS == 0 ] || exit 1
#make clean
make -j4 || exit 1
make install

$TOOLCHAIN/bin/arm-linux-androideabi-ar d libavcodec/libavcodec.a inverse.o

}

######################################################################
## build_start

function build_share
{

#STAGEFRIGHT_LDFLAGS="-lstdc++ -lstlport -lutils -lmedia  -lbinder -lstagefright"
#STAGEFRIGHT_LDFLAGS="-lstlport -lutils -lmedia -lbinder -lstagefright -lstagefright_foundation"

$TOOLCHAIN/bin/arm-linux-androideabi-ld \
        -rpath-link=${ANDROID_LIBS} -L${ANDROID_LIBS} \
        -rpath-link=${SYSROOT}/usr/lib -L${SYSROOT}/usr/lib \
        -soname lib${BUILD}.so -shared \
        -nostdlib  -z noexecstack -Bsymbolic --whole-archive --no-undefined \
        -o ${DEST}/lib${BUILD}.so \
        libavcodec/libavcodec.a libavformat/libavformat.a libavutil/libavutil.a libswscale/libswscale.a libswresample/libswresample.a\
        -lc -lm -lz -ldl -llog \
  --dynamic-linker=/system/bin/linker \
  ${TOOLCHAIN}/lib/gcc/arm-linux-androideabi/4.8/libgcc.a
}
function build_start
{
build_configure
build_share

}


######################################################################
## excute armv7-a
CPU=armv7-a
BUILD=ffmpeg
# BUILD=${CPU}_vfpv3
#-mfpu=vfpv3-d16
DEST="../build/${CPU}/$BUILD"
BUILD_CFLAGS="-mfloat-abi=softfp -mfpu=neon -marm -march=$CPU -mtune=cortex-a8"
ADDITIONAL_CONFIGURE_FLAG="--arch=arm --cpu=armv7-a --enable-memalign-hack"
build_start
