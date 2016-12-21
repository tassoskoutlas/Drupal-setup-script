#!/bin/bash
#
# Contains helper and drupal specific functions.

# Exit script if any exit 0 code.
set -e

####################
# Helper functions #
####################

# Helper to display a message in specific colour.
#
# Globals:
#  None
# Arguments:
#  ${message} - A string which contains the message to be displayed.
#  ${colour} - A string which contains the format code of the colour the message
#    should be displayed in.
# Returns:
#  None
text() {
  local message="$1"
  local colour="$2"
  local start="\033[${colour}m"
  local end="\033[0m"
  echo -en ${start} ; echo -e ${message} ; echo -en ${end}
}

# Displays an informational message.
#
# Globals:
#  ${GREEN} - A string containing the format code of colour green.
# Arguments:
#  ${message} - A string which contains the message to be displayed.
# Returns:
#  None
message() {
  local message="$1"
  text "${message}" ${INFO_COLOUR}
}

# Exits with an error message and non zero status.
#
# Globals:
#  ${RED} - A string containing the format code of colour red.
# Arguments:
#  ${message} - A string which contains the message to be displayed.
# Returns:
#  None
abort() {
  local message="$1"
  text "${message}\n" ${ERROR_COLOUR} >&2
  show_help
  # TODO(tassos): pull out exit codes into globals (proposal #2).
  exit 1
}

# Checks for an empty variable and aborts with message.
#
# Globals:
#  None
# Arguments:
#  ${var} - A string which contains the variable to check.
#  ${message} - A string which contains the message to be displayed.
# Returns:
#  None
empty() {
  local var="$1"
  local message="$2"
  if [[ -z ${var} ]]; then
    abort "${message}"
  fi
}

# Explains the usage of the script.
#
# Globals:
#  None
# Arguments:
#  ${shell_name} - Name of the shell.
# Returns:
#  None
show_help() {
  local shell_name="$0"
  message "Usage: ${shell_name} [options ...]\n"
  message "   -i, --install\t\tAssmble the codebase according to the latest package.json."
  message "   -u, --update\t\tUpdate the codebase according to the latest package.json."
  message "   -s, --setup\t\tSetup Drupal with a canonical database for local-development (override defaults in config file)."
  message "   -c, --config-only\tDon't use the canonical database (override defaults in config file)."
  message "   -nl, --non-local\tDon't update the administrator's password (override defaults in config file)."
  message "   -h, --help\t\tDisplay this help and exit."
}

# Shows debug information.
#
# Globals:
#  ${SCRIPTPATH} - The path of the script.
#  ${REPOSITORY} - The path of the repository.
#  ${DB} - The full path of the canonical database.
#  ${DOCROOT} - The path of the document root.
#  ${DRUPAL_CONFIG_DIR} - The path where Drupal configuration is exported.
# Arguments:
#  None
# Returns:
#  None
show_debug_info() {
  message "SCRIPTPATH: \t\t${SCRIPTPATH}"
  message "REPOSITORY: \t\t${REPOSITORY}"
  message "DB: \t\t\t${DB}"
  message "DOCROOT: \t\t${DOCROOT}"
  message "DRUPAL_CONFIG_DIR: \t${DRUPAL_CONFIG_DIR}"
}

####################
# Drupal functions #
####################

# Sets Drupal's maintenance mode.
#
# This function is used to put a Drupal site in and out of maintenance mode. Use
# "on" to set Drupal into maintenance or "off" otherwise.
#
# Globals:
#  None
# Arguments:
#  ${switch} - A string with which can be 'on' or 'off'.
# Returns:
#  None
drupal_set_maintenance_mode() {
  # TODO(tassos): change this to use a switch statement (proposal #3)
  local switch="$1"
  if [[ -z "${switch}" ]]; then
    abort "Wrong maintenance mode value"
  fi
  
  if [[ "${switch}" = "on" ]]; then
    local mode=1
    local message="enabled"
  fi
  
  if [[ "${switch}" = "off" ]]; then
    local mode=0
    local message="disabled"
  fi
  
  ${DRUSH} sset system.maintenance_mode ${mode}
  message "Maintenance mode ${message}."
}

