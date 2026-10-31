echo "Fix up /product/etc/build.prop"
sed -i "/# Removed by /d" "$WORK_DIR/product/etc/build.prop" \
    && sed -i "s/#bluetooth./bluetooth./g" "$WORK_DIR/product/etc/build.prop" \
    && sed -i "s/?=/=/g" "$WORK_DIR/product/etc/build.prop" \
    && sed -i "$(sed -n "/provisioning.hostname/=" "$WORK_DIR/product/etc/build.prop" | sed "2p;d")d" "$WORK_DIR/product/etc/build.prop"

# Android 17 ueventd only reads /system/etc/ueventd.rc, which imports
# /vendor/etc/ueventd.rc and /odm/etc/ueventd.rc. The legacy /vendor/ueventd.rc
# of the Android 11 vendor is no longer parsed, so /dev/qseecom, /dev/ion,
# adsprpc etc. stay root-only and the TEE HALs (keymaster, gatekeeper) abort.
for UEV_PART in vendor odm; do
    UEV_OLD="$WORK_DIR/$UEV_PART/ueventd.rc"
    UEV_NEW="$WORK_DIR/$UEV_PART/etc/ueventd.rc"
    [ -f "$UEV_OLD" ] || continue
    LOG_STEP_IN "- Moving /$UEV_PART/ueventd.rc to /$UEV_PART/etc/ueventd.rc"
    if [ -f "$UEV_NEW" ]; then
        { echo; cat "$UEV_OLD"; } >> "$UEV_NEW"
    else
        cp -a "$UEV_OLD" "$UEV_NEW"
    fi
    SET_METADATA "$UEV_PART" "etc/ueventd.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
    LOG_STEP_OUT
done
# The Android 11 vendor ueventd.rc has no /dev/ion rule and the One UI 9
# platform ueventd.rc does not set it either, so it stays root-only. QSEECom and
# fastrpc still allocate from it.
UEV_NEW="$WORK_DIR/vendor/etc/ueventd.rc"
if [ -f "$UEV_NEW" ] && ! grep -q "^/dev/ion[[:space:]]" "$UEV_NEW"; then
    LOG "- Adding /dev/ion to /vendor/etc/ueventd.rc"
    printf '\n/dev/ion                  0664   system     system\n' >> "$UEV_NEW"
fi
unset UEV_PART UEV_OLD UEV_NEW

# Android 17 dropped ION from the platform policy: /dev/ion is no longer in
# plat_file_contexts (it falls back to the generic "device" label) and every
# "allow ... ion_device" rule is gone. The Android 11 vendor still allocates
# from ION (QSEECom for keymaster/gatekeeper, fastrpc, camera, graphics), so
# restore the Android 16 label and rules for the domains this policy has.
PLAT_SE="$WORK_DIR/system/system/etc/selinux"
if [ -f "$PLAT_SE/plat_sepolicy.cil" ] && grep -q "^(type ion_device)" "$PLAT_SE/plat_sepolicy.cil"; then
    LOG_STEP_IN "- Restoring ION SELinux label and rules"
    if ! grep -q "^/dev/ion[[:space:]]" "$PLAT_SE/plat_file_contexts"; then
        printf '/dev/ion\t\tu:object_r:ion_device:s0\n' >> "$PLAT_SE/plat_file_contexts"
    fi
    if ! grep -q "unica_ion_" "$PLAT_SE/plat_sepolicy.cil"; then
        ION_R=""
        ION_RW=""
        for ION_DOM in hal_gatekeeper gatekeeperd hal_keymaster hal_keymint_server hal_authgraph_server \
                hal_audio hal_fingerprint fingerprintd hal_face hal_neuralnetworks_server \
                hal_codec2_server hal_codec2_client hal_graphics_allocator hal_graphics_composer \
                gpuservice surfaceflinger system_server zygote mediaserver dumpstate rs \
                bufferhubd fwk_bufferhub; do
            grep -qE "^\((type|typeattribute) $ION_DOM\)" "$PLAT_SE/plat_sepolicy.cil" && ION_R+="$ION_DOM "
        done
        for ION_DOM in hal_camera cameraserver hal_drm hal_cas hal_omx_server bootanim adbd shell; do
            grep -qE "^\((type|typeattribute) $ION_DOM\)" "$PLAT_SE/plat_sepolicy.cil" && ION_RW+="$ION_DOM "
        done
        ION_APP=false
        if grep -q "^(typeattribute appdomain)" "$PLAT_SE/plat_sepolicy.cil" && \
                grep -q "^(typeattribute isolated_app_all)" "$PLAT_SE/plat_sepolicy.cil"; then
            ION_APP=true
        fi
        ION_CIL=""
        if [ -n "$ION_R" ]; then
            ION_CIL+="(typeattribute unica_ion_r)"$'\n'
            ION_CIL+="(typeattributeset unica_ion_r ($ION_R))"$'\n'
            ION_CIL+="(allow unica_ion_r ion_device (chr_file (getattr open read ioctl lock map watch watch_reads)))"$'\n'
        fi
        if [ -n "$ION_RW" ]; then
            ION_CIL+="(typeattribute unica_ion_rw)"$'\n'
            ION_CIL+="(typeattributeset unica_ion_rw ($ION_RW))"$'\n'
            ION_CIL+="(allow unica_ion_rw ion_device (chr_file (getattr open read write append ioctl lock map watch watch_reads)))"$'\n'
        fi
        if $ION_APP; then
            ION_CIL+="(typeattribute unica_ion_app)"$'\n'
            ION_CIL+="(typeattributeset unica_ion_app (and (appdomain) (not (isolated_app_all))))"$'\n'
            ION_CIL+="(allow unica_ion_app ion_device (chr_file (getattr open read ioctl lock map watch watch_reads)))"$'\n'
        fi
        printf '%s' "$ION_CIL" >> "$PLAT_SE/plat_sepolicy.cil"
        LOG "- ION read: $ION_R"
        LOG "- ION read/write: $ION_RW"
    fi
    LOG_STEP_OUT
else
    LOGW "ion_device is not declared in plat_sepolicy.cil, skipping ION policy restore"
fi
unset PLAT_SE ION_R ION_RW ION_DOM ION_APP ION_CIL
