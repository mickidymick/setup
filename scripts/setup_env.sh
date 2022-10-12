#!/usr/bin/env bash
env_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

export MEM_EF_ENV="yes"
export MEM_EF_ENV_DIR="${env_dir}"
export PATH="${env_dir}/bin:${env_dir}/scripts:${PATH}"
export LD_LIBRARY_PATH="${env_dir}/lib:${LD_LIBRARY_PATH}"
export RAPPORT_DIR="${env_dir}/rapport"

if [ -f ~/.bashrc ]; then
    cp ~/.bashrc ${env_dir}
else
    touch ${env_dir}/.bashrc
fi

# echo "export PS1=\"(\[\e[0;35m\]mem-ef\[\e[m\]) \${PS1}\"" >> ${env_dir}/.bashrc
echo "export PS1_PRE=\"(\[\e[0;35m\]mem-ef\[\e[m\]) \"" >> ${env_dir}/.bashrc

bash --rcfile $(realpath ${env_dir}/.bashrc)
