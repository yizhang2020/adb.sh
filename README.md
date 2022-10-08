# adb.sh
In a nutshell, adb.sh is a shell script that extends android adb functionality. The purpose of this script is to provide shortcuts to make the interaction
with an android device more effictive.

Assuming the user understands the basic operation of [how Android adb works](https://developer.android.com/studio/command-line/adb), the script 
**adb.sh** will provide a standard Linux terminal shortcuts  with Double-\<TAB\> (**\<TAB\> \<TAB\>**) for the following operations:

* **init** : automatically install **adb** and **fastboot** binary for you
* **udev** : automatically check the connected USB devices, create **udev** rules, insert into **/etc/udev/rules.d/51-android.rules** file, and reload the rules
* **devices**: print a text table to list connected android devices
* **shell**: shortcut of **adb -s \<dsn\> shell** -- the beauty is that you don't have to enter the **-s \<dsn\>** yourself, the <tab><tab> will find it for you
* **logs** : short cut of **adb -s \<dsn\> logcat** 
* **screen_shot**: take a screen shot, save it in local file system

Screen Shots 
### adb.sh init
![adb.sh init terminal output](./images/adb-init.png "adb.sh init")

### adb.sh udev
![adb.sh udev terminal output](./images/adb-udev.png "adb.sh udev")


![adb.sh udev terminal output](./images/adb-udev.rules.before.and.after.png "adb.sh udev")

### adb.sh devices
![adb.sh devices terminal output](./images/adb-devices.png "adb.sh udev")

### adb.sh shell
![adb.sh shell terminal output](./images/adb-shell.png "adb.sh udev")

### adb.sh screen_shot
![adb.sh udev screen_shot output](./images/adb-screen_shot.png "adb.sh udev")
