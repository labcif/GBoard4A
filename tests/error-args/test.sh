#!/usr/bin/env bash

set -eo pipefail

mkdir -p empty-dir
touch empty-file
trap_add 'rm -rf empty-dir empty-file' EXIT

# test -f with fake files
test_compare \
	"$(run_gboard_forensics -f doesnt-exist 2>&1)" \
	'One or more files specified ["doesnt-exist"] do not exist!'

# multiple -f args
test_compare \
	"$(run_gboard_forensics -f doesnt-exist -f doesnt-exist2 -f $PWD/empty-file 2>&1)" \
	'One or more files specified ["doesnt-exist", "doesnt-exist2"] do not exist!'

# test -d with fake dirs
test_compare \
	"$(run_gboard_forensics -d doesnt-exist 2>&1)" \
	'One or more directories specified ["doesnt-exist"] do not exist!'

# multiple -d args
test_compare \
	"$(run_gboard_forensics -d doesnt-exist -d doesnt-exist2 -d $PWD/empty-dir 2>&1)" \
	'One or more directories specified ["doesnt-exist", "doesnt-exist2"] do not exist!'

# fake output folder
test_compare \
	"$(run_gboard_forensics -r $PWD/empty-dir -o doesnt-exist/file.json 2>&1)" \
	"The ouput folder specified \"doesnt-exist/file.json\" does not exist!"
