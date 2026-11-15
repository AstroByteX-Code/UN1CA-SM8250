KERNEL_REPO="https://github.com/AstroByteX-Code/not_samsung.sm8250-4.19/releases/download/Astral-z3q-20261115-020051"

LOG_STEP_IN "- Downloading Astral kernel"
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
