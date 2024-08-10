#!/bin/bash
# Copyright (c) 2024  Ronan LE MEILLAT
# License Apache Software License 2.0
# This script is a part of the Reframe360XL project

# Function: 360_check_tools
#
# Description:
# This function checks if the required tools are installed on the system.
#
# Usage: 360_check_tools
#
# Returns:
# This function does not return any value. It exits the script if the required tools are not installed.
#
function 360_check_tools {
    if ! command -v ffmpeg &>/dev/null; then
        echo "ffmpeg could not be found"
        exit
    fi
}

# Function: 360_check_file_extension
#
# Description:
# This function checks if the given file has a .mov extension.
#
# Usage: 360_check_file_extension file
#
# Returns:
# This function does not return any value. It exits the script if the file does not have a .mov extension.
#
function 360_check_file_extension {
    if [[ "$1" != *.mov ]]; then
        echo "The input file must be a .mov file"
        exit
    fi
}


# Function: 360_create_front_or_rear_video_with_path
#
# Description:
# This function creates a front or rear video based on the given mode. It takes three arguments:
#   - mode: The mode of the video (front or rear)
#   - input_video: The path to the input video file
#   - output_video: The path to the output video file
#
# Usage: 360_create_front_or_rear_video_with_path front/rear input_video output_video
#
# Returns:
# This function does not return any value. It creates the front or rear video with the given input and output files.
#
# Dependencies:
# This function depends on the following tools:
#   - check_tools: A function that checks if the required tools are installed
#   - 360_check_file_extension: A function that checks if the output video file has a .mov extension
#
# Notes:
# - The mode argument must be either "front" or "rear".
# - The input video file must exist.
# - The output video file will be created with the same format as the input video file.
# - The function uses ffmpeg to create the video, copying the streams from the input video file.
# - The function adds metadata to the output video file to specify the handlers for each stream.
function 360_create_front_or_rear_video_with_path {
    # arguments:
    # $1: mode (front or rear)
    # $2: input video
    # $3: output video
    check_tools
    # check arguments
    if [ "$#" -ne 3 ]; then
        echo "Usage: 360_create_front_or_rear_video_with_path front/rear input_video output_video"
        return
    fi
    check if the mode is front or rear
    if [ "$1" != "front" ] && [ "$1" != "rear" ]; then
        echo "The mode must be front or rear"
        return
    fi

    echo "Creating the $1 video with $2 ..."
    if [ "$1" = "front" ]; then
        _STREAM="0:0"
    else
        _STREAM="0:4"
    fi
    #check if the input video exists
    if [ ! -f "$2" ]; then
        echo "The input video does not exist"
        return
    fi

    # check if the output video is a .mov file
    360_check_file_extension "$3"

    # create the video
    FILE="$2"
    echo "Creating the $1 video with $FILE ..."
    ffmpeg -y -i "$FILE" \
        -copy_unknown -map_metadata 0 \
        -map $_STREAM \
        -map 0:1 \
        -map 0:2 -tag:d:0 'tmcd' \
        -map 0:3 -tag:d:1 'gpmd' \
        -map 0:5 \
        -metadata:s:0 handler='GoPro H.265' \
        -metadata:s:1 handler='GoPro AAC' \
        -metadata:s:d:0 handler='GoPro TCD' \
        -metadata:s:d:1 handler='GoPro MET' \
        -metadata:s:4 handler='GoPro AMB' \
        -c copy "$3"
}



# Function: 360_create_front_video_with_path
#
# Description: This function creates a front video using the input video and saves it to the output video path.
#
# Parameters:
#   - input_video: The path of the input video.
#   - output_video: The path where the output video will be saved.
#
# Usage: 360_create_front_video_with_path input_video output_video
#
# Returns: None
#
# Example:
#   360_create_front_video_with_path "/path/to/input_video.mp4" "/path/to/output_video.mp4"
#
function 360_create_front_video_with_path {
    if [ "$#" -ne 2 ]; then
        echo "Usage: 360_create_front_video_with_path input_video output_video"
        return
    fi
    360_create_front_or_rear_video_with_path "front" "$1" "$2"
}




