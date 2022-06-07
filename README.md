# idevicesetnonce
An utility for setting nonce on checkm8-vulnerable devices
## Download
The statically compiled version of idevicesetnonce can be found [here](https://github.com/Mini-Exploit/idevicesetnonce/releases/latest)
## Usage
```
idevicesetnonce - An utility for setting nonce on checkm8-vulnerable devices
Statically compiled: yes
usage: idevicesetnonce <iOS version> <SHSH blob> [-d]
    <iOS version>			Target iOS version to downgrade to
    <SHSH blob>			SHSH blob used for restoring
    -d			Print more information during process
Source code: https://github.com/Mini-Exploit/idevicesetnonce
Report issue: https://github.com/Mini-Exploit/idevicesetnonce/issue
```
Ensure:
1. Your device is in pwned DFU mode with bootrom sigchecks disabled
2. You have a stable internet connection
## Compiling/Building
Requirements for compiling:
* [libirecovery](https://github.com/libimobiledevice/libirecovery)
* [img4tool](http://github.com/tihmstar/img4tool)
* [libfragmentzip](https://github.com/tihmstar/libfragmentzip)

Then, just open `idevicesetnonce.xcodeproj` then click `Build`
**NOTE**: You cannot compile idevicesetnonce statically from the source
 
## Credits
* [kairos](https://github.com/dayt0n/kairos)
* [api.m1sta.xyz](api.m1sta.xyz)
* [api.ipsw.me](api.ipsw.me)

