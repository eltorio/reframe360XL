# Reframe360 XL

This plugin is an extension of the excellent Reframe360 (http://reframe360.com/) plugin by Stefan Sietzen.  When Stefan discontinued the project and released the source code, I got to work to add features and fix bugs and it became Reframe360 XL.  XL is used to point out that new features were put in place and is also a nudge to the excellent SkaterXL game.

New features and bug fixes:
- New animation curves implemented (Sine, Expo, Circular)
- Apply animation curves to main camera parameters
- Fix black dot in center of output
- Update to latest libraries and Resolve 17

Enjoy!

# GoPro Max import
If you own a GoPro Max I wrote two "proof of concept".  
For converting the native .360 files into a standard equirectangular clip with FFmpeg I wrote a filter, see https://github.com/eltorio/FFmpeg  (I already made a pull request on the main FFmpeg repository).  
For dealing -almost- directly in DaVinci Resolve 17 studio I wrote an openFX plugin, see https://github.com/eltorio/MaxToEquirectPlugin 

# Installation on MacOS (Intel and Apple Silicon)
* Build tested on MacOS 11.2.3 / XCode 12.4
* Install latest XCode from Apple App store
* Install Blackmagic DaVinci Resolve from Blackmagic website (studio version)
* clone glm repository https://github.com/bclarksoftware/glm.git
* clone this repository
* and build

````
cd reframe360XL
make
````

# Binary for MacOS
* install [bundle](https://github.com/eltorio/reframe360XL/blob/master/Reframe360.ofx.bundle.zip?raw=true)
* uncompress it and puts it to /Library/OFX/Plugins

# Binaries for MacOS / Linux 64 / Windows 64
* Windows are coming directly from [Sylvain repository](https://github.com/LRP-sgravel/reframe360XL)
* for Windows put the bundle directory in C:\Program Files\Common Files\OFX\Plugins\
* for Linux put the bundle in /usr/OFX/Plugins/
* the 3 architectures are bundled in the [same «universal» plugin](https://github.com/eltorio/reframe360XL/blob/master/Reframe360.ofx.bundle.zip?raw=true)
