#!/usr/bin/env bash

set -eo pipefail

SOURCE="${BASH_SOURCE[0]}"
# resolve $SOURCE until the file is no longer a symlink
while [ -h "$SOURCE" ]; do
  ROOT_PROJECT_FOLDER="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  [[ $SOURCE != /* ]] && SOURCE="$ROOT_PROJECT_FOLDER/$SOURCE"
done
ROOT_PROJECT_FOLDER="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
unset SOURCE

export ROOT_PROJECT_FOLDER
ROOT_PROJECT_FOLDER="$(dirname "$ROOT_PROJECT_FOLDER")"

export GBOARD_FORENSICS_BIN="$ROOT_PROJECT_FOLDER/bin/gboard-forensics"

log() { printf '%s\n' "$*"; }
error() { log "ERROR: $*" >&2; }
fatal() { error "$@"; exit 1; }

# Add trap_add to have nested trap commands
trap_add() {
    trap_add_cmd=$1; shift || fatal "${FUNCNAME} usage error"
    for trap_add_name in "$@"; do
        trap -- "$(
            extract_trap_cmd() { printf '%s\n' "$3"; }
            # print existing trap command with newline
            eval "extract_trap_cmd $(trap -p "${trap_add_name}")"
            # print the new trap command
            printf '%s\n' "${trap_add_cmd}"
        )" "${trap_add_name}" \
            || fatal "unable to add to trap ${trap_add_name}"
    done
}

declare -f -t trap_add

( # subshell to build gboard-forensics standalone app
	cd "$ROOT_PROJECT_FOLDER";
	dub build $@
)

function run_gboard_forensics()
{
	( # run tests in subshell
		cd "$ROOT_PROJECT_FOLDER";
		$GBOARD_FORENSICS_BIN --DRT-covopt="merge:1" $@
	)
}

function test_compare()
{
	local actual="$1"
	local expected="$2"

	[[ "$actual" == "$expected" ]] && return || :

	printf 'Actual:\n---\n%s\n---\n' "$actual"
	printf 'Expected:\n---\n%s\n---\n' "$expected"

	echo "Diff:"
	diff <(echo "$actual") <(echo "$expected")
	exit 1
}

# enables globbing
shopt -s globstar

for _test_folder in $(find $ROOT_PROJECT_FOLDER/tests/ -maxdepth 1 -mindepth 1 -type d); do
	if [ ! -f "$_test_folder/test.sh" ]; then
		echo "!! No test.sh found in $_test_folder"
		exit 1
	fi

	echo "Testing $(basename "$_test_folder")"

	( # subshell to run the test case
		cd "$_test_folder"
		source "$_test_folder/test.sh"
	)
done
