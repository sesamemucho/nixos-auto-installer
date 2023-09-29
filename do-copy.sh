set -x

isoname=$(echo result/iso/*.iso)
time dd status=progress if=$isoname  of=/dev/sdb bs=2M; sync; sync; sync
