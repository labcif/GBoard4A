#!/usr/bin/env bash

set -eo pipefail

mkdir -p empty
trap_add 'rm -rf empty' EXIT

# generate html file
run_gboard_forensics -r "$PWD/empty" -t html -o "$PWD/aoutput.html"
trap_add 'rm aoutput.html' EXIT

# check if file is at least generated
[ ! -f aoutput.html ] && fatal "File 'aoutput.html' doesn't exist!" || :

# check if it is actually an html file
[[ "$(cat aoutput.html)" != '<!DOCTYPE html>'* ]] \
	&& fatal "File 'aoutput.html' is not an HTML" \
	|| :
