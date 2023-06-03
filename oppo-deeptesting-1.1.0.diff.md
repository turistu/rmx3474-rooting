**I don't know if a trick similar to the one that *used to* work
with the realme apk could be used with oppo too, so this is just
for fun. If you're looking for a ready to work recipe for unlocking
your Oppo phone, please do NOT waste your time with this**

For the Oppo deeptesting 1.1.0 app, the fields from the json data of
the request are as follows:
```
model			ro.product.name
udid			IMEI 1
chipId			/proc/oppoVersion/serialID
otaVersion		ro.build.version.ota
token			login token obtained from com.heytap.usercenter
clientLockStatus	0
operator		ro.oppo.operator
```
The way the request and replies are encrypted (better said obfuscated)
are also different from the realme apk -- see the [`oppo.pl`](oppo.pl)
script which implements both the client and the server part.

#### Applying this patch

You can modify any apk by unpacking it with `apktool d`, editing the
smali files and resources, packing it back with `apktool b`, signing
it with the `apksigner` from android's SDK, and finally installing it
with `apk install`.

The [`patch-apk`](patch-apk) script will take a diff applying to an
unpacked apk and do all those steps. By default, it will sign the apk
with a throwaway key.
```
export ANDROID_SDK_ROOT=/path/to/the/android-sdk
./patch-apk old.apk new.apk < deeptesting-1.1.0.diff.md
```
This patch applies to [OPPO Deeptesting 1.1.0][1] and will turn it
into a regular app which doesn't need privileges and could also be
installed on the android emulator with `adb -e install`.

#### Playing with the patched apk

In order to simulate a fastboot unlocking procedure with the patched
apk, change `192.168.0.133` in this patch to an actual external address
reachable from the phone or emulator and run the [oppo.pl script](oppo.pl)
with `perl oppo.pl -s`.

The apk will go through all the steps (get the serial number and imei,
change the oem unlock flag, call `fastbootUnlock`, reboot), except that
--since it's not a privileged signed app and **cannot** actually do any
of those actions-- it will just log error messages instead:
```
05-28 09:19:08.824  8735  8769 E XXXX    : FAKE proc/oppoVersion/serialID = [[SERIAL_ID]]
05-28 09:19:08.868  8735  8735 E XXXX    : FAKE 1 OplusOSTelephonyManager->oplusIsSimLockedEnabled() = 0
05-28 09:19:08.869  8735  8735 E XXXX    : FAKE android.engineer.OplusEngineerManager.fastbootUnlock() = true
05-28 09:19:08.869  8735  8735 E XXXX    : 12345
05-28 09:19:08.869  8735  8735 E XXXX    : FAKE PersistentDataBlockManager.setOemUnlockEnabled()
05-28 09:19:08.869  8735  8735 E XXXX    : FAKE reboot bootloader (will fail)
```

