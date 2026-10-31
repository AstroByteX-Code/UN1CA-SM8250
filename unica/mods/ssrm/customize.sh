# This warning also appears when there are a few edits to the GPU freq table in the kernel
SDHMS_APK="system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk"

DECODE_APK "system" "$SDHMS_APK"

SDHMS_ROOT="$APKTOOL_DIR/$SDHMS_APK"

# Samsung renames the obfuscated SDHMS classes and methods between platform releases.
SSRM_WARNING_SMALI="smali/o5/s0.smali"
SSRM_WARNING_METHOD="J(Landroid/content/Context;Ljava/lang/String;)V"
if [ "$SOURCE_PLATFORM_SDK_VERSION" -ge 37 ]; then
    SSRM_WARNING_SMALI="smali/n5/f1.smali"
    SSRM_WARNING_METHOD="M(Landroid/content/Context;Ljava/lang/String;)V"
fi

# The class and method are obfuscated and may be renamed across different base versions.
# Resolve dynamically from the "SSRM Warning" literal if the expected file does not exist.
if [ ! -f "$SDHMS_ROOT/$SSRM_WARNING_SMALI" ]; then
    SSRM_WARNING_MATCHES="$(grep -RFl --include='*.smali' '"SSRM Warning"' "$SDHMS_ROOT" 2>/dev/null || true)"
    if [ "$(printf '%s\n' "$SSRM_WARNING_MATCHES" | sed '/^$/d' | wc -l)" -eq 1 ]; then
        SSRM_WARNING_SMALI="${SSRM_WARNING_MATCHES#"$SDHMS_ROOT/"}"
        DETECTED_METHOD="$(awk '/^\.method/ { method = $NF } /"SSRM Warning"/ { print method; exit }' "$SSRM_WARNING_MATCHES")"
        if [ -n "$DETECTED_METHOD" ]; then
            SSRM_WARNING_METHOD="$DETECTED_METHOD"
        fi
        LOG "- Resolved SDHMS SSRM warning method: $SSRM_WARNING_METHOD in $SSRM_WARNING_SMALI"
    fi
fi

SMALI_PATCH "system" "$SDHMS_APK" \
    "$SSRM_WARNING_SMALI" "null" \
    "$SSRM_WARNING_METHOD"

unset SDHMS_APK SDHMS_ROOT SSRM_WARNING_SMALI SSRM_WARNING_METHOD SSRM_WARNING_MATCHES DETECTED_METHOD
