#!/bin/bash


# utility variables

_em="\033[1m\033[37m"
_gr="\033[1m\033[32m"
_me="\033[0m"


# exit on error

function exit_on_error() {
    exit_code=$1
    last_command=${@:2}
    if [ ${exit_code} -ne 0 ]; then
        >&2 echo "\"${last_command}\" command failed with exit code ${exit_code}."
        exit ${exit_code}
    fi
}


# Test remotes. Useful for testing connections. Creates remote db folder if it doesn't exist.

function test_remote {
  _remoteurl=$( wp option get home --skip-themes --skip-plugins --ssh=${_remote} --exec="error_reporting(0); @ini_set('display_errors', 0);" )
  _remoteversion=$( wp core version --skip-themes --skip-plugins --ssh=${_remote} --exec="error_reporting(0); @ini_set('display_errors', 0);" )
  if [ ${_remoteurl} ]; then
    printf "\n${_gr}${_remote}${_me} Connected to remote host" &&
    printf "\nWordPress ${_remoteversion} at ${_remoteurl}" ||
    ssh ${_remote} [ -d ${_remote_path} ] && printf "\n${_remote}:${_remote_path} directory is present\n" || printf "\n${_remote}:${_remote_path} creating remote directory\n" && mkdir -p ${_remote_path}
  else
    printf "\n${_gr}${_remote}${_me} Error connecting to host"
  fi
}

# Sync A to B

function syncdb {

# Export
printf "\n${_em}Exporting the ${_gr}${_source}${_me} database\n"
wp db export --ssh=${_source} ${_remote_path}/syncdb.sql --add-drop-table --exec="error_reporting(0); @ini_set('display_errors', 0);"

# Download
printf "\n${_em}Downloading ${_gr}${_source}${_me} db to local ${_gr}${_local_path}/syncdb.sql\n${_me}"
rsync -avz -e "ssh -o StrictHostKeyChecking=no" ${_source}:${_remote_path}/syncdb.sql ${_local_path}/syncdb.sql

# Upload
if [ ! ${_destination} = "local" ]; then
  printf "${_em}\nUploading ${_gr}${_source}${_me} db to ${_gr}${_destination}\n${_me}"
  rsync -avz -e "ssh -o StrictHostKeyChecking=no" ${_local_path}/syncdb.sql ${_destination}:${_remote_path}/syncdb.sql
fi

# fetch URLs
printf "${_em}\nGettimg urls from ${_gr}${_source}${_me} and ${_gr}${_destination}${_em}\n${_me}"
_search_url=$( wp option get home --skip-themes --skip-plugins --exec="error_reporting(0); @ini_set('display_errors', 0);" --ssh=${_source} )
if [ ${_destination} = "local" ]; then
  _replace_url=$( lando wp option get home --skip-themes --skip-plugins --exec="error_reporting(0); @ini_set('display_errors', 0);" )
else
  _replace_url=$( wp option get home --skip-themes --skip-plugins --exec="error_reporting(0); @ini_set('display_errors', 0);" --ssh=${_destination} )
fi
_search_url=$( echo ${_search_url} | tr -cd "[:print:]\n" ) # sanitize url
_replace_url=$( echo ${_replace_url} | tr -cd "[:print:]\n" )

# import
printf "${_em}\nImporting ${_gr}${_source}${_me} db at ${_gr}${_destination}${_em}\n${_me}"
if [ ${_destination} = "local" ]; then
  lando db-import ${_local_path}/syncdb.sql
else
  wp db import ${_remote_path}/syncdb.sql --exec="error_reporting(0); @ini_set('display_errors', 0);" --ssh=${_destination}
fi

# search-replace
printf "\n${_em}Searching for ${_gr}${_search_url}${_me} and replacing with ${_gr}${_replace_url}\n${_me}"
if [ ${_destination} = "local" ]; then
  lando wp search-replace "${_search_url}" "${_replace_url}" --skip-columns=guid --exec="error_reporting(0); @ini_set('display_errors', 0);"
else
  wp search-replace "${_search_url}" "${_replace_url}" --skip-columns=guid --exec="error_reporting(0); @ini_set('display_errors', 0);"  --ssh=${_destination}
fi

# clean up
printf "\n${_em}Cleaning up${_me}\n"
_pre="" ; _post=""
if [ ${_destination} = "local" ]; then
  _pre="lando"
else
  _post="--ssh=${_destination}"
fi
${_pre} wp plugin activate --all ${_post}
${_pre} wp cache flush ${_post}
${_pre} wp rewrite flush ${_post}
${_pre} wp spinupwp cache purge-site ${_post}
${_pre} wp acorn view:clear ${_post}
${_pre} wp acorn view:cache ${_post}
if [ ${_destination} = "local" ]; then
  rm ${_local_path}/syncdb.sql
else
  ssh ${_destination} rm ${_remote_path}/syncdb.sql
fi
ssh ${_source} rm ${_remote_path}/syncdb.sql

}
