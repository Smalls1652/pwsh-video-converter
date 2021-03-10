[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = "Default")]
param(
    [Parameter(Position = 0, Mandatory, ParameterSetName = "Default")]
    [Parameter(Position = 0, Mandatory, ParameterSetName = "BurnInSubtitles")]
    [Parameter(Position = 0, ParameterSetName = "DefaultTestConversion")]
    [Parameter(Position = 0, ParameterSetName = "BurnInSubtitlesTestConversion")]
    [string[]]$VideoFile,
    [Parameter(Position = 1, Mandatory, ParameterSetName = "Default")]
    [Parameter(Position = 1, Mandatory, ParameterSetName = "BurnInSubtitles")]
    [Parameter(Position = 1, ParameterSetName = "DefaultTestConversion")]
    [Parameter(Position = 1, ParameterSetName = "BurnInSubtitlesTestConversion")]
    [string]$OutputDir,
    [Parameter(Position = 2, ParameterSetName = "Default")]
    [Parameter(Position = 2, ParameterSetName = "BurnInSubtitles")]
    [Parameter(Position = 2, ParameterSetName = "DefaultTestConversion")]
    [Parameter(Position = 2, ParameterSetName = "BurnInSubtitlesTestConversion")]
    [int]$VideoStream = 0,
    [Parameter(Position = 3, ParameterSetName = "Default")]
    [Parameter(Position = 3, ParameterSetName = "BurnInSubtitles")]
    [Parameter(Position = 3, ParameterSetName = "DefaultTestConversion")]
    [Parameter(Position = 3, ParameterSetName = "BurnInSubtitlesTestConversion")]
    [int]$AudioStream = 0,
    [Parameter(Position = 4, ParameterSetName = "Default")]
    [Parameter(Position = 4, ParameterSetName = "BurnInSubtitles")]
    [Parameter(Position = 4, ParameterSetName = "DefaultTestConversion")]
    [Parameter(Position = 4, ParameterSetName = "BurnInSubtitlesTestConversion")]
    [switch]$CopyAudioStream,
    [Parameter(Position = 5, ParameterSetName = "Default")]
    [Parameter(Position = 5, ParameterSetName = "BurnInSubtitles")]
    [Parameter(Position = 5, ParameterSetName = "DefaultTestConversion")]
    [Parameter(Position = 5, ParameterSetName = "BurnInSubtitlesTestConversion")]
    [int]$AudioBitrateKb = 640,
    [Parameter(Position = 6, ParameterSetName = "Default")]
    [Parameter(Position = 6, ParameterSetName = "BurnInSubtitles")]
    [Parameter(Position = 6, ParameterSetName = "DefaultTestConversion")]
    [Parameter(Position = 6, ParameterSetName = "BurnInSubtitlesTestConversion")]
    [int]$VideoConstantRateFactor = 16,
    [Parameter(Position = 7, ParameterSetName = "Default")]
    [Parameter(Position = 7, ParameterSetName = "BurnInSubtitles")]
    [Parameter(Position = 7, ParameterSetName = "DefaultTestConversion")]
    [Parameter(Position = 7, ParameterSetName = "BurnInSubtitlesTestConversion")]
    [ValidateSet(
        "ultrafast",
        "superfast",
        "veryfast",
        "faster",
        "fast",
        "medium",
        "slow",
        "slower",
        "veryslow"
    )]
    [string]$VideoEncodingSpeed = "medium",
    [Parameter(Position = 8, ParameterSetName = "BurnInSubtitles")]
    [Parameter(Position = 8, ParameterSetName = "BurnInSubtitlesTestConversion")]
    [int]$SubtitleStream,
    [Parameter(Position = 8, ParameterSetName = "DefaultTestConversion")]
    [Parameter(Position = 9, ParameterSetName = "BurnInSubtitlesTestConversion")]
    [timespan]$TestConversionStartTime,
    [Parameter(Position = 9, ParameterSetName = "Default")]
    [Parameter(Position = 10, ParameterSetName = "BurnInSubtitlesTestConversion")]
    [int]$TestConversionDuration
)

