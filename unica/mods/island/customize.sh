# Native source port: sampple-korea/dynamicisland; module credits: sampple-korea.
# Integration copyright (c) 2026 UN1CA contributors
# SPDX-License-Identifier: GPL-3.0-or-later
# shellcheck disable=SC2034
SKIPUNZIP=1
if [[ "$TARGET_CODENAME" =~ ^(dm1q|dm2q|dm3q|b5q|q5q|x1q|y2q|z3q|c1q|c2q|r8q)$ ]]; then
    DECODE_APK "system_ext" "priv-app/SystemUI/SystemUI.apk" || return 1
    if compgen -G "$APKTOOL_DIR/system_ext/priv-app/SystemUI/SystemUI.apk/smali*/dev/flexy/dynamicisland/island/NativeBridge.smali" > /dev/null; then
        ABORT "The old APK-based island is already in the decoded target. Rebuild from a clean target for the source port."
        return 1
    fi
    APPLY_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" \
        "$MODPATH/patches/0001-Add-native-Dynamic-Island-renderer.patch" || return 1
    APPLY_PATCH "system_ext" "priv-app/SystemUI/SystemUI.apk" \
        "$MODPATH/patches/0002-Connect-native-Dynamic-Island-to-SystemUI.patch" || return 1
    SET_PROP "system" "ro.unica.dynamic_island" "true"
fi