# Checks if a file exists.
#
# A helper function to abstract various checks in the filesystem which are used
# to determine validity of scenarions. It is usually invocked through other 
# drupal functions.
#
# Globals:
#  None
# Arguments:
#  ${path} - A string with which can be 'on' or 'off'.
#  ${message} - A string with the abort message.
# Returns:
#  None
drupal_check_if_file_exists() {
  local path="$1"
  local message="$2"
  if [[ ! -f ${path} ]]; then
    abort ${message}
  fi
}

# Checks if an installation exists.
#
# This functions checks if an installation of Drupal exists before it allows to
# go any further. If an installation does not exist then it aborts with a
# a default message.
#
# Globals:
#  ${DOCROOT} - The path of the document root.
#  ${FILE_TO_CHECK_INSTALLATION} - A string with the filename for the
#  installation check.
# Arguments:
#  None
# Returns:
#  None
drupal_check_if_installation_exists() {
  drupal_check_if_file_exists \
    "${DOCROOT}/${FILE_TO_CHECK_INSTALLATION}" \
    "Aborted -- installation does not exist"
  message "Entering docroot ..."
  cd ${DOCROOT}
}

# Checks if configuration is exported.
#
# This function checks if configuration is exported or exits with an abort
# message otherwise. If configuration is not exported and an configuration
# import command is run it will delete anything in the database which is 
# undesirable. This function ensures that cim commands run only if configuration
# is exported.
#
# Globals:
#  ${DRUPAL_CONFIG_DIR} - The path of the configuration directory.
#  ${FILE_TO_CHECK_CONFIGURATION} - A string with the filename to determine if 
#  configuration is exported.
# Arguments:
#  None
# Returns:
#  None
drupal_check_if_configuration_is_exported() {
  drupal_check_if_file_exists \
    "${DRUPAL_CONFIG_DIR}/${FILE_TO_CHECK_CONFIGURATION}" \
    "Aborted -- configuration not exported"
}

# Restores a database.
#
# This function restores a canonical database backup which is within the backup
# directory. A canonical database is the database dump right after the first
# drupal installation. It is used to create all other environments and eases the
# importing and exporting configuration between environments.
#
# Globals:
#  ${DRUSH} - The location of drush executable.
#  ${DB} - A string with the canonical database to be imported.
# Arguments:
#  None
# Returns:
#  None
drupal_restore_canonical_db() {
  message "Dropping previous database ..."
  ${DRUSH} sql-drop -y
  message "Importing master database ..."
  # TODO(tassos): create a generalised version of this (drush sql-connect does
  # not work anymore) (issue #4).
  mysql kontrast <  ${DB}
}

# Updates administrator's password.
#
# This functions is invocked with the -d parameter and ensures that it updates
# the password for user/1. This is used to ease local development while 
# retaining a comprehensive password policy in other environments.
#
# Globals:
#  ${DRUSH} - The location of drush executable.
#  ${LOCAL_ADMIN_USER} - A string with the administrator's username.
#  ${LOCAL_ADMIN_PASSWORD} - A string with the administrator's password.
# Arguments:
#  None
# Returns:
#  None
drupal_set_admin_password_to_admin() {
  message "Setting up administrator's password for local development ..."
  ${DRUSH} upwd ${LOCAL_ADMIN_USER} --password="${LOCAL_ADMIN_PASSWORD}"
}

