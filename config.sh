##########################################################################################
#
# Magisk Module Template Config Script
# by topjohnwu
#
##########################################################################################
##########################################################################################
#
# Instructions:
#
# 1. Place your files into system folder (delete the placeholder file)
# 2. Fill in your module's info into module.prop
# 3. Configure the settings in this file (config.sh)
# 4. If you need boot scripts, add them into common/post-fs-data.sh or common/service.sh
# 5. Add your additional or modified system properties into common/system.prop
#
##########################################################################################

##########################################################################################
# Configs
##########################################################################################

# Set to true if you need to enable Magic Mount
# Most mods would like it to be enabled
AUTOMOUNT=true

# Set to true if you need to load system.prop
PROPFILE=false

# Set to true if you need post-fs-data script
POSTFSDATA=false

# Set to true if you need late_start service script
LATESTARTSERVICE=true

##########################################################################################
# Installation Message
##########################################################################################

# Set what you want to show when installing your mod

print_modname() {
  ui_print "*******************************"
  ui_print "  Viper4Android Magisk module  "
  ui_print "      by Sicco den Otter       "
  ui_print "                               "
  ui_print "    Based on V4A 2.6.0.x by    "
  ui_print "          Team_DeWitt          "
  ui_print "*******************************"
}

##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
# Check the documentations for more info about how Magic Mount works, and why you need this

# This is an example
REPLACE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

# Construct your own list here, it will override the example above
# !DO NOT! remove this if you don't need to replace anything, leave it empty as it is now
REPLACE="
"

##########################################################################################
# Permissions
##########################################################################################

set_permissions() {
  # Only some special files require specific permissions
  # The default permissions should be good enough for most cases

  # Here are some examples for the set_perm functions:

  # set_perm_recursive  <dirname>                <owner> <group> <dirpermission> <filepermission> <contexts> (default: u:object_r:system_file:s0)
  # set_perm_recursive  $MODPATH/system/lib       0       0       0755            0644

  # set_perm  <filename>                         <owner> <group> <permission> <contexts> (default: u:object_r:system_file:s0)
  # set_perm  $MODPATH/system/bin/app_process32   0       2000    0755         u:object_r:zygote_exec:s0
  # set_perm  $MODPATH/system/bin/dex2oat         0       2000    0755         u:object_r:dex2oat_exec:s0
  # set_perm  $MODPATH/system/lib/libart.so       0       0       0644

  # The following is default permissions, DO NOT remove
  set_perm_recursive  $MODPATH  0  0  0755  0644
}

##########################################################################################
# Custom Functions
##########################################################################################

# This file (config.sh) will be sourced by the main flash script after util_functions.sh
# If you need custom logic, please add them here as functions, and call these functions in
# update-binary. Refrain from adding code directly into update-binary, as it will make it
# difficult for you to migrate your modules to newer template versions.
# Make update-binary as clean as possible, try to only do function calls in it.

# This function blacklists modules/effects known to mess with V4A
blacklist_effects() {
  EFFECT_LIST="
    /system/priv-app/MusicFX
    /system/priv-app/AudioFX
    /system/app/DiracAudioControlService
    /system/app/DiracManager"

  for effect in $EFFECT_LIST; do
    if [ -d "$effect" ]; then
      name=$(basename "$effect")
      ui_print "-> Found $name, blacklisting"
      pth="$MODPATH$effect/.replace"
      mkdir -p $(dirname "$pth")
      touch "$pth"
    fi
  done

}

