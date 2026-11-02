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

if [[ "$SOURCE_PLATFORM_SDK_VERSION" -ge 36 ]]; then
    LOG_STEP_IN "- Updating Codec2 seccomp policy"
    CODEC2_POLICY="$WORK_DIR/vendor/etc/seccomp_policy/samsung.software.media.c2-base-policy"
    CODEC2_OLD_RULE="mremap: arg3 == 3"
    CODEC2_NEW_RULE="mremap: arg3 == 3 || arg3 == MREMAP_MAYMOVE"

    if [ ! -f "$CODEC2_POLICY" ]; then
        LOG "  - Codec2 seccomp policy is not present; skipping"
    else
        if grep -q -F -x "$CODEC2_NEW_RULE" "$CODEC2_POLICY"; then
            LOG "  - MREMAP_MAYMOVE is already allowed"
        elif grep -q -F -x "$CODEC2_OLD_RULE" "$CODEC2_POLICY"; then
            LOG "  - Allowing MREMAP_MAYMOVE in ${CODEC2_POLICY//$WORK_DIR\//}"
            EVAL "sed -i 's/^mremap: arg3 == 3$/mremap: arg3 == 3 || arg3 == MREMAP_MAYMOVE/' \"$CODEC2_POLICY\""
        elif grep -q '^mremap:' "$CODEC2_POLICY"; then
            ABORT "Unsupported mremap rule in ${CODEC2_POLICY//$WORK_DIR\//}"
        else
            LOG "  - Adding the missing mremap rule to ${CODEC2_POLICY//$WORK_DIR\//}"
            EVAL "printf '%s\\n' '$CODEC2_NEW_RULE' >> \"$CODEC2_POLICY\""
        fi

        grep -q -F -x "$CODEC2_NEW_RULE" "$CODEC2_POLICY" || \
            ABORT "Failed to update ${CODEC2_POLICY//$WORK_DIR\//}"

        for CODEC2_SYSCALL_RULE in "setsockopt: 1" "listen: 1" "bind: 1"; do
            if ! grep -q -F -x "$CODEC2_SYSCALL_RULE" "$CODEC2_POLICY"; then
                grep -q -F -x "prctl: 1" "$CODEC2_POLICY" || \
                    ABORT "Unable to locate the Codec2 syscall insertion point"
                LOG "  - Allowing ${CODEC2_SYSCALL_RULE%%:*}"
                EVAL "sed -i '/^prctl: 1$/i$CODEC2_SYSCALL_RULE' \"$CODEC2_POLICY\""
            fi
        done

        for CODEC2_SYSCALL_RULE in "setsockopt: 1" "listen: 1" "bind: 1"; do
            grep -q -F -x "$CODEC2_SYSCALL_RULE" "$CODEC2_POLICY" || \
                ABORT "Failed to add $CODEC2_SYSCALL_RULE to ${CODEC2_POLICY//$WORK_DIR\//}"
        done
    fi
    unset CODEC2_POLICY CODEC2_OLD_RULE CODEC2_NEW_RULE CODEC2_SYSCALL_RULE
    LOG_STEP_OUT
fi

