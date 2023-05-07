# list the ssh config host names of remote installs for this project

_production=ds6_prod
_remotes=( ds6_stage ds6_dev)


# enter the paths to directories where .sql files will be stored. Omit trailing slash.

_local_path="dev/db"
_remote_path="db"


# utility variables

_em="\033[1m\033[37m"
_gr="\033[1m\033[32m"
_me="\033[0m"
