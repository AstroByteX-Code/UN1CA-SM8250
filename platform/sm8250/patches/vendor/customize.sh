LOG_STEP_IN "- Adding AIDL vibrator HAL"
DELETE_FROM_WORK_DIR "vendor" "bin/hw/vendor.samsung.hardware.vibrator@2.2-service"
DELETE_FROM_WORK_DIR "vendor" "etc/init/vendor.samsung.hardware.vibrator@2.2-service.rc"
DELETE_FROM_WORK_DIR "vendor" "lib64/vendor.samsung.hardware.vibrator@2.0.so"
DELETE_FROM_WORK_DIR "vendor" "lib64/vendor.samsung.hardware.vibrator@2.1.so"
DELETE_FROM_WORK_DIR "vendor" "lib64/vendor.samsung.hardware.vibrator@2.2.so"
LOG "- Patching /vendor/etc/vintf/manifest.xml"
EVAL "sed -i '/<hal format=\"hidl\">.*/{:a;N;/<\/hal>/!ba;/android.hardware.vibrator/d}' \"$WORK_DIR/vendor/etc/vintf/manifest.xml\""
EVAL "sed -i '/<hal format=\"hidl\">.*/{:a;N;/<\/hal>/!ba;/vendor.samsung.hardware.vibrator/d}' \"$WORK_DIR/vendor/etc/vintf/manifest.xml\""
ADD_TO_WORK_DIR "a52qnsxx" "vendor" "bin/hw/vendor.samsung.hardware.vibrator-service" 0 2000 755 "u:object_r:hal_vibrator_default_exec:s0"
ADD_TO_WORK_DIR "a52qnsxx" "vendor" "etc/init/vendor.samsung.hardware.vibrator-default.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "a52qnsxx" "vendor" "etc/vintf/manifest/vendor.samsung.hardware.vibrator-default.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "a52qnsxx" "vendor" "lib64/vendor.samsung.hardware.vibrator-V3-ndk_platform.so" 0 0 644 "u:object_r:vendor_configs_file:s0"
LOG_STEP_OUT


if [[ "$TARGET_CODENAME" == "x1q" || \
      "$TARGET_CODENAME" == "y2q" || \
      "$TARGET_CODENAME" == "z3q" || \
      "$TARGET_CODENAME" == "c1q" || \
      "$TARGET_CODENAME" == "c2q" ]]; then
    LOG_STEP_IN "- Adding dm3qxxx light blobs"
    ADD_TO_WORK_DIR "dm3qxxx" "vendor" "bin/hw/vendor.samsung.hardware.light-service"
    ADD_TO_WORK_DIR "dm3qxxx" "vendor" "lib64/vendor.samsung.hardware.light-V1-ndk_platform.so"
    LOG_STEP_OUT
fi

if [[ "$TARGET_CODENAME" == "x1q" || \
      "$TARGET_CODENAME" == "y2q" || \
      "$TARGET_CODENAME" == "z3q" || \
      "$TARGET_CODENAME" == "c1q" || \
      "$TARGET_CODENAME" == "c2q" ]]; then
    LOG_STEP_IN "- Adding dm3qxxx wifi blobs"
    ADD_TO_WORK_DIR "dm3qxxx" "vendor" "bin/hw/wpa_supplicant" 0 2000 755 "u:object_r:hal_wifi_supplicant_default_exec:s0"
    LOG_STEP_OUT
fi

LOG_STEP_IN "- Setting Adaptive HFR flags"
    SET_PROP "vendor" "debug.sf.show_refresh_rate_overlay_render_rate" "true"
    SET_PROP "vendor" "ro.surface_flinger.game_default_frame_rate_override" "60"
    SET_PROP "vendor" "ro.surface_flinger.use_content_detection_for_refresh_rate" "true"
    SET_PROP "vendor" "ro.surface_flinger.set_idle_timer_ms" "250"
    SET_PROP "vendor" "ro.surface_flinger.set_touch_timer_ms" "300"
    SET_PROP "vendor" "ro.surface_flinger.set_display_power_timer_ms" "200"
    SET_PROP "vendor" "ro.surface_flinger.enable_frame_rate_override" "true"
LOG_STEP_OUT

LOG_STEP_IN "- Enabling Vulkan"
SET_PROP "vendor" "ro.hwui.use_vulkan" "true"
LOG_STEP_OUT


LOG_STEP_IN "- Replacing singletake blobs with dm3qxxx"
DELETE_FROM_WORK_DIR "vendor" "etc/singletake"
ADD_TO_WORK_DIR "dm3qxxx" "vendor" "etc/singletake" 0 0 755 "u:object_r:vendor_file:s0"
LOG_STEP_OUT

