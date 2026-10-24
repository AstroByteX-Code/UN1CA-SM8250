# Add Polarr libs
ADD_TO_WORK_DIR "a73xqxx" "system" "system/etc/public.libraries-polarr.txt" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libBestComposition.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libFeature.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libPolarrSnap.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libTracking.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "a73xqxx" "system" "system/lib64/libYuv.polarr.so" 0 0 644 "u:object_r:system_lib_file:s0"

# Add camera libs
ADD_TO_WORK_DIR "r9qxxx" "system" "system/lib64/libSceneDetector_v1.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
EVAL "echo \"libSceneDetector_v1.camera.samsung.so\" >> \"$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt\""
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libSwIsp_core.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhigh_dynamic_range.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhigh_res.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
EVAL "echo \"libhigh_res.arcsoft.so\" >> \"$WORK_DIR/system/system/etc/public.libraries-arcsoft.txt\""
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhumantracking.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libhumantracking_util.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/liblow_light_hdr.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsuperresolution.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"
EVAL "echo \"libsuperresolution.arcsoft.so\" >> \"$WORK_DIR/system/system/etc/public.libraries-arcsoft.txt\""
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsuperresolution_wrapper_v2.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
EVAL "echo \"libsuperresolution_wrapper_v2.camera.samsung.so\" >> \"$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt\""
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libveengine.arcsoft.so" 0 0 644 "u:object_r:system_lib_file:s0"

BLOBS_LIST="
system/lib64/libhigh_dynamic_range.arcsoft.so
system/lib64/liblow_light_hdr.arcsoft.so
system/lib64/libhigh_res.arcsoft.so
system/lib64/libsnap_aidl.snap.samsung.so
system/lib64/libsuperresolution.arcsoft.so
system/lib64/libsuperresolution_raw.arcsoft.so
system/lib64/libsuperresolution_wrapper_v2.camera.samsung.so
system/lib64/libsuperresolutionraw_wrapper_v2.camera.samsung.so
system/lib64/libMultiFrameProcessing30.camera.samsung.so
system/lib64/libMultiFrameProcessing30.snapwrapper.camera.samsung.so
system/lib64/libMultiFrameProcessing30Tuning.camera.samsung.so
"
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "p3qxxx" "system" "$blob" 0 0 644 "u:object_r:system_lib_file:s0" &
done


LOG_STEP_IN "- Adding dm3qxxx NightMode libs"
ADD_TO_WORK_DIR "dm3qxxx" "system" "system/lib64/libSwIsp_core.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "dm3qxxx" "system" "system/lib64/libSwIsp_wrapper_v1.camera.samsung.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT

ADD_TO_WORK_DIR "a73xqxx" "vendor" "lib64/libsnaplite_native.so" 0 0 644 "u:object_r:same_process_hal_file:s0"

# Force disable Snaplite in Shot suggestions
# Before: [blt #0x1f890]
# After: [b #0x1f890]
HEX_PATCH "$WORK_DIR/vendor/lib/libshotsuggestion_engines.so" "0ddb" "0de0"

# Before: [b.lt 0x40dedc]
# After: [b 0x40dedc]
HEX_PATCH "$WORK_DIR/vendor/lib64/libshotsuggestion_engines.so" "eb010054" "0f000014"

# Pro mode EV Fix
LOG_STEP_IN "- Adding camera PRO mode EV-fix"
ADD_TO_WORK_DIR "r9qxxx" "vendor" \
    "lib64/X12QS_libTsAe.so" 0 0 644 "u:object_r:vendor_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Removing HDR10+ check"

if [ -f "$WORK_DIR/system/system/lib64/libstagefright.so" ]; then
    if xxd -p -c 0 "$WORK_DIR/system/system/lib64/libstagefright.so" | grep -q "010140f9cc9f059480480034"; then
        # Android 16 (S928U1 / One UI 8.5 QSSI base): bypass HEVC HDR10+ abort in ACodec::setupVideoEncoder
        HEX_PATCH "$WORK_DIR/system/system/lib64/libstagefright.so" \
            "010140f9cc9f059480480034" \
            "010140f91f2003d51f2003d5"
    elif xxd -p -c 0 "$WORK_DIR/system/system/lib64/libstagefright.so" | grep -q "010140f97069059420510034"; then
        # Legacy / pa3qzcx HDR10+ check removal (SDK < 36)
        HEX_PATCH "$WORK_DIR/system/system/lib64/libstagefright.so" \
            "010140f97069059420510034" \
            "010140f91f2003d51f2003d5"
    elif xxd -p -c 0 "$WORK_DIR/system/system/lib64/libstagefright.so" | grep -q "70690594205100347a9a40f9"; then
        HEX_PATCH "$WORK_DIR/system/system/lib64/libstagefright.so" \
            "70690594205100347a9a40f9" \
            "706905941f2003d57a9a40f9"
    elif xxd -p -c 0 "$WORK_DIR/system/system/lib64/libstagefright.so" | grep -q "864d0594604d00347a9a40f9"; then
        HEX_PATCH "$WORK_DIR/system/system/lib64/libstagefright.so" \
            "864d0594604d00347a9a40f9" \
            "864d05941f2003d57a9a40f9"
    else
        LOG "- No known HDR10+ abort check found in libstagefright.so (or already patched)"
    fi

    # Android 16: MediaCodecSource::suspendRecording(bool) fix
    if xxd -p -c 0 "$WORK_DIR/system/system/lib64/libstagefright.so" | grep -q "810240f97ef9019421f5ffd021481091e00314aa2200805225fd0194"; then
        HEX_PATCH "$WORK_DIR/system/system/lib64/libstagefright.so" \
            "810240f97ef9019421f5ffd021481091e00314aa2200805225fd0194" \
            "810240f97ef9019421f5ffd021481091e00314aa0200805225fd0194"
    fi

    # Android 16: disable temporal SVC for HEVC encoder
    if xxd -p -c 0 "$WORK_DIR/system/system/lib64/libstagefright.so" | grep -q "e10740b9e22340b9e00313aa44aa059420020034fa03002a"; then
        HEX_PATCH "$WORK_DIR/system/system/lib64/libstagefright.so" \
            "e10740b9e22340b9e00313aa44aa059420020034fa03002a" \
            "e10740b9e22340b9e00313aa44aa059411000014fa03002a"
    fi
fi
LOG_STEP_OUT

# Vendor bufferqueue helper: patch backward-in-time timestamp check
if [ -f "$WORK_DIR/vendor/lib/libstagefright_bufferqueue_helper_vendor.so" ] && \
        xxd -p -c 0 "$WORK_DIR/vendor/lib/libstagefright_bufferqueue_helper_vendor.so" | grep -q "d7e94601401b71eb060006da"; then
    LOG_STEP_IN "- Patching vendor bufferqueue helper backward timestamp check"
    HEX_PATCH "$WORK_DIR/vendor/lib/libstagefright_bufferqueue_helper_vendor.so" \
        "d7e94601401b71eb060006da" \
        "d7e94601401b71eb060000bf"
    LOG_STEP_OUT
fi
