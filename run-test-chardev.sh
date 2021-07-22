#!/usr/bin/env bash

#set -x

SWTPM_DEVICE=${SWTPM_DEVICE:-/dev/tpm0}
SWTPM_CTRL_PORT=${SWTPM_CTRL_PORT:-2322}

# Start swtpm like this:
# mkdir /tmp/myvtpm
# sudo modprobe tpm_vtpm_proxy
# sudo swtpm socket \
#   --tpmstate dir=/tmp/myvtpm \
#   --tpm2 \
#   --vtpm-proxy \
#   --ctrl type=tcp,port=2322 \
#   --flags not-need-init,startup-clear \
#   --log level=20

# Get the size of a file in bytes
#
# @1: filename
function get_filesize()
{
  if [[ "$(uname -s)" =~ (Linux|CYGWIN_NT-) ]]; then
    stat -c%s $1
  else
    # OpenBSD
    stat -f%z $1
  fi
}

# Check whether a file contains a valid TPM command
# so that we don't get stuck due to the TPM driver blocking
# us on incomplete data
#
# @1: filename
function is_file_valid()
{
  local flen plen

  flen=$(get_filesize "${f}")
  [ $flen -lt 10 ] && return 1

  plen=$(dd bs=1 skip=2 count=4 status=none < ${1} \
         | od -tx1 -An \
         | tr -d " ")
  [ "$(printf "%08x" ${flen} )" != "${plen}" ] && return 1
  return 0
}

for f in *;
do
  is_file_valid "${f}"
  [ $? -ne 0 ] && continue

  echo "${f}"

  if ! [ -c "${SWTPM_DEVICE}" ]; then
    echo "${SWTPM_DEVICE} is not a chardev!"
    exit 1
  fi

  exec 100<>${SWTPM_DEVICE}
  cat "${f}">&100
  cat <&100 <&100 | od -tx1
  exec 100>&-

  if [ "${SWTPM_SAVE_RESTORE}" -ne 0 ]; then
    echo "saving and restoring volatile state"
    swtpm_ioctl -v --tcp localhost:${SWTPM_CTRL_PORT}
    [ $? -ne 0 ] && exit 1
    swtpm_ioctl -i --tcp localhost:${SWTPM_CTRL_PORT}
    [ $? -ne 0 ] && exit 1
  fi
done

exit 0