LOG "- Patching /vendor/etc/vintf/manifest.xml"
EVAL "sed -i \"s/type=\\\"device\\\" target-level=\\\"4\\\">/type=\\\"device\\\" target-level=\\\"5\\\">/\" \"$WORK_DIR/vendor/etc/vintf/manifest.xml\""
EVAL "sed -i '/<hal format=\"hidl\">.*/{:a;N;/<\/hal>/!ba;/android.hardware.configstore/d}' \"$WORK_DIR/vendor/etc/vintf/manifest.xml\""
EVAL "sed -i \"/^<\/manifest>\\\$/i\\\\    <kernel target-level=\\\"5\\\"\/>\" \"$WORK_DIR/vendor/etc/vintf/manifest.xml\""

LOG_STEP_IN "- Removing configstore-1.1 service"
DELETE_FROM_WORK_DIR "vendor" "bin/hw/android.hardware.configstore@1.1-service"
DELETE_FROM_WORK_DIR "vendor" "etc/init/android.hardware.configstore@1.1-service.rc"
DELETE_FROM_WORK_DIR "vendor" "etc/seccomp_policy/configstore@1.1.policy"
LOG_STEP_OUT

if [[ "$SOURCE_PLATFORM_SDK_VERSION" -ge 36 ]]; then
    LOG_STEP_IN "- Updating Codec2 seccomp policy"
    CODEC2_POLICY="$WORK_DIR/vendor/etc/seccomp_policy/samsung.software.media.c2-base-policy"
    CODEC2_OLD_RULE="mremap: arg3 == 3"
    CODEC2_NEW_RULE="mremap: arg3 == 3 || arg3 == MREMAP_MAYMOVE"

    if [ ! -f "$CODEC2_POLICY" ]; then
        LOG "  - Codec2 seccomp policy is not present; skipping"
    else
        if grep -q -F -x "$CODEC2_NEW_RULE" "$CODEC2_POLICY"; then
            LOG "  - MREMAP_MAYMOVE is already allowed"
        elif grep -q -F -x "$CODEC2_OLD_RULE" "$CODEC2_POLICY"; then
            LOG "  - Allowing MREMAP_MAYMOVE in ${CODEC2_POLICY//$WORK_DIR\//}"
            EVAL "sed -i 's/^mremap: arg3 == 3$/mremap: arg3 == 3 || arg3 == MREMAP_MAYMOVE/' \"$CODEC2_POLICY\""
        elif grep -q '^mremap:' "$CODEC2_POLICY"; then
            ABORT "Unsupported mremap rule in ${CODEC2_POLICY//$WORK_DIR\//}"
        else
            LOG "  - Adding the missing mremap rule to ${CODEC2_POLICY//$WORK_DIR\//}"
            EVAL "printf '%s\\n' '$CODEC2_NEW_RULE' >> \"$CODEC2_POLICY\""
        fi

        grep -q -F -x "$CODEC2_NEW_RULE" "$CODEC2_POLICY" || \
            ABORT "Failed to update ${CODEC2_POLICY//$WORK_DIR\//}"

        for CODEC2_SYSCALL_RULE in "setsockopt: 1" "listen: 1" "bind: 1"; do
            if ! grep -q -F -x "$CODEC2_SYSCALL_RULE" "$CODEC2_POLICY"; then
                grep -q -F -x "prctl: 1" "$CODEC2_POLICY" || \
                    ABORT "Unable to locate the Codec2 syscall insertion point"
                LOG "  - Allowing ${CODEC2_SYSCALL_RULE%%:*}"
                EVAL "sed -i '/^prctl: 1$/i$CODEC2_SYSCALL_RULE' \"$CODEC2_POLICY\""
            fi
        done

        for CODEC2_SYSCALL_RULE in "setsockopt: 1" "listen: 1" "bind: 1"; do
            grep -q -F -x "$CODEC2_SYSCALL_RULE" "$CODEC2_POLICY" || \
                ABORT "Failed to add $CODEC2_SYSCALL_RULE to ${CODEC2_POLICY//$WORK_DIR\//}"
        done
    fi
    unset CODEC2_POLICY CODEC2_OLD_RULE CODEC2_NEW_RULE CODEC2_SYSCALL_RULE
    LOG_STEP_OUT
fi

LOG_STEP_IN "- Removing 24-bit deep_buffer output (fixes no media sound on speaker)"
sed -i '/<mixPort name="deep_buffer"/,/<\/mixPort>/d' "$WORK_DIR/vendor/etc/audio_policy_configuration_base.xml"
sed -i 's/deep_buffer,//g' "$WORK_DIR/vendor/etc/audio_policy_configuration_base.xml"
LOG_STEP_OUT
