adb-getversion:
	@adb shell dumpsys package com.google.android.inputmethod.latin | grep "versionName=" | cut -d = -f2

adb-pull:
	adb shell su root rm -rf /sdcard/gboard-temp \&\& mkdir -p /sdcard/gboard-temp
	adb shell su root tar -czvf /sdcard/gboard-temp/data.tar.gz /data/data/com.google.android.inputmethod.latin/
	adb shell su root chown $(shell adb shell stat -L -c "%U:%G" /sdcard) -R /sdcard/gboard-temp
	adb pull /sdcard/gboard-temp gboard-data-$(shell make adb-getversion)
	adb shell su root rm -rf /sdcard/gboard-temp
