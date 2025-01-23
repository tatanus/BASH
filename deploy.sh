#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# NAME: build_and_package.sh
# DESCRIPTION : Build a deployable project, copy necessary files, update tools,
#              and package it as a tar file.
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

# Variables
DEPLOY_DIR="deploy"
TAR_FILE="BASH_ENV.tar"
TOOLS_EXTRA_DIR="${DEPLOY_DIR}/tools/extra"
DOT_DIR="${DEPLOY_DIR}/dot"
KEYS_FILE="../pentest.keys"
INHOUSE_FILE="../inhouse.sh"

REPOS=()
SUBDIRS=()

# Source configuration file
DEPLOY_CONF="../deploy.conf"
if [[ ! -f "${DEPLOY_CONF}" ]]; then
    echo "Error: Configuration file '${DEPLOY_CONF}' not found."
else
    # Source the deploy.conf file
    source "${DEPLOY_CONF}"
fi

# =============================================================================
# Functions
function log_info() {
    echo -e "\e[34m[* INFO  ]\e[0m $1"
}

function log_success() {
    echo -e "\e[32m[+ SUCCESS]\e[0m $1"
}

function log_fail() {
    echo -e "\e[31m[- FAIL  ]\e[0m $1"
}

# =============================================================================
# Step 1: Remove existing deploy directory if it exists
if [[ -d "${DEPLOY_DIR}" ]]; then
    log_info "Removing existing '${DEPLOY_DIR}' directory..."
    rm -rf "${DEPLOY_DIR}"
fi

if [[ -f "${TAR_FILE}" ]]; then
    log_info "Removing existing tar file '${TAR_FILE}'..."
    rm -f "${TAR_FILE}"
fi

# =============================================================================
# Step 2: Create deploy directory
log_info "Creating '${DEPLOY_DIR}' directory..."
mkdir -p "${DEPLOY_DIR}"

# =============================================================================
# Step 3: Copy all files and subdirectories into deploy
log_info "Copying project files into '${DEPLOY_DIR}'..."
rsync -av --exclude "${DEPLOY_DIR}" \
          --exclude ".git" \
          --exclude ".github" \
          --exclude "tests" \
          --exclude "deploy.sh" \
          --exclude ".DS_Store" \
          --exclude ".editorconfig" \
          --exclude ".shellcheckrc" \
          --exclude ".gitignore" \
          --exclude "setup.log" ./ "${DEPLOY_DIR}/"

# =============================================================================
# Step 4: Copy pentest.keys to deploy/dot
log_info "Copying '${KEYS_FILE}' to '${DOT_DIR}/pentest.keys'..."
if [[ ! -f "${KEYS_FILE}" ]]; then
    log_fail "File '${KEYS_FILE}' does not exist. Exiting."
else
    cp "${KEYS_FILE}" "${DOT_DIR}/pentest.keys"
    log_success "'${KEYS_FILE}' successfully copied to '${TOOLS_EXTRA_DIR}/pentest.keys'."
fi

# ==============================================================================
# Step 5: Copy inhouse.sh to deploy/tools/extra/inhouse.sh
log_info "Copying '${INHOUSE_FILE}' to '${TOOLS_EXTRA_DIR}/inhouse.sh'..."
if [[ ! -f "${INHOUSE_FILE}" ]]; then
    log_fail "File '${INHOUSE_FILE}' does not exist. Exiting."
else
    cp "${INHOUSE_FILE}" "${TOOLS_EXTRA_DIR}/inhouse.sh"
    log_success "${INHOUSE_FILE} successfully copied to '${TOOLS_EXTRA_DIR}/inhouse.sh'."
fi

# =============================================================================
# Step 6: Clone private repositories into deploy/tools/extra
log_info "Cloning private repositories into '${TOOLS_EXTRA_DIR}'..."
mkdir -p "${TOOLS_EXTRA_DIR}"

for repo in "${REPOS[@]}"; do
    repo_name=$(basename "${repo}" .git)
    log_info "Cloning repository '${repo_name}'..."
    git clone "${repo}" "${TOOLS_EXTRA_DIR}/${repo_name}" || {
        log_fail "Failed to clone '${repo_name}'."
        exit 1
    }
done

# =============================================================================
# Step 7: Clone specific subdirectories
for entry in "${SUBDIRS[@]}"; do
    IFS="|" read -r repo path dest <<< "${entry}"
    log_info "Cloning repository '${repo}' to extract '${path}' into '${dest}'..."

    TEMP_REPO="${dest}/temp_repo"
    mkdir -p "${dest}"

    # Clone the repository into a temporary location
    git clone "${repo}" "${TEMP_REPO}"

    # Verify the repository was cloned successfully
    if [[ ! -d "${TEMP_REPO}/${path}" ]]; then
        log_fail "Subdirectory '${path}' does not exist in the cloned repository."
        rm -rf "${TEMP_REPO}"
        exit 1
    fi

    # Copy the desired files to the target directory
    cp -r "${TEMP_REPO}/${path}/"* "${dest}/"
    rm -rf "${TEMP_REPO}"

    log_success "Subdirectory '${path}' successfully copied to '${dest}'."
done

# =============================================================================
# Step 8: Package the deploy directory as a tar file
log_info "Packaging '${DEPLOY_DIR}' as '${TAR_FILE}'..."
tar -cf "${TAR_FILE}" "${DEPLOY_DIR}"

# =============================================================================
# Step 9: Clean up deploy directory
if [[ -d "${DEPLOY_DIR}" ]]; then
    log_info "Removing existing '${DEPLOY_DIR}' directory..."
    rm -rf "${DEPLOY_DIR}"
fi

log_success "Build and packaging complete. Output: ${TAR_FILE}"
