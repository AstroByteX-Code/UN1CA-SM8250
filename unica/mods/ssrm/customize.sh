# This warning also appears when there are a few edits to the GPU freq table in the kernel
SDHMS_APK="system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk"

DECODE_APK "system" "$SDHMS_APK"

SSRM_WARNING_SMALI="$(find "$APKTOOL_DIR/system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk" \
    -path '*/o5/s0.smali' -printf '%P\n' -quit)"

if [ -z "$SSRM_WARNING_SMALI" ]; then
    SSRM_WARNING_SMALI="smali/o5/s0.smali"
fi

SMALI_PATCH "system" "$SDHMS_APK" \
    "$SSRM_WARNING_SMALI" "null" \
    "J(Landroid/content/Context;Ljava/lang/String;)V"

unset SDHMS_APK SSRM_WARNING_SMALI
