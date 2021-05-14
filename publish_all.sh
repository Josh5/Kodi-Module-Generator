#!/bin/bash
###
# File: publish_all.sh
# Project: Kodi-Module-Generator
# File Created: Friday, 14th May 2021 5:21:20 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Friday, 14th May 2021 6:17:08 pm
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

        # Create new branch
        existed_in_local=$(git branch --list ${git_branch}-${plugin_name})

        if [[ -z ${existed_in_local} ]]; then
            echo -e "\nCreating new branch '${git_branch}-${plugin_name}'" 
            git checkout -b ${git_branch}-${plugin_name}
        else
            echo -e "\nCheckout existing branch '${git_branch}-${plugin_name}'" 
            git checkout ${git_branch}-${plugin_name}
        fi

        echo -e "\nCopy files..." 
        mkdir -p "${tmp_dir}/kodi-repo-scripts/${plugin_name}"
        cp -rf "${out_path}"/* ${tmp_dir}/kodi-repo-scripts/${plugin_name}/

        # Add all files to git
        echo -e "\nAdd new files to git tracking" 
        git add ./ 

        # Commit
        echo -e "\nCommit changes" 
        git commit -a -m "[${plugin_name}] v${plugin_version}"

        # Push changes...
        echo -e "\nPush changes"
        git push -f origin ${git_branch}-${plugin_name}

        popd &> /dev/null
    fi
done 
