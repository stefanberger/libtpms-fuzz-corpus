## Fuzzing data for swtpm

This project contains fuzzing data for swtpm, but it can also be used to fuzz hardware TPMs.

The TPM 2 command packets in this project were created by libtpms's fuzzer. The intention of
these TPM 2 commands is to trigger faults in swtpm's TPM 2 code and possibly to improve
testing code coverage, but this is secondary.

Two scripts are provided that feed all these fuzzer data into swtpm. You can
run them as described below. You should watch swtpm that it doesn't crash. The
responses to the commands that are sent may be TPM 2 error messages, but this
is expected for fuzzing. The command don't necessarily succeed. Actually
most will not.

## Fuzzing swtpm via socket interface

In one terminal run the following commands to start swtpm:

```
mkdir /tmp/myvtpm
swtpm socket \
  --tpmstate dir=/tmp/myvtpm \
  --tpm2 \
  --ctrl type=tcp,port=2322 \
  --server type=tcp,port=2321,disconnect \
  --flags not-need-init,startup-clear \
  --log level=20
```

In another terminal start the provided client tool. The passed environment variables
show that you can control on which ports the swtpm is listening.

```
SWTPM_SERVER_NAME=localhost SWTPM_SERVER_PORT=2321 SWTPM_CTRL_PORT=2322 \
SWTPM_SAVE_RESTORE=1 \
  ./run-test-tcp.sh
```

## Fuzzing swtpm via chardev interface

In one terminal run the following commands to start swtpm:

```
mkdir /tmp/myvtpm
sudo modprobe tpm_vtpm_proxy
sudo swtpm chardev \
  --tpmstate dir=/tmp/myvtpm \
  --tpm2 \
  --vtpm-proxy \
  --ctrl type=tcp,port=2322 \
  --flags startup-clear \
  --log level=0
```

In another terminal start the provided client tool. The command line below assumes
that the device created by swtpm above is `/dev/tpm1`. You may need to adjust this.

```
sudo bash -c "SWTPM_SAVE_RESTORE=1 SWTPM_DEVICE=/dev/tpm1 ./run-test-chardev.sh"
```

