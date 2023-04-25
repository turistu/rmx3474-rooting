For the Oppo deeptesting 1.1.0 app, the fields from the json data of
the request are as follows:

model			ro.product.name
udid			IMEI 1
chipId			read /proc/oppoVersion/serialID
otaVersion		ro.build.version.ota
clientLockStatus	0
operator		ro.oppo.operator

You can modify any apk by unpacking it with `apktool d`, modifying the
smali files and resources, then packing it back with `apktool b`, signing
it with the `apksigner` from android's SDK, and finally installing it
with `apk install`.

The [`patch-apk`][../patch-apk] will take a diff applying to an unpacked
apk and do all those steps. By default, it will sign the apk with a
throwaway key.
```
./patch-apk old.apk new.apk < deeptesting-1.1.0.diff.md
```
In this diff, change the `LOCALHOST:LOCALPORT`, `[[IMEI]]` and
`[[SERIAL_ID]]` as appropriate.

diff -Nrup old/AndroidManifest.xml new/AndroidManifest.xml
--- old/AndroidManifest.xml	2023-04-25 09:10:42.822927014 +0300
+++ new/AndroidManifest.xml	2023-04-25 09:41:36.056842447 +0300
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
diff -Nrup old/smali/com/coloros/deeptesting/a/a.smali new/smali/com/coloros/deeptesting/a/a.smali
--- old/smali/com/coloros/deeptesting/a/a.smali	2023-04-25 00:58:17.107174578 +0300
+++ new/smali/com/coloros/deeptesting/a/a.smali	2023-04-25 07:00:17.272267473 +0300
@@ -533,11 +533,28 @@
     return-object v0
 .end method
 
