LOG "- Patching /vendor/ueventd.rc"
EVAL "cat \"$MODPATH/ueventd.rc.diff\" >> \"$WORK_DIR/vendor/ueventd.rc\""

# Force disable ScenarioManager::IsSupported3rdPartyYuvCapture()
# Before: [bne #0xdabb8]
# After: [b #0xdabb8]
HEX_PATCH "$WORK_DIR/vendor/lib/unihal_main@2.1.so" "01280dd1" "01280de0"

# Before: [b.ne 0x5099f4]
# After: [b 0x5099f4]
HEX_PATCH "$WORK_DIR/vendor/lib64/unihal_main@2.1.so" "a101005468e640b9" "0d00001468e640b9"
