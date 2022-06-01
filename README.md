# idevicesetnonce
An utility for setting nonce on checkm8-vulnerable devices
## Download
* The latest compiled version of idevicesetnonce can be found [here](https://github.com/Mini-Exploit/idevicesetnonce/releases/latest)
## Usage
```
idevicesetnonce - An utility for setting nonce on checkm8-vulnerable devices
usage: idevicesetnonce <iOS version> <SHSH blob>
    <iOS version>		The iOS version about to restored to
    <SHSH blob>		SHSH blob used for restoring
Version: 0.1
Source code: https://github.com/Mini-Exploit/idevicesetnonce
Report issue: https://github.com/Mini-Exploit/idevicesetnonce/issue
```
Ensure:
1. Your device is in pwned DFU mode with bootrom sigchecks disabled
2. You have a stable internet connection
## Compiling/Building
Open `idevicesetnonce.xcodeproj` then click `Build`
## Dependencies
* [libirecovery](https://github.com/libimobiledevice/libirecovery/)
* [img4tool](http://github.com/tihmstar/img4tool)
* [libfragmentzip]((https://github.com/tihmstar/libfragmentzip)

**NOTE**: If you just intend to use idevicesetnonce (not to compile and build) and you don't want to install the requirements, you can place `libimg4tool.0.dylib`, `libfragmentzip.dylib` and `libirecovery-1.0.3.dylib` to `/usr/local/lib` instead
 
## Coming soon
* No longer need dependencies (use static libraries instead of dynamic libraries)