process {
    foreach ($videoFileItem in $VideoFile) { #Process through each input file provided

        #Try to resolve the path of the video file and the output directory. If resolving the path fails, then terminate the script.
        $videoFilePath = (Resolve-Path -Path $videoFileItem -ErrorAction "Stop").Path
        $outputDirPath = (Resolve-Path -Path $OutputDir -ErrorAction "Stop").Path

        #Get the FileInfo and DirectoryInfo objects of the video file and output directory.
        $videoFileItem = Get-Item -Path $videoFilePath
        $outputDirItem = Get-Item -Path $outputDirPath

        #Check to see if the output directory supplied is actually a directory, if it isn't then throw a terminating error.
        switch ($outputDirItem.Attributes -eq [System.IO.FileAttributes]::Directory) {
            $false {
                $PSCmdlet.ThrowTerminatingError(
                    [System.Management.Automation.ErrorRecord]::new(
                        [System.Exception]::new("Output is not a directory."),
                        "OutputDir.IsDirectory",
                        [System.Management.Automation.ErrorCategory]::InvalidType,
                        $outputDirItem
                    )
                )
            }
        }

        #Generate the file name of the output file and join it with the path to the output directory.
        $outputFilePath = Join-Path -Path $outputDirItem.FullName -ChildPath "$($videoFileItem.BaseName).mp4"

        # -- Start building the argument list for 'ffmpeg' --

        #Create a list object and supply the initial arguments to start with.
        $ffmpegArgs = [System.Collections.Generic.List[string]]::new(
            [string[]]@(
                "-hide_banner",
                "-v error",
                "-stats",
                "-i `"$($videoFileItem.FullName)`""
            )
        )

        #Determine if the parameter set is 'BurnInSubtitles' or 'Default'. Then add the necessary arguments to the list.
        switch ($PSCmdlet.ParameterSetName) {
            { $PSItem -in @("BurnInSubtitles", "BurnInSubtitlesTestConversion") } {
                Write-Warning "Subtitles will be burned into the video stream."
                $ffmpegArgs.AddRange(
                    [string[]]@(
                        "-filter_complex `"[$($VideoStream):v:0][$($SubtitleStream):s:0]overlay[v]`"",
                        "-map `"[v]`"",
                        "-c:v libx265",
                        "-preset $($VideoEncodingSpeed)",
                        "-crf $($VideoConstantRateFactor)",
                        "-x265-params log-level=error"
                        #"-profile:v main10"
                    )
                )
                break
            }

            Default {
                Write-Warning "Subtitles will not be processed."
                $ffmpegArgs.AddRange(
                    [string[]]@(
                        "-map $($VideoStream):v:0",
                        "-c:v libx265",
                        "-preset $($VideoEncodingSpeed)",
                        "-crf $($VideoConstantRateFactor)",
                        "-x265-params log-level=error"
                        #"-profile:v main10"
                    )
                )
                break
            }
        }

        #If 'TestConversionStartTime' and 'TestConversionDuration' are supplied, then only encode the specified timeframe.
        switch ($PSCmdlet.ParameterSetName) {
            { $PSItem -in @("DefaultTestConversion", "BurnInSubtitlesTestConversion") } {
                Write-Warning "Conversion will only encode the specified timeframe."
                $ffmpegArgs.AddRange(
                    [string[]]@(
                        "-ss `"$($TestConversionStartTime.ToString())`"",
                        "-t $($TestConversionDuration)"
                    )
                )
                break
            }
        }

        #Determine if the audio stream will be copied or re-encoded if the 'CopyAudioStream' switch parameter is provided.
        switch ($CopyAudioStream) {
            $true {
                Write-Warning "Audio stream will be copied."
                $ffmpegArgs.AddRange(
                    [string[]]@(
                        "-map $($AudioStream):a:0",
                        "-c:a copy"
                    )
                )
                break
            }

            Default {
                Write-Warning "Audio stream will be re-encoded to $($AudioBitrateKb) Kb/s AAC."
                $ffmpegArgs.AddRange(
                    [string[]]@(
                        "-map $($AudioStream):a:0",
                        "-c:a libfdk_aac",
                        "-b:a $($AudioBitrateKb)k"
                    )
                )
                break
            }
        }

        # Add the last arguments to the list.
        $ffmpegArgs.AddRange(
            [string[]]@(
                "-tag:v hvc1",
                "`"$($outputFilePath)`""
            )
        )

        # -- End building the argument list for 'ffmpeg' --

        #Create a hashtable of the parameters to pass to 'Start-Process'
        $ffmpegSplat = @{
            "FilePath"     = "ffmpeg";
            "ArgumentList" = $ffmpegArgs;
            "Wait"         = $true;
            "NoNewWindow"  = $true;
        }

        #Begin the 'ffmpeg' process
        if ($PSCmdlet.ShouldProcess("ffmpeg $($ffmpegArgs -join " ")")) {
            Start-Process @ffmpegSplat
        }
    }
}