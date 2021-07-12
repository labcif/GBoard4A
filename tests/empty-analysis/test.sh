#!/usr/bin/env bash

set -eo pipefail

mkdir -p empty
trap_add "rm -rf  empty" EXIT

# check if output is the same as expected
test_compare \
	"$(run_gboard_forensics -r "$PWD/empty")" \
	"$(sed "s|@@ROOT_PATH@@|$PWD/empty|g" output.json)"

# generate output file
run_gboard_forensics -r "$PWD/empty" -o "$PWD/aoutput.json"
trap_add 'rm aoutput.json' EXIT

# check generated output file
[ ! -f aoutput.json ] && fatal "File 'aoutput.json' doesn't exist!" || :

# test generated output file
test_compare \
	"$(cat aoutput.json)" \
	"$(sed "s|@@ROOT_PATH@@|$PWD/empty|g" output.json)"
