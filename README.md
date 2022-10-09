# adb.sh
\<working in progress...>

In a nutshell, adb.sh is a shell script that extends android adb functionality. The purpose of this script is to provide shortcuts to make the interaction with an android device more effective.

Assuming the user knows [how Android adb works](https://developer.android.com/studio/command-line/adb), the script 
**adb.sh** will provide Linux terminal shortcuts with Double-\<TAB\> (**\<TAB\> \<TAB\>**) for the following operations:

* **init** : automatically install **adb** and **fastboot** binary for you
* **udev** : automatically check the connected USB devices, create udev rules, and insert them into */etc/udev/rules.d/51-android.rules* file, then reload the rules
* **devices**: print a text table to list connected android devices
* **shell**: shortcut of **adb -s \<dsn\> shell** -- the beauty is you don't have to enter the **-s \<dsn\>** yourself, the auto-complete feature, \<tab\>\<tab\>, will find it for you
* **logs** : shortcut of **adb -s \<dsn\> logcat** 
* **screen_shot**: take a screenshot, save it in the local file system
* **getprop**: shortcut of **adb -s \<dsn\> shell getprop**, the property file will be saved as text file in local file system

## Install
There is no actual "install" for this tool set. 

Download it as a zip file, unzip it and add the local file location to your $PATH variable and you are good to go. The only trick is to enable <TAB> completion: you need to add the following lines in your $HOME/.bashrc file

```shell
adbsh_home="$HOME/adb.sh/"
export PATH=$PATH:$adbsh_home
source $adbsh_home/_adbsh_complete
```

## Screen Shots 
### adb.sh init
![adb.sh init terminal output](./images/adb-init.png "adb.sh init")

### adb.sh udev
![adb.sh udev terminal output](./images/adb-udev.png "adb.sh udev")


![adb.sh udev terminal output](./images/adb-udev.rules.before.and.after.png "adb.sh udev")

### adb.sh devices
![adb.sh devices terminal output](./images/adb-devices.png "adb.sh devices")

### adb.sh shell
![adb.sh shell terminal output](./images/adb-shell.png "adb.sh shell")

### adb.sh screen_shot
![adb.sh screen_shot output](./images/adb-screen_shot.png "adb.sh screen_shot")

  ### adb.sh getprop
![adb.sh getprop output](./images/adb-getprop.png "adb.sh getprop")
