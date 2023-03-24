#requires -PSEdition Core

<#

.SYNOPSIS

    Adds Rust binaries for a specific target into a zip archive.

.DESCRIPTION

    Adds Rust binaries for a specific target into a zip archive.

    This is meant to be run as part of GitHub Actions so the resulting archive
    can be uploaded into a GitHub release as an artifact.

.PARAMETER Target

    The specific target to get the binary for.

    For example; 'x86_64-apple-darwin, release'

.PARAMETER LogLevel

    Optional log level to use for the script output.

    Valid options; debug, info, information, verbose, warn, warning, err, error

    Defaults to information level logging

.PARAMETER Project

    Optional name of the GitHub project.

    If not provided, the script will determine the project name from the ${env:GITHUB_REPOSITORY} variable if present.

.INPUTS

    * Target architecture
    * Log Level
    * Project name
    * GitHub Actions environment variables

.OUTPUTS

    * An archive is created in the format $PROJECT-$TARGET.zip

.NOTES

    Version: 		0.1
    Author: 		MAHDTech@saltlabs.tech
    Creation Date:	17/06/2020
    Purpose/Change:	Initial script development

.EXAMPLE

    ./archive.ps1 -Target "${{ matrix.target }}"

#>

#################################################
# Parameters
#################################################

[CmdletBinding(

    ConfirmImpact = "Medium",
    DefaultParameterSetName = "DefaultParameterSet",
    HelpURI = "",
    SupportsPaging = $False,
    SupportsShouldProcess = $True,
    PositionalBinding = $False

)]
Param(

    # Parameter: Target
    [Parameter(
        Mandatory = $True,
        HelpMessage = "[MANDATORY]: Sets the Target architecture."
    )]
    [ValidateSet(
        "aarch64-apple-ios",
        "aarch64-fuchsia",
        "aarch64-linux-android",
        "aarch64-pc-windows-msvc",
        "aarch64-unknown-linux-gnu",
        "aarch64-unknown-linux-musl",
        "aarch64-unknown-none",
        "aarch64-unknown-none-softfloat",
        "arm-linux-androideabi",
        "arm-unknown-linux-gnueabi",
        "arm-unknown-linux-gnueabihf",
        "arm-unknown-linux-musleabi",
        "arm-unknown-linux-musleabihf",
        "armebv7r-none-eabi",
        "armebv7r-none-eabihf",
        "armv5te-unknown-linux-gnueabi",
        "armv5te-unknown-linux-musleabi",
        "armv7-linux-androideabi",
        "armv7-unknown-linux-gnueabi",
        "armv7-unknown-linux-gnueabihf",
        "armv7-unknown-linux-musleabi",
        "armv7-unknown-linux-musleabihf",
        "armv7a-none-eabi",
        "armv7r-none-eabi",
        "armv7r-none-eabihf",
        "asmjs-unknown-emscripten",
        "i586-pc-windows-msvc",
        "i586-unknown-linux-gnu",
        "i586-unknown-linux-musl",
        "i686-linux-android",
        "i686-pc-windows-gnu",
        "i686-pc-windows-msvc",
        "i686-unknown-freebsd",
        "i686-unknown-linux-gnu",
        "i686-unknown-linux-musl",
        "mips-unknown-linux-gnu",
        "mips-unknown-linux-musl",
        "mips64-unknown-linux-gnuabi64",
        "mips64-unknown-linux-muslabi64",
        "mips64el-unknown-linux-gnuabi64",
        "mips64el-unknown-linux-muslabi64",
        "mipsel-unknown-linux-gnu",
        "mipsel-unknown-linux-musl",
        "nvptx64-nvidia-cuda",
        "powerpc-unknown-linux-gnu",
        "powerpc64-unknown-linux-gnu",
        "powerpc64le-unknown-linux-gnu",
        "riscv32i-unknown-none-elf",
        "riscv32imac-unknown-none-elf",
        "riscv32imc-unknown-none-elf",
        "riscv64gc-unknown-linux-gnu",
        "riscv64gc-unknown-none-elf",
        "riscv64imac-unknown-none-elf",
        "s390x-unknown-linux-gnu",
        "sparc64-unknown-linux-gnu",
        "sparcv9-sun-solaris",
        "thumbv6m-none-eabi",
        "thumbv7em-none-eabi",
        "thumbv7em-none-eabihf",
        "thumbv7m-none-eabi",
        "thumbv7neon-linux-androideabi",
        "thumbv7neon-unknown-linux-gnueabihf",
        "thumbv8m.base-none-eabi",
        "thumbv8m.main-none-eabi",
        "thumbv8m.main-none-eabihf",
        "wasm32-unknown-emscripten",
        "wasm32-unknown-unknown",
        "wasm32-wasi",
        "x86_64-apple-darwin",
        "x86_64-apple-ios",
        "x86_64-fortanix-unknown-sgx",
        "x86_64-fuchsia",
        "x86_64-linux-android",
        "x86_64-pc-windows-gnu",
        "x86_64-pc-windows-msvc",
        "x86_64-rumprun-netbsd",
        "x86_64-sun-solaris",
        "x86_64-unknown-cloudabi",
        "x86_64-unknown-freebsd",
        "x86_64-unknown-linux-gnu",
        "x86_64-unknown-linux-gnux32",
        "x86_64-unknown-linux-musl",
        "x86_64-unknown-netbsd",
        "x86_64-unknown-redox"
    )]
    [String]
    $Target,

    # Parameter: LogLevel
    [Parameter(
        Mandatory = $False,
        HelpMessage = "[OPTIONAL]: The Log Level for the script. Valid options; Debug, Information, Warning, Error"
    )]
    [ValidateSet(
        "Debug",
        "Verbose",
        "Information",
        "Info",
        "Warning",
        "Warn",
        "Error",
        "Err"
    )]
    [String]
    $LogLevel = "Information",

    # Parameter: Project
    [Parameter(
        Mandatory = $False,
        HelpMessage = "[OPTIONAL]: The name of the GitHub Project."
    )]
    [ValidateNotNullOrEmpty()]
    [String]
    $Project = "Default",

    # Parameter: DieHard
    [Parameter(
        Mandatory = $False,
        HelpMessage = "[OPTIONAL]: A switch to fail early on error."
    )]
    [Switch]
    $DieHard

)

