#!/usr/bin/env bats

load "node_modules/bats-support/load"
load "node_modules/bats-assert/load"

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
