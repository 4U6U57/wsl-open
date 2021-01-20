#!/bin/bash

##
# @file wsl-open.sh
# @brief Opens files on Windows Subsystem for Linux with default Windows applications
# @author August Valera
#
# @version 2.2.1

# Global
# shellcheck disable=SC1117
# This is for the explicit manpage

# Variables
Exe=$(basename "$0" .sh)
PowershellExe=$(command -v powershell.exe)
PowershellExe=${PowershellExe:-/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe}
WslOpenExe=${WslOpenExe:-"${PowershellExe} Start"}
WslPathExe=${WslPathExe:-"wslpath -w"}
WslDisks=${WslDisks:-/mnt}
EnableWslCheck=${EnableWslCheck:-true}
EnableWslPath=${EnableWslPath:-true}
DryRun=${DryRun:-false}
DefaultsFile=${DefaultsFile:-~/.mailcap}
BashFile=${BashFile:-~/.bashrc}

# Error functions
Error() {
  echo "$Exe: ERROR: $*" >&2
  exit 1
}
Warning() {
  echo "$Exe: WARNING: $*" >&2
}

# Usage message, ran on help (-h)
Usage="
.\" IMPORT wsl-open.1
.TH \"WSL\-OPEN\" \"1\" \"January 2021\" \"wsl-open 2.2.1\" \"wsl-open manual\"
.SH \"NAME\"
\fBwsl-open\fR
.SH SYNOPSIS
.P
\fBwsl\-open [OPTIONS] { FILE | DIRECTORY | URL }\fP
.SH DESCRIPTION
.P
wsl\-open is a shell script that uses Bash for Windows' \fBpowershell\.exe Start\fP
command to open files with Windows applications\.
.SH OPTIONS
.P
\fB\-h\fP
displays this help page
.P
\fB\-a\fP
associates this script with xdg\-open for files like this
.P
\fB\-d\fP
disassociates this script with xdg\-open for files like this
.P
\fB\-w\fP
associates this script with xdg\-open for links (\fBhttp://\fP)
.P
\fB\-x\fP
dry run, does not open file, just echos command used to do it\.
Useful for testing\.
.SH EXAMPLES
.P
\fBwsl\-open manual\.docx\fP
.P
\fBwsl\-open /mnt/c/Users/Test\\ User/Downloads/profile\.png\fP
.P
\fBwsl\-open https://gitlab\.com/4U6U57/wsl\-open\fP
.P
\fBwsl\-open \-a README\.txt\fP
.SH AUTHORS
.P
\fBAugust Valera\fR @4U6U57 on GitLab/GitHub
.SH SEE ALSO
.P
xdg\-open(1), Project Page \fIhttps://gitlab\.com/4U6U57/wsl\-open\fR

.\" END IMPORT wsl-open.1
"

# Path conversion functions
WinPathToLinux() {
  Path=$*
  # Sanitize, remove \r and \n
  Path=$(tr -d '\r\n' <<< "$Path")
  # C:\\folder\path -> C:\folder\path (only if there is \\)
  Path=${Path//\\\\/\\}
  # C:\folder\path -> C:/folder/path
  Path=${Path//\\/\/}
  # C:/folder/path -> c/folder/path
  # shellcheck disable=SC2018,SC2019
  Path=$(tr 'A-Z' 'a-z' <<< "${Path:0:1}")${Path:2}
  # c/folder/path -> /mnt/c/folder/path
  Path=$WslDisks/$Path
  echo "$Path"
}
LinuxPathToWin() {
  Path=$*
  # If path not under $Disks, can't convert
  [[ $Path != $WslDisks/* ]] && Error "Error converting Linux path to Windows"
  # /mnt/c/folder/path -> c/folder/path
  Path=${Path:$((${#WslDisks} + 1))}
  # c/folder/path -> C://folder/path
  Path=$(tr '[:lower:]' '[:upper:]' <<< "${Path:0:1}"):/${Path:1}
  # C://folder/path -> C:\\folder\path
  Path=${Path//\//\\}
  echo "$Path"
}

# Printer for dry run function
DryRunner() {
  echo "$Exe: RUN: $*"
}

# Check that we're on Windows Subsystem for Linux
# shellcheck disable=SC2154
if $EnableWslCheck; then
  [[ ! $(uname -r) =~ (m|M)icrosoft ]] && Error "Could not detect WSL (Windows Subsystem for Linux)"
fi

# Check command line arguments
while getopts "ha:d:wx" Opt; do
  case $Opt in
    (h)
      man <(echo "$Usage")
      ;;
    (a)
      File=$OPTARG
      [[ ! -e $File ]] && Error "File does not exist: $File"
      Type=$(xdg-mime query filetype "$File")
      TypeSafe="${Type//\//\\/}"
      echo "Associating type $Type with $Exe"
      if ! $DryRun; then
        [[ -e "$DefaultsFile" ]] && sed -i "/$TypeSafe/d" "$DefaultsFile"
        echo "$Type; $Exe '%s'" >>"$DefaultsFile"
      else
        DryRunner "[[ -e \"$DefaultsFile ]] && sed -i \"/$TypeSafe/d\" \"$DefaultsFile\""
        DryRunner "echo \"$Type; $Exe '%s'\" >>\"$DefaultsFile\""
      fi
      ;;
    (d)
      File=$OPTARG
      [[ ! -e $File ]] && Error "File does not exist: $File"
      Type=$(xdg-mime query filetype "$File")
      TypeSafe="${Type//\//\\/}"
      echo "Disassociating type $Type with $Exe"
      if ! $DryRun; then
        [[ -e "$DefaultsFile" ]] && sed -i "/$TypeSafe.*$Exe/d" "$DefaultsFile"
      else
        DryRunner "[[ -e \"$DefaultsFile\" ]] && sed -i \"/$TypeSafe.*$Exe/d\" \"$DefaultsFile\""
      fi
      ;;
    (w)
      if echo "$BROWSER" | grep "$Exe" >/dev/null; then
        Warning "$Exe is already set as BROWSER"
      else
        [[ ! -e $BashFile ]] && touch "$BashFile"
        echo "Adding $Exe to BROWSER environmental variables"
        if grep "export.*BROWSER=.*$Exe" "$BashFile" >/dev/null; then
          Error "$BashFile already adds $Exe to BROWSER, check it for problems or restart your Bash"
        else
          echo "
          # Adding $Exe as a browser for Bash for Windows
          if [[ \$(uname -r) =~ (m|M)icrosoft ]]; then
            if [[ -z \$BROWSER ]]; then
              export BROWSER=$Exe
            else
              export BROWSER=\$BROWSER:$Exe
            fi
          fi
          " >>"$BashFile"
        fi
      fi
      ;;
    (x)
      DryRun=true
      ;;
    (?)
      Error "Invalid option: -$OPTARG"
      ;;
  esac
done
shift $(( OPTIND - 1 ))

# Open file
File=$1
if [[ -n $File ]]; then
  if [[ -e $File ]]; then
    # File or directory
    unset FileWin
    FilePath="$(readlink -f "$File")"

    if $EnableWslPath && echo "$WslPathExe" | cut -d " " -f 1 | xargs which >/dev/null; then
      # Native WSL path translation utility
      if ! FileWin=$($WslPathExe "$FilePath" 2>/dev/null); then
        Warning "Native path translation ($WslPathExe) failed for path: $FilePath"
      fi
    fi

    if [[ -z "$FileWin" ]]; then
      # Backwards compatability for WSL builds without wslpath
      # shellcheck disable=SC2053
      if [[ $FilePath != $WslDisks/* ]]; then
        # File or directory is not on a Windows accessible disk
        # If it is a directory, then we can't do anything, quit
        [[ ! -f $FilePath ]] && Error "Directory not in Windows partition: $FilePath"
        # If it's a file, we copy it to the user's temp folder before opening
        Warning "File not in Windows partition: $FilePath"
        # If we do not have a temp folder assigned, find one using Windows
        if [[ -z $WslTempDir ]]; then
          # shellcheck disable=SC2016
          TempFolder=$(${PowershellExe} '$env:temp')
          WslTempDir=$(WinPathToLinux "$TempFolder")
        fi
        ExeTempDir="$WslTempDir/$Exe"
        if [[ ! -e $ExeTempDir ]]; then
          Warning "Creating temp dir for $Exe to use: $ExeTempDir"
          mkdir --parents "$ExeTempDir"
        fi
        FilePath="$ExeTempDir/$(basename "$FilePath")"
        if ! $DryRun; then
          echo -n "Copying " >&2
          cp -v "$File" "$FilePath" 1>&2 || Error "Could not copy file, check that it's not open on Windows"
        else
          DryRunner "cp -v \"$File\" \"$FilePath\""
        fi
      fi
      FileWin=$(LinuxPathToWin "$FilePath")
    fi
  elif [[ $File == *://* ]]; then
    # If "file" input is a link, just pass it directly
    FileWin=$File
  else
    Error "File/directory does not exist: $File"
  fi

  # Open the file with Windows
  if ! $DryRun; then
    $WslOpenExe "\"$FileWin\""
  else
    DryRunner "$WslOpenExe \"$FileWin\""
  fi
fi
