#!/bin/bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# utility variables

_em="\033[1m\033[37m"
_gr="\033[1m\033[32m"
_me="\033[0m"


# exit on error

function exit_on_error() {
    exit_code=$1
    last_command=${@:2}
    if [ "${exit_code}" -ne 0 ]; then
        >&2 echo "\"${last_command}\" command failed with exit code ${exit_code}."
        exit "${exit_code}"
    fi
}


# Validate URL format
function validate_url() {
  local url="$1"
  # Check for http/https protocol
  if [[ ! "${url}" =~ ^https?:// ]]; then
    return 1
  fi
  # Check for shell injection characters
  if [[ "${url}" =~ [\;\|\&\$\`] ]]; then
    return 1
  fi
  return 0
}


# Validate that source/destination is in allowed list
function validate_remote() {
  local remote="$1"
  local allowed=("${_production}" "${_remotes[@]}" "local")

  for allowed_remote in "${allowed[@]}"; do
    if [ "${remote}" = "${allowed_remote}" ]; then
      return 0
    fi
  done

  printf "\n${_em}${_gr}ERROR:${_me} Invalid remote '${remote}'\n"
  printf "Allowed remotes: ${allowed[*]}\n"
  return 1
}


# Validate path to prevent directory traversal
function validate_path() {
  local path="$1"
  # Check for directory traversal attempts
  if [[ "${path}" == *".."* ]]; then
    printf "\n${_em}${_gr}ERROR:${_me} Path contains '..' which is not allowed\n"
    return 1
  fi
  # Check for absolute paths outside project
  if [[ "${path}" =~ ^/ ]]; then
    printf "\n${_em}${_gr}ERROR:${_me} Absolute paths are not allowed\n"
    return 1
  fi
  return 0
}


# Test remotes. Useful for testing connections. Creates remote db folder if it doesn't exist.

function test_remote {
  _remoteurl=$( wp option get home --skip-themes --skip-plugins --ssh="${_remote}" --exec="error_reporting(0); @ini_set('display_errors', 0);" )
  _remoteversion=$( wp core version --skip-themes --skip-plugins --ssh="${_remote}" --exec="error_reporting(0); @ini_set('display_errors', 0);" )
  if [ -n "${_remoteurl}" ]; then
    printf "\n${_gr}${_remote}${_me} Connected to remote host"
    printf "\nWordPress ${_remoteversion} at ${_remoteurl}"
    if ssh "${_remote}" "[ -d ${_remote_path} ]"; then
      printf "\n${_remote}:${_remote_path} directory is present\n"
    else
      printf "\n${_remote}:${_remote_path} creating remote directory\n"
      ssh "${_remote}" "mkdir -p ${_remote_path}"
    fi
  else
    printf "\n${_gr}${_remote}${_me} Error connecting to host"
  fi
}

# Sync A to B

function syncdb {

# Validate source and destination
validate_remote "${_source}" || return 1
validate_remote "${_destination}" || return 1

# Validate paths
validate_path "${_local_path}" || return 1
validate_path "${_remote_path}" || return 1

# Ensure remote directory exists on source server
printf "\n${_em}Ensuring remote directory exists on ${_gr}${_source}${_me}\n"
if ! ssh "${_source}" "mkdir -p ${_remote_path}"; then
  printf "\n${_em}${_gr}ERROR:${_me} Failed to create directory on ${_source}\n"
  return 1
fi

# Export
printf "\n${_em}Exporting the ${_gr}${_source}${_me} database\n"
if ! wp db export --ssh="${_source}" "${_remote_path}/syncdb.sql" --add-drop-table --exec="error_reporting(0); @ini_set('display_errors', 0);"; then
  printf "\n${_em}${_gr}ERROR:${_me} Failed to export database from ${_source}\n"
  return 1
fi

# Download
printf "\n${_em}Downloading ${_gr}${_source}${_me} db to local ${_gr}${_local_path}/syncdb.sql\n${_me}"
mkdir -p "${_local_path}"
if ! rsync -avz -e "ssh" "${_source}:${_remote_path}/syncdb.sql" "${_local_path}/syncdb.sql"; then
  printf "\n${_em}${_gr}ERROR:${_me} Failed to download database from ${_source}\n"
  return 1
fi

# Upload
if [ "${_destination}" != "local" ]; then
  printf "${_em}\nUploading ${_gr}${_source}${_me} db to ${_gr}${_destination}\n${_me}"
  if ! ssh "${_destination}" "mkdir -p ${_remote_path}"; then
    printf "\n${_em}${_gr}ERROR:${_me} Failed to create directory on ${_destination}\n"
    return 1
  fi
  if ! rsync -avz -e "ssh" "${_local_path}/syncdb.sql" "${_destination}:${_remote_path}/syncdb.sql"; then
    printf "\n${_em}${_gr}ERROR:${_me} Failed to upload database to ${_destination}\n"
    return 1
  fi
fi

# fetch source URL
printf "${_em}\nGetting source URL from ${_gr}${_source}${_em}\n${_me}"
_search_url=$( wp option get home --skip-themes --skip-plugins --exec="error_reporting(0); @ini_set('display_errors', 0);" --ssh="${_source}" )
_search_url=$( echo "${_search_url}" | tr -cd "[:print:]\n" ) # sanitize url

# Validate source URL
if ! validate_url "${_search_url}"; then
  printf "\n${_em}${_gr}ERROR:${_me} Invalid source URL: ${_search_url}\n"
  return 1
fi

# fetch destination URL (before import)
printf "${_em}\nGetting destination URL from ${_gr}${_destination}${_em}\n${_me}"
if [ "${_destination}" = "local" ]; then
  # Try to get URL from existing database, fall back to config/Lando
  _replace_url=$( lando wp option get home --skip-themes --skip-plugins 2>/dev/null || true )
  if [ -z "${_replace_url}" ] || [[ "${_replace_url}" =~ "Error:" ]]; then
    # Database doesn't exist or returned error, derive from config or .lando.yml
    if [ -z "${_local_url:-}" ]; then
      _lando_name=$(grep -E "^name:" .lando.yml | awk '{print $2}')
      _replace_url="https://${_lando_name}.lndo.site"
      printf "${_em}No existing database found, using Lando config: ${_gr}${_replace_url}${_em}\n${_me}"
    else
      _replace_url="${_local_url}"
      printf "${_em}No existing database found, using config: ${_gr}${_replace_url}${_em}\n${_me}"
    fi
  fi
else
  # Try to get URL from remote destination database
  _replace_url=$( wp option get home --skip-themes --skip-plugins --exec="error_reporting(0); @ini_set('display_errors', 0);" --ssh="${_destination}" 2>/dev/null || true )
  if [ -z "${_replace_url}" ] || [[ "${_replace_url}" =~ "Error:" ]]; then
    printf "\n${_em}${_gr}ERROR:${_me} Cannot retrieve destination URL from ${_gr}${_destination}${_me}\n"
    printf "The destination database must exist with a configured site URL.\n"
    printf "Please ensure WordPress is installed on ${_gr}${_destination}${_me} before syncing.\n"
    return 1
  fi
fi
_replace_url=$( echo "${_replace_url}" | tr -cd "[:print:]\n" )

# Validate destination URL
if ! validate_url "${_replace_url}"; then
  printf "\n${_em}${_gr}ERROR:${_me} Invalid destination URL: ${_replace_url}\n"
  return 1
fi

# import
printf "${_em}\nImporting ${_gr}${_source}${_me} db at ${_gr}${_destination}${_em}\n${_me}"
if [ "${_destination}" = "local" ]; then
  if ! lando db-import "${_local_path}/syncdb.sql"; then
    printf "\n${_em}${_gr}ERROR:${_me} Failed to import database locally\n"
    return 1
  fi
else
  if ! wp db import "${_remote_path}/syncdb.sql" --exec="error_reporting(0); @ini_set('display_errors', 0);" --ssh="${_destination}"; then
    printf "\n${_em}${_gr}ERROR:${_me} Failed to import database to ${_destination}\n"
    return 1
  fi
fi

# search-replace
printf "\n${_em}Searching for ${_gr}${_search_url}${_me} and replacing with ${_gr}${_replace_url}\n${_me}"
if [ "${_destination}" = "local" ]; then
  if ! lando wp search-replace "${_search_url}" "${_replace_url}" --skip-columns=guid --exec="error_reporting(0); @ini_set('display_errors', 0);"; then
    printf "\n${_em}${_gr}WARNING:${_me} Search-replace may have encountered issues\n"
  fi
else
  if ! wp search-replace "${_search_url}" "${_replace_url}" --skip-columns=guid --exec="error_reporting(0); @ini_set('display_errors', 0);" --ssh="${_destination}"; then
    printf "\n${_em}${_gr}WARNING:${_me} Search-replace may have encountered issues\n"
  fi
fi

# clean up
printf "\n${_em}Cleaning up${_me}\n"
_pre="" ; _post=""
if [ "${_destination}" = "local" ]; then
  _pre="lando"
else
  _post="--ssh=${_destination}"
fi
${_pre} wp plugin activate --all ${_post} || true
${_pre} wp cache flush ${_post} || true
${_pre} wp rewrite flush ${_post} || true

# Check if SpinupWP is available before running cache purge
if ${_pre} wp cli has-command "spinupwp cache purge-site" ${_post} 2>/dev/null; then
  printf "${_em}Purging SpinupWP cache${_me}\n"
  ${_pre} wp spinupwp cache purge-site ${_post} || true
fi

# Check if Acorn (Sage/Bedrock) is available before running view commands
if ${_pre} wp cli has-command "acorn view:clear" ${_post} 2>/dev/null; then
  printf "${_em}Clearing Acorn views${_me}\n"
  ${_pre} wp acorn view:clear ${_post} || true
  ${_pre} wp acorn view:cache ${_post} || true
fi

# Clean up temporary files
if [ "${_destination}" = "local" ]; then
  if [ -f "${_local_path}/syncdb.sql" ]; then
    rm "${_local_path}/syncdb.sql"
  fi
else
  ssh "${_destination}" "rm -f ${_remote_path}/syncdb.sql" || true
fi
ssh "${_source}" "rm -f ${_remote_path}/syncdb.sql" || true

printf "\n${_em}${_gr}Sync completed successfully!${_me}\n"

}
