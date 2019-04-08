The templates in this directory are read by the genfile.sh script
which uses them to generate Dockerfiles. Here's a few notes about
them:

 1) Files ending in .template are the top-level templates, all other
    files are re-usable "chunks" with (hopefully) self-descriptive
    names.
 
 2) The funny comment characters (#:#) in these files allow comments
    to be used that will not show up in the generated output.

 3) lines starting with "insertfile " followed by a filename are used
    to insert the contents of a file directly into the generated
    output.

 4) lines starting with "runcommand " followed by a command and
    optional args are used for running that command with args and
    adding its output directly in the generated output.

 5) everything else not recognized by genfile.sh is included directly
    as-is in the generated output.
