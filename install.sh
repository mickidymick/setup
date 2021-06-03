#! /usr/bin/env bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd $DIR

eval HM=$(echo ~${USER})

echo ".bashrc"
cp .bashrc $HM/.bashrc
echo ".vimrc"
cp .vimrc $HM/.vimrc
echo ".vim/"
cp -r .vim $HM
echo ".tmux.conf"
cp .tmux.conf $HM
echo ".ssh/config"
mkdir -p $HM/.ssh
cp .ssh/config $HM/.ssh

mkdir -p ~/.yed

# YED_INSTALLATION_PREFIX="${HM}/.local"
C_FLAGS="-O3 -shared -fPIC -Wall -Werror"
CC=gcc

if [ -d /opt/yed ]; then # M1
    YED_INSTALLATION_PREFIX="/opt/yed"
    C_FLAGS="-arch arm64 ${C_FLAGS}"
    CC=clang
elif [ -f /usr/local/bin/yed ]; then # Older Mac
    YED_INSTALLATION_PREFIX="/usr/local"
else
    YED_INSTALLATION_PREFIX="/usr" # Linux probably
fi
C_FLAGS+=" -I${YED_INSTALLATION_PREFIX}/include -L${YED_INSTALLATION_PREFIX}/lib -lyed"


YED_DIR=${DIR}/.yed
HOME_YED_DIR=${HM}/.yed

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
echo "Done."
