# shellcheck disable=SC2034
SKIPUNZIP=1

APPLY_PATCH "system" "system/framework/framework.jar" "$MODPATH/0001-Give-up-on-a-dead-native-app-zygote-after-12s.patch"
