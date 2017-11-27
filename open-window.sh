#!/bin/bash

##
# @file open-window.sh
# @brief Opens files on Windows Subsystem for Linux with default Windows applications
# @author August Valera
#
# @version
# @date 2017-11-23
#

Exe=$(basename $0 .sh)

# Error function
Error() {
  echo "$Exe: ERROR: $@" >&2
  exit 1
}
Warning() {
  echo "$Exe: WARNING: $@" >&2
}
PrintUsage() {
  ManFile=$(mktemp)
  EchoUsage ".TH man 1 \"$(date)\" \"1.0\" \"$Exe man page\""
  EchoUsage ".SH NAME" >> $ManFile
  EchoUsage "$Exe \- Windows Subsystem for Linux opening utility"
  EchoUsage ".SH SYNOPSIS"
  EchoUsage "$Exe FILE"
  EchoUsage "$Exe [-a][-d] FILE"
  EchoUsage ".SH DESCRIPTION"
  EchoUsage "$Exe is a shell script that uses Bash for Windows' \`cmd.exe /C start\` command to open files with Windows applications."
  EchoUsage ".SH OPTIONS"
  EchoUsage ".IP -h"
  EchoUsage "displays this help page"
  EchoUsage ".IP -a"
  EchoUsage "associates this script with this filetype with xdg-open"
  EchoUsage ".IP -d"
  EchoUsage "disassociates this script with this filetype with xdg-open"
  man $ManFile
  rm -f $ManFile
}
EchoUsage() {
  echo "$@" >> $ManFile
}

# Check that we're on Windows Subsystem for Linux
! grep -q "Microsoft" /proc/sys/kernel/osrelease &> /dev/null && Error "Could not detect Windows Subsystem"

# Find windows path
WinPath=""
ConfigFile=~/.$Exe
DefaultsFile=~/.mailcap
if [[ -e $ConfigFile ]]; then
  source $ConfigFile
else
  echo "Creating configuration file: $ConfigFile"
  touch $ConfigFile
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
  echo "WinHome=$WinHome" >> $ConfigFile
fi

# Check command line arguments
while getopts "ha:d:" Opt; do
  case $Opt in
    (h)
      PrintUsage
      ;;
    (a)
      File=$OPTARG
      [[ ! -e $File ]] && Error "File does not exist: $File"
      Type=$(xdg-mime query filetype $File)
      TypeSafe=$(tr '/' '\/' <<< $Type)
      echo "Associating type $Type with $Exe"
      sed -i "#$TypeSafe#d" $DefaultsFile
      echo "$Type; open-window '%s'" > $DefaultsFile
      ;;
    (d)
      File=$OPTARG
      [[ ! -e $File ]] && Error "File does not exist: $File"
      Type=$(xdg-mime query filetype $File)
      TypeSafe=$(tr '/' '\/' <<< $Type)
      echo "Disassociating type $Type with $Exe"
      sed -i "#$TypeSafe.*open-window#d" $DefaultsFile
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
  # Check file existence
  [[ ! -e $File ]] && Error "File does not exist: $File"

  # Move file to Windows partition, if necessary
  FilePath=$(readlink -f $File)
  if [[ $FilePath != $WinHome/* ]]; then
    Warning "File not in Windows partition: $FilePath"
    TempFolder=$WinHome/$Exe
    [[ ! -e $TempFolder ]] && echo "Creating temporary folder: $TempFolder" && mkdir $TempFolder
    FilePath=$TempFolder/$(basename $File)
    cp -v $File $FilePath || Error "Could not copy file, check that it's not open on Windows"
  fi

  FileWin=$(echo $FilePath | cut -d "/" -f 3-)
  FileWin="$(tr '[a-z]' '[A-Z]' <<< ${FileWin:0:1}):/${FileWin:1}"
  FileWin="$(tr '/' '\\' <<< $FileWin)"

  # Open the file with windows
  cmd.exe /C start "$FileWin"
fi