#################################################
# Begin
#################################################

Begin {

    #########################
    # Declarations
    #########################

    If ( $DieHard ) {
        $ErrorActionPreference = "Stop"
    } Else {
        $ErrorActionPreference = "Continue"
    }

    $ProgressPreference = "Continue"
    $ConfirmPreference = "High"

    # Set the Invocation
    $ScriptInvocation = (Get-Variable MyInvocation -Scope Script).Value

    # Get the invocation path (relative to $PWD)
    $ScriptInvocationPath = $ScriptInvocation.InvocationName

    # Full path to the script
    $ScriptPath = $ScriptInvocation.MyCommand.Path

    # Get the directory of the script
    $ScriptDirectory = Split-Path $ScriptPath

    # Name of the script
    $ScriptFileName = $ScriptInvocation.MyCommand.Name

    # Script Version
    $ScriptVersion = "0.1"

    # Set the Script Name so it can be used in logs, matching the filename with no extension
    $ScriptName = [System.IO.Path]::GetFilenameWithoutExtension($ScriptFileName)

    # Decorate the console
    $Host.Ui.RawUI.WindowTitle = "$ScriptName v$ScriptVersion"

    # Initialise an error counter
    $Global:ErrorCount = 0

    #########################
    # Functions
    #########################

    Function Register-Logging {

        <#

        .SYNOPSIS

            Sets the logging level used throughout the script based on a provided parameter.

        #>

        [CmdletBinding()]
        Param()

        Begin {

        }

        Process {

            $ValidLogLevels = @(
                "Debug",
                "Verbose",
                "Information",
                "Info",
                "Warning",
                "Warn",
                "Error",
                "Err"
            )

            If ( $ValidLogLevels -NotContains $LogLevel ) {

                Write-Output "The provided Log Level '$LogLevel' is invalid. Defaulting to a Log Level of 'Information'"
                $LogLevel = "Information"

            }

            # LogLevel is a parameter defined in the Global scope
            Switch ( $LogLevel ) {

                { "Debug" -Contains "$_" } {

                    $Global:DebugPreference = "Continue"
                    $Global:VerbosePreference = "Continue"
                    $Global:InformationPreference = "Continue"
                    $Global:WarningPreference = "Continue"
                    Break

                }

                { "Verbose" -Contains "$_" } {

                    $Global:DebugPreference = "SilentlyContinue"
                    $Global:VerbosePreference = "Continue"
                    $Global:InformationPreference = "Continue"
                    $Global:WarningPreference = "Continue"
                    Break

                }

                { "Information", "Info" -Contains "$_" } {

                    $Global:DebugPreference = "SilentlyContinue"
                    $Global:VerbosePreference = "SilentlyContinue"
                    $Global:InformationPreference = "Continue"
                    $Global:WarningPreference = "Continue"
                    Break

                }

                { "Warning", "Warn" -Contains "$_" } {

                    $Global:DebugPreference = "SilentlyContinue"
                    $Global:VerbosePreference = "SilentlyContinue"
                    $Global:InformationPreference = "SilentlyContinue"
                    $Global:WarningPreference = "Continue"
                    Break

                }

                { "Error", "Err" -Contains "$_" } {

                    $Global:DebugPreference = "SilentlyContinue"
                    $Global:VerbosePreference = "SilentlyContinue"
                    $Global:InformationPreference = "SilentlyContinue"
                    $Global:WarningPreference = "SilentlyContinue"
                    Break

                }

            }

        }

        End {

        }

    }

    Function Get-TimeStamp {

        <#

        .SYNOPSIS

            Returns a date in a format useful for log files

        #>

        Begin {

        }

        Process {

            Return Get-Date -Format "yyyy-MM-dd hh:mm:ss"

        }

        End {

        }

    }

    Function Write-Log {

        <#

        .SYNOPSIS

            Writes to stdout as a method of logging.

        .DESCRIPTION

            Writes to stdout and an optional log file as a method of logging.

        .PARAMETER LogLevel

            Case insensitive log level of the message written to file. Available options are;

                - Debug
                - Verbose
                - Information, Info
                - Warning, Warn
                - Error, Err

        .PARAMETER LogMessage

            Mandatory. The log message to write to the log file.

            Example:
                "This is a log message"

        .PARAMETER LogFile

            Optional. If you also want the log to be written to a log file as well as stdout.

            Example:
                "my-script.log"

        .PARAMETER Fatal

            Switch to indicate if the error is Fatal and the script should stop.

        .INPUTS

            Parameters

        .OUTPUTS

            Messages to stdout
            Log file if enabled

        .NOTES

            Version:        1.0
            Author:         Matthew Duncan
            Creation Date:  02/05/2019
            Purpose/Change: Initial function development

            Version:        1.1
            Author:         Matthew Duncan
            Creation Date:  15/05/2019
            Purpose/Change: Improved error handling

        .EXAMPLE

            Write-Log -LogLevel "Information" -LogMessage "Started $ScriptName"

        .EXAMPLE

            Write-Log -LogLevel "Debug" -LogFile "my-script.log" -LogMessage "This is a debug message"

        .EXAMPLE

            Write-Log -LogLevel "Error" -LogMessage "Fatal Exception $_.Exception" -Fatal

        #>

        [CmdletBinding(

            ConfirmImpact = "Medium",
            DefaultParameterSetName = "DefaultParameterSet",
            HelpURI = "",
            SupportsPaging = $False,
            SupportsShouldProcess = $True,
            PositionalBinding = $False

        )]
        Param (

            # Parameter: LogLevel
            [Parameter(
                Mandatory = $True,
                HelpMessage = "[MANDATORY]: The Log Level to display. Valid options; Debug, Information, Warning, Error"
            )]
            [ValidateNotNullOrEmpty()]
            [ValidateSet(
                "Debug",
                "Verbose",
                "Information",
                "Info",
                "Warning",
                "Warn",
                "Error",
                "Err"
            )]
            [String]
            $LogLevel,

            # Parameter: LogMessage
            [Parameter(
                Mandatory = $True,
                HelpMessage = "[MANDATORY]: The message to write to the log file."
            )]
            [ValidateNotNullOrEmpty()]
            [String]
            $LogMessage,

            # Parameter: LogFile
            [Parameter(
                Mandatory = $False,
                HelpMessage = "[OPTIONAL]: The full path to the Log File to write the message in."
            )]
            [ValidateNotNullOrEmpty()]
            [String]
            $LogFile,

            # Parameter: Fatal
            [Parameter(
                Mandatory = $False,
                HelpMessage = "[MANDATORY]: Switch that indicates the error is Fatal and the script will stop."
            )]
            [Switch]
            $Fatal,

            # Parameter: Fresh
            [Parameter(
                Mandatory = $False,
                HelpMessage = "[OPTIONAL]: Switch that indicates to start a Fresh log file."
            )]
            [Switch]
            $Fresh

        )

        Begin {

            $AddContent = $null

        }

        Process {

            Switch ( $LogLevel ) {

                { "Debug" -Contains "$_" } {

                    $LogFileLevel = "DEBUG"
                    Write-Debug -Message "$(Get-TimeStamp) - $LogMessage"
                    If ( $DebugPreference -eq "SilentlyContinue" ) {
                        $AddContent = $False
                    } Else {
                        $AddContent = $True
                    }

                }

                { "Verbose" -Contains "$_" } {

                    $LogFileLevel = "VERBOSE"
                    Write-Verbose -Message "$(Get-TimeStamp) - $LogMessage"
                    If ( $VerbosePreference -eq "SilentlyContinue" ) {
                        $AddContent = $False
                    } Else {
                        $AddContent = $True
                    }

                }

                { "Information", "Info" -Contains "$_" } {

                    $LogFileLevel = "INFO"
                    Write-Information -Message "$(Get-TimeStamp) - $LogMessage"
                    If ( $InformationPreference -eq "SilentlyContinue" ) {
                        $AddContent = $False
                    } Else {
                        $AddContent = $True
                    }

                }

                { "Warning", "Warn" -Contains "$_" } {

                    $LogFileLevel = "WARNING"
                    Write-Warning -Message "$(Get-TimeStamp) - $LogMessage"
                    If ( $WarningPreference -eq "SilentlyContinue" ) {
                        $AddContent = $False
                    } Else {
                        $AddContent = $True
                    }

                }

                { "Error", "Err" -Contains "$_" } {

                    $LogFileLevel = "ERROR"
                    #Write-Error -Message "$(Get-TimeStamp) - $LogMessage"
                    Write-Warning -Message "$(Get-TimeStamp) - $LogMessage"
                    $AddContent = $True
                    # Increment the error count for DieHard mode.
                    $Global:ErrorCount ++

                }

                Default {

                    $LogFileLevel = "UNKNOWN"
                    Write-Warning -Message "An incorrect Log Level of $LogLevel was provided to the Write-Log function"
                    $AddContent = $True

                }

            }

            # If the LogFile is defined
            if ( $LogFile ) {

                If ( $PScmdlet.ShouldProcess( "$LogFile", "Write message to the Log File" ) ) {

                    # Fresh will always run as the file needs to be started :/
                    If ( $Fresh ) {

                        # Create a fresh log file
                        New-Item -ItemType File -Path "$LogFile" -Force | Out-Null

                    }

                    If ( $AddContent ) {

                        # Append the log file
                        Add-Content -Path "$LogFile" -Value "$(Get-TimeStamp) $LogFileLevel $LogMessage"

                    }

                }

            }

            # If Fatal was provided
            If ( $Fatal ) {

                Throw "Fatal Error. Execution of $ScriptName Halted."

            }


        }

        End {

            $AddContent = $null

        }

    }
    #Export-ModuleMember -Function Write-Log -Alias Log

    Function Add-Archive {

        <#

        .SYNOPSIS

            Adds a file to an existing ZIP archive

        .PARAMETER Archive

            The Archive to add the binaries to.

        .PARAMETER File

            The file to add to the ZIP archive

        .INPUTS

            Parameters

        .OUTPUTS

            Updated ZIP archive

        #>

        [CmdletBinding(

            ConfirmImpact = "Medium",
            DefaultParameterSetName = "DefaultParameterSet",
            HelpURI = "",
            SupportsPaging = $False,
            SupportsShouldProcess = $True,
            PositionalBinding = $False

        )]
        Param (

            # Parameter: Archive
            [Parameter(
                Mandatory = $True,
                HelpMessage = "[MANDATORY]: The ZIP Archive where the file is added to"
            )]
            [ValidateScript( {
                If ( Test-Path -PathType Leaf -Path "$_" ) {
                    $True
                } Else {
                    Throw "The ZIP Archive $_ does not exist"
                }
            } )]
            [String]
            $Archive,

            # Parameter: File
            [Parameter(
                Mandatory = $True,
                HelpMessage = "[MANDATORY]: The File to add to the ZIP Archive"
            )]
            [ValidateScript( {
                If ( Test-Path -PathType Leaf -Path "$_" ) {
                    $True
                } Else {
                    Throw "The File $_ does not exist"
                }
            } )]
            [String]
            $File

        )

        Begin {

            Write-Log -LogLevel "Debug" -LogMessage "Archive: $Archive"
            Write-Log -LogLevel "Debug" -LogMessage "File: $File"

        }

        Process {

            Write-Log -LogLevel "Information" -LogMessage "Adding $File to ZIP Archive $Archive"

            Try {

                If ( $PScmdlet.ShouldProcess( "Archive", "Update ZIP" ) ) {

                Compress-Archive `
                    -Update `
                    -DestinationPath "$Archive" `
                    -Path "$File"

                }

            } Catch {

                Write-Log -LogLevel "Error" -LogMessage "Failed to add $File to the ZIP Archive $Archive"

            }

        }

        End {

        }

    }

    #########################
    # Parameter Validation
    #########################

    Register-Logging

    # Parameter: LogLevel
    Write-Log -LogLevel "Debug" -LogMessage "Initialized logging to Log Level $LogLevel"

    # Parameter: Target
    Write-Log -LogLevel "Debug" -LogMessage "Target set to $Target"

    # Parameter: Project
    If ( $Project -eq "Default" ) {

        Write-Log -LogLevel "Debug" -LogMessage "No Project provided, using default GITHUB_REPOSITORY variable if available"

        if ( $null -eq ${env:GITHUB_REPOSITORY} ) {
            Write-Log -Fatal -LogLevel "Error" -LogMessage "No project name was provided and the GITHUB_REPOSITORY variable is empty. Please provide a Project to continue"
        }

        $Project = ${env:GITHUB_REPOSITORY}.Substring(${env:GITHUB_REPOSITORY}.IndexOf('/')+1)

    }
    Write-Log -LogLevel "Debug" -LogMessage "Project set to $Project"

    # Define the archive name
    $Archive = "$Project-$Target.zip"

    # Define the release directory
    $Release = "target/$Target/release"

}

#################################################
# Process
#################################################

Process {

    Write-Log -LogLevel "Information" -LogMessage "$ScriptName has started"

    Try {

        # If the zip archive already exists, abort
        If ( Test-Path "$Archive" ) {

            Write-Log -Fatal -LogLevel "Error" -LogMessage "ZIP Archive already exists $Archive"

        } Else {

            Write-Log -LogLevel "Information" -LogMessage "Creating new ZIP Archive $Archive"

            If ( $PScmdlet.ShouldProcess( "Archive", "Create ZIP" ) ) {

                Compress-Archive `
                    -DestinationPath $Archive `
                    -Path README.md

            }

        }

    } Catch {

        Write-Log -Fatal -LogLevel "Error" -LogMessage "Failed to create new ZIP Archive $Archive"

    }

    # Add the binary with the project name to the Archive
    $BinNix = "$Release/$Project"
    $BinWin = "$Release/$Project.exe"

    $BinNixExists = Test-Path -PathType Leaf -Path "$BinNix" -ErrorAction SilentlyContinue
    $BinWinExists = Test-Path -PathType Leaf -Path "$BinWin" -ErrorAction SilentlyContinue

    Write-Log -LogLevel "Debug" -LogMessage "Archive: $Archive"
    Write-Log -LogLevel "Debug" -LogMessage "Bin Nix: $BinNix"
    Write-Log -LogLevel "Debug" -LogMessage "Bin Win: $BinWin"

    If ( $BinNixExists ) {
        Add-Archive -Archive $Archive -File $BinNix
    } Else {
        Write-Log -LogLevel "Warning" -LogMessage "Skipping missing binary $BinNix"
    }

    If ( $BinWinExists ) {
        Add-Archive -Archive $Archive -File $BinWin
    } Else {
        Write-Log -LogLevel "Warning" -LogMessage "Skipping missing binary $BinWin"
    }

    # Add the binaries with individual names to the existing Archive
    Get-ChildItem -Path "src/bin" -Filter *.rs -ErrorAction SilentlyContinue |
    ForEach-Object {

        $BinNix = $Release + "/" + $_.BaseName
        $BinWin = $Release + "/" + $_.BaseName + ".exe"

        $BinNixExists = Test-Path -PathType Leaf -Path "$BinNix" -ErrorAction SilentlyContinue
        $BinWinExists = Test-Path -PathType Leaf -Path "$BinWin" -ErrorAction SilentlyContinue

        Write-Log -LogLevel "Debug" -LogMessage "Archive: $Archive"
        Write-Log -LogLevel "Debug" -LogMessage "Bin Nix: $BinNix"
        Write-Log -LogLevel "Debug" -LogMessage "Bin Win: $BinWin"

        If ( $BinNixExists ) {
            Add-Archive -Archive $Archive -File $BinNix
        } Else {
            Write-Log -LogLevel "Warning" -LogMessage "Skipping missing binary $BinNix"
        }

        If ( $BinWinExists ) {
            Add-Archive -Archive $Archive -File $BinWin
        } Else {
            Write-Log -LogLevel "Warning" -LogMessage "Skipping missing binary $BinWin"
        }

    }

}

#################################################
# End
#################################################

End {

    # Confirm that the archive exists
    $ArchiveExists = Test-Path -PathType Leaf -Path "$Archive" -ErrorAction SilentlyContinue
    If ( -Not $ArchiveExists ) {

        Write-Log -Fatal -LogLevel "Error" -LogMessage "The ZIP Archive $Archive cannot be found"

    }

    If ( ( $DieHard ) -And ( $ErrorCount -gt 0 ) ) {

        Write-Log -Throw -LogLevel "Error" -LogMessage "$ErrorCount errors during execution. Review the log file for details."

    }

    Write-Log -LogLevel "Information" -LogMessage "$ScriptName has completed"
    Exit $LASTEXITCODE

}