[1]: https://www.apkmirror.com/apk/oppo/depth-testing/depth-testing-1-1-0-release/
```

diff -Nrup orig/AndroidManifest.xml modd/AndroidManifest.xml
--- orig/AndroidManifest.xml	2023-06-02 07:14:17.296709530 +0300
+++ modd/AndroidManifest.xml	2023-06-02 03:54:27.496778000 +0300
@@ -1,4 +1,4 @@
-<?xml version="1.0" encoding="utf-8" standalone="no"?><manifest xmlns:android="http://schemas.android.com/apk/res/android" android:compileSdkVersion="30" android:compileSdkVersionCodename="11" android:sharedUserId="android.uid.system" package="com.coloros.deeptesting" platformBuildVersionCode="12" platformBuildVersionName="1.1.0">
+<?xml version="1.0" encoding="utf-8" standalone="no"?><manifest xmlns:android="http://schemas.android.com/apk/res/android" android:compileSdkVersion="30" android:compileSdkVersionCodename="11" package="poop.coloros.deeptesting" platformBuildVersionCode="12" platformBuildVersionName="1.1.0">
     <uses-permission android:name="android.permission.INTERNET"/>
     <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
     <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
@@ -8,7 +8,7 @@
     <uses-permission android:name="android.permission.READ_PRIVILEGED_PHONE_STATE"/>
     <uses-permission android:name="android.permission.READ_PHONE_STATE"/>
     <uses-permission android:name="com.oppo.permission.safe.LOG"/>
-    <application android:appComponentFactory="androidx.core.app.CoreComponentFactory" android:icon="@drawable/ic_launcher" android:label="@string/app_name" android:resizeableActivity="false" android:screenOrientation="portrait" android:supportsRtl="true" android:theme="@style/AppNoTitleTheme">
+    <application android:appComponentFactory="androidx.core.app.CoreComponentFactory" android:icon="@drawable/ic_launcher" android:label="(T) Deep testing" android:resizeableActivity="false" android:screenOrientation="portrait" android:supportsRtl="true" android:theme="@style/AppNoTitleTheme">
         <uses-library android:name="org.apache.http.legacy" android:required="false"/>
         <activity android:name="com.coloros.deeptesting.activity.MainActivity" android:screenOrientation="portrait">
             <intent-filter>
diff -Nrup orig/assets/lk_unlock.pem modd/assets/lk_unlock.pem
--- orig/assets/lk_unlock.pem	1970-01-01 02:00:00.000000000 +0200
+++ modd/assets/lk_unlock.pem	2023-06-02 05:15:22.144623896 +0300
@@ -0,0 +1,17 @@
+-----BEGIN CERTIFICATE-----
+MIICqTCCAZECFF1QO2BP6wBCb0xQWzfktYWytpnXMA0GCSqGSIb3DQEBCwUAMBEx
+DzANBgNVBAMMBmRlZXBlcjAeFw0yMzA0MjYxMjUxNDRaFw0yNDA0MjUxMjUxNDRa
+MBExDzANBgNVBAMMBmRlZXBlcjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
+ggEBALYhGQCd5CpwKY14neExTf/DvS9xYBc1L6B6sQIWGj6tpeWcPYkxqdhym5kV
+EyCibW02IuxnUbDKqIDKm7OQd+TAI0puXK+0DSM2gXJv7ccNv36bm/bGAH5B/Vt1
+0r4a2ZGByjn0qgGzvwmUoReYoJUExnfX3eJF13ULVBOStEmhmuOYTOYHJ0ZDojAg
+UFNhhGWqSc2FaiNFG+U1/gR9goqM5twR4KkIWt31wDhPizQNqT2itpfJqHYBDOb4
+mogrOIbMdzTymfJb17Hvh0zHlRgZ4oX0pZAX/9RfggLWFH4AC1JZs/zWdfaI1Gvj
+MWejR0ovnX4HH4BpVE+1iBdHyhsCAwEAATANBgkqhkiG9w0BAQsFAAOCAQEAX474
+x37qshEWK2fR19nQxkY5cjSWCDgm4qwWqasQKX31Jh+3uqw+9Dx60QtVsWZZEl67
+b5+iv8Ww/qBg9wfQ/hnGhr/7EM7HE6OWDMLt4i1ZzQJOPIuHcLWhV3UvTzaUg/Yt
+wbI1x3dh3PLEuBLiHcExWjZypDxH2DIRhTTqhbJ0z9FSWk2ljlpMWETdI7UoHu09
+pC3Gy2wcZH4Up1PniJiTgr3ExN72eY/qdDnMVpFrJOLvA4VoJ+tDUt6Q9Ru80lSg
+Vz+1Kuk2k9iKjn78nYjMz6fL3C82xsXxD9r5GX1l3xyA2HO52d+88ECIl2P9SmBv
+sPAQaQWNv1UMFRagMw==
+-----END CERTIFICATE-----
diff -Nrup orig/smali/com/coloros/deeptesting/a/i.smali modd/smali/com/coloros/deeptesting/a/i.smali
--- orig/smali/com/coloros/deeptesting/a/i.smali	2023-06-02 03:52:01.573895842 +0300
+++ modd/smali/com/coloros/deeptesting/a/i.smali	2023-06-02 06:09:33.047219014 +0300
@@ -364,6 +364,16 @@
 .end method
 
 .method public static a(Ljava/lang/String;)Z
+    .locals 1
+    const-string v0, "FAKE android.engineer.OplusEngineerManager.fastbootUnlock() = true"
+    invoke-static {v0}, Lod/log;->s(Ljava/lang/String;)V
+    invoke-static {p0}, Lod/log;->s(Ljava/lang/String;)V
+    const/4 p0, 1
+    return p0
+
+.end method
+
+.method public static a_DISABLED(Ljava/lang/String;)Z
     .locals 8
 
     const/4 v0, 0x0
@@ -522,6 +532,14 @@
 
 .method public static b(Landroid/content/Context;)I
     .locals 1
+    const-string p0, "FAKE PersistentDataBlockManager.getFlashLockState() = 1"
+    invoke-static {p0}, Lod/log;->s(Ljava/lang/String;)V
+    const/4 p0, 1
+    return p0
+.end method
+
+.method public static b_DISABLED(Landroid/content/Context;)I
+    .locals 1
 
     :try_start_0
     const-string v0, "persistent_data_block"
@@ -554,7 +572,8 @@
 
     const-string v0, "ro.build.version.ota"
 
-    const-string v1, ""
+    # const-string v1, ""
+    const-string v1, "[[FAKE.DEFAULT.ro.build.version.ota]]"
 
     .line 157
     invoke-static {v0, v1}, Landroid/os/SystemProperties;->get(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
@@ -604,6 +623,14 @@
 .end method
 
 .method public static c()Ljava/lang/String;
+    .locals 1
+    const-string v0, "FAKE proc/oppoVersion/serialID = [[SERIAL_ID]]"
+    invoke-static {v0}, Lod/log;->s(Ljava/lang/String;)V
+    const-string v0, "[[SERIAL_ID]]"
+    return-object v0
+.end method
+
+.method public static c_DISABLED()Ljava/lang/String;
     .locals 5
 
     .line 187
@@ -756,6 +783,13 @@
 .end method
 
 .method public static d(Landroid/content/Context;)Ljava/lang/String;
+    .locals 1
+    const-string v0, "FAKE TelephonyManager.getImei() = [[IMEI]]"
+    invoke-static {v0}, Lod/log;->s(Ljava/lang/String;)V
+    const-string v0, "[[IMEI]]"
+    return-object v0
+.end method
+.method public static d_DISABLED(Landroid/content/Context;)Ljava/lang/String;
     .locals 2
 
     const-string v0, "0"
diff -Nrup orig/smali/com/coloros/deeptesting/activity/f.smali modd/smali/com/coloros/deeptesting/activity/f.smali
--- orig/smali/com/coloros/deeptesting/activity/f.smali	2023-06-02 03:52:01.577895811 +0300
+++ modd/smali/com/coloros/deeptesting/activity/f.smali	2023-06-02 05:39:17.343382692 +0300
@@ -73,16 +73,18 @@
     iget-object p1, p0, Lcom/coloros/deeptesting/activity/f;->a:Lcom/coloros/deeptesting/activity/ApplyActivity;
 
     .line 1152
-    invoke-static {p1}, Landroid/telephony/OplusOSTelephonyManager;->getDefault(Landroid/content/Context;)Landroid/telephony/OplusOSTelephonyManager;
+    # invoke-static {p1}, Landroid/telephony/OplusOSTelephonyManager;->getDefault(Landroid/content/Context;)Landroid/telephony/OplusOSTelephonyManager;
 
-    move-result-object p1
+    # move-result-object p1
 
     .line 1153
-    invoke-virtual {p1}, Landroid/telephony/OplusOSTelephonyManager;->oplusIsSimLockedEnabled()Z
+    # invoke-virtual {p1}, Landroid/telephony/OplusOSTelephonyManager;->oplusIsSimLockedEnabled()Z
 
-    move-result p1
+    # move-result p1
+    const-string p1, "FAKE 2 OplusOSTelephonyManager->oplusIsSimLockedEnabled() = 0"
+    invoke-static {p1}, Lod/log;->s(Ljava/lang/String;)V
 
-    if-eqz p1, :cond_1
+    # if-eqz p1, :cond_1
 
     goto :goto_0
 
diff -Nrup orig/smali/com/coloros/deeptesting/activity/l.smali modd/smali/com/coloros/deeptesting/activity/l.smali
--- orig/smali/com/coloros/deeptesting/activity/l.smali	2023-06-02 03:52:01.577895811 +0300
+++ modd/smali/com/coloros/deeptesting/activity/l.smali	2023-06-02 05:48:41.550858167 +0300
@@ -101,16 +101,20 @@
     iget-object p1, p0, Lcom/coloros/deeptesting/activity/l;->a:Lcom/coloros/deeptesting/activity/StatusActivity;
 
     .line 1152
-    invoke-static {p1}, Landroid/telephony/OplusOSTelephonyManager;->getDefault(Landroid/content/Context;)Landroid/telephony/OplusOSTelephonyManager;
+    #invoke-static {p1}, Landroid/telephony/OplusOSTelephonyManager;->getDefault(Landroid/content/Context;)Landroid/telephony/OplusOSTelephonyManager;
 
-    move-result-object p1
+    #move-result-object p1
 
     .line 1153
-    invoke-virtual {p1}, Landroid/telephony/OplusOSTelephonyManager;->oplusIsSimLockedEnabled()Z
+    #invoke-virtual {p1}, Landroid/telephony/OplusOSTelephonyManager;->oplusIsSimLockedEnabled()Z
 
-    move-result p1
+    #move-result p1
 
-    if-eqz p1, :cond_1
+    const-string p1, "FAKE 1 OplusOSTelephonyManager->oplusIsSimLockedEnabled() = 0"
+    invoke-static {p1}, Lod/log;->s(Ljava/lang/String;)V
+    goto :cond_1
+
+    # if-eqz p1, :cond_1
 
     goto/16 :goto_a
 
@@ -151,17 +155,20 @@
     iget-object p0, p0, Lcom/coloros/deeptesting/activity/l;->a:Lcom/coloros/deeptesting/activity/StatusActivity;
 
     :try_start_0
-    const-string p1, "persistent_data_block"
+    # const-string p1, "persistent_data_block"
 
     .line 1304
-    invoke-virtual {p0, p1}, Landroid/content/Context;->getSystemService(Ljava/lang/String;)Ljava/lang/Object;
+    # invoke-virtual {p0, p1}, Landroid/content/Context;->getSystemService(Ljava/lang/String;)Ljava/lang/Object;
 
-    move-result-object p0
+    # move-result-object p0
 
-    check-cast p0, Landroid/service/persistentdata/PersistentDataBlockManager;
+    # check-cast p0, Landroid/service/persistentdata/PersistentDataBlockManager;
 
     .line 1305
-    invoke-virtual {p0, v2}, Landroid/service/persistentdata/PersistentDataBlockManager;->setOemUnlockEnabled(Z)V
+    # invoke-virtual {p0, v2}, Landroid/service/persistentdata/PersistentDataBlockManager;->setOemUnlockEnabled(Z)V
+
+    const-string p0, "FAKE PersistentDataBlockManager.setOemUnlockEnabled()"
+    invoke-static {p0}, Lod/log;->s(Ljava/lang/String;)V
 
     const-string p0, "Utils"
 
@@ -192,6 +199,8 @@
 
     .line 1318
     :try_start_1
+    const-string v0, "FAKE reboot bootloader (will fail)"
+    invoke-static {v0}, Lod/log;->s(Ljava/lang/String;)V
     invoke-static {}, Ljava/lang/Runtime;->getRuntime()Ljava/lang/Runtime;
 
     move-result-object v0
diff -Nrup orig/smali/com/coloros/deeptesting/service/RequestService.smali modd/smali/com/coloros/deeptesting/service/RequestService.smali
--- orig/smali/com/coloros/deeptesting/service/RequestService.smali	2023-06-02 03:52:01.577895811 +0300
+++ modd/smali/com/coloros/deeptesting/service/RequestService.smali	2023-06-02 04:26:35.177038678 +0300
@@ -475,7 +475,8 @@
 
     iput-object p2, p0, Lcom/coloros/deeptesting/service/RequestService;->e:Landroid/os/Messenger;
 
-    const-string p2, "https://ilk.apps.coloros.com/api/v2/"
+    # const-string p2, "https://ilk.apps.coloros.com/api/v2/"
+    const-string p2, "https://192.168.0.133:7777/ilk.apps.coloros.com/api/v2/"
 
     .line 108
     iput-object p2, p0, Lcom/coloros/deeptesting/service/RequestService;->f:Ljava/lang/String;
diff -Nrup orig/smali/com/heytap/usercenter/accountsdk/AccountAgent.smali modd/smali/com/heytap/usercenter/accountsdk/AccountAgent.smali
--- orig/smali/com/heytap/usercenter/accountsdk/AccountAgent.smali	2023-06-02 03:52:01.661895170 +0300
+++ modd/smali/com/heytap/usercenter/accountsdk/AccountAgent.smali	2023-06-03 22:45:14.741506755 +0300
@@ -73,6 +73,15 @@
 
 .method public static getToken(Landroid/content/Context;Ljava/lang/String;)Ljava/lang/String;
     .locals 1
+    invoke-static {p1}, Lod/log;->s(Ljava/lang/String;)V
+    const-string p0, "FAKE getToken() = [FAKE_TOKEN]"
+    invoke-static {p0}, Lod/log;->s(Ljava/lang/String;)V
+    const-string p0, "[FAKE_TOKEN]"
+    return-object p0
+.end method
+
+.method public static getToken_DISABLED(Landroid/content/Context;Ljava/lang/String;)Ljava/lang/String;
+    .locals 1
 
     .line 1
     invoke-static {p0}, Lcom/heytap/usercenter/accountsdk/AccountAgent;->initContextIfNeeded(Landroid/content/Context;)V
@@ -131,6 +140,15 @@
 
 .method public static isLogin(Landroid/content/Context;Ljava/lang/String;)Z
     .locals 1
+    invoke-static {p1}, Lod/log;->s(Ljava/lang/String;)V
+    const-string p0, "FAKE isLogin() = 1"
+    invoke-static {p0}, Lod/log;->s(Ljava/lang/String;)V
+    const/4 p0, 1
+    return p0
+.end method
+
+.method public static isLogin_DISABLED(Landroid/content/Context;Ljava/lang/String;)Z
+    .locals 1
 
     .line 1
     invoke-static {p0}, Lcom/heytap/usercenter/accountsdk/AccountAgent;->initContextIfNeeded(Landroid/content/Context;)V
diff -Nrup orig/smali/od/log.smali modd/smali/od/log.smali
--- orig/smali/od/log.smali	1970-01-01 02:00:00.000000000 +0200
+++ modd/smali/od/log.smali	2023-06-02 04:02:03.373268283 +0300
@@ -0,0 +1,8 @@
+.class public final Lod/log;
+.super Ljava/lang/Object;
+.method public static s(Ljava/lang/String;)V
+    .locals 1
+    const-string v0, "XXXX"
+    invoke-static {v0, p0}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;)I
+    return-void
+.end method
diff -Nrup orig/smali/okhttp3/OkHttpClient.smali modd/smali/okhttp3/OkHttpClient.smali
--- orig/smali/okhttp3/OkHttpClient.smali	2023-06-02 03:52:01.677895047 +0300
+++ modd/smali/okhttp3/OkHttpClient.smali	2023-06-02 04:40:05.650545701 +0300
@@ -321,9 +321,12 @@
 
     .line 257
     :cond_3
-    invoke-static {}, Lokhttp3/internal/Util;->platformTrustManager()Ljavax/net/ssl/X509TrustManager;
+    # invoke-static {}, Lokhttp3/internal/Util;->platformTrustManager()Ljavax/net/ssl/X509TrustManager;
+
+    # move-result-object v0
+    new-instance v0, Lokhttp3/TrustAllManager;
+    invoke-direct {v0}, Lokhttp3/TrustAllManager;-><init>()V
 
-    move-result-object v0
 
     .line 258
     invoke-static {v0}, Lokhttp3/OkHttpClient;->newSslSocketFactory(Ljavax/net/ssl/X509TrustManager;)Ljavax/net/ssl/SSLSocketFactory;
diff -Nrup orig/smali/okhttp3/TrustAllManager.smali modd/smali/okhttp3/TrustAllManager.smali
--- orig/smali/okhttp3/TrustAllManager.smali	1970-01-01 02:00:00.000000000 +0200
+++ modd/smali/okhttp3/TrustAllManager.smali	2023-06-02 04:37:35.947738791 +0300
@@ -0,0 +1,40 @@
+.class public final Lokhttp3/TrustAllManager;
+.super Ljava/lang/Object;
+.source "TrustAllCertification.java"
+
+# interfaces
+.implements Ljavax/net/ssl/X509TrustManager;
+
+# direct methods
+.method constructor <init>()V
+    .locals 0
+
+    .line 45
+    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
+
+    return-void
+.end method
+
+# virtual methods
+.method public checkClientTrusted([Ljava/security/cert/X509Certificate;Ljava/lang/String;)V
+    .locals 0
+
+    return-void
+.end method
+
+.method public checkServerTrusted([Ljava/security/cert/X509Certificate;Ljava/lang/String;)V
+    .locals 0
+
+    return-void
+.end method
+
+.method public getAcceptedIssuers()[Ljava/security/cert/X509Certificate;
+    .locals 0
+
+    const/4 p0, 0x0
+
+    .line 59
+    new-array p0, p0, [Ljava/security/cert/X509Certificate;
+
+    return-object p0
+.end method
diff -Nrup orig/smali/okhttp3/internal/tls/OkHostnameVerifier.smali modd/smali/okhttp3/internal/tls/OkHostnameVerifier.smali
--- orig/smali/okhttp3/internal/tls/OkHostnameVerifier.smali	2023-06-02 03:52:01.693894925 +0300
+++ modd/smali/okhttp3/internal/tls/OkHostnameVerifier.smali	2023-06-02 04:57:16.516313749 +0300
@@ -304,6 +304,11 @@
 
 # virtual methods
 .method public final verify(Ljava/lang/String;Ljava/security/cert/X509Certificate;)Z
+   .locals 1
+   const/4 p0, 1
+   return p0
+.end method
+.method public final verify_DISABLED(Ljava/lang/String;Ljava/security/cert/X509Certificate;)Z
     .locals 1
 
     .line 56
@@ -330,6 +335,11 @@
 .end method
 
 .method public final verify(Ljava/lang/String;Ljavax/net/ssl/SSLSession;)Z
+   .locals 1
+   const/4 p0, 1
+   return p0
+.end method
+.method public final verify_DISABLED(Ljava/lang/String;Ljavax/net/ssl/SSLSession;)Z
     .locals 1
 
     const/4 v0, 0x0
