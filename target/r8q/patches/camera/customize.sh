LOG "- Patching /vendor/etc/ueventd.rc"
EVAL "cat \"$MODPATH/ueventd.rc.diff\" >> \"$WORK_DIR/vendor/etc/ueventd.rc\""

# Force disable ScenarioManager::IsSupported3rdPartyYuvCapture()
# Before: [bne #0xdabb8]
# After: [b #0xdabb8]
HEX_PATCH "$WORK_DIR/vendor/lib/unihal_main@2.1.so" "01280dd1" "01280de0"

# Before: [b.ne 0x5099f4]
# After: [b 0x5099f4]
HEX_PATCH "$WORK_DIR/vendor/lib64/unihal_main@2.1.so" "a101005468e640b9" "0d00001468e640b9"


LOG_STEP_IN "- Adding Samsung Camera"
mkdir -p "target/r8q/patches/camera-app/system/priv-app/SamsungCamera"
cat "target/r8q/patches/camera/splits/SamsungCamera.apk."* > "target/r8q/patches/camera-app/system/priv-app/SamsungCamera/SamsungCamera.apk"
ADD_TO_WORK_DIR "target/r8q/patches/camera-app" "system" "system/priv-app/SamsungCamera/SamsungCamera.apk" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT
