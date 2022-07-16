#! /usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd $DIR

eval HM=$(echo ~${USER})

echo ".bashrc"
cp .bashrc $HM/.bashrc
source $HM/.bashrc
mkdir -p $HM/.config/kitty
echo ".config/kitty/kitty.conf"
cp kitty.conf $HM/.config/kitty/kitty.conf
#echo ".vimrc"
#cp .vimrc $HM/.vimrc
#echo ".vim/"
#cp -r .vim $HM
#echo ".tmux.conf"
#cp .tmux.conf $HM
#echo ".ssh/config"
#mkdir -p $HM/.ssh
#cp .ssh/config $HM/.ssh

mkdir -p ~/.config/yed

C_FLAGS="-O3"
CC=gcc
C_FLAGS+=" $(yed --print-cflags) $(yed --print-ldflags)"

YED_DIR=${DIR}/.yed
HOME_YED_DIR=${HM}/.config/yed

pids=()

for f in $(find ${DIR}/.yed -name "*.c"); do
    echo "Compiling ${f/${YED_DIR}/.yed} and installing."
    PLUG_DIR=$(dirname ${f/${YED_DIR}/${HOME_YED_DIR}})
    PLUG_FULL_PATH=${PLUG_DIR}/$(basename $f ".c").so

    mkdir -p ${PLUG_DIR}
    ${CC} ${f} ${C_FLAGS} -o ${PLUG_FULL_PATH} &
    pids+=($!)
done

for p in ${pids[@]}; do
    wait $p || exit 1
done

echo "Moving yedrc."
cp ${YED_DIR}/yedrc ${HOME_YED_DIR}

echo "Moving ypm_list."
cp ${YED_DIR}/ypm_list ${HOME_YED_DIR}

echo "Moving templates."
cp -r ${YED_DIR}/templates ${HOME_YED_DIR}

echo "Done."
