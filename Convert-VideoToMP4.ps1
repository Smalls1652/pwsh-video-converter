[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Position = 0, Mandatory)]
    [Parameter(ParameterSetName = "Default")]
    [Parameter(ParameterSetName = "DefaultAndSubtitles")]
    [string[]]$VideoFile,
    [Parameter(Position = 1, Mandatory)]
    [Parameter(ParameterSetName = "Default")]
    [Parameter(ParameterSetName = "DefaultAndSubtitles")]
    [string]$OutputDir,
    [Parameter(Position = 2)]
    [Parameter(ParameterSetName = "Default")]
    [Parameter(ParameterSetName = "DefaultAndSubtitles")]
    [int]$VideoStream = 0,
    [Parameter(Position = 3)]
    [Parameter(ParameterSetName = "Default")]
    [Parameter(ParameterSetName = "DefaultAndSubtitles")]
    [int]$AudioStream = 0,
    [Parameter(Position = 4)]
    [Parameter(ParameterSetName = "DefaultAndSubtitles")]
    [int]$SubtitleStream
)

process {
    foreach ($videoFileItem in $VideoFile) {
        $videoFilePath = (Resolve-Path -Path $videoFileItem -ErrorAction "Stop").Path
        $outputDirPath = (Resolve-Path -Path $OutputDir -ErrorAction "Stop").Path

        $videoFileItem = Get-Item -Path $videoFilePath
        $outputDirItem = Get-Item -Path $outputDirPath

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

        $outputFilePath = Join-Path -Path $outputDirItem.FullName -ChildPath "$($videoFileItem.BaseName).mp4"

        $ffmpegArgs = $null
        switch ($PSCmdlet.ParameterSetName) {
            "DefaultAndSubtitles" {
                Write-Verbose "Subtitles will be burned into the video stream."
                $ffmpegArgs = @(
                    "-i `"$($videoFileItem.FullName)`"",
                    "-filter_complex `"[$($VideoStream):v:0][$($SubtitleStream):s:0]overlay[v]`"",
                    "-map `"[v]`"",
                    "-map $($AudioStream):a:0",
                    "-c:v libx265",
                    "-preset fast",
                    "-crf 16",
                    "-profile:v main10",
                    "-c:a libfdk_aac",
                    "-b:a 640k",
                    "-tag:v hvc1",
                    "`"$($outputFilePath)`""
                )
                break
            }

            Default {
                Write-Verbose "Subtitles will not be processed."
                $ffmpegArgs = @(
                    "-i `"$($videoFileItem.FullName)`"",
                    "-map $($VideoStream):v:0",
                    "-map $($AudioStream):a:0",
                    "-c:v libx265",
                    "-preset fast",
                    "-crf 16",
                    "-profile:v main10",
                    "-c:a libfdk_aac",
                    "-b:a 640k",
                    "-tag:v hvc1",
                    "`"$($outputFilePath)`""
                )
                break
            }
        }

        $ffmpegSplat = @{
            "FilePath"     = "ffmpeg";
            "ArgumentList" = $ffmpegArgs;
            "Wait"         = $true;
            "NoNewWindow"  = $true;
        }


        if ($PSCmdlet.ShouldProcess("ffmpeg", "$($ffmpegArgs -join " ")")) {
            Start-Process @ffmpegSplat
        }
    }
}