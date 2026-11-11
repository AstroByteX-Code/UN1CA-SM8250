# shellcheck disable=SC2034
SKIPUNZIP=1

LOG_STEP_IN "- ION and GPU access for the Android 11-era vendor on an Android 17 system"
if $TARGET_OS_BUILD_SYSTEM_EXT_PARTITION; then
    _SE="$WORK_DIR/system_ext/etc/selinux"
else
    _SE="$WORK_DIR/system/system/system_ext/etc/selinux"
fi
_SDK="$(GET_PROP "system" "ro.build.version.sdk")"
if [ "${_SDK:-0}" -lt 37 ]; then
    LOG "- Skipped: sdk $_SDK still labels /dev/ion and grants ion/gpu access itself"
elif grep -q '^/dev/ion[[:space:]]' "$WORK_DIR/system/system/etc/selinux/plat_file_contexts"; then
    LOG "- Skipped: plat_file_contexts already labels /dev/ion"
else
    grep -q '^/dev/ion[[:space:]]' "$_SE/system_ext_file_contexts" \
        || EVAL "printf '/dev/ion\t\tu:object_r:ion_device:s0\n' >> \"$_SE/system_ext_file_contexts\""
    grep -q '^;; MinsOS y2q gpu_ion_compat' "$_SE/system_ext_sepolicy.cil" \
        || EVAL "cat \"$MODPATH/files/gpu_ion_compat.cil\" >> \"$_SE/system_ext_sepolicy.cil\""

fi
LOG_STEP_OUT
unset _SE _SDK
