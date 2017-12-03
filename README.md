# wsl-open :open_file_folder: :arrow_right: :computer:

Utility for opening files within the [Windows Subsystem for Linux][wsl] command line in Windows GUI applications.

## Installation

### npm

The easiest way to install is to use the [Node Package Manager][npm] to install it globally.

```bash
# Get npm if you don't have it already
sudo apt-get install -yqq npm

# Install
sudo npm install -g wsl-open
```

### Bash script

*wsl-open* is actually just a single, self contained bash script, so the bare minimum installation is simply downloading the script, either by cloning the repo or downloading it from this site, and then adding it to your path. Here is an example:

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

## Usage

```bash
# Opens your Windows default image viewer
wsl-open image.png

# Opens your Windows default browser
wsl-open http://google.com
```

### Set file associations

The real benefit of *wsl-open* is setting it as the default program in the Windows Subsystem for a particular filetype. This allow you to use Linux's standard `xdg-open` utility to open files, and *wsl-open* will handle the rest! This keeps your scripts platform agnostic.

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

[wsl]: https://msdn.microsoft.com/en-us/commandline/wsl/about
[npm]: https://npmjs.com
