#!/bin/bash

##
# @file open-window.sh
# @brief Opens files on Windows Subsystem for Linux with default Windows applications
# @author August Valera
#
# @version
# @date 2017-11-23
#

Exe=$(basename "$0" .sh)
OpenExe="powershell.exe Start"

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
.TH man 1 \"$(date)\" \"1.0\" \"$Exe man page\"
.SH NAME
$Exe \\- Windows Subsystem for Linux opening utility
.SH SYNOPSIS
$Exe [-w] [ -a | -d ] FILE
.SH DESCRIPTION
$Exe is a shell script that uses Bash for Windows' \`$OpenExe\` command to open files with Windows applications.
.SH OPTIONS
.IP -h
displays this help page
.IP -a
associates this script with xdg-open for files like this
.IP -d
disassociates this script with xdg-open for files like this
.IP -w
associates this script with xdg-open for links (http://)
.IP -x
dry run, does not open file, just echos command used to do it. Useful for testing.
"

# Generate a desktop file for this script. not actually used anymore
DeskFile=~/.local/share/applications/$Exe.desktop
Desktop="
[Desktop Entry]
Name=Open Window
Exec=open-window %u
Type=Application
"
MakeDesktop() {
  [[ ! -e $(dirname "$DeskFile") ]] && mkdir --parents "$(dirname "$DeskFile")"
  echo "$Desktop" >"$DeskFile"
}

# Used for dry runs
DryRun=false

# Load preferences
WinHome=""
ConfigFile=~/.$Exe
DefaultsFile=~/.mailcap
AllDisk="/mnt/*"
if [[ -e $ConfigFile ]]; then
  # shellcheck source=/dev/null
  source "$ConfigFile"
else
  echo "Creating configuration file: $ConfigFile"
  touch "$ConfigFile"
fi
! [[ -e $DefaultsFile ]] && touch $DefaultsFile

# Check that we're on Windows Subsystem for Linux
# shellcheck disable=SC2154
if [[ -z $EnableWslCheck ]] || $EnableWslCheck; then
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
      sed -i "/$TypeSafe/d" $DefaultsFile
      echo "$Type; $Exe '%s'" >>$DefaultsFile
      ;;
    (d)
      File=$OPTARG
      [[ ! -e $File ]] && Error "File does not exist: $File"
      Type=$(xdg-mime query filetype "$File")
      TypeSafe="${Type//\//\\/}"
      echo "Disassociating type $Type with $Exe"
      sed -i "/$TypeSafe.*open-window/d" $DefaultsFile
      ;;
    (w)
      if echo "$BROWSER" | grep "$Exe" >/dev/null; then
        Warning "$Exe is already set as BROWSER"
      else
        BashFile=~/.bashrc
        [[ ! -e $BashFile ]] && touch $BashFile
        echo "Adding $Exe to BROWSER environmental variables"
        if grep "export.*BROWSER=.*$Exe" $BashFile >/dev/null; then
          Error "$BashFile already adds $Exe to BROWSER, check it for problems or restart your Bash"
        else
          {
            echo;
            echo "# Adding $Exe as a browser for Bash for Windows";
            echo "export BROWSER=\$BROWSER:$Exe";
          } >>$BashFile
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
    if [[ $FilePath != $AllDisk ]]; then
      # File or directory is not on a Windows accessible disk
      # If it is a directory, then we can't do anything, quit
      [[ ! -f $FilePath ]] && Error "Directory not in Windows partition: $FilePath"
      # If it's a file, we copy it to the user's temp folder before opening
      Warning "File not in Windows partition: $FilePath"
      # Get user's home folder
      if [[ -z $WinHome ]]; then
        # First get Windows disk, which is the first disk we find that has a Windows/System32
        if [[ -z $WinDisk ]]; then
          for Disk in $AllDisk; do
            # If we find a Windows folder, this is the disk with the OS
            [[ -e $Disk/Windows/System32 ]] && WinDisk=$Disk && echo "WinDisk=$WinDisk" >>"$ConfigFile" && break
          done
        fi
        [[ -z $WinDisk ]] && Error "Could not detect Windows disk"
        # Prompt user to select their home folder
        echo "Select your Windows home folder:"
        select WinHome in $WinDisk/Users/*; do break; done
        [[ -z $WinHome ]] && Error "Could not find Windows home folder"
        # Save home folder to configuration file to reuse next time
        echo "WinHome=$WinHome" >>"$ConfigFile"
      fi
      # Temp folder is where we'll save the file
      TempFolder=$WinHome/AppData/Local/Temp/$Exe
      [[ ! -e $TempFolder ]] && Warning "Creating temp folder for $Exe to use: $TempFolder" && mkdir --parents "$TempFolder"
      FilePath="$TempFolder/$(basename "$FilePath")"
      echo -n "Copying "
      cp -v "$File" "$FilePath" || Error "Could not copy file, check that it's not open on Windows"
    fi

    # Convert file path to Windows path, using these two simple rules:
    # - /mnt/[a-z] -> [A-Z]:\\
    # - / -> \
      FileWin=$(echo "$FilePath" | cut -d "/" -f 3-)
    FileWin="$(tr '[:lower:]' '[:upper:]' <<< "${FileWin:0:1}"):/${FileWin:1}"
    # shellcheck disable=SC1003
    FileWin="$(tr '/' '\\' <<< "$FileWin")"
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
