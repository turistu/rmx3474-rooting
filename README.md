### [deeptesting-junk.pl](deeptesting-junk.pl)

If you tried to use Realme's "deep testing" apk from [here](https://c.realme.com/in/post-details/1591008567903752192)
and got that nasty "This phone model does not support deep testing." screen,
this [script](deeptesting-junk.pl) may help you bypass it.

Run it like this, replacing the `HHH...` with the serial number and the `DDD...`
with IMEI 1 (you can get them from Settings/About Device/Status).
```
perl deeptesting-junk.pl pcb 0xHHHHHHHH imei DDDDDDDDDDDDDDD cmd applyLkUnlock
```
**Keep the `0x` before the serial number, it's not a typo!**

Also notice that --despite the `pcb` name-- it really is the serial number, not the
pcb number!

If the answer is `{"resultCode":0,"msg":"SUCCESS"}`, continue with
```
perl deeptesting-junk.pl pcb 0xHHHHHHHH imei DDDDDDDDDDDDDDD cmd checkApproveResult
```
If the answer is somethink like
```
{"resultCode":0,"msg":"SUCCESS","data":{"unlockCode":"0345af...lots of hexdigits"}}
```
then try running again the deeptesting app on the phone.

That should now work as described in their tutorials, and the app will reboot the phone
into fastboot/bootloader mode from where you could unlock the bootloader from
your PC with `fastboot flashing unlock`.

This worked for me, at some point in February 2023, on a Realme 9 5G RMX3474, the
Android 12 EEA/GDPR variant of the firmware.

The `deeptesting-junk.pl` script does nothing else than simulate the https requests
performed by the deeptesting app to their `lkf.realmemobile.com` server; it does not
save or send any data anywhere else.
