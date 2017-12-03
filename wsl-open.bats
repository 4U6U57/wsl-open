#!/usr/bin/env bats

load "node_modules/bats-support/load"
load "node_modules/bats-assert/load"

TestFolder="test_folder"
TestDisk=~/test_disk
Source="$BATS_TEST_DIRNAME/wsl-open.sh"
Exe=$(basename $Source .sh)
ConfigFile=~/.$Exe
AllDisk="/mnt/*"
DetectWsl=$([[ $(uname -r) == *Microsoft ]])

setup() {
  mkdir $TestFolder
  cd $TestFolder
  # Any test that is after the environment is setup (created virtual WinDisk)
  # should assert that we have a valid WinDisk to work on
  if [[ $BATS_TEST_NAME == env:* ]]; then
    assert_valid_windisk
  fi
}

@test "env: test environment" {
assert_equal $(basename $(pwd)) $TestFolder
}

@test "env: not on WSL" {
if $DetectWsl; then
  # We are on a real WSL
  skip "Cannot test non-WSL machine behavior on WSL machine"
else
  # Test functionality if ran on non WSL machine
  run $Source
  assert_failure
  assert_output --partial "Could not detect WSL"
fi
}

@test "env: emulate WinDisk" {
# Load configuration, if exists
if [[ -e $ConfigFile ]]; then
  source $ConfigFile
fi
# If WinDisk is not set, we need to find it or emulate it
if [[ -z $WinDisk ]]; then
  # If we're on a real WSL machine, need to find it
  if $DetectWsl; then
    for Disk in $AllDisk; do
      # If we find a Windows folder, this is the disk with the OS
      [ -e $Disk/Windows/System32 ] && WinDisk=$Disk && echo "WinDisk=$WinDisk" >>"$ConfigFile" && break
    done
  else
    # We're on a non-WSL machine, emulate and create
    WinDisk="/mnt/c"
    mkdir $TestDisk
    assert [ -d $TestDisk ]
    mount $TestDisk $WinDisk
  fi
fi
refute [ -z $WinDisk ]
assert [ -d $WinDisk ]
}

@test "env: emulate WSL" {
if $DetectWsl; then
  skip "Cannot test overriding WSL protection on WSL machine"
else
  echo "EnableWslCheck=false" >>$ConfigFile
  source $ConfigFile
  run $Source
  assert_success
fi
}

@test "basic: no input" {
run $Source
assert_success
assert_output ""
}

teardown() {
  cd ..
  rm -rf $TestFolder
}

## Helper functions
assert_valid_windisk() {
  if [[ -e $ConfigFile ]]; then
    source $ConfigFile
  fi
  refute [ -z $WinDisk ]
  assert [ -d $WinDisk ]
  assert [ -d $WinDisk/Windows/System32 ]
}
