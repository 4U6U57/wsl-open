#!/bin/bash

##
# @file open-window.sh
# @brief Opens files on Windows Subsystem for Linux with default Windows applications
# @author August Valera
#
# @version
# @date 2017-11-23
#

# Global
# shellcheck disable=SC1117
# This is for the explicit manpage

# Variables
Exe=$(basename "$0" .sh)
OpenExe=${OpenExe:-"powershell.exe Start"}
EnableWslCheck=${EnableWslCheck:-true}
DryRun=false
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
.TH \"WSL\-OPEN\" \"1\" \"December 2017\" \"wsl-open 1.0.8\" \"wsl-open manual\"
.SH \"NAME\"
\fBwsl-open\fR
.SH SYNOPSIS
.P
.RS 2
.nf
wsl\-open [OPTIONS] { FILE | DIRECTORY | URL }
.fi
.RE
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
  # C:/folder/path -> /mnt/c/folder/path
  # shellcheck disable=SC2018,SC2019
  Path=/mnt/$(tr 'A-Z' 'a-z' <<< "${Path:0:1}")${Path:2}
  echo "$Path"
}
LinuxPathToWin() {
  Path=$*
  [[ $Path != /mnt/* ]] && exit
  # /mnt/c/folder/path -> c/folder/path
  Path=$(cut -d "/" -f 3- <<< "$Path")
  # c/folder/path -> C://folder/path
  Path=$(tr '[:lower:]' '[:upper:]' <<< "${Path:0:1}"):/${Path:1}
  # C://folder/path -> C:\\folder\path
  Path=${Path//\//\\}
  echo "$Path"
}

# Check that we're on Windows Subsystem for Linux
# shellcheck disable=SC2154
if $EnableWslCheck; then
  [[ $(uname -r) != *Microsoft ]] && Error "Could not detect WSL (Windows Subsystem for Linux)"
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
      sed -i "/$TypeSafe/d" "$DefaultsFile"
      echo "$Type; $Exe '%s'" >>"$DefaultsFile"
      ;;
    (d)
      File=$OPTARG
      [[ ! -e $File ]] && Error "File does not exist: $File"
      Type=$(xdg-mime query filetype "$File")
      TypeSafe="${Type//\//\\/}"
      echo "Disassociating type $Type with $Exe"
      sed -i "/$TypeSafe.*open-window/d" "$DefaultsFile"
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
          if [[ \$(uname -r) == *Microsoft ]]; then
            if [[ -z $BROWSER ]]; then
              export BROWSER=$Exe
            else
              export BROWSER=$BROWSER:$Exe
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
if [[ ! -z $File ]]; then
  if [[ -e $File ]]; then
    # File or directory
    FilePath="$(readlink -f "$File")"

    # shellcheck disable=SC2053
    if [[ $FilePath != /mnt/* ]]; then
      # File or directory is not on a Windows accessible disk
      # If it is a directory, then we can't do anything, quit
      [[ ! -f $FilePath ]] && Error "Directory not in Windows partition: $FilePath"
      # If it's a file, we copy it to the user's temp folder before opening
      Warning "File not in Windows partition: $FilePath"
      # If we do not have a temp folder assigned, find one using Windows
      if [[ -z $TempFolder ]]; then
        TempWin=$(cmd.exe /C echo %TEMP%)
        TempDir=$(WinPathToLinux "$TempWin")
        TempFolder="$TempDir/$Exe"
      fi
      [[ ! -e $TempFolder ]] && Warning "Creating temp folder for $Exe to use: $TempFolder" && mkdir --parents "$TempFolder"
      FilePath="$TempFolder/$(basename "$FilePath")"
      echo -n "Copying "
      cp -v "$File" "$FilePath" || Error "Could not copy file, check that it's not open on Windows"
    fi

    FileWin=$(LinuxPathToWin "$FilePath")
  elif [[ $File == *://* ]]; then
    # If "file" input is a link, just pass it directly
    FileWin=$File
  else
    Error "File/directory does not exist: $File"
  fi

  # Open the file with Windows
  if ! $DryRun; then
    $OpenExe "\"$FileWin\""
  else
    echo "Run this to open file: $OpenExe \"$FileWin\""
  fi
fi