# Function: 360_create_rear_video_with_path
#
# Description: Creates a rear video with the given input video and output video paths.
#
# Parameters:
#   - input_video: The path of the input video.
#   - output_video: The path of the output video.
#
# Usage: 360_create_rear_video_with_path input_video output_video
#
# Returns: None
#
# Example:
#   360_create_rear_video_with_path "input.mp4" "output.mp4"
#
function 360_create_rear_video_with_path {
    if [ "$#" -ne 2 ]; then
        echo "Usage: 360_create_rear_video_with_path input_video output_video"
        return
    fi
    360_create_front_or_rear_video_with_path "rear" "$1" "$2"
}

# Function: 360_create_merged_video_with_path
#
# Description: This function creates a merged video with the given 360 video path.
# this merged video can be used in Blackmagic DaVinci Resolve with Reframe360XL plugin.
#
# Parameters:
#   - 360_video: The path of the 369° video.
#   - output_video: The path of the output video.
#
# Usage: 360_create_merged_video_with_path 360_video output_video
#
# Returns: None
#
function 360_create_merged_video_with_path {
    # use hevc_videotoolbox if system is macOS
    if [ "$(uname)" = "Darwin" ]; then
        CODEC="hevc_videotoolbox"
        echo "Using hevc_videotoolbox codec"
    else
        CODEC="hevc"
    fi
    
    if [ "$#" -ne 2 ]; then
        echo "Usage: 360_create_merged_video_with_path 360_video output_video"
        return
    fi
    check_tools
    if [ ! -f "$1" ]; then
        echo "The input video does not exist"
        return
    fi
    360_check_file_extension "$2"
    echo "Creating the merged video with $1 ..."
    FRONT=$(mktemp).mov
    REAR=$(mktemp).mov
    360_create_front_video_with_path "$1" "$FRONT"
    360_create_rear_video_with_path "$1" "$REAR"
    ffmpeg -i "$FRONT" -i "$REAR" \
        -filter_complex "[0:v][1:v]vstack=inputs=2[v]" -map "[v]" \
        -map 0:1 \
        -map 0:2 \
        -map 0:3 \
        -map 0:4 \
        -metadata:s:0 handler='GoPro H.265' \
        -metadata:s:1 handler='GoPro AAC' \
        -metadata:s:d:0 handler='GoPro TCD' \
        -metadata:s:d:1 handler='GoPro MET' \
        -metadata:s:4 handler='GoPro AMB' \
        -c:v $CODEC -profile:v main -b:v 30000k -tag:v hvc1 \
        -c:a copy -c:s copy \
        "$2"
    rm "$FRONT" "$REAR" 

}

# Function: 360_create_front_and_rear_videos
#
# Description: This function creates the front and rear videos from the given 360 video.
#
# Parameters:
#   - 360_video: The path of the 360 video.
#
# Usage: 360_create_front_and_rear_videos 360_video
#
# Returns: None
#
function 360_create_front_and_rear_videos {
    if [ "$#" -ne 1 ]; then
        echo "Usage: 360_create_front_and_rear_videos 360_video"
        return
    fi
    check_tools
    if [ ! -f "$1" ]; then
        echo "The input video does not exist"
        return
    fi
    FILEPATH_WITHOUT_EXTENSION=$(dirname "$1")/$(basename "$1" .${1##*.})
    FRONT="${FILEPATH_WITHOUT_EXTENSION}_front.mov"
    REAR="${FILEPATH_WITHOUT_EXTENSION}_rear.mov"
    360_create_front_video_with_path "$1" "$FRONT"
    360_create_rear_video_with_path "$1" "$REAR"
    echo "Front video: $FRONT"
    echo "Rear video: $REAR"
}