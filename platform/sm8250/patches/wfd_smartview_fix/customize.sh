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

# One UI 9 changed the AudioTrack constructor ABI, so older 32-bit WFD libs
# still linked against the 16-argument form crash or fail to start.
# Provide a compatibility shim for all SM8250 builds and bind it in if present.
if [ -f "$WORK_DIR/system/system/lib/libremotedisplay_wfd.so" ] && \
        [ -f "$WORK_DIR/system/system/lib/libaudioclient_shim.so" ] && \
        command -v patchelf > /dev/null 2>&1; then
    if ! patchelf --print-needed "$WORK_DIR/system/system/lib/libremotedisplay_wfd.so" 2> /dev/null | \
            grep -Fxq "libaudioclient_shim.so"; then
        LOG "- Hooking libremotedisplay_wfd.so to libaudioclient_shim.so"
        patchelf --add-needed "libaudioclient_shim.so" "$WORK_DIR/system/system/lib/libremotedisplay_wfd.so"
    fi
fi

# The older WFD stack built for some SM8250 firmware variants still rejects the
# newer R2 parameter encoding; bypass the unsupported path when the pattern is
# present.
if [ -f "$WORK_DIR/system/system/lib/libremotedisplay_wfd.so" ]; then
    if xxd -p -c 0 "$WORK_DIR/system/system/lib/libremotedisplay_wfd.so" | grep -q "94f80d0318b994f8141301290ed1"; then
        # r9qxxx / Snapdragon S23 / S21 FE WFD R2 bypass
        HEX_PATCH "$WORK_DIR/system/system/lib/libremotedisplay_wfd.so" \
            "94f80d0318b994f8141301290ed1" \
            "00f00fb818b994f8141301290ed1"
    elif xxd -p -c 0 "$WORK_DIR/system/system/lib/libremotedisplay_wfd.so" | grep -q "94f81d0318b994f8241301290ed1"; then
        # r9sxxx / Exynos S23 / S22 WFD R2 bypass
        HEX_PATCH "$WORK_DIR/system/system/lib/libremotedisplay_wfd.so" \
            "94f81d0318b994f8241301290ed1" \
            "00f00fb818b994f8241301290ed1"
    fi
fi

# One UI 9 libgui added IGraphicBufferProducer methods. The old vtable offset
# in PlaybackSession::addConsumerUsageBits() now lands on the wrong entry for
# some SM8250 firmware variants; nudge the pointer before the getConsumerUsage()
# call so the encoder keeps valid usage bits.
if [ -f "$WORK_DIR/system/system/lib/libremotedisplay_wfd.so" ]; then
    if xxd -p -c 0 "$WORK_DIR/system/system/lib/libremotedisplay_wfd.so" | grep -q "224643f0c2e8e26f"; then
        HEX_PATCH "$WORK_DIR/system/system/lib/libremotedisplay_wfd.so" \
            "224643f0c2e8e26f" \
            "2246083400bfe26f"
    fi
fi

# runtime32_compat stages the S911B (dm1qxxx) library before this module runs.
# Its ARM32 libstagefright reads 512 bytes into a 255-byte buffer here.
# Limit the fread count to 254 bytes, leaving space for the terminator.
if [ -f "$WORK_DIR/system/system/lib/libstagefright.so" ]; then
    if xxd -p -c 0 "$WORK_DIR/system/system/lib/libstagefright.so" | grep -q "01214ff40072384633460094"; then
        HEX_PATCH "$WORK_DIR/system/system/lib/libstagefright.so" \
            "01214ff40072384633460094" \
            "0121fe2200bf384633460094"
    elif xxd -p -c 0 "$WORK_DIR/system/system/lib/libstagefright.so" | grep -q "0121fe2200bf384633460094"; then
        LOG "- S911B ARM32 ACodec fread buffer overflow already patched"
    else
        LOG "- No known S911B ARM32 ACodec fread signature found in libstagefright.so"
    fi
fi