if [[ "$SOURCE_PLATFORM_SDK_VERSION" -ge 37 ]]; then
    LOG_STEP_IN "- Aligning SLMK swap watermark with Android 17 RAM Plus"

    # Android 17's SLMKD re-evaluates its free-swap watermark after RAM Plus
    # has expanded zram.  The target build.prop has no explicit
    # swap_free_low_percentage, so SLMKD falls back to 55 and then derives
    # 86% from the 8 GiB runtime zram device.  LMKD consequently kills cached
    # apps while more than 7 GiB of swap is still free.  The S24+ source
    # policy explicitly uses 10% for both SLMK policies; retain that policy
    # when the target vendor properties replace the source build.prop.  This
    # changes only the reclaim watermark, not zram capacity or OOM scores.
    SET_PROP "vendor" "ro.slmk.swap_free_low_percentage" "10"
    SET_PROP "vendor" "ro.slmk.2nd.swap_free_low_percentage" "10"

    LOG_STEP_OUT

    LOG_STEP_IN "- Disabling unsupported Codec2 availability accounting"

    # Android 17 enables codec_availability_metrics and consequently queries
    # C2ResourcesCapacityTuning/C2ResourcesExcludedTuning on the component
    # store and C2ResourcesNeededTuning on every component.  Those proposed
    # parameters are absent from the legacy Codec2 HIDL 1.0 stack,
    # which correctly returns C2_BAD_INDEX (ENXIO, status 6).  Make only the
    # two optional accounting routines return an empty resource set/success,
    # matching CCodec's feature-disabled fallback.  Actual codec creation,
    # buffer allocation and allocation failures remain untouched.
    C2_PLUGIN_32="$WORK_DIR/system/system/lib/libsfplugin_ccodec.so"
    C2_PLUGIN_64="$WORK_DIR/system/system/lib64/libsfplugin_ccodec.so"

    # ARM32 CCodecResources::queryRequiredResources(): return OK.
    C2_REQUIRED_32_FROM="f0b58db004464d4878440068"
    C2_REQUIRED_32_TO="0020704704464d4878440068"
    # ARM32 queryGlobalResources(): initialize the returned vector to empty.
    C2_GLOBAL_32_FROM="2de9f04f9fb0e1490646dff8"
    C2_GLOBAL_32_TO="00210160416081607047dff8"

    # ARM64 CCodecResources::queryRequiredResources(): return OK.
    C2_REQUIRED_64_FROM="3f2303d5ff0302d1fd7b05a9f53300f9f44f07a9fd430191f30300aa340040f9"
    C2_REQUIRED_64_TO="e0031f2ac0035fd6fd7b05a9f53300f9f44f07a9fd430191f30300aa340040f9"
    # ARM64 queryGlobalResources(): initialize the returned vector to empty.
    C2_GLOBAL_64_FROM="3f2303d5ff8304d1fd7b0ca9fc6f0da9fa670ea9f85f0fa9f65710a9f44f11a9fd030391f30308aa"
    C2_GLOBAL_64_TO="1f7d00a91f0900f9e0031f2ac0035fd6fa670ea9f85f0fa9f65710a9f44f11a9fd030391f30308aa"

    if [[ -f "$C2_PLUGIN_32" ]]; then
        if xxd -p -c 0 "$C2_PLUGIN_32" | grep -q "$C2_REQUIRED_32_FROM"; then
            HEX_PATCH "$C2_PLUGIN_32" \
                "$C2_REQUIRED_32_FROM" "$C2_REQUIRED_32_TO" || return 1
        elif ! xxd -p -c 0 "$C2_PLUGIN_32" | grep -q "$C2_REQUIRED_32_TO"; then
            ABORT "Missing ARM32 Codec2 required-resource query pattern"
        fi
        if xxd -p -c 0 "$C2_PLUGIN_32" | grep -q "$C2_GLOBAL_32_FROM"; then
            HEX_PATCH "$C2_PLUGIN_32" \
                "$C2_GLOBAL_32_FROM" "$C2_GLOBAL_32_TO" || return 1
        elif ! xxd -p -c 0 "$C2_PLUGIN_32" | grep -q "$C2_GLOBAL_32_TO"; then
            ABORT "Missing ARM32 Codec2 global-resource query pattern"
        fi
    fi

    if [[ -f "$C2_PLUGIN_64" ]]; then
        if xxd -p -c 0 "$C2_PLUGIN_64" | grep -q "$C2_REQUIRED_64_FROM"; then
            HEX_PATCH "$C2_PLUGIN_64" \
                "$C2_REQUIRED_64_FROM" "$C2_REQUIRED_64_TO" || return 1
        elif ! xxd -p -c 0 "$C2_PLUGIN_64" | grep -q "$C2_REQUIRED_64_TO"; then
            ABORT "Missing ARM64 Codec2 required-resource query pattern"
        fi
        if xxd -p -c 0 "$C2_PLUGIN_64" | grep -q "$C2_GLOBAL_64_FROM"; then
            HEX_PATCH "$C2_PLUGIN_64" \
                "$C2_GLOBAL_64_FROM" "$C2_GLOBAL_64_TO" || return 1
        elif ! xxd -p -c 0 "$C2_PLUGIN_64" | grep -q "$C2_GLOBAL_64_TO"; then
            ABORT "Missing ARM64 Codec2 global-resource query pattern"
        fi
    fi

    unset C2_PLUGIN_32 C2_PLUGIN_64 \
        C2_REQUIRED_32_FROM C2_REQUIRED_32_TO \
        C2_GLOBAL_32_FROM C2_GLOBAL_32_TO \
        C2_REQUIRED_64_FROM C2_REQUIRED_64_TO \
        C2_GLOBAL_64_FROM C2_GLOBAL_64_TO
    LOG_STEP_OUT

    LOG_STEP_IN "- Removing stale legacy OMX performance metadata"

    # Android 17's codec-list generator no longer registers the legacy OMX
    # performance entries from the target.  Keeping this file makes
    # it emit "cannot update non-existing codec" for every OMX entry.  The
    # actual codec declarations remain in media_codecs.xml and the C2 metadata
    # remains in media_codecs_c2_sec*.xml; only the obsolete performance
    # overlay is removed.
    DELETE_FROM_WORK_DIR "vendor" "etc/media_codecs_performance.xml"

    LOG_STEP_OUT
fi

# For some reason we are missing 2 permissions here: android.hardware.security.model.compatible and android.software.controls
# First one is related to encryption and second one to SmartThings Device Control
LOG "- Patching vendor permissions"
sed -i '$d' "$WORK_DIR/vendor/etc/permissions/handheld_core_hardware.xml"
{
    echo ""
    echo "    <!-- Indicate support for the Android security model per the CDD. -->"
    echo "    <feature name=\"android.hardware.security.model.compatible\"/>"
    echo ""
    echo "    <!--  Feature to specify if the device supports controls.  -->"
    echo "    <feature name=\"android.software.controls\"/>"
    echo "</permissions>"
} >> "$WORK_DIR/vendor/etc/permissions/handheld_core_hardware.xml"

unset PLAT_SE ION_R ION_RW ION_DOM ION_APP ION_CIL
