# shellcheck shell=bash
LOG_STEP_IN "- Adding Galaxy S26 My FanCam GPU backend"

# Keep the Gallery analyzer separate from the editor's newer tracking ABI.
# These private S26 libraries use the V1 detector categories and all 768
# features from the A56 float model, through a local TFLite GPU adapter.
for FANCAM_LIB in libmca_fancam.so libfancam_highlight.so libfancam_reframing.so libmca_tflite_gpu.so; do
    ADD_TO_WORK_DIR "$SRC_DIR/platform/$TARGET_PLATFORM/mods/miracle" "system" "system/lib64/$FANCAM_LIB" \
        0 0 644 "u:object_r:system_lib_file:s0" || return 1
done

FANCAM_MODELS="system/etc/mediacontext_fancam_"
EVAL "mkdir -p \"$WORK_DIR/system/$FANCAM_MODELS\"" || return 1
SET_METADATA "system" "$FANCAM_MODELS" 0 0 755 "u:object_r:system_file:s0"

# Retain the filenames expected by the S26 loader; the adapter validates and
# executes TFLite contents rather than sending SM8850 DLCs to the S20 DSP.
for FANCAM_MODEL in Locator Reid Detection Pose Keyword; do
    case "$FANCAM_MODEL" in
        Locator|Detection) FANCAM_TARGET="human-pet-det_SR-V131.tflite" ;;
        Reid|Pose) FANCAM_TARGET="human-pet-pose_SR-V200.tflite" ;;
        Keyword) FANCAM_TARGET="keyword-classification_SR-V031.tflite" ;;
    esac
    for FANCAM_EXT in dlc dala tflite; do
        EVAL "ln -sfn \"../mediacontextanalyzer/$FANCAM_TARGET\" \"$WORK_DIR/system/$FANCAM_MODELS/$FANCAM_MODEL.$FANCAM_EXT\"" || return 1
        SET_METADATA "system" "$FANCAM_MODELS/$FANCAM_MODEL.$FANCAM_EXT" \
            0 0 777 "u:object_r:system_file:s0"
    done
done

# Redirect both the APEX probe and the system fallback to the private analyzer.
# NUL padding keeps the donor's string offsets intact.
for FANCAM_PATH in apex system; do
    LOG "- Redirecting $FANCAM_PATH analyzer path"
    HEX_PATCH "$WORK_DIR/system/system/lib64/libveframework.videoeditor.samsung.so" \
        "6c69626d65646961636f6e74657874616e616c797a65722e736f00" \
        "6c69626d63615f66616e63616d2e736f0000000000000000000000" || return 1
done

unset FANCAM_LIB FANCAM_MODELS FANCAM_MODEL FANCAM_TARGET FANCAM_EXT FANCAM_PATH
LOG_STEP_OUT
