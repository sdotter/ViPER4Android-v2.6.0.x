#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in late_start service mode
# More info in the main Magisk thread

if [ -d /system/priv-app ]; then SRC=priv_app; else SRC=system_app; fi

# selinux enforcing processing on most of devices
magiskpolicy --live "allow mediaserver mediaserver_tmpfs file { read write execute }"
magiskpolicy --live "allow audioserver audioserver_tmpfs file { read write execute }"

# this one is a fix for Xiaomi Mi A1 and for Pixels running stock Oreo.
# probably fixes sepolicy for many other devices.
magiskpolicy --live "allow hal_audio_default hal_audio_default_tmpfs file { execute }"

magiskpolicy --live "allow { audioserver hal_audio_default mediaserver $SRC unlabeled } { app_data_file audioserver_tmpfs hal_audio_default_tmpfs mediaserver_tmpfs system_file } file { read write execute execmod execute_no_trans getattr open }"
magiskpolicy --live "allow hal_audio_default hal_audio_default process execmem"
magiskpolicy --live "allow hal_audio_default audio_data_file dir search"

# Fix everything on boot...
am start -a android.intent.action.MAIN -n com.pittvandewitt.viperfx/.StartActivity
killall com.pittvandewitt.viperfx
killall audioserver
killall mediaserver