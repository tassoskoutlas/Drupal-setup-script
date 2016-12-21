#!/bin/bash
#
# Run drupal setup commands.

# Exit script if any zero exit code encountered.
set -e

# The main function.
#
# It loops through the arguments passed from the command line and sets flags to
# influence the execution of the scripts. Once done processing command line 
# arguments calls the run() function which starts the execution of logic.
#
# Globals:
#  ${INSTALL} - A string defined 'true' or 'false' to determine if installation
#  commands will run.
#  ${UPDATE} - A string defined 'true' or 'false' to determine if update
#  commands will run.
#  ${SETUP} - A string defined 'true' or 'false' to determine if setup commands
#  will run.
#  ${INIT} - A string defined 'true' or 'false' to determine if setup will
#  replace the current database with the canonical database.
#  ${DEV} - A string defined 'true' or 'false' to determine if setup will
#  update the administrator's password.
# Arguments:
#  None
# Returns:
#  None
main() {
  # Display help if no arguments given.
  if [[ $# -eq 0 ]]; then
    abort "Aborted -- No arguments passed to script."
  fi
  
  # Main loop through arguments
  while [[ $# -gt 0 ]]; do

    case "$1" in
      -i | --install)
        readonly INSTALL="true"
        ;;
      -u | --update)
        readonly UPDATE="true"
        ;;
      -s | --setup)
        readonly SETUP="true"
        ;;
      -c | --config-only)
        empty "${SETUP}" "You need to use -s or --setup with this option first."
        readonly INIT="false"
        ;;
      -nl | --non-local)
        empty "${SETUP}" "You need to use -s or --setup with this option first."
        readonly DEV="false"
        ;;
      --show-config)
        show_debug_info
        exit 0
        ;;
      -h | --help)
        show_help
        exit 0
        ;;
      -*)
        abort "Aborted -- Please see correct usage below."
        ;;
      *) 
        abort "Aborted -- Please see correct usage below." 
        ;;
      esac
      shift
  done

  # Run the main functions.
  run
}

# Path of the script
SCRIPTPATH=$( cd $(dirname $0) ; pwd -P)

# Source other files
source ${SCRIPTPATH}/config
source ${SCRIPTPATH}/functions.sh

# Script
main "$@"
exit 0