api_level_arch_detect() {
  API=`grep_prop ro.build.version.sdk`
  ABI=`grep_prop ro.product.cpu.abi | cut -c-3`
  ABI2=`grep_prop ro.product.cpu.abi2 | cut -c-3`
  ABILONG=`grep_prop ro.product.cpu.abi`
  ARCH=arm
  ARCH32=arm
  IS64BIT=false
  if [ "$ABI" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
  if [ "$ABI2" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
  if [ "$ABILONG" = "arm64-v8a" ]; then ARCH=arm64; ARCH32=arm; IS64BIT=true; fi;
  if [ "$ABILONG" = "x86_64" ]; then ARCH=x64; ARCH32=x86; IS64BIT=true; fi;
}

installV4A() {

	case $ABILONG in
	  arm64*) JNI=arm64;;
	  arm*) JNI=arm;;
	  x86_64*) JNI=x86_64; DRV=x86;;
	  x86*) JNI=x86; DRV=x86;;
	  *64*) JNI=arm64;;
	  *) JNI=arm;;
	esac
	
	APK=$INSTALLER/system/app/ViPER4AndroidFX/ViPER4AndroidFX.apk
	DRIVER=$INSTALLER/drivers/libv4a_fx_NEON.so

	ui_print "* Module path: $MODPATH"
	ui_print "* Default driver: $DRIVER"

	ui_print "- Extracting module files"
	unzip -o "$ZIP" 'drivers/*' 'libs/*' 'system/*' -d $INSTALLER 2>/dev/null
	
	# clean up some shit...
	ui_print "* Checking for existing audio libs and effects"
	blacklist_effects

	# create skeleton files and dirs
	ui_print "- Creating driver paths"
	mkdir -p $MODPATH/system/lib/soundfx 2>/dev/null
	mkdir -p $MODPATH/system/app/ViPER4AndroidFX/lib/$JNI 2>/dev/null
	
	# determine CPU arch and driver
	ui_print "- Determining your device's arch and installing driver"
	if [ "$ARCH" = "x86" -o "$ARCH" = "x64" ]; then
		DRIVER=$INSTALLER/drivers/libv4a_fx_x86.so
	fi

	ui_print "* Your device is $ARCH using:"
	ui_print "  > $DRIVER"

	# copy driver
	ui_print "- Copying V4A driver"
	cp -af $DRIVER $MODPATH/system/lib/soundfx/libv4a_fx.so
	cp -f $INSTALLER/libs/libJniUtils_$JNI.so $MODPATH/system/app/ViPER4AndroidFX/lib/$JNI/libJniUtils.so
	
	# create skeleton files and dirs
	ui_print "- Creating files and directories"
	mkdir -p $MODPATH/system/etc 2>/dev/null
	mkdir -p $MODPATH/system/vendor/etc 2>/dev/null
	mkdir -p $MODPATH/system/vendor/lib 2>/dev/null
	mkdir -p $MODPATH/system/vendor/soundfx 2>/dev/null
	mkdir -p $MODPATH/system/vendor/lib/soundfx 2>/dev/null

	# copy app
	ui_print "- Installing V4A v2.6.0.x"
	cp -af $APK $MODPATH/system/app/ViPER4AndroidFX/ViPER4AndroidFX.apk

	# modify configurations
	ui_print "- Modifying audio_effects.conf"

	cp -af /system/etc/audio_effects.conf $MODPATH/system/etc/audio_effects.conf 2>/dev/null
	cp -af /system/etc/audio_policy.conf $MODPATH/system/etc/audio_policy.conf 2>/dev/null
	cp -af /system/etc/htc_audio_effects.conf $MODPATH/system/etc/htc_audio_effects.conf 2>/dev/null
	cp -af /system/vendor/etc/audio_effects.conf $MODPATH/system/vendor/etc/audio_effects.conf 2>/dev/null

	CONFIG_FILE=$MODPATH/system/etc/audio_effects.conf
	POLICY_FILE=$MODPATH/system/etc/audio_policy.conf
	HTC_CONFIG_FILE=$MODPATH/system/etc/htc_audio_effects.conf
	VENDOR_CONFIG=$MODPATH/system/vendor/etc/audio_effects.conf

	if [ -f "$CONFIG_FILE" ]; then
	  sed -i 's/^libraries {/libraries {\n  v4a_fx {\n    path \/system\/lib\/soundfx\/libv4a_fx.so\n  }/g' $CONFIG_FILE
	  sed -i 's/^effects {/effects {\n  v4a_standard_fx {\n    library v4a_fx\n    uuid 41d3c987-e6cf-11e3-a88a-11aba5d5c51b\n  }/g' $CONFIG_FILE
	fi

	if [ -f "$POLICY_FILE" ]; then
	  sed -i -e '/low_latency {/,/}/s/flags.*/&|AUDIO_OUTPUT_FLAG_DIRECT/' $POLICY_FILE
	fi

	if [ -f "$HTC_CONFIG_FILE" ]; then
	  sed -i 's/^libraries {/libraries {\n  v4a_fx {\n    path \/system\/lib\/soundfx\/libv4a_fx.so\n  }/g' $HTC_CONFIG_FILE
	  sed -i 's/^effects {/effects {\n  v4a_standard_fx {\n    library v4a_fx\n    uuid 41d3c987-e6cf-11e3-a88a-11aba5d5c51b\n  }/g' $HTC_CONFIG_FILE
	fi

	if [ -f "$VENDOR_CONFIG" ]; then
	  sed -i 's/^libraries {/libraries {\n  v4a_fx {\n    path \/system\/lib\/soundfx\/libv4a_fx.so\n  }/g' $VENDOR_CONFIG
	  sed -i 's/^effects {/effects {\n  v4a_standard_fx {\n    library v4a_fx\n    uuid 41d3c987-e6cf-11e3-a88a-11aba5d5c51b\n  }/g' $VENDOR_CONFIG
	fi

	if ping -c 1 8.8.8.8 >> /dev/null 2>&1; then
		ui_print "- Counting..."
		wget -t 1 -T 3 https://leodenotter.eu/v4a/count.php > /dev/null 2>&1
	fi
}
