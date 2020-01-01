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
WslOpenExe=${WslOpenExe:-"powershell.exe Start"}
WslDisks=${WslDisks:-/mnt}
EnableWslCheck=${EnableWslCheck:-true}
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
.TH \"WSL\-OPEN\" \"1\" \"September 2019\" \"wsl-open 1.3.0\" \"wsl-open manual\"
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
        sed -i "/$TypeSafe/d" "$DefaultsFile"
        echo "$Type; $Exe '%s'" >>"$DefaultsFile"
      else
        DryRunner "sed -i \"/$TypeSafe/d\" \"$DefaultsFile\""
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
        sed -i "/$TypeSafe.*open-window/d" "$DefaultsFile"
      else
        DryRunner "sed -i \"/$TypeSafe.*open-window/d\" \"$DefaultsFile\""
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
    FilePath=$(readlink -f "$File")
	#FilePath=${FilePath//\ /\\\ }
	#echo $FilePath

	#echo wslpath -w "$FilePath"
      FileWin=$(wslpath -w "$FilePath")
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
