#!/bin/bash

# define our variables
source "${0%/*}"/options.sh
source "${0%/*}"/lib/functions.sh

# Define the array of choices
_sources=( ${_production[@]} ${_remotes[@]} )
_destinations=( "local" ${_remotes[@]}  )
echo "Sources: ${_sources[@]}"

# execute from the base path of the install
# cd "$(dirname "$0")/../../.."

# Caveat
echo "
This script will overwrite a selected destination db with a selected source db.
Select Quit if this isn't cool."


# Main menu

_options=( "Sync database" "Test connections" "Quit" )
printf "${_em}\nPlease select an option:\n\n${_me}"
PS3="Enter a number: "
select _option in "${_options[@]}"; do

    # execute the selected reply
    case $_option in

      #  Quit
      "Quit")
      printf "\nLater gator!\n"
      exit 0
      ;;

      #  Test
      "Test connections")
      printf "${_em}\nTesting hosts: ${_sources[@]}\n${_me}"
      for _remote in "${_sources[@]}"; do test_remote && wait; done
      exit 0
      ;;

      #  Sync
      "Sync database")
      printf "${_em}\nSyncronize two databases\n\n${_me}"
      break;;

      # Out of range
      *)
      echo "Whoa there! Select any number from 1-${#_options[@]}."; continue

    esac
done


# Prompt the user to select a source

_count=$((${#_sources[@]} + 0))
printf "\nPlease select a source (1-$_count).\n"
PS3="Source: "
select _source in "${_sources[@]}"; do
    case 1 in
        $(($REPLY<= $_count)))
            printf "Source is ${_em}${_gr}$_source${_me}\n"
            break
            ;;
        *)
            echo "Invalid selection, please try again."
            ;;
    esac
done


# Prompt the user to select a destination

_count=$((${#_destinations[@]} + 0))
printf "\nPlease select a destination (1-$_count).\n"
PS3="Destination: "
select _destination in "${_destinations[@]}"; do
  case 1 in
      $(($REPLY<= $_count)))
          printf "Destination is ${_em}${_gr}$_destination${_me}\n"
          break
          ;;
      *)
          echo "Invalid selection, please try again."
          ;;
  esac
done

# Confirm selections

printf "\nSyncing '${_em}${_gr}$_source${_me}' to '${_em}${_gr}$_destination${_me}'\n"
read -p "You sure? (y/n)" choice
case "$choice" in
  y|Y ) echo "yes"
      syncdb
      ;;
  n|N ) echo "no"
      return;
      ;;
  *) echo "(y/n)"
  ;;
esac
