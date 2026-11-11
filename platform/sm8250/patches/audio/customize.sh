BLOBS_LIST="
lib/android.hardware.audio.common@5.0-util.so
lib/hw/android.hardware.audio.effect@5.0-impl.so
lib/hw/android.hardware.audio@5.0-impl.so
lib64/android.hardware.audio.common@5.0-util.so
lib64/hw/android.hardware.audio.effect@5.0-impl.so
lib64/hw/android.hardware.audio@5.0-impl.so
"
for blob in $BLOBS_LIST
do
    DELETE_FROM_WORK_DIR "vendor" "$blob"
done

LOG_STEP_IN "- Adding stock SoundBooster libs"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/lib_SoundBooster_ver1050.so" 0 0 644 "u:object_r:system_lib_file:s0"
DELETE_FROM_WORK_DIR "system" "system/lib/lib_SoundBooster_ver1100.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/lib_SoundAlive_play_plus_ver400.so" 0 0 644 "u:object_r:system_lib_file:s0"
DELETE_FROM_WORK_DIR "system" "system/lib/lib_SoundAlive_play_plus_ver800.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libaudiosaplus_sec_legacy.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libsamsungSoundbooster_plus_legacy.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundBooster_ver1050.so" 0 0 644 "u:object_r:system_lib_file:s0"
DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SoundBooster_ver1100.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundAlive_play_plus_ver400.so" 0 0 644 "u:object_r:system_lib_file:s0"
DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SoundAlive_play_plus_ver800.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libaudiosaplus_sec_legacy.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsamsungSoundbooster_plus_legacy.so" 0 0 644 "u:object_r:system_lib_file:s0"
LOG_STEP_OUT


# Audio Eraser on playback (quick panel) is the VoiceBooster stage effect.
# The source stage_policy.conf only puts it on the deep buffer (media) output,
# which the SM8250 audio policy does not open: music plays on the primary
# output, so the effect was never created. Add it to the primary music
# sub-stages as well, the same way the media output declares it.
STAGE_POLICY="$WORK_DIR/system/system/etc/stage_policy.conf"
if [ -f "$STAGE_POLICY" ] && grep -q "STAGE_EFFECT_VOICE_BOOSTER" "$STAGE_POLICY"; then
    LOG_STEP_IN "- Adding VoiceBooster to the primary output stages"
    EVAL "awk '
        /^primary \\{/ { p = 1 }
        p && /^\\}/ { p = 0 }
        p && /^                    prefx STAGE_EFFECT_DOLBY\$/ { sub(/STAGE_EFFECT_DOLBY\$/, \"STAGE_EFFECT_VOICE_BOOSTER:lazy|STAGE_EFFECT_DOLBY\") }
        { print }
    ' \"$STAGE_POLICY\" > \"$STAGE_POLICY.tmp\" && mv -f \"$STAGE_POLICY.tmp\" \"$STAGE_POLICY\"" || return 1
    LOG_STEP_OUT
fi
unset STAGE_POLICY
