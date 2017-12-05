#!/usr/bin/env bats

load "node_modules/bats-support/load"
load "node_modules/bats-assert/load"

TestFolder="$BATS_TEST_DIRNAME/test_folder"
TestDisks="$BATS_TEST_DIRNAME/test_mnt"
Source="$BATS_TEST_DIRNAME/wsl-open.sh"
TestSource() {
  if assert_wsl; then
    EnableWslCheck=false
  fi
  WslDisks=$TestDisks
  $Source
}
Exe=$(basename $Source .sh)
ConfigFile=~/.$Exe

setup() {
  create_test_env
  cd $TestFolder
}

@test "env: test environment" {
assert_equal $(pwd) $TestFolder
assert [ -d $TestDisks ]
}

@test "env: not on WSL error" {
if assert_wsl; then
  # We are on a real WSL
  skip "Cannot test non-WSL behavior on WSL machine"
else
  # Test functionality if ran on non WSL machine
  run $Source
  assert_failure
  assert_output --partial "Could not detect WSL"
fi
}

@test "env: emulate WSL" {
if assert_wsl; then
  skip "Cannot emulate WSL on WSL machine"
else
  run $TestSource
  assert_success
fi
}

@test "basic: no input" {
run $TestSource
assert_success
assert_output ""
}

teardown() {
  cd ..
  rm -rf $TestFolder $TestDisk
}

## Helper functions
assert_wsl() {
  [[ $(uname -r) == *Microsoft ]]
}
refute_wsl() {
  ! assert_wsl
}
create_test_env() {
  # Create test folder and test disk
  for TempFolder in $TestFolder $TestDisks; do
    if [[ -e $TempFolder ]]; then
      rm -rf $TempFolder
    fi
    refute [ -e $TempFolder ]
    mkdir $TempFolder
    assert [ -d $TempFolder ]
  done
  # export WslDisks=$TestDisks
  # export EnableWslCheck=false
}
create_valid_windisk() {
  Disk="$*"
  mkdir $Disk
  mkdir $Disk/Windows
  mkdir $Disk/Windows/System32
  mkdir $Disk/Users
  mkdir $Disk/Users/$USER
}
assert_valid_windisk() {
  Disk="$*"
  assert [ -d $Disk ]
  assert [ -d $Disk/Windows ]
  assert [ -d $Disk/Windows/System32 ]
  assert [ -d $Disk/Users ]
  assert [ -d $Disk/Users/$USER ]
}
