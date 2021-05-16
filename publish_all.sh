#!/bin/bash
###
# File: publish_all.sh
# Project: Kodi-Module-Generator
# File Created: Friday, 14th May 2021 5:21:20 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Sunday, 16th May 2021 10:04:20 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###


git_repo="git@github.com:Josh5/repo-scripts.git"
git_branch="matrix"


project_directory=$(readlink -e $(dirname ${BASH_SOURCE[0]}))
tmp_dir=$(mktemp -d --suffix='-kodi-repo-scripts')


# Clone to temp directory
echo -e "\n*** Clone temp repo of project"
git clone --depth=1 --branch "${git_branch}" --single-branch "${git_repo}" "${tmp_dir}/kodi-repo-scripts"



# Add modules
for out_path in ${project_directory}/out/*; do
    if [ -d "${out_path}" ]; then
        echo -e "\n*** Processing module '${out_path}'" 
        pushd ${tmp_dir}/kodi-repo-scripts &> /dev/null

        # Checkout main branch again...
        echo -e "\nCheckout '${git_branch}'" 
        git checkout ${git_branch}
        git clean -fdx

        # Get the plugin name
        plugin_name=$(basename ${out_path})

        # Get the plugin version
        plugin_version=$(python3 "${project_directory}/read_plugin_version.py" "${out_path}")

        # Print info
        echo -e "\nAdding module '${plugin_name} v${plugin_version}' to kodi plugins repo" 

        # Check if branch already exists...
        existed_in_remote=$(git fetch origin ${git_branch}-${plugin_name} &> /dev/null && echo 'true')
        existed_in_local=$(git branch --list ${git_branch}-${plugin_name})

        if [[ ! -z ${existed_in_local} ]]; then
            echo -e "\nCheckout existing local branch '${git_branch}-${plugin_name}'"
            git checkout ${git_branch}-${plugin_name}
            git clean -f
            git reset --hard HEAD~100 &> /dev/null
            git pull origin ${git_branch}-${plugin_name} &> /dev/null
            existing_branch='true'
        elif [[ ! -z ${existed_in_remote} ]]; then
            echo -e "\nCheckout existing remote branch 'origin/${git_branch}-${plugin_name}'"
            git checkout -b ${git_branch}-${plugin_name}
            git pull origin ${git_branch}-${plugin_name} &> /dev/null
            existing_branch='true'
        else
            echo -e "\nCreating new branch '${git_branch}-${plugin_name}'"
            git checkout -b ${git_branch}-${plugin_name}
            existing_branch='false'
        fi

        if [[ -d ${tmp_dir}/kodi-repo-scripts/${plugin_name}/lib ]]; then
            echo -e "\nClear out old files..." 
            rm -rf ${tmp_dir}/kodi-repo-scripts/${plugin_name}/lib/*
        fi

        echo -e "\nCopy files..." 
        mkdir -p "${tmp_dir}/kodi-repo-scripts/${plugin_name}/lib"
        cp -rf "${out_path}"/lib/* ${tmp_dir}/kodi-repo-scripts/${plugin_name}/lib/
        cp -fv "${out_path}"/addon.xml ${tmp_dir}/kodi-repo-scripts/${plugin_name}/addon.xml
        if [[ ! -f ${tmp_dir}/kodi-repo-scripts/${plugin_name}/icon.png ]]; then
            cp -fv "${out_path}"/icon.png ${tmp_dir}/kodi-repo-scripts/${plugin_name}/icon.png
        fi


        # Add all files to git
        echo -e "\nAdd new files to git tracking" 
        git add ./

        # Commit
        if [[ "${existing_branch}" == "true" ]]; then
            echo -e "\nAmending previously committed changes" 
            git commit --amend -a -m "[${plugin_name}] ${plugin_version}" 1> /dev/null
        else
            echo -e "\nCommit changes" 
            git commit -a -m "[${plugin_name}] ${plugin_version}" 1> /dev/null
        fi

        # Push changes...
        echo -e "\nPush changes"
        git push -f origin ${git_branch}-${plugin_name}

        popd &> /dev/null
    fi
done
