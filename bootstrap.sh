#!/bin/sh

set -x
set -e

apt-get install -y make
make setup
