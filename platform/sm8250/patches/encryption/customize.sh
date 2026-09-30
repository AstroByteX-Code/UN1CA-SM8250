LOG "- Patching /vendor/etc/fstab.qcom"
EVAL "sed -i \"/[[:space:]]\/data[[:space:]]/ s|fileencryption=ice|fileencryption=aes-256-xts:aes-256-cts:v2+inlinecrypt_optimized,fscompress,keydirectory=/metadata/vold/metadata_encryption,sysfs_path=/sys/devices/platform/soc/1d84000.ufshc|g\" \"$WORK_DIR/vendor/etc/fstab.qcom\""
EVAL "sed -i \"/Samsung ODE/,+2d\" \"$WORK_DIR/vendor/etc/fstab.qcom\""

LOG_STEP_IN "- Remove Samsung Encryption"
sed -i -E \
    's/^([^#].*?)fileencryption=[^,]*(.*)$/# &\n\1encryptable\2/' \
    "$WORK_DIR/vendor/etc/fstab.qcom"
sed -i -E \
    's/^([^#].*?)forceencrypt=[^,]*(.*)$/# &\n\1encryptable\2/' \
    "$WORK_DIR/vendor/etc/fstab.qcom"
LOG_STEP_OUT

LOG_STEP_IN "- wifi+security Prop"
SET_PROP "vendor" "wlan.wfd.hdcp" "disabled"
SET_PROP "vendor" "wifi.interface" "wlan0"
SET_PROP "vendor" "ro.security.vaultkeeper.native" "0"
SET_PROP "vendor" "ro.security.vaultkeeper.feature" "0"
LOG_STEP_OUT
