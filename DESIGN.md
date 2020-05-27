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
- The file must be accessible on Windows. This means either:
  - The file is on the Windows filesystem, which is usually any folder under
    `/mnt/*` on WSL.
  - The Linux filesystem is accessible on Windows. This is only true after build
    1803, which introduced the `wslpath` utility

**wsl-open** makes your life easier, by allowing you to specify a Linux style
relative or absolute path, and resolving it to a Windows path. In addition, any
files that are inaccessible to the Windows filesystem will be copied into a
temporary directory on the Windows filesystem before being opened.

### Copying from WSL

If the requested file is not on the Windows filesystem and we are on a build
before 1803, we need to copy it over to a Windows accessible folder before we
can open it with `powershell`/`cmd`. We use a temporary directory, specifically
`%TEMP%\wsl-open%` (which resolves to `%USERPROFILE%\AppData\Temp\wsl-open`), to
hold these files. Note that there are a couple of caveats in doing so:

- As the files being opened are only copies, any changes made with the Windows
  application will not be reflected in the original.
- Only the file requested is open, which means that files that have relative
  dependencies (such as HTML files including stylesheets or Javascript includes)
  will not display correctly
- We only support copying files and not directories, to prevent excessive disk
  usage copying recursively, and because there is not much use opening a
  directory whose changes will not be reflected in the original.

The `wslpath` utility has made a large part of this script, particularly the
path translation logic and copying functionality, unnecessary. However, it is
still kept around for backwards compatibility.

### Hooking into `xdg-open`

The script creates/modifies two different configuration files, which allows it
to hook into the Linux `xdg-open` command. These are:

- `~/.mailcap`: used by `run-mailcap`, which in turn is called by `xdg-open`.
  Holds entries for different filetypes, as well as the program which should
  open them. Each entry is of the form `application/pdf; wsl-open '%s'`,
  `image/png; wsl-open '%s'`
- `~/.bashrc`: exports the variable `$BROWSER`, which is called by `xdg-open` to
  open URLs.

### Limitations/Unexpected Behavior

Here are some limitations of the script as it is written currently, which may
result in unexpected behavior.

- Some Windows applications will prevent other programs from writing to a file
  while it is open, which will cause the script to fail if using the copying
  functionality. This affects reloading a file (regardless of whether or not it
  has been edited), as well as attempting to open a different file of with the
  same name.

[wsl]: https://msdn.microsoft.com/en-us/commandline/wsl/about
