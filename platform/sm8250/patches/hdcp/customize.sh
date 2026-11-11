if [ "$SOURCE_PLATFORM_SDK_VERSION" -ge 37 ] && \
        [ -f "$WORK_DIR/vendor/bin/hw/vendor.samsung.hardware.security.hdcp.keyprovisioning@1.0-service" ]; then
    LOG_STEP_IN "- Matching HDCP provisioning to the target HIDL service"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/bin/qchdcpkprov"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" \
        "system/lib64/vendor.samsung.hardware.security.hdcp.keyprovisioning@1.0.so"
    LOG_STEP_OUT
fi
