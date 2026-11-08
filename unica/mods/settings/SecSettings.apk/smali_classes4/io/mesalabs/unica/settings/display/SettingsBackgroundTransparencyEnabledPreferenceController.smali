.class public Lio/mesalabs/unica/settings/display/SettingsBackgroundTransparencyEnabledPreferenceController;
.super Lcom/android/settings/core/TogglePreferenceController;
.source "SettingsBackgroundTransparencyEnabledPreferenceController.java"


# direct methods
.method public constructor <init>(Landroid/content/Context;Ljava/lang/String;)V
    .locals 0

    invoke-direct {p0, p1, p2}, Lcom/android/settings/core/TogglePreferenceController;-><init>(Landroid/content/Context;Ljava/lang/String;)V

    return-void
.end method


# virtual methods
.method public getAvailabilityStatus()I
    .locals 0

    const/4 p0, 0x0

    return p0
.end method

.method public isChecked()Z
    .locals 0

    iget-object p0, p0, Lcom/android/settingslib/core/AbstractPreferenceController;->mContext:Landroid/content/Context;

    invoke-static {p0}, Lio/mesalabs/unica/settings/display/SettingsBackgroundTransparencyUtils;->isEnabled(Landroid/content/Context;)Z

    move-result p0

    return p0
.end method

.method public isControllable()Z
    .locals 0

    const/4 p0, 0x1

    return p0
.end method

.method public setChecked(Z)Z
    .locals 3

    if-eqz p1, :disabled_value

    const/4 v2, 0x1

    goto :value_ready

    :disabled_value
    const/4 v2, 0x0

    :value_ready

    iget-object v0, p0, Lcom/android/settingslib/core/AbstractPreferenceController;->mContext:Landroid/content/Context;

    invoke-virtual {v0}, Landroid/content/Context;->getContentResolver()Landroid/content/ContentResolver;

    move-result-object v0

    const-string v1, "unica_settings_bg_transparency_enabled"

    invoke-static {v0, v1, v2}, Landroid/provider/Settings$System;->putInt(Landroid/content/ContentResolver;Ljava/lang/String;I)Z

    move-result p1

    if-eqz p1, :return_result

    iget-object p0, p0, Lcom/android/settingslib/core/AbstractPreferenceController;->mContext:Landroid/content/Context;

    if-eqz v2, :disable_mode

    invoke-static {p0}, Lio/mesalabs/unica/settings/display/SettingsBackgroundTransparencyUtils;->apply(Landroid/content/Context;)V

    goto :return_result

    :disable_mode
    instance-of v0, p0, Landroid/app/Activity;

    if-eqz v0, :return_result

    check-cast p0, Landroid/app/Activity;

    invoke-virtual {p0}, Landroid/app/Activity;->recreate()V

    :return_result
    return p1
.end method
