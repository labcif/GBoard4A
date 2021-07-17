all: build

adb-getversion:
	@adb shell dumpsys package com.google.android.inputmethod.latin | grep "versionName=" | cut -d = -f2 | head -n1

adb-pull:
	adb shell su root -c 'rm -rf /sdcard/gboard-temp \&\& mkdir -p /sdcard/gboard-temp'
	adb shell su root -c 'tar -czvf /sdcard/gboard-temp/data.tar.gz /data/data/com.google.android.inputmethod.latin/'
	adb shell su root -c 'chown $(shell adb shell stat -L -c "%U:%G" /sdcard) -R /sdcard/gboard-temp'
	adb pull /sdcard/gboard-temp gboard-data-$(shell make adb-getversion)
	adb shell su root -c 'rm -rf /sdcard/gboard-temp'

DUB_ARGS=--parallel
DRUNTIME_ARGS=--DRT-covopt="merge:1"

build:
	dub build $(DUB_ARGS)

test:
	dub build --build=unittest $(DUB_ARGS)
	dub test --build=release $(DUB_ARGS) -- $(DRUNTIME_ARGS)
	./tests/run.sh $(DUB_ARGS)
	./tests/run.sh --build=release $(DUB_ARGS)

coverage:
	dub test --build=cov $(DUB_ARGS) -- $(DRUNTIME_ARGS)
	dub test --build=unittest-cov $(DUB_ARGS) -- $(DRUNTIME_ARGS)
	./tests/run.sh --build=cov $(DUB_ARGS)

clean:
	rm -rf .dub/
	rm -rf bin/

clean-coverage:
	find . -type f -name '*.lst' -delete
