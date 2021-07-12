adb-getversion:
	@adb shell dumpsys package com.google.android.inputmethod.latin | grep "versionName=" | cut -d = -f2 | head -n1

adb-pull:
	adb shell su root -c 'rm -rf /sdcard/gboard-temp \&\& mkdir -p /sdcard/gboard-temp'
	adb shell su root -c 'tar -czvf /sdcard/gboard-temp/data.tar.gz /data/data/com.google.android.inputmethod.latin/'
	adb shell su root -c 'chown $(shell adb shell stat -L -c "%U:%G" /sdcard) -R /sdcard/gboard-temp'
	adb pull /sdcard/gboard-temp gboard-data-$(shell make adb-getversion)
	adb shell su root -c 'rm -rf /sdcard/gboard-temp'

test:
	dub build --build=unittest
	dub test --build=release
	./tests/run.sh
	./tests/run.sh --build=release

coverage:
	dub test --build=cov
	dub test --build=unittest-cov
	./tests/run.sh --build=cov

clean:
	rm -rf .dub/
	rm -rf bin/

clean-coverage:
	find . -type f -name '*.lst' -delete
