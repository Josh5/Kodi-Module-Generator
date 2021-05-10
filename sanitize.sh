#!/bin/bash

###
# File: sanitize.sh
# Project: Kodi-Module-Generator
# File Created: Monday, 10th May 2021 11:02:32 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 10th May 2021 11:10:23 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###



addon_root=${@}
lib_dir="${addon_root}/lib"


print_step(){
    ten="          "
    spaces="${ten}${ten}${ten}${ten}${ten}${ten}${ten}${ten}${ten}"
    message="      - ${@}"
    message="${message:0:70}${spaces:0:$((70 - ${#message}))}"
    echo -ne "${message}"
}
print_sub_step(){
    ten="          "
    spaces="${ten}${ten}${ten}${ten}${ten}${ten}${ten}${ten}${ten}"
    message="          - ${@}"
    message="${message:0:70}${spaces:0:$((70 - ${#message}))}"
    echo -ne "${message}"
}
mark_step(){
    RED="\e[31m"
    GREEN="\e[32m"
    ENDCOLOR="\e[0m"
    status_message=""
    [[ ${1} == 'failed' ]] && status_message="${RED}[FAILED]${ENDCOLOR}"
    [[ ${1} == 'success' ]] && status_message="${GREEN}[SUCCESS]${ENDCOLOR}"
    echo -e "${status_message}"
}


# Remove everything except the Python source
remove_extensions=(
    "ans"
    "bz2"
    "db"
    "dll"
    "exe"
    "gz"
    "mo"
    "pyc"
    "pyo"
    "so"
    "xbt"
    "xpr"
)
print_step "Cleaning out unnecessary binary files:"
mark_step
for ext in "${remove_extensions[@]}"; do
    print_sub_step "Delete all '*.${ext}' files..."
    find "${lib_dir}" -type f -iname "*.${ext}" -delete 
    [[ $? > 0 ]] && mark_step failed && exit 1
    mark_step success
done
print_step "Cleaning out Python cache directories"
find "${lib_dir}" -type d -name "__pycache__" -exec rm -rf {} +
[[ $? > 0 ]] && mark_step failed && exit 1
mark_step success
print_step "Cleaning out Python 'dist-info' directories"
find "${lib_dir}" -type d -name "*.dist-info" -exec rm -rf {} +
[[ $? > 0 ]] && mark_step failed && exit 1
mark_step success

# Remove Python bin
print_step "Removing 'bin' Python directory"
rm -rf "${lib_dir}/bin"
[[ $? > 0 ]] && mark_step failed && exit 1
mark_step success

# Ensure all files are not executable
print_step "Ensure all items in the lib directory are not executable"
find "${lib_dir}" -type f -exec chmod a-x {} +
[[ $? > 0 ]] && mark_step failed && exit 1
mark_step success

exit 0
