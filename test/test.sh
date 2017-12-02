#!/bin/bash

Exe=$(basename "${BASH_SOURCE[0]}")
TestDir=$(dirname "${BASH_SOURCE[0]}")

shellcheck "$TestDir/$Exe"
shellcheck "$TestDir/../open-window.sh"
"$TestDir/bats/bin/bats" "$TestDir"
