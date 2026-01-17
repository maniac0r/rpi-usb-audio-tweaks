#!/bin/bash
############################################
# script to prepare crosscompile build-env #
# build env: vagrant VM with Ubuntu
############################################

#####################################################################################################
#
prepare_dev_env() {
  apt update && \
    apt upgrade -y && \
    apt full-upgrade

  apt install -y \
    binutils-aarch64-linux-gnu gcc-aarch64-linux-gnu \
    device-tree-compiler \
    autoconf \
    automake \
    libtool \
    build-essential \
    git \
    libssl-dev \
    libelf-dev flex \
    bison \
    libncurses-dev \
    dwarves \
    joe \
    colordiff \
    ncdu \
    mc
}


#####################################################################################################
# initial clone kernel repo, apply RT patch
#################################################
prepare_kernel_src() {
  KV="6.18"
  RTPATCH="6.18-rc4-rt3"
  SRCBASEPATH="/usr/src"
  SRCBASEPATH="./test"

  OPWD=$PWD
  cd ${SRCBASEPATH} && \
    mkdir "linux-${KV}-rpi-git" ; \
    cd "linux-${KV}-rpi-git" && \
    git clone --branch "rpi-${KV}.y" https://github.com/raspberrypi/linux.git && \
    cd linux && \
    wget "https://mirrors.edge.kernel.org/pub/linux/kernel/projects/rt/${KV}/patch-${RTPATCH}.patch.xz" && \
    cd linux && \
      xzcat "../patch-${RTPATCH}.patch.xz" | patch -p1 &&
      echo "DONE - KERNEL cloned from github, RT-patch applied - ALL SEEMS OK."

  cd $OPWD
}

#####################################################################################################
# cross-compile desired version (debug/nodebug)
#################################################
crosscompile() {
  ./compile-gcc-O3-NODEBUG
}


##### MAIN ########

#prepare_dev_env

prepare_kernel_src

#crosscompile