+.method private static log1(Ljava/lang/String;)V
+    .locals 1
+    const-string v0, "XXXX-1"
+    invoke-static {v0, p0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
+    return-void
+.end method
+.method private static log2(Ljava/lang/String;)V
+    .locals 1
+    const-string v0, "XXXX-2"
+    invoke-static {v0, p0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
+    return-void
+.end method
+
 .method private static b(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
     .locals 3
 
     .line 157
     :try_start_0
+
+    invoke-static {p0}, Lcom/coloros/deeptesting/a/a;->log1(Ljava/lang/String;)V
+    invoke-static {p1}, Lcom/coloros/deeptesting/a/a;->log1(Ljava/lang/String;)V
+
     new-instance v0, Ljavax/crypto/spec/SecretKeySpec;
 
     const-string v1, "UTF-8"
@@ -613,6 +630,7 @@
     :try_end_0
     .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0
 
+    invoke-static {v0}, Lcom/coloros/deeptesting/a/a;->log1(Ljava/lang/String;)V
     return-object v0
 
     :catch_0
@@ -630,6 +648,8 @@
     .locals 3
 
     .line 178
+    invoke-static {p0}, Lcom/coloros/deeptesting/a/a;->log2(Ljava/lang/String;)V
+    invoke-static {p1}, Lcom/coloros/deeptesting/a/a;->log2(Ljava/lang/String;)V
     :try_start_0
     new-instance v0, Ljavax/crypto/spec/SecretKeySpec;
 
@@ -699,6 +719,7 @@
     :try_end_0
     .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0
 
+    invoke-static {p0}, Lcom/coloros/deeptesting/a/a;->log2(Ljava/lang/String;)V
     return-object p0
 
     :catch_0
diff -Nrup old/smali/com/coloros/deeptesting/a/h.smali new/smali/com/coloros/deeptesting/a/h.smali
--- old/smali/com/coloros/deeptesting/a/h.smali	2023-04-25 00:58:17.111174580 +0300
+++ new/smali/com/coloros/deeptesting/a/h.smali	2023-04-25 01:30:46.557923602 +0300
@@ -35,6 +35,10 @@
 .end method
 
 .method public static a(Landroid/content/Context;Landroid/os/Handler;)V
+    .locals 1
+    return-void
+.end method
+.method public static a_DISABLED(Landroid/content/Context;Landroid/os/Handler;)V
     .locals 8
 
     .line 74
diff -Nrup old/smali/com/coloros/deeptesting/a/i.smali new/smali/com/coloros/deeptesting/a/i.smali
--- old/smali/com/coloros/deeptesting/a/i.smali	2023-04-25 00:58:17.111174580 +0300
+++ new/smali/com/coloros/deeptesting/a/i.smali	2023-04-25 07:42:24.704418130 +0300
@@ -522,6 +522,12 @@
 
 .method public static b(Landroid/content/Context;)I
     .locals 1
+    const/4 p0, 0x1
+    return p0
+.end method
+
+.method public static b_DISABLED(Landroid/content/Context;)I
+    .locals 1
 
     :try_start_0
     const-string v0, "persistent_data_block"
@@ -604,6 +610,11 @@
 .end method
 
 .method public static c()Ljava/lang/String;
+    .locals 1
+    const-string v0, "[[SERIAL_ID]]"
+    return-object v0
+.end method
+.method public static c_DISABLED()Ljava/lang/String;
     .locals 5
 
     .line 187
@@ -756,6 +767,12 @@
 .end method
 
 .method public static d(Landroid/content/Context;)Ljava/lang/String;
+    .locals 1
+    const-string v0, "[[IMEI]]"
+    return-object v0
+.end method
+
+.method public static d_DISABLED(Landroid/content/Context;)Ljava/lang/String;
     .locals 2
 
     const-string v0, "0"
diff -Nrup old/smali/com/coloros/deeptesting/service/RequestService.smali new/smali/com/coloros/deeptesting/service/RequestService.smali
--- old/smali/com/coloros/deeptesting/service/RequestService.smali	2023-04-25 00:58:17.111174580 +0300
+++ new/smali/com/coloros/deeptesting/service/RequestService.smali	2023-04-25 01:01:24.227352391 +0300
@@ -475,7 +475,8 @@
 
     iput-object p2, p0, Lcom/coloros/deeptesting/service/RequestService;->e:Landroid/os/Messenger;
 
-    const-string p2, "https://ilk.apps.coloros.com/api/v2/"
+    const-string p2, "[[https://LOCALHOST:LOCALPORT/api/v2/]]"
+    # const-string p2, "https://ilk.apps.coloros.com/api/v2/"
 
     .line 108
     iput-object p2, p0, Lcom/coloros/deeptesting/service/RequestService;->f:Ljava/lang/String;
diff -Nrup old/smali/com/heytap/usercenter/accountsdk/AccountAgent.smali new/smali/com/heytap/usercenter/accountsdk/AccountAgent.smali
--- old/smali/com/heytap/usercenter/accountsdk/AccountAgent.smali	2023-04-25 00:58:17.187174618 +0300
+++ new/smali/com/heytap/usercenter/accountsdk/AccountAgent.smali	2023-04-25 01:31:30.377623585 +0300
@@ -131,6 +131,12 @@
 
 .method public static isLogin(Landroid/content/Context;Ljava/lang/String;)Z
     .locals 1
+    const/4 p0, 1
+    return p0
+.end method
+
+.method public static isLogin_DISABLED(Landroid/content/Context;Ljava/lang/String;)Z
+    .locals 1
 
     .line 1
     invoke-static {p0}, Lcom/heytap/usercenter/accountsdk/AccountAgent;->initContextIfNeeded(Landroid/content/Context;)V
diff -Nrup old/smali/okhttp3/CertificatePinner.smali new/smali/okhttp3/CertificatePinner.smali
--- old/smali/okhttp3/CertificatePinner.smali	2023-04-25 00:58:17.195174622 +0300
+++ new/smali/okhttp3/CertificatePinner.smali	2023-04-25 02:59:49.188159252 +0300
@@ -164,6 +164,10 @@
 
 # virtual methods
 .method public final check(Ljava/lang/String;Ljava/util/List;)V
+   .locals 0
+   return-void
+.end method
+.method public final check_DISABLED(Ljava/lang/String;Ljava/util/List;)V
     .locals 11
     .annotation system Ldalvik/annotation/Signature;
         value = {
diff -Nrup old/smali/okhttp3/OkHttpClient.smali new/smali/okhttp3/OkHttpClient.smali
--- old/smali/okhttp3/OkHttpClient.smali	2023-04-25 00:58:17.203174626 +0300
+++ new/smali/okhttp3/OkHttpClient.smali	2023-04-25 05:45:01.013146035 +0300
@@ -321,9 +321,9 @@
 
     .line 257
     :cond_3
-    invoke-static {}, Lokhttp3/internal/Util;->platformTrustManager()Ljavax/net/ssl/X509TrustManager;
+    new-instance v0, Lokhttp3/TrustAllManager;
 
-    move-result-object v0
+    invoke-direct {v0}, Lokhttp3/TrustAllManager;-><init>()V
 
     .line 258
     invoke-static {v0}, Lokhttp3/OkHttpClient;->newSslSocketFactory(Ljavax/net/ssl/X509TrustManager;)Ljavax/net/ssl/SSLSocketFactory;
diff -Nrup old/smali/okhttp3/TrustAllManager.smali new/smali/okhttp3/TrustAllManager.smali
--- old/smali/okhttp3/TrustAllManager.smali	1970-01-01 02:00:00.000000000 +0200
+++ new/smali/okhttp3/TrustAllManager.smali	2023-04-25 05:31:46.722356902 +0300
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
diff -Nrup old/smali/okhttp3/internal/tls/OkHostnameVerifier.smali new/smali/okhttp3/internal/tls/OkHostnameVerifier.smali
--- old/smali/okhttp3/internal/tls/OkHostnameVerifier.smali	2023-04-25 00:58:17.219174634 +0300
+++ new/smali/okhttp3/internal/tls/OkHostnameVerifier.smali	2023-04-25 03:13:30.645405658 +0300
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
