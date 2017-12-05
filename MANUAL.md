# wsl-open

## SYNOPSIS

```bash
wsl-open [OPTIONS] { FILE | DIRECTORY | URL }
```

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
