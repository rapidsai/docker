# retry - source this file to add the "retry" function to your environment.
# retry retries a command 10 times after a non-zero exit, waiting 10 seconds
# between attempts. 10 times and 10 seconds are default values which can be
# configured with env vars described below.
#
#   NOTE: source this file to update your bash environment with the settings
#   below. Keep in mind that the calling environment will be modified, so do not
#   set or change the environment here unless the caller expects that.  Also
#   remember that "exit" will exit the calling shell!  Consider rewriting this
#   as a callable script if the functionality below needs to make changes to its
#   environment as a side-effect.
#
# Example usage:
# retry docker push rapidsai/rapidsai-nightly:latest
#
# Configurable options are set using the following env vars:
#
# RETRY__MAX_RETRIES - set to a positive integer to set the max number of retry
#                      attempts (attempts after the initial try).
#                      Default is 10 retries
#
# RETRY__SLEEP_INTERVAL - set to a positive integer to set the duration, in
#                         seconds, to wait between retries.
#                         Default is a 10 second sleep
#
function retry {
   command=$1
   shift
   args=$*
   max_retries=${RETRY__MAX_RETRIES:=10}
   retries=0
   sleep_interval=${RETRY__SLEEP_INTERVAL:=10}

   ${command} ${args}
   retcode=$?
   while (( ${retcode} != 0 )) && \
         (( ${retries} < ${max_retries} )); do
       ((retries++))
       echo "========================================"
       echo "RETRY ${retries} OF ${max_retries}"...
       echo -n "sleeping for ${sleep_interval} seconds..."
       sleep ${sleep_interval}
       echo "done"
       echo "========================================"

       ${command} ${args}
       retcode=$?
   done
   return ${retcode}
}
