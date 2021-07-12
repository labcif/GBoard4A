# GBoard4A

[![Build and Test](https://github.com/labcif/GBoard4A/actions/workflows/workflow.yml/badge.svg)](https://github.com/labcif/GBoard4A/actions/workflows/workflow.yml)
[![codecov](https://codecov.io/gh/labcif/GBoard4A/branch/main/graph/badge.svg?token=XD675L6X9K)](https://codecov.io/gh/labcif/GBoard4A)

GBoard4A is forensic analyzer for Autopsy digital forensic software to analyze GBoard application data.

## Requirements

* A D compiler (e.g.: `dmd`)
* `dub` package manager
* `autopsy` at least version 4.17
* `sqlite3` library

## Build

To build the project you run:

```
$ dub build
```

To build and run the test suite run:

```
$ dub test
```

## Usage

To run an analysis using the CLI, all you have to do is run:

```
$ dub run -- <command-args>
```

Some information about the program arguments:

```
-r --root-dir GBoard root directory analysis (must be used alone)
-d      --dir GBoard directory analysis
-f     --file GBoard file analysis
-t     --type Output format type (default: json)
-o   --output Output file path of analysis report
-v  --verbose Print extra information on the analysis
-h     --help This help information.
```

To run the GBoard Autopsy modules you need to copy the generated binary and `gboard_autopsy.py` to the `python_modules` folder of your Autopsy instance.

## Examples

**Run a full analysis:**

```shell
dub run -- -r ./path/to/gboard/data/folder/
```

**Run a partial analysis:**

```shell
dub run -- -f ./path/to/gboard/data/folder/databases/gboard_clipboard.db
```

## License

This software is licensed under GNU GPL (Version 3, 29 June 2007).
