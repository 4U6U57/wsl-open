#!/usr/bin/env bats

load "bats-support/load"
load "bats-assert/load"

TestFolder="test_folder"

setup() {
  export Test=true
}

@test "test_environment" {
  cd ..
  assert [ -d $FolderName ]
}

teardown() {
  cd ..
  rm -rf $TestFolder
}
