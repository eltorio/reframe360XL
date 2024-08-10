# Reframe360 XL

This plugin is an extension of the excellent Reframe360 (<http://reframe360.com/>) plugin by Stefan Sietzen.  When Stefan discontinued the project and released the source code, I got to work to add features and fix bugs and it became Reframe360 XL.  
XL is used to point out that new features were put in place and is also a nudge to the excellent SkaterXL game.

## Table of Contents

- [Reframe360 XL](#reframe360-xl)
  - [Table of Contents](#table-of-contents)
  - [New Features and Bug Fixes](#new-features-and-bug-fixes)
  - [Requirements](#requirements)
  - [GoPro Max import](#gopro-max-import)
  - [Building on MacOS (Intel and Apple Silicon)](#building-on-macos-intel-and-apple-silicon)
  - [Building on Windows 10](#building-on-windows-10)
  - [Building on Linux](#building-on-linux)
  - [Binary for MacOS](#binary-for-macos)
  - [Binary for Windows](#binary-for-windows)
  - [Binary for Linux 64](#binary-for-linux-64)
  - [Trying with Blackmagic DaVinci Resolve 19 studio with standard equirectangular 360 movies](#trying-with-blackmagic-davinci-resolve-19-studio-with-standard-equirectangular-360-movies)
  - [Using 360.sh for easy GoPro Max Video Processing with Reframe360 XL](#using-360sh-for-easy-gopro-max-video-processing-with-reframe360-xl)
  - [Manual method with Blackmagic DaVinci Resolve 19 studio and GoPro Max .360 files](#manual-method-with-blackmagic-davinci-resolve-19-studio-and-gopro-max-360-files)
    - [First divide the .360 files in two movies](#first-divide-the-360-files-in-two-movies)
    - [Second import them in a timeline](#second-import-them-in-a-timeline)
    - [Third create a compound clip and a new timeline](#third-create-a-compound-clip-and-a-new-timeline)
    - [Finally apply the filter](#finally-apply-the-filter)
  - [Sample DaVinci Resolve 17.2 studio project](#sample-davinci-resolve-172-studio-project)
  - [Troubleshooting](#troubleshooting)
  - [Contributing](#contributing)
  - [License](#license)

## New Features and Bug Fixes

- Support GoPro Max pseudo Equiangular cubemap files
- Support Youtube Equiangular cubemap files
- New animation curves implemented (Sine, Expo, Circular)
- Apply animation curves to main camera parameters
- Fix black dot in center of output
- Update to latest libraries and Resolve 19

## Requirements

- FFmpeg must be installed on your system
- Bash shell (standard on MacOS and Linux)

## GoPro Max import

If you own a GoPro Max I wrote two "proof of concept".  
For converting the native .360 files into a standard equirectangular clip with FFmpeg I wrote a filter, see <https://github.com/eltorio/FFmpeg>  (I already made a pull request on the main FFmpeg repository).  
For dealing -almost- directly in DaVinci Resolve 17 studio I wrote an openFX plugin, see <https://github.com/eltorio/MaxToEquirectPlugin>

## Building on MacOS (Intel and Apple Silicon)

- Build tested on MacOS 11.2.3 / XCode 12.4
- Build also tested on MacOS 15.0 beta 6 / XCode 16.0 beta 6
- Install latest XCode from Apple App store
- Install Blackmagic DaVinci Resolve from Blackmagic website (studio version)
- clone glm repository <https://github.com/bclarksoftware/glm.git>
- clone this repository
- and build

```bash
git clone https://github.com/bclarksoftware/glm.git
git clone https://github.com/eltorio/reframe360XL.git
cd reframe360XL
#if you have an Apple Distribution certificate
DEV_IDENTITY="Apple Distribution: YOUR NAME (ID)" make zip clean
#if you have an Apple Developer certificate
make zip clean
#Alternatively you can also install it system wide
DEV_IDENTITY="Apple Distribution: YOUR NAME (ID)" make zip root-install clean
```

The plugin is now available in the root directory it is named Reframe360.ofx.bundle  
You can install it in /Library/OFX/Plugins/ or ~/Library/OFX/Plugins/

## Building on Windows 10

- Build tested with VS2019 community edition and CUDA Toolkit 11.2
- You need to have python installed and working for generating OpenCL and Metal embedded kernel source code
- If you have a different CUDA Toolkit version open the vcxproj file with a text editor, search for 'CUDA 11.2' string and correct it

## Building on Linux

- Resolve only works with x86_64  
- Build tested with Ubuntu 20.04.2 / NVidia Cuda 11.3

## Binary for MacOS

- install [bundle](https://github.com/eltorio/reframe360XL/blob/master/Reframe360.ofx.bundle.zip?raw=true)
- uncompress it and puts it to /Library/OFX/Plugins (create the directory if it does not exist)
- Metal and OpenCL are tested
- Note that on recent MacOS versions you need to allow the plugin with this command in a terminal
  
```bash
sudo xattr -r -d com.apple.quarantine /Library/OFX/Plugins/Reframe360.ofx.bundle
```

## Binary for Windows

- install [bundle](https://github.com/eltorio/reframe360XL/blob/master/Reframe360.ofx.bundle.zip?raw=true)
- uncompress it and puts it to C:\Program Files\Common Files\OFX\Plugins\
- only CUDA is tested (OpenCL seems not working with NVidia drivers >= v465)

## Binary for Linux 64

- install [bundle](https://github.com/eltorio/reframe360XL/blob/master/Reframe360.ofx.bundle.zip?raw=true)
- uncompress and put the bundle in /usr/OFX/Plugins/
- the 3 architectures are bundled in the [same «universal» plugin](https://github.com/eltorio/reframe360XL/blob/master/Reframe360.ofx.bundle.zip?raw=true)
- only CUDA is tested (OpenCL seems not working with NVidia drivers >= v465)

## Trying with Blackmagic DaVinci Resolve 19 studio with standard equirectangular 360 movies

- If you have an equirectangular movie just import it in the timeline  
- Apply the Reframe360 XL filter
- Choose Equirectangular as the input format (default)
- Reframe

## Using 360.sh for easy GoPro Max Video Processing with Reframe360 XL

The `360.sh` script is a powerful tool designed to simplify the process of preparing GoPro Max 360 videos for use with Reframe360 XL in DaVinci Resolve. It provides functions to extract front and rear videos from GoPro Max .360 files, as well as to create merged videos ready for editing. This script automates many of the manual steps previously required, significantly streamlining your workflow.  

The `360.sh` script provides several functions to help process GoPro Max 360 videos for use with Reframe360 XL in DaVinci Resolve. Here's how to use these functions in a MacOS or Linux terminal:

1. First, make sure the `360.sh` script is in your current directory or in your system's PATH.

2. Source the script in your terminal:

   ```bash
   source 360.sh
   ```

3. Now you can use the following functions:

   - To create a front video:

     ```bash
     360_create_front_video_with_path "input.360" "output_front.mov"
     ```

   - To create a rear video:

     ```bash
     360_create_rear_video_with_path "input.360" "output_rear.mov"
     ```

   - To create a merged video ready for use in DaVinci Resolve:

     ```bash
     360_create_merged_video_with_path "input.360" "output_merged.mov"
     ```

   - To create both front and rear videos in one command:

     ```bash
     360_create_front_and_rear_videos "input.360"
     ```

     This will create `input_front.mov` and `input_rear.mov` in the same directory as the input file.

4. The merged video created by `360_create_merged_video_with_path` is ready to use with the Reframe360 XL plugin in DaVinci Resolve. Import this video into your project and apply the Reframe360 XL filter, selecting "GoPro Max" as the Input Format.

Note: Make sure you have FFmpeg installed on your system, as these functions rely on it for video processing.

These functions will help you prepare your GoPro Max 360 videos for editing in DaVinci Resolve with Reframe360 XL, streamlining your workflow.

## Manual method with Blackmagic DaVinci Resolve 19 studio and GoPro Max .360 files

### First divide the .360 files in two movies

Today DaVinci Resolve does not support dual video stream in the same MP4 container  
So I divide my .360 in two files with ffmpeg  
Front stream is 0:0 in ffmpeg

```bash
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
```

Rear stream is 0:4 in ffmpeg

```bash
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

```

### Second import them in a timeline

- Import your front and rear movies
- Create a 4096x2688 timeline
- Insert front movie in the V1 channel (and the audio)
- Apply a translation in the inspector y=+672 for putting the front camera on the top
- Insert rear movie in the V2 channel (without the audio because it is the same)
- Apply a translcation of y=-672 for putting it on the bottom

### Third create a compound clip and a new timeline

- Create with this two clips a compound clip
- Create a new timeline 4096x2688 input and UHD or HD output depending on what you want  
- Insert your compound clip in the timeline

### Finally apply the filter

- Apply Reframe360XL
- Use GoPro Max as the Input Format
- Reframe

## Sample DaVinci Resolve 17.2 studio project

- Just restore the project archive Reframe360XL-GoProMax-test.dra from the repository for testing a sample GoPro Max to your Resolve database
- It contains only 2 clips of 15s, they were generated from a still taken from my GoPro Max at take off with my daughter front of the mont Blanc in the Alps.
![Screenshot](https://github.com/eltorio/reframe360XL/blob/master/Reframe360XL-GoProMax-test.dra/MediaFiles/screenshot.png?raw=true)

## Troubleshooting

[Add common issues and their solutions here. For example:]

- **Issue**: Black screen when applying the Reframe360 XL filter.
  **Solution**: Ensure that your input format matches your video type. For GoPro Max videos, select "GoPro Max" as the Input Format.

- **Issue**: FFmpeg command not found when using 360.sh.
  **Solution**: Make sure FFmpeg is installed and in your system PATH.

## Contributing

Contributions to Reframe360 XL are welcome! Here's how you can contribute:

1. Fork the repository
2. Create a new branch (`git checkout -b feature-branch`)
3. Make your changes
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin feature-branch`)
6. Create a new Pull Request

Please ensure your code adheres to the existing style and all tests pass before submitting a pull request.

## License

Reframe360 XL is licensed under the Apache 2.0 License. See [LICENSE](LICENSE) for more information.