## [deeptesting-junk.pl](deeptesting-junk.pl)

# WARNING: Since May 26-31 2023, this does not seem to work anymore

If you tried to use Realme's "deep testing" apk from [here](https://c.realme.com/in/post-details/1591008567903752192)
and got that nasty "This phone model does not support deep testing." screen,
this [script](deeptesting-junk.pl) may help you bypass it.

Run it like this, replacing the `HHH...` with the serial number and the `DDD...`
with IMEI 1 (you can get them both from Settings/About Device/Status):
```
perl deeptesting-junk.pl pcb 0xHHHHHHHH imei DDDDDDDDDDDDDDD cmd applyLkUnlock
```
**Keep the `0x` at the start of the serial number, it's not a typo!**\
Also notice that --despite the `pcb` name-- it really is the serial number, not the
pcb number from the engineermode app! [^1]

**Do NOT edit the script to change the `model` or `otaVersion` to the ones from your phone**; that will defeat the very purpose of this script: namely, to submit the unlock request using *your* serial + imei and a *supported* phone model.

If the answer is `{"resultCode":0,"msg":"SUCCESS"}`, continue with
```
perl deeptesting-junk.pl pcb 0xHHHHHHHH imei DDDDDDDDDDDDDDD cmd checkApproveResult
```
If the answer is somethink like
```
{"resultCode":0,"msg":"SUCCESS","data":{"unlockCode":"0345af...lots of hexdigits"}}
```
(**without any warnings**) then try running again the deeptesting app on the phone.

That should now work as described in their tutorials, and the app will reboot the phone
into fastboot/bootloader mode from where you could unlock the bootloader from
your PC with `fastboot flashing unlock`.

Before running the app, you could also try the script with the actual model and
firmware version sent by the app, e.g.:
```
perl deeptesting-junk.pl pcb 0xHHHHHHHH imei DDDDDDDDDDDDDDD cmd checkApproveResult \
       model RMX3474EEA otaVersion RMX3474_XX.L.XX_XXXX_YYYYMMDDHHMM
```

This worked for me, at some point in February 2023, on a Realme 9 5G RMX3474, the
Android 12 GDPR variant of the firmware.

-----

If instead of that all you get is:
```
{"resultCode":-1006,"msg":"已成功提交审核，正在审核..."}
```
(even when retrying the `checkApproveResult` after a couple of minutes), that means
that either their server doesn't work, or they don't accept your serial number or IMEI.

In that case (or if the deeptesting app doesn't work, despite a succesful answer) please
open an issue, including the output of:
```
adb shell pm has-feature oppo.version.exp
adb shell getprop ro.product.name
adb shell getprop ro.product.model
adb shell getprop ro.build.version.ota
```

I cannot guarantee that that will help, but there still are some leads which could be
investigated.

-----

The `deeptesting-junk.pl` script does nothing else than simulate the https requests
performed by the deeptesting app to their `lkf.realmemobile.com` server; it does not
save or send any data anywhere else.

On a debian-like linux system, use `apt-get install libwww-perl libcrypt-rijndael-perl`
to install the modules required by this script.

On windows, the [Strawberry Perl](https://strawberryperl.com/) distribution includes
those modules by default; to prevent the windows console from mangling the output, set
its code page to utf-8 with `chcp 65001` before running the script.

[^1]: The app is getting that value from the [`/proc/oplusVersion/serialID`][serial_id] file. The serial number should be an 8-digit hex number; if the serial number has a different format, then this script will probably NOT work, and you will get the -1006 "please wait till the hell freezes over" result code.

[serial_id]: https://github.com/realme-kernel-opensource/realme_9pro-5G_9-5G_V25_Q5-AndroidT-vendor-source/blob/9b580d19cd823d93177691661bba365faba23096/vendor/oplus/kernel/system/oplus_project/qcom/oplus_project.c#L362
