#! /bin/bash
set -e

esphome compile shutterswitch.yaml

# List of MAC addreses suffixes
MACS="d39b07 2380dd 2361e0 2332a4"

for mac in $MACS
do
    esphome upload shutterswitch.yaml --device shutterswitch-$mac.local
done
