# PowerShell wrapper script MP4 video conversions through ffmpeg

This is a script I have been working on for automating my video conversions to the `mp4` container through `ffmpeg`. This is really just a personal script I started creating since it can be cumbersome to remember all of the individual `ffmpeg` arguments. This helps me batch multiple encodes through a scripting language I know best: PowerShell.

## Things to note

- `ffmpeg` will need to have `libx265` and `libfdk_aac` enabled during build for this script to work. It's what I'm using to convert videos from one container to a `mp4` container.
- Using the `-SubtitleStream` parameter is currently set to **burn-in** the subtitles. The subtitles I'm working with aren't text-based subtitles, but rather image-based. I'll probably have a need to rework that to support text-based subtitles.
- This can be ran on any platform that supports PowerShell 7.0 and `ffmpeg`. I've been making this on macOS.

## Sample Usage

### Usage 01

- Convert the first video stream and audio stream
- CRF value is set to 16
- Encoding preset is set to fast

```powershell
./Convert-VideoToMP4.ps1 -VideoFile "./path/to/video" -OutputDir "./" -VideoStream 0 -AudioStream 0 -VideoConstantRateFactor 16 -VideoEncodingSpeed fast
```

### Usage 02

- Convert the first video stream
- Copy the audio stream
- CRF value is set to 16
- Encoding preset is set to fast

```powershell
./Convert-VideoToMP4.ps1 -VideoFile "./path/to/video" -OutputDir "./" -VideoStream 0 -AudioStream 0 -CopyAudioStream -VideoConstantRateFactor 16 -VideoEncodingSpeed fast
```

### Usage 03

- Convert the first video stream and audio stream
    - The first subtitle stream will also be burned into the video stream
- CRF value is set to 12

```powershell
./Convert-VideoToMP4.ps1 -VideoFile "./path/to/video" -OutputDir "./" -VideoStream 0 -AudioStream 0 -SubtitleStream -VideoConstantRateFactor 12
```

### Usage 04

- Convert the first video stream and audio stream
    - The first subtitle stream will also be burned into the video stream
- CRF value is set to 12

```powershell
./Convert-VideoToMP4.ps1 -VideoFile "./path/to/video" -OutputDir "./" -VideoStream 0 -AudioStream 0 -SubtitleStream 0 -VideoConstantRateFactor 12
```

### Usage 05

- Convert the first video stream and audio stream
    - The first subtitle stream will also be burned into the video stream
    - _Not supplying the `-VideoStream` and `-AudioStream` parameters will imply that the first stream will be used._
- CRF value is set to 12
- Will only encode a 69 seconds of the video starting at the `4 minutes and 20 seconds` timestamp.

```powershell
./Convert-VideoToMP4.ps1 -VideoFile "./path/to/video" -OutputDir "./" -SubtitleStream 0 -VideoConstantRateFactor 12 -TestConversionStartTime "00:04:20" -TestConversionDuration 69
```