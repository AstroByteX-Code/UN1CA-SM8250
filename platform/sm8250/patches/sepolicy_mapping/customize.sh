# [PATCH] selinux: drop undeclared versioned mapping attributes
#
# The source firmware’s mapping files reference versioned attributes
# (e.g. vendor_smcinvoke_device_30_0) that are not declared in any
# policy file. This causes secilc to fail when compiling the target
# vendor policy.
#
# This patch removes such undeclared attributes from system_ext and
# product mapping files, while preserving valid entries. It ensures
# policy compilation succeeds without unknown QC vendor types.
#
# Changes:
# - Detect version suffix from plat_sepolicy_vers.txt
# - Scan mapping files for expandtypeattribute/typeattributeset entries
# - Drop attributes not declared in any .cil policy file
# - Log removals for visibility

VER="$(cat "$WORK_DIR/vendor/etc/selinux/plat_sepolicy_vers.txt" 2>/dev/null)"
if [ -n "$VER" ]; then
    SUFFIX="_${VER//./_}"
    SYSTEM_EXT_SE="$WORK_DIR/system/system/system_ext/etc/selinux"
    [ -d "$WORK_DIR/system_ext/etc/selinux" ] && SYSTEM_EXT_SE="$WORK_DIR/system_ext/etc/selinux"
    ALL_CIL="$(find "$WORK_DIR/system/system/etc/selinux" "$SYSTEM_EXT_SE" "$WORK_DIR/product/etc/selinux" \
        "$WORK_DIR/vendor/etc/selinux" "$WORK_DIR/odm/etc/selinux" -name "*.cil" 2> /dev/null)"
    for MAPPING in "$SYSTEM_EXT_SE/mapping/$VER.cil" "$WORK_DIR/product/etc/selinux/mapping/$VER.cil"; do
        [ -f "$MAPPING" ] || continue
        while IFS= read -r ATTR; do
            # shellcheck disable=SC2086
            if ! grep -q -E "^\(typeattribute $ATTR\)" $ALL_CIL; then
                LOG "- Removing undeclared $ATTR from ${MAPPING//$WORK_DIR/}"
                EVAL "sed -i -E '/\\(expandtypeattribute \\($ATTR\\)|\\(typeattributeset $ATTR /d' \"$MAPPING\""
            fi
        done < <(grep -oE "\(expandtypeattribute \([a-z0-9_]+$SUFFIX\)" "$MAPPING" | sed -E 's/.*\(([a-z0-9_]+)\)$/\1/' | sort -u)
    done
fi
unset VER SUFFIX SYSTEM_EXT_SE ALL_CIL MAPPING ATTR
