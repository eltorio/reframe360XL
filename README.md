# Reframe360 XL

This plugin is an extension of the excellent Reframe360 (http://reframe360.com/) plugin by Stefan Sietzen.  When Stefan discontinued the project and released the source code, I got to work to add features and fix bugs and it became Reframe360 XL.  XL is used to point out that new features were put in place and is also a nudge to the excellent SkaterXL game.

New features and bug fixes:
- Support GoPro Max pseudo Equiangular cubemap files
- Support Youtube Equiangular cubemap files
- New animation curves implemented (Sine, Expo, Circular)
- Apply animation curves to main camera parameters
- Fix black dot in center of output
- Update to latest libraries and Resolve 17

Enjoy!

# GoPro Max import
If you own a GoPro Max I wrote two "proof of concept".  
For converting the native .360 files into a standard equirectangular clip with FFmpeg I wrote a filter, see https://github.com/eltorio/FFmpeg  (I already made a pull request on the main FFmpeg repository).  
For dealing -almost- directly in DaVinci Resolve 17 studio I wrote an openFX plugin, see https://github.com/eltorio/MaxToEquirectPlugin 

# Building on MacOS (Intel and Apple Silicon)
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

# Building on Windows 10
* Build tested with VS2019 community edition and CUDA Toolkit 11.2


# Binary for MacOS
* install [bundle](https://github.com/eltorio/reframe360XL/blob/master/Reframe360.ofx.bundle.zip?raw=true)
* uncompress it and puts it to /Library/OFX/Plugins
* Metal and OpenCL are tested

# Binary for Windows
* install [bundle](https://github.com/eltorio/reframe360XL/blob/master/Reframe360.ofx.bundle.zip?raw=true)
* uncompress it and puts it to C:\Program Files\Common Files\OFX\Plugins\
* only CUDA is tested

# Binary for Linux 64
* install [bundle](https://github.com/eltorio/reframe360XL/blob/master/Reframe360.ofx.bundle.zip?raw=true)
* uncompress and put the bundle in /usr/OFX/Plugins/
* the 3 architectures are bundled in the [same «universal» plugin](https://github.com/eltorio/reframe360XL/blob/master/Reframe360.ofx.bundle.zip?raw=true)
* everything builds correctly but I do not have a working Resolve for testing under Linux

# Trying with DaVinci Resolve 17.2 studio with standard equirectangular 360 movies
* If you have an equirectangular movie just import it in the timeline  
* Apply the Reframe360 XL filter
* Choose Equirectangular as the input format (default)
* Reframe

# Trying with DaVinci Resolve 17.2 studio and GoPro Max .360 files
## First divide the .360 files in two movies
Today DaVinci Resolve does not support dual video stream in the same MP4 container  
So I divide my .360 in two files with ffmpeg  
Front stream is 0:0 in ffmpeg
````bash
FILE=in.360
ffmpeg -y -i "$FILE" \
    -copy_unknown -map_metadata 0 \
    -map 0:0 \
    -map 0:1 \
    -map 0:2 -tag:d:0 'tmcd' \
    -map 0:3 -tag:d:1 'gpmd' \
    -map 0:5 \
    -metadata:s:0 handler='GoPro H.265' \
    -metadata:s:1 handler='GoPro AAC' \
    -metadata:s:d:0 handler='GoPro TCD' \
    -metadata:s:d:1 handler='GoPro MET' \
    -metadata:s:4 handler='GoPro AMB' \
    -c copy ~/Desktop/temp360/out-p1.mov
````
Rear stream is 0:4 in ffmpeg
````bash
FILE=in.360
ffmpeg -y -i "$FILE" \
    -copy_unknown -map_metadata 0 \
    -map 0:4 \
    -map 0:1 \
    -map 0:2 -tag:d:0 'tmcd' \
    -map 0:3 -tag:d:1 'gpmd' \
    -map 0:5 \
    -metadata:s:0 handler='GoPro H.265' \
    -metadata:s:1 handler='GoPro AAC' \
    -metadata:s:d:0 handler='GoPro TCD' \
    -metadata:s:d:1 handler='GoPro MET' \
    -metadata:s:4 handler='GoPro AMB' \
    -c copy ~/Desktop/temp360/out-p2.mov

````
## Second import them in a timeline
* Import your front and rear movies
* Create a 4096x2688 timeline
* Insert front movie in the V1 channel (and the audio)
* Apply a translation in the inspector y=+672 for putting the front camera on the top
* Insert rear movie in the V2 channel (without the audio because it is the same)
* Apply a translcation of y=-672 for putting it on the bottom
## Third create a compound clip and a new timeline
* Create with this two clips a compound clip
* Create a new timeline 4096x2688 input and UHD or HD output depending on what you want  
* Insert your compound clip in the timeline
## Finally apply the filter
* Apply Reframe360XL
* Use GoPro Max as the Input Format
* Reframe

# Sample DaVinci Resolve 17.2 studio project
* Just restore the project archive Reframe360XL-GoProMax-test.dra from the repository for testing a sample GoPro Max to your Resolve database
* It contains only 2 clips of 15s, they were generated from a still taken from my GoPro Max at take off with my daughter front of the mont Blanc in the Alps.
![Screenshot](https://github.com/eltorio/reframe360XL/blob/master/Reframe360XL-GoProMax-test.dra/MediaFiles/screenshot.png?raw=true)
