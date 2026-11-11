# shellcheck disable=SC2034
SKIPUNZIP=1

APPLY_PATCH "system" "system/framework/framework.jar" "$MODPATH/9004-Make-IProcessObserver-tolerate-missing-onProcessStarted-oneui9.patch"
