# Copyright (c) 2025 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# Overlays
SYSTEM_DEBLOAT+="
system/app/WifiRROverlayAppH2E
system/app/WifiRROverlayAppLls
"
PRODUCT_DEBLOAT+="
overlay/SoftapOverlayQC
"

# mAFPC
SYSTEM_DEBLOAT+="
system/bin/mafpc_write
"

# Auto Blocker
SYSTEM_DEBLOAT+="
system/app/Rampart
"

# Google
PRODUCT_DEBLOAT+="
priv-app/Velvet
"

# GameDriver
SYSTEM_DEBLOAT+="
system/priv-app/GameDriver-SM8450
"

# system_ext clean-up
SYSTEM_EXT_DEBLOAT+="
etc/permissions/com.qti.location.sdk.xml
etc/permissions/com.qualcomm.location.xml
etc/permissions/privapp-permissions-com.qualcomm.location.xml
framework/com.qti.location.sdk.jar
priv-app/com.qualcomm.location
"
