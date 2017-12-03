# Design Specification

## Core Features

### WSL :right_arrow: Windows

The [Windows Subsystem for Linux][wsl], as of the *Summer Creators Update
(2017)*, allows the execution of Windows binaries from within the WSL terminal,
which means the following is possible:

```bash
# Open file in default Windows application
powershell.exe Start C:\\Users\TestUser\Documents\file.pdf
```

WSL hands off the command to Powershell, which "starts" (opens) the file just as
if you opened it in Explorer, opening the Windows program associated with it, or
prompting the user to select a program if not set. This has several limitations:

- The file path must be in Windows format, which means backslashes for
  directories and the `C:\\` (or whatever disk label) prefix. For reference, on
  Bash for Windows, the equivalent file path would be
  `/mnt/c/Users/TestUser/Documents/file.pdf`
- The file must be in a Windows accessible disk, meaning any folder under
  `/mnt/*` on WSL. The WSL filesystem is not accessible from the Windows side,
  so files in your home folder, for instance, will not be accessible.

**wsl-open** makes your life easier, by allowing you to specify a Linux style
relative or absolute path, and resolving it to a Windows path. In addition, any
files that are on the WSL filesystem will be copied into a temporary directory
on the Windows disk before being opened.

### Copying from WSL

> TODO: Add info

### Hooking into `xdg-open`

The script creates/modifies two different configuration files, which allows it
to hook into the Linux `xdg-open` command. These are:

- `~/.wsl-open`: holds the user inputted file path to the user's Windows home
  folder, in the format `WinHome=/mnt/c/Users/augus`
- `~/.mailcap`: used by `run-mailcap`, which in turn is called by `xdg-open`.
  Holds entries for different filetypes, as well as the program which should
  open them. Each entry is of the form `application/pdf; wsl-open '%s'`,
  `image/png; wsl-open '%s'`

### Limitations/Unexpected Behavior

Here are some limitations of the script as it is written currently, which may
result in unexpected behavior.

- On first run, users will be requested to select their Windows home folder.
  This cannot be done programatically, as Linux usernames are independent of
  Windows usernames
- Any file not in your Windows user home folder will be copied into the
  `%USERPROFILE%\AppData\Local\Temp\wsl-open` before being opened.
  - You can also use `wsl-open` to open directories, but we will not allow
    directories not in the Windows partition (because we don't want to recursive
    copy all those files over)
- Some Windows applications will prevent other programs from writing to a file
  while it is open, which will cause the script to fail. This affects reloading
  a file (regardless of whether or not it has been edited), as well as
  attempting to open a different file of with the same name.
- Only the file specified will be copied if required. This may cause issues when
  opening files that have dependencies, such as an html file which imports CSS
  stylesheets or Javascript files.

[wsl]: https://msdn.microsoft.com/en-us/commandline/wsl/about
