#!/usr/bin/env bats

load "node_modules/bats-support/load"
load "node_modules/bats-assert/load"

TestFolder="$BATS_TEST_DIRNAME/test_folder"
TestDisks="$BATS_TEST_DIRNAME/test_mnt"
Source() {
  $BATS_TEST_DIRNAME/wsl-open.sh $@
}
TestSource() {
  if assert_wsl; then
    export EnableWslCheck=false
  fi
  export WslDisks=$TestDisks
  export OpenExe="echo"
  Source $*
}
Exe=$(basename $Source .sh)
ConfigFile=~/.$Exe

setup() {
  create_test_env
  cd $TestFolder
  if grep -q "env:" <(echo $BATS_TEST_NAME) &>/dev/null; then
    # Env tests, do nothing
    true
  else
    create_valid_windisk c
    assert_valid_windisk
  fi
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
  run Source
  assert_failure
  assert_output --partial "Could not detect WSL"
fi
}

@test "env: emulate WSL" {
if assert_wsl; then
  skip "Cannot emulate WSL on WSL machine"
else
  run TestSource
  assert_success
fi
}

@test "basic: no input" {
run TestSource
assert_success
assert_output ""
}

@test "basic: missing file" {
run TestSource noexist
assert_failure
assert_output --partial "ERROR"
assert_output --partial "does not exist"
}

@test "basic: file on Windows" {
TestFile=$TestDisks/c/test.txt
touch $TestFile
run TestSource $TestFile
assert_success
assert_output '"C:\\test.txt"'
}

teardown() {
  cd ..
  rm -rf $TestFolder $TestDisks
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
  for TempFolder in "$TestFolder" "$TestDisks"; do
    if [ -e $TempFolder ]; then
      rm -rf $TempFolder
    fi
    refute [ -e $TempFolder ]
    mkdir $TempFolder
    assert [ -d $TempFolder ]
  done
}
create_valid_windisk() {
  Disk="$TestDisks/$*"
  export UserDir=$Disk/Users/$USER
  export WinDisk=$Disk
  export TempFolder=$UserDir/AppData/Temp
  for Folder in $Disk $Disk/Windows $Disk/Windows/System32 $Disk/Users \
    $Disk/Users/$USER $UserDir/AppData $TempFolder; do
    if [ -e $Folder ]; then
      rm -rf $Folder
    fi
    mkdir $Folder
    assert [ -d $Folder ]
  done
}
assert_valid_windisk() {
  Disk="$WinDisk"
  assert [ -d $UserDir ]
  assert_equal $UserDir $Disk/Users/$USER
  assert [ -d $TempFolder ]
  assert_equal $TempFolder $UserDir/AppData/Temp
}
