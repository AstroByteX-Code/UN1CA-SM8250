SOURCE_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$SOURCE_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$SOURCE_FIRMWARE")"
TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"

SOURCE_HAS_SPEN="$(test -n "$(find "$FW_DIR/$SOURCE_FIRMWARE_PATH/system/system/etc/permissions" -type f -name "com.sec.feature.spen_usp*.xml")" && echo "true" || echo "false")"
TARGET_HAS_SPEN="$(test -n "$(find "$FW_DIR/$TARGET_FIRMWARE_PATH/system/system/etc/permissions" -type f -name "com.sec.feature.spen_usp*.xml")" && echo "true" || echo "false")"

if [[ "$TARGET_HAS_SPEN" == "true" ]]; then
    if [[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "mssi" ]]; then
        ABORT "\"mssi\" system image does not support targets with S Pen. Ignoring."
    fi
    LOG_STEP_IN "- Adding SPen stack"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/app/AirGlance"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/app/LiveDrawing"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/etc/default-permissions/default-permissions-com.samsung.android.service.aircommand.xml"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/etc/permissions/privapp-permissions-com.samsung.android.app.readingglass.xml"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/etc/permissions/privapp-permissions-com.samsung.android.service.aircommand.xml"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/etc/permissions/privapp-permissions-com.samsung.android.service.airviewdictionary.xml"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/etc/public.libraries-smps.samsung.txt"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/etc/sysconfig/airviewdictionaryservice.xml"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/lib64/libsmpsft.smps.samsung.so"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/media/audio/pensounds"
    ADD_TO_WORK_DIR "$SRC_DIR/prebuilts/extras" "system" "system/priv-app/AirCommand"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/priv-app/AirReadingGlass"
    ADD_TO_WORK_DIR "dm3qxxx" "system" "system/priv-app/SmartEye"
    LOG_STEP_OUT
else
    LOG "\033[0;33m! Target has no S Pen support. Skipping patch.\033[0m"
fi

unset SOURCE_FIRMWARE_PATH TARGET_FIRMWARE_PATH SOURCE_HAS_SPEN TARGET_HAS_SPEN
