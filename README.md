# wsl-open :open_file_folder: :arrow_right: :floppy_disk:

A shell script utility for opening files from the [Windows Subsystem for Linux][wsl] command line in Windows applications.

## Usage

### Installation

Download the shell script and put it somewhere in your PATH. If you don't know how to do that, here are a few lines that should do the trick. (But if you aren't really one to use the command line, this utility might not be that useful! :dizzy_face:)

```bash
mkdir ~/bin
curl -o ~/bin/wsl-open https://raw.githubusercontent.com/4U6U57/wsl-open/master/wsl-open.sh
chmod +x ~/bin/wsl-open
echo "[[ -e ~/bin ]] && PATH=$PATH:~/bin" » .bashrc
```

### Usage

- **Easy usage:** `wsl-open FILE` opens `FILE` with the default program associated with that filetype in Windows
- **More general:** `wsl-open -a FILE` associates the script with the filetype of that file, meaning that you can run `xdg-open FILE` (the usual way of opening files on Linux) and the file will open with `wsl-open`
    - You can revert this setting by running `wsl-open -d FILE`. You will still have to set your previous default manually.

> *Protip:* I like to `alias open="xdg-open"` in the `.bashrc` file on all my Linux setups, to make them behave more like macOS. Also, I rarely (never) use the actual Linux open command, which starts a program in a new virutal terminal.

## How it Works

### The "open window"

The [Windows Subsystem for Linux][wsl], as of the Summer 2017 Creators Update, leaves an "open window" of sorts into the Windows environment, by allowing the Bash (or other) shell to run Windows executables. This means that you can run the following in Bash:

```bash
cmd.exe /C start C:\\Users\augus\Documents\resume.pdf
```

and Bash will call Command Prompt, which will call start, which will open the file. However, this has several caveats:

- The file path must be in Windows format, which means backslashes for directories and the `C:\\` prefix. For reference, on Bash for Windows, the equivalent file path would be `/mnt/c/Users/augus/Documents/resume.pdf`
- The file must be in the Windows "partition", meaning any files in your Linux home folder or any other folder that isn't under `/mnt/c` is inaccessible and will return an error.

`wsl-open` strives to make this open window a little wider by facilitating this path conversion, as well as copying any files in the Linux partition you would like to open to a temporary directory on the Windows partition.

### Hooking into `xdg-open`

The script creates/modifies two different configuration files, which allows it to hook into the Linux `xdg-open` command. These are:

- `~/.wsl-open`: holds the user inputted file path to the user's Windows home folder, in the format `WinHome=/mnt/c/Users/augus`
- `~/.mailcap`: used by `run-mailcap`, which in turn is called by `xdg-open`. Holds entries for different filetypes, as well as the program which should open them. Each entry is of the form `application/pdf; wsl-open '%s'`, `image/png; wsl-open '%s'`

### Limitations/Unexpected Behavior

Here are some limitations of the script as it is written currently, which may result in unexpected behavior.

- On first run, users will be requested to select their Windows home folder. This cannot be done programatically, as Linux usernames are independent of Windows usernames
- Any file not in your Windows user home folder will be copied into the `%HOME%\AppData\Local\Temp\wsl-open` before being opened.
    - Yes, this includes any folder that is in another part of the Windows disk, or on any removable drives, regardless of whether or not they are accessible in Windows.
    - You can also use `wsl-open` to open directories, but we will not allow directories not in the Windows partition (because we don't want to recursive copy all those files over)
- Some Windows applications will prevent other programs from writing to a file while it is open, which will cause the script to fail. This affects reloading a file (regardless of whether or not it has been edited), as well as attempting to open a different file of with the same name.
- Only the file specified will be copied if required. This may cause issues when opening files that have dependencies, such as an html file which imports CSS stylesheets or Javascript files.
- Files with spaces in their name will have the spaces converted to dashes on Windows.

[wsl]: https://msdn.microsoft.com/en-us/commandline/wsl/about
