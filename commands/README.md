# commands

This directory contains scripts that make up the individual commands supported by `rapidsdevtool.sh`. To add a command to `rapidsdevtool.sh`, simply add a script to this directory and make sure it conforms to the following minimum requirements:

* It responds to the `-h` arg by outputting a "short" help that simply shows the command and all the available options. Run `rapidsdevtool.sh -h` for an example.
* It responds to the `-H` arg by outputting the short help plus more detailed help, similar to a man page. Run `rapidsdevtool.sh -H` for an example.

All other args a script needs are passed straight through from `rapidsdevtool.sh` to the script.

The script may access the `utils` subdir which contains utilities shared by all the command scripts. See any of the existing scripts in this directory for examples.

