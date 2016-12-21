# Drupal setup script

This script is used to automatically perform drupal tasks in a code base. It is
geared towards Drupal 8 but with modifications it can be run in Drupal 7
environmnets.

In Drupal 8 it is combined with composer to assemble the codebase. For more 
information please visit the 
[Drupal composer project](https://github.com/drupal-composer/drupal-project).

## Installation

Download the files from https://github.com/tassoskoutlas/Drupal-setup-script/archive/master.zip

Extract the contents of the zip within your Drupal installation, prefferably in a
directory containing scripts (eg. `./scripts`).

To tweak paths according to your use case edit `config` and set appropriate
paths.

## Usage

The most common use case of this script is when a developer creates or checks
out a new branch and want to create a local installation. The script allows that
through the following

```
drupal.sh --setup
```

This will check for an installation, update the database, import configuration
and rebuild Drupal's registry (clear caches). There are two behaviours included
with the default setup:

1. The current database will be dropped and a canonical database will be
imported.
2. The administrator's password will be updated

The reason behind default behaviour 1 is the concept of UUIDs in Drupal 8 and
the ability to import configuration only in databases which contain the same
global UUID. This works differently to Features in Drupal 7. Currently to be 
able to import configuration exported in code in other environments they should
have used the same canonical database. By installing drupal and exporting the
database right away, an empty, clean, canonical database is created that then
can be imported in all other environments.

The reason behind default behaviour 2 is that in a local environment easier 
access is usually preffered.

Both behaviours can be overriden via command line switches or by editing the 
`config` file.

To see all options invoke the build in help:
```
drupal.sh -h
```

This will result in the following help snippet

```
Usage: ./drupal.sh [options ...]

-i, --install           Assmble the codebase according to the latest package.json.
-u, --update            Update the codebase according to the latest package.json.
-s, --setup             Setup Drupal with a canonical database for local-development (override defaults in config file).
-c, --config-only       Don't use the canonical database (override defaults in config file).
-nl, --non-local        Don't update the administrator's password (override defaults in config file).
-h, --help              Display this help and exit.
```

## Credits

This code is developed and maintained by
[Tassos Koutlas](https://github.com/tassoskoutlas). Pull requests welcome. The 
code is distributed under the [EUPL v1.1](http://ec.europa.eu/idabc/eupl.html) 
open source software license.
