#!/usr/bin/env bash
# Copyright (c) 2026

DELETE_FROM_WORK_DIR "system" "system/lib64/libhdcp_client_aidl.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libhdcp2.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libremotedisplay_wfd.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libremotedisplayservice.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libsecuibc.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libstagefright_hdcp.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.security.hdcp.wifidisplay-V2-ndk.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/wfd_log.so"


# Hex patch libremotedisplay_wfd.so to bypass unsupported WFD R2 parameters
if [ -f "$WORK_DIR/system/system/lib/libremotedisplay_wfd.so" ]; then
    if xxd -p -c 0 "$WORK_DIR/system/system/lib/libremotedisplay_wfd.so" | grep -q "94f80d0318b994f8141301290ed1"; then
        # r9qxxx (Snapdragon S23 / S21 FE) WFD R2 bypass
        HEX_PATCH "$WORK_DIR/system/system/lib/libremotedisplay_wfd.so" \
            "94f80d0318b994f8141301290ed1" \
            "00f00fb818b994f8141301290ed1"
    elif xxd -p -c 0 "$WORK_DIR/system/system/lib/libremotedisplay_wfd.so" | grep -q "94f81d0318b994f8241301290ed1"; then
        # r9sxxx (Exynos S23 / S22) WFD R2 bypass
        HEX_PATCH "$WORK_DIR/system/system/lib/libremotedisplay_wfd.so" \
            "94f81d0318b994f8241301290ed1" \
            "00f00fb818b994f8241301290ed1"
    fi
fi

# Hex patch libstagefright.so to fix ACodec getProcessNameByPid buffer overflow
if [ -f "$WORK_DIR/system/system/lib/libstagefright.so" ]; then
    if xxd -p -c 0 "$WORK_DIR/system/system/lib/libstagefright.so" | grep -q "204601214ff400722b46"; then
        # r11qxxx / Android 16 ARM32 ACodec getProcessNameByPid buffer overflow fix (512 -> 254 bytes)
        HEX_PATCH "$WORK_DIR/system/system/lib/libstagefright.so" \
            "204601214ff400722b46" \
            "204601214ff0fe022b46"
    elif xxd -p -c 0 "$WORK_DIR/system/system/lib/libstagefright.so" | grep -q "01214ff4007230462b460097"; then
        # Legacy ACodec getProcessNameByPid buffer overflow fix
        HEX_PATCH "$WORK_DIR/system/system/lib/libstagefright.so" \
            "01214ff4007230462b460097" \
            "01214ff0fe0230462b460097"
    fi
fi
