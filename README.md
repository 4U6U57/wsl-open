# wsl-open (:open_file_folder: :arrow_right: :computer:)

[![pipeline
status](https://gitlab.com/4U6U57/wsl-open/badges/master/pipeline.svg)](https://gitlab.com/4U6U57/wsl-open/commits/master)
[![npm
version](https://img.shields.io/npm/v/wsl-open.svg)](http://npmjs.com/package/wsl-open)

Utility for opening files within the [Windows Subsystem for Linux][wsl] command
line in Windows GUI applications.

## Usage

Just run **wsl-open** with the file/directory/URL that you want to open.

```bash
wsl-open { FILE | DIRECTORY | URL }

```

- `FILE` paths can be relative or absolute
- `DIRECTORY` paths are the same, with a possible limitation*
- `URL`s must include the protocol (`http://`, `https://`, `ftp://`, etc) or
  begin with `www`, which is consistent with how `xdg-open` handles URLs

> *If using a WSL build without the `wslpath` (prior to Build 1803 - released
> April 2018), only Windows directories can be opened

### Examples

```bash
# Opens in your Windows default image viewer
wsl-open image.png

# Relative and absolute paths work
wsl-open ../Downloads/resume.pdf
wsl-open /home/other/README.txt

# Directories under Windows
wsl-open /mnt/c/Users/4u6u5/Music

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

# Now, you can open up any PNG with xdg-open, and wsl-open will handle it
xdg-open another_image.png

# Unassociate wsl-open with a file type
wsl-open -d image.png

# Associate wsl-open with links (set wsl-open as your shell's BROWSER)
wsl-open -w

# Now URL's work as well!
xdg-open https://gitlab.com/4U6U57/wsl-open

# And this allows other programs that depend on xdg-open to use it as well!
npm repo wsl-open # Same as the previous command
```

> **Protip**: I like to furthur generalize my scripts by setting `alias
> open='xdg-open'` on my Linux machines, which make them behave more like macOS

### Full specification

For full details on how the script operates, feel free to check out the
[manpage][manpage] or [design specification][design]

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

### Standalone

**wsl-open** is actually just a single, self contained bash script, so the bare
minimum installation is simply downloading the script (either by cloning the
repo or via `curl`) and then adding it to your path. Here is an example:

```bash
# Make a bin folder in your home directory
mkdir ~/bin

# Add the bin folder to your PATH in your bashrc
echo '[[ -e ~/bin ]] && PATH=$PATH:~/bin' >> .bashrc

# Download the script to a file named 'wsl-open'
curl -o ~/bin/wsl-open https://raw.githubusercontent.com/4U6U57/wsl-open/master/wsl-open.sh
```

[wsl]: https://msdn.microsoft.com/en-us/commandline/wsl/about
[npm]: https://npmjs.com
[manpage]: MANUAL.md
[design]: DESIGN.md
