# Kaggle FFmpeg

An FFmpeg deb package that support NVENC, and can be used for hardware accelerated video encoding on Kaggle. [deb package source](http://lliurex.net/bionic/pool/universe/f/ffmpeg/ffmpeg_3.4.2-2_amd64.deb).
## Kaggle Setup

    !rm /opt/conda/bin/ffmpeg
    !git clone https://github.com/YousufSSyed/Kaggle-FFmpeg.git
    !dkpg -i "./Kaggle-FFmpeg/KaggleFFmpeg.deb"
## Video Encoding example
Hardware accelerated encoding can be done with either the h264_nvenc or hevc_nvenc encoders.

    ffmpeg -hwaccel cuvid -i <input video> -c:v hevc_nvenc <output video>
