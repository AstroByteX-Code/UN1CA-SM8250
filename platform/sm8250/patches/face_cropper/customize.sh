if [ "$SOURCE_PLATFORM_SDK_VERSION" -ge 37 ]; then
    LOG_STEP_IN "- Matching the FaceService cropper to SM8250"
    # Keep the donor cropper for other apps, whose newer JNI methods are not
    # provided by the target library. FaceService only uses the common API.
    CROPPER_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"
    CROPPER_SOURCE="$FW_DIR/$CROPPER_FIRMWARE_PATH/system/system/lib64/libImageCropper.camera.samsung.so"
    if [ ! -f "$CROPPER_SOURCE" ]; then
        CROPPER_SOURCE="$FW_DIR/$CROPPER_FIRMWARE_PATH/system/lib64/libImageCropper.camera.samsung.so"
    fi
    if [ ! -f "$CROPPER_SOURCE" ]; then
        LOGE "File not found: $CROPPER_SOURCE"
        return 1
    fi
    EVAL "cp -a \"$CROPPER_SOURCE\" \"$WORK_DIR/system/system/lib64/libImageCropper_sm8250.camera.samsung.so\"" || return 1
    SET_METADATA "system" "system/lib64/libImageCropper_sm8250.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
    # Export it through the same namespace as the original so DLInterface can
    # load its platform dependencies. Only FaceService requests the new name.
    if ! grep -qxF "libImageCropper_sm8250.camera.samsung.so" "$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt"; then
        EVAL "echo 'libImageCropper_sm8250.camera.samsung.so' >> \"$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt\""
    fi
    SMALI_PATCH "system" "system/priv-app/FaceService/FaceService.apk" \
        "smali/vizinsight/atl/vzimagecropper/VZImageCropper.smali" "replace" \
        '<clinit>()V' 'ImageCropper.camera.samsung' 'ImageCropper_sm8250.camera.samsung' || return 1
    EVAL "sed -i 's/libImageCropper\\.camera\\.samsung\\.so/libImageCropper_sm8250.camera.samsung.so/g' \"$APKTOOL_DIR/system/priv-app/FaceService/FaceService.apk/AndroidManifest.xml\"" || return 1
    unset CROPPER_FIRMWARE_PATH CROPPER_SOURCE
    LOG_STEP_OUT
fi
