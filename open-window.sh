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

# Error function
Error() {
  echo "$Exe: ERROR: $*" >&2
  exit 1
}
Warning() {
  echo "$Exe: WARNING: $*" >&2
}

Usage="
.TH man 1 \"$(date)\" \"1.0\" \"$Exe man page\"
.SH NAME
$Exe \- Windows Subsystem for Linux opening utility
.SH SYNOPSIS
$Exe [-a][-d] FILE
.SH DESCRIPTION
$Exe is a shell script that uses Bash for Windows' \`cmd.exe /C start\` command to open files with Windows applications.
.SH OPTIONS
.IP -h
displays this help page
.IP -a
associates this script with this filetype with xdg-open
.IP -d
disassociates this script with this filetype with xdg-open
"

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

# Check that we're on Windows Subsystem for Linux
! grep -q "Microsoft" /proc/sys/kernel/osrelease &>/dev/null && Error "Could not detect Windows Subsystem"

# Find windows path
WinHome=""
ConfigFile=~/.$Exe
DefaultsFile=~/.mailcap
if [[ -e $ConfigFile ]]; then
  source "$ConfigFile"
else
  echo "Creating configuration file: $ConfigFile"
  touch "$ConfigFile"
fi
! [[ -e $DefaultsFile ]] && touch $DefaultsFile

if [[ -z $WinHome ]]; then
  # Iterate through disks
  WinDisk=""
  for Disk in /mnt/*; do
    [[ -e $Disk/Windows ]] && WinDisk=$Disk && break
  done
  [[ -z $WinDisk ]] && Error "Could not detect Windows disk"
  echo "Select your Windows home folder:"
  select WinHome in $WinDisk/Users/*; do break; done
  [[ -z $WinHome ]] && Error "Could not find Windows home folder"
  echo "WinHome=$WinHome" >>"$ConfigFile"
fi

# Check command line arguments
while getopts "ha:d:w" Opt; do
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
      echo "$Type; open-window '%s'" >> $DefaultsFile
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
        if grep "BROWSER=.*$Exe" $BashFile >/dev/null; then
          Error "$BashFile already adds $Exe to BROWSER, check it for problems or restart your Bash"
        else
          echo "# Adding $Exe as a browser for Bash for Windows
          BROWSER=\$BROWSER:$Exe
          " >>$BashFile
        fi
      fi
      ;;
    (\?)
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
    # Move file to Windows partition, if necessary
    FilePath="$(readlink -f "$File" | sed 's/ /-/g')"
    if [[ $FilePath != $WinHome/* ]]; then
      [[ ! -f $FilePath ]] && Error "Directory not in Windows partition: $FilePath"
      Warning "File not in Windows partition: $FilePath"
      TempFolder=$WinHome/AppData/Local/Temp/$Exe
      [[ ! -e $TempFolder ]] && echo "Creating temporary folder: $TempFolder" && mkdir --parents "$TempFolder"
      FilePath="$TempFolder/$(basename "$FilePath")"
      echo -n "Copying "
      cp -v "$File" "$FilePath" || Error "Could not copy file, check that it's not open on Windows"
    fi

    FileWin=$(echo "$FilePath" | cut -d "/" -f 3-)
    FileWin="$(tr '[:lower:]' '[:upper:]' <<< ${FileWin:0:1}):/${FileWin:1}"
    FileWin="$(tr '/' '\\' <<< $FileWin)"
  elif [[ $File == *://* ]]; then
    # Link
    FileWin=$File
  else
    Error "File/directory does not exist: $File"
  fi

  # Open the file with windows
  cmd.exe /C start "$FileWin"
fi
