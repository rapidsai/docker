# templates

`rapidsdevtool.sh` utilizes several code generators for creating Dockerfiles and utility scripts for users that are specific to the environment they're using. The templates in this dir can be modified or new ones can be added to customize various generated files.

The `docker` subdir contains templates for Dockerfile generation.

The `scripts` subdir contains templates for various generated scripts.

Templates are read by the genfile.sh script which uses them to
generate Dockerfiles. Here's a few notes about them:

 1) Files ending in .template are the top-level templates, all other
    files are re-usable "chunks" with (hopefully) self-descriptive
    names.
 
 2) The funny comment characters (#:#) in these files allow comments
    to be used that will not show up in the generated output.

 3) lines starting with `insertfile <fileName>` are used to insert the
    contents of a file directly into the generated output.

 4) `runcommand <command>` runs `<command>` and inserts the output of
    command inline into the generated output. `<command>` is typically
    a shell script, but can also be any command you would run in a
    shell, such as `ls -l`. Many existing templates make use of the
    scripts in `commands/utils` for generating output, in particular,
    output based on the contents of the config file.

 5) everything else not recognized by genfile.sh is included directly
    as-is in the generated output.
