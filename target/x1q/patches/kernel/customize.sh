KERNEL_REPO="https://github.com/AstroByteX-Code/unica-kernel_samsung_sm8250/releases/download/UN1CA-x1q-20260930-100216"

LOG_STEP_IN "- Downloading  kernel"
if [ -f "$WORK_DIR/kernel/boot.img" ]; then
    rm -f "$WORK_DIR/kernel/boot.img"
fi
if [ -f "$WORK_DIR/kernel/dtbo.img" ]; then
    rm -f "$WORK_DIR/kernel/dtbo.img"
fi

DOWNLOAD_FILE "$KERNEL_REPO/boot.img" "$WORK_DIR/kernel/boot.img"
DOWNLOAD_FILE "$KERNEL_REPO/dtbo.img" "$WORK_DIR/kernel/dtbo.img"
unset KERNEL_REPO
LOG_STEP_OUT
