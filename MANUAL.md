# wsl-open

## SYNOPSIS

`wsl-open [OPTIONS] { FILE | DIRECTORY | URL }`

## DESCRIPTION

wsl-open is a shell script that uses Bash for Windows' `powershell.exe Start`
command to open files with Windows applications.

## OPTIONS

`-h`
displays this help page

`-a`
associates this script with xdg-open for files like this

`-d`
disassociates this script with xdg-open for files like this

`-w`
associates this script with xdg-open for links (`http://`)

`-x`
dry run, does not open file, just echos command used to do it.
Useful for testing.

## EXAMPLES

`wsl-open manual.docx`

`wsl-open /mnt/c/Users/Test\ User/Downloads/profile.png`

`wsl-open https://gitlab.com/4U6U57/wsl-open`

`wsl-open -a README.txt`

## AUTHORS

**August Valera** @4U6U57 on GitLab/GitHub

## SEE ALSO

xdg-open(1), [Project Page](https://gitlab.com/4U6U57/wsl-open)