# Imports Drupal's configuration.
#
# Drupal's configuration is contained within the DRUPAL_CONFIG_DIR configuraiton
# variable. The function ensures that configuration is exported and if it is
# it imports it in the codebase.
#
# Globals:
#  ${DRUSH} - The location of drush executable.
# Arguments:
#  None
# Returns:
#  None
drupal_configuration_import() {
  drupal_check_if_configuration_is_exported
  message "Importing configuration ..."
  ${DRUSH} cim -y
}

# Updates the Drupal database.
#
# This function is used to trigger the default Drupal behaviour when a database
# needs to be updated.
#
# Globals:
#  ${DRUSH} - The location of drush executable.
# Arguments:
#  None
# Returns:
#  None
drupal_database_update() {
  message "Applying database updates ..."
  ${DRUSH} updb -y
}

# Rebuilds the Drupal cache.
#
# This function is used to trigger the default Drupal behaviour when cache needs
# to be rebuilt.
#
# Globals:
#  ${DRUSH} - The location of drush executable.
# Arguments:
#  None
# Returns:
#  None
drupal_registry_rebuild() {
  message "Rebuilding cache ..."
  ${DRUSH} cr -y
}

# Creates a Drupal installation.
#
# This function is used to abstract the composer commands required to assmble
# the Drupal codebase. All codebase depends on the package.json that is included
# in the top level directory of the repository.
#
# Globals:
#  ${UPDATE} - A string defined 'true' or 'false' based on the command line 
#  argument passed to the script.
# Arguments:
#  None
# Returns:
#  None
drupal_install() {
  if [[ "${UPDATE}" = "true" ]]; then
    abort "Aborted -- You can not invoke install and update on the same command."
  fi
  abort "Aborted -- Installation function not yet implemented."
  # TODO(tassos): once completed export the canonical database and place it in
  # the appropriateplace.
}

# Updates a Drupal installation.
#
# This function is used to abstract the composer commands required to update the
# Drupal codebase. Runing the update function will download the latest version
# of all Drupal modules.
#
# Globals:
#  ${INSTALL} - A string defined 'true' or 'false' based on the command line 
#  argument passed to the script.
# Arguments:
#  None
# Returns:
#  None
drupal_update() {
  if [[ "${INSTALL}" = "true" ]]; then
    abort "Aborted -- You can not invoke install and update on the same command."
  fi
  abort "Aborted -- Update function not yet implemented."
}

# Set's up a Drupal installation.
#
# This function is used to setup a Drupal codebase. It takes care of executing
# all pending updates to the database, import all new configuration and clearing
# caches. For more help see the help for individual commands.
#
# Globals:
#  ${INIT} - A string defined 'true' or 'false' to determine if the canonical
#  database will be restored.
#  ${DEV} - A string defined 'true' or 'false' to determine if this is a local
#  development environment
# Arguments:
#  None
# Returns:
#  None
drupal_setup() {
  message "Starting setup ..."
  drupal_check_if_installation_exists

  if [[ "${INIT}" = "true" ]]; then
    drupal_restore_canonical_db
  fi
  
  drupal_set_maintenance_mode "on"
  drupal_database_update
  drupal_configuration_import
  drupal_registry_rebuild
  
  if [[ "${DEV}" = "true" ]]; then
    drupal_set_admin_password_to_admin
  fi
  
  drupal_set_maintenance_mode "off"
  message "All done!"
}

# Runs the specified routines.
#
# Globals:
#  ${INSTALL} - A string defined 'true' or 'false' to determine if installation
#  commands will run.
#  ${UPDATE} - A string defined 'true' or 'false' to determine if update
#  commands will run.
#  ${SETUP} - A string defined 'true' or 'false' to determine if setup commands
#  will run.
#  argument passed to the script.
# Arguments:
#  None
# Returns:
#  None
run() {

  if [[ "${INSTALL}" = "true" ]]; then
    drupal_install
  fi

  if [[ "${UPDATE}" = "true" ]]; then
    drupal_update
  fi

  if [[ "${SETUP}" = "true" ]]; then
    drupal_setup
  fi

}
