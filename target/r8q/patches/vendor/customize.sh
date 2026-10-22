
    LOG_STEP_IN "- Adding a73xqxx light blobs"
    ADD_TO_WORK_DIR "a73xqxx" "vendor" "bin/hw/vendor.samsung.hardware.light-service"
    ADD_TO_WORK_DIR "a73xqxx" "vendor" "lib64/vendor.samsung.hardware.light-V1-ndk_platform.so"
    LOG_STEP_OUT
    
    LOG_STEP_IN "- Adding  wifi blobs"
    ADD_TO_WORK_DIR "a52qnsxx" "vendor" "bin/hw/wpa_supplicant" 0 2000 755 "u:object_r:hal_wifi_supplicant_default_exec:s0"
    LOG_STEP_OUT
