# shellcheck disable=SC2034
SKIPUNZIP=1

LOG_STEP_IN "- Fixing DisplayQuality HAL wait (waitForService -> checkService)"
DECODE_APK "system" "system/framework/services.jar"
_DQ_SMALI="$APKTOOL_DIR/system/framework/services.jar/smali_classes2/com/samsung/android/displayquality/SemDisplayQualityAidlClient.smali"
if [ -f "$_DQ_SMALI" ] && ! grep -q "waitForService" "$_DQ_SMALI"; then
    LOG "- donor ships a dummy client with no waitForService call - nothing to fix"
else
    SMALI_PATCH "system" "system/framework/services.jar" \
        "smali_classes2/com/samsung/android/displayquality/SemDisplayQualityAidlClient.smali" "replace" \
        "<init>()V" \
        "invoke-static {v2}, Landroid/os/ServiceManager;->waitForService(Ljava/lang/String;)Landroid/os/IBinder;" \
        "invoke-static {v2}, Landroid/os/ServiceManager;->checkService(Ljava/lang/String;)Landroid/os/IBinder;"
fi
unset _DQ_SMALI
LOG_STEP_OUT
