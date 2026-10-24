if xxd -p -c 0 "$WORK_DIR/system/system/bin/audioserver" | grep -q -E "08f0a7521f2003d511000014|08f0a7521f2003d50d000014"; then
    LOG "- VoIP call volume fix already applied in /system/system/bin/audioserver"
    return 0
elif xxd -p -c 0 "$WORK_DIR/system/system/bin/audioserver" | grep -q "08f0a752680200b911000014"; then
    # Android 16 (One UI 8.5): str w8, [x19]
    HEX_PATCH "$WORK_DIR/system/system/bin/audioserver" \
        "08f0a752680200b911000014" "08f0a7521f2003d511000014"
elif xxd -p -c 0 "$WORK_DIR/system/system/bin/audioserver" | grep -q "08f0a752880300b90d000014"; then
    # Android 14/15: str w8, [x28]
    HEX_PATCH "$WORK_DIR/system/system/bin/audioserver" \
        "08f0a752880300b90d000014" "08f0a7521f2003d50d000014"
elif xxd -p -c 0 "$WORK_DIR/system/system/bin/audioserver" | grep -q "08f0a752780300b90d000014"; then
    # str w8, [x27]
    HEX_PATCH "$WORK_DIR/system/system/bin/audioserver" \
        "08f0a752780300b90d000014" "08f0a7521f2003d50d000014"
elif xxd -p -c 0 "$WORK_DIR/system/system/bin/audioserver" | grep -q "08f0a752680300b90d000014"; then
    # str w8, [x26]
    HEX_PATCH "$WORK_DIR/system/system/bin/audioserver" \
        "08f0a752680300b90d000014" "08f0a7521f2003d50d000014"
elif xxd -p -c 0 "$WORK_DIR/system/system/bin/audioserver" | grep -q "08f0a752850300b90d000014"; then
    HEX_PATCH "$WORK_DIR/system/system/bin/audioserver" \
        "08f0a752850300b90d000014" "08f0a7521f2003d50d000014"
else
    LOGE "No matching pattern found in audioserver for VoIP call volume fix"
    return 1
fi

