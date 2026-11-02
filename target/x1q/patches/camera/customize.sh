
LOG "- Patching /vendor/etc/ueventd.rc"
EVAL "cat \"$MODPATH/ueventd.rc.diff\" >> \"$WORK_DIR/vendor/etc/ueventd.rc\""
