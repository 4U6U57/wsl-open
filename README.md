# wsl-open (:open_file_folder: :arrow_right: :computer:)

[![npm
version](https://img.shields.io/npm/v/wsl-open.svg)](http://npmjs.com/package/wsl-open)
[![pipeline
status](https://gitlab.com/4U6U57/wsl-open/badges/master/pipeline.svg)](https://gitlab.com/4U6U57/wsl-open/commits/master)

Utility for opening files within the [Windows Subsystem for Linux][wsl] command
line in Windows GUI applications.

## Usage

Just run **wsl-open** with the file that you want to open.

```bash
wsl-open { FILE | DIRECTORY | URL }

```

- `FILE` paths can be relative or absolute
- `DIRECTORY` paths are the same, but can only refer to directories accessible
  in Windows (under `/mnt/*` in WSL)
- `URL`s must include the `http(s)://` or begin with `www`, same as how
  `xdg-open` handles URLs

### Examples

```bash
# Opens in your Windows default image viewer
wsl-open image.png

# Relative and absolute paths work
wsl-open ../Downloads/resume.pdf
wsl-open /home/other/README.txt

# Opens your Windows default browser
wsl-open http://google.com
```

### Set file associations

The real benefit of **wsl-open** is setting it as the default program in the
Windows Subsystem for a particular filetype. This allow you to use Linux's
standard `xdg-open` utility to open files, and wsl-open will handle the rest!
This keeps your scripts platform agnostic.

```bash
# Set association for file type
wsl-open -a image.png

# Now, you can open up any image with xdg-open, and wsl-open will handle it
xdg-open another-image.png

# Unassociate wsl-open with a file type
wsl-open -u image.png

# Associate wsl-open with links (set wsl-open as your shell's BROWSER)
wsl-open -w
```

> **Protip**: I like to furthur generalize my scripts by setting `alias
> open='xdg-open'` on my Linux machines, which make them behave more like macOS

## Installation

### npm

The easiest way to get it is to use the [Node Package Manager][npm] and install
it globally.

```bash
# Get npm if you don't have it already
sudo apt-get install -yqq npm

# Install
sudo npm install -g wsl-open
```

### Bash script

**wsl-open** is actually just a single, self contained bash script, so the bare
minimum installation is simply downloading the script, either by cloning the
repo or downloading it from this site, and then adding it to your path. Here is
an example:

```bash
# Make a bin folder in your home directory
mkdir ~/bin

# Add the bin folder to your PATH in your bashrc
echo "[[ -e ~/bin ]] && PATH=$PATH:~/bin" » .bashrc

# Download the script to a file named 'wsl-open'
curl -o ~/bin/wsl-open https://raw.githubusercontent.com/4U6U57/wsl-open/master/wsl-open.sh

# Mark it as executable
chmod +x ~/bin/wsl-open
```

[wsl]: https://msdn.microsoft.com/en-us/commandline/wsl/about
[npm]: https://npmjs.com
