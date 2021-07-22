#!/usr/bin/env bash

#set -x

SWTPM_SERVER_NAME=${SWTPM_SERVER_NAME:-localhost}
SWTPM_SERVER_PORT=${SWTPM_SERVER_PORT:-2321}
SWTPM_CTRL_PORT=${SWTPM_CTRL_PORT:-2322}

# Start swtpm like this:
# mkdir /tmp/myvtpm
# swtpm socket \
#   --tpmstate dir=/tmp/myvtpm \
#   --tpm2 \
#   --ctrl type=tcp,port=2322 \
#   --server type=tcp,port=2321,disconnect \
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

for f in *;
do
  exec 100<>/dev/tcp/${SWTPM_SERVER_NAME}/${SWTPM_SERVER_PORT}
  len=$(get_filesize "${f}")
  [ $len -lt 10 ] && continue
  echo "${f}"
  cat "${f}">&100
  [ $? -ne 0 ] && exit 1
  od -tx1 <&100
  exec 100>&-

  if [ "${SWTPM_SAVE_RESTORE}" -ne 0 ]; then
    echo "saving and restoring volatile state"
    swtpm_ioctl -v --tcp ${SWTPM_SERVER_NAME}:${SWTPM_CTRL_PORT}
    [ $? -ne 0 ] && exit 1
    swtpm_ioctl -i --tcp ${SWTPM_SERVER_NAME}:${SWTPM_CTRL_PORT}
    [ $? -ne 0 ] && exit 1
  fi
done

exit 0
