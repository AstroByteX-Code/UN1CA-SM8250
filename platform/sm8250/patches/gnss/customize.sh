if [ "$SOURCE_PLATFORM_SDK_VERSION" -ge 37 ]; then
    LOG_STEP_IN "- Removing the unsupported AIDL GNSS companion"
    # SM8250 uses the target HIDL GNSS HAL. The donor companion waits for
    # vendor.qti.gnss.ILocAidlGnss/default, which this vendor does not provide.
    DELETE_FROM_WORK_DIR "system_ext" "bin/loc_sys_service"
    DELETE_FROM_WORK_DIR "system_ext" "etc/init/loc_sys_service.rc"
    LOG_STEP_OUT
fi
