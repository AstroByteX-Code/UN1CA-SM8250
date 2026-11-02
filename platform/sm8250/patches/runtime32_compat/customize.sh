    DELETE_FROM_WORK_DIR "system" "system/apex/com.android.i18n.apex"
    DELETE_FROM_WORK_DIR "system" "system/apex/com.android.runtime.apex"
    DELETE_FROM_WORK_DIR "system" "system/apex/com.google.android.art_compressed.apex"
    
    
    LOG_STEP_IN "- Adding S23 (dm1qxxx) lib/ blobs"
    ADD_TO_WORK_DIR "dm1qxxx" "system" "system/lib" 0 0 644

    BLOBS_LIST="
    system/apex/com.android.i18n.apex
    system/apex/com.android.runtime.apex
    system/apex/com.google.android.art_compressed.apex
    system/bin/bootstrap/linker
    system/bin/bootstrap/linker_asan
    "
    for blob in $BLOBS_LIST
    do
        ADD_TO_WORK_DIR "dm1qxxx" "system" "$blob"
    done
    LOG_STEP_OUT

    LOG_STEP_IN "- Creating symlinks"
    ln -sf "/apex/com.android.runtime/bin/linker" "$WORK_DIR/system/system/bin/linker"
    ln -sf "/apex/com.android.runtime/bin/linker" "$WORK_DIR/system/system/bin/linker_asan"
    SET_METADATA "system" "system/bin/linker" 0 0 755 "u:object_r:system_file:s0"
    SET_METADATA "system" "system/bin/linker_asan" 0 0 755 "u:object_r:system_file:s0"

    ln -sf "/apex/com.android.runtime/lib/bionic/libc.so" "$WORK_DIR/system/system/lib/libc.so"
    ln -sf "/apex/com.android.runtime/lib/bionic/libdl.so" "$WORK_DIR/system/system/lib/libdl.so"
    ln -sf "/apex/com.android.runtime/lib/bionic/libdl_android.so" "$WORK_DIR/system/system/lib/libdl_android.so"
    ln -sf "/apex/com.android.runtime/lib/bionic/libm.so" "$WORK_DIR/system/system/lib/libm.so"
    SET_METADATA "system" "system/lib/libc.so" 0 0 644 "u:object_r:system_lib_file:s0"
    SET_METADATA "system" "system/lib/libdl.so" 0 0 644 "u:object_r:system_lib_file:s0"
    SET_METADATA "system" "system/lib/libdl_android.so" 0 0 644 "u:object_r:system_lib_file:s0"
    SET_METADATA "system" "system/lib/libm.so" 0 0 644 "u:object_r:system_lib_file:s0"
    LOG_STEP_OUT
