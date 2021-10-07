#!/bin/sh

is_abspath() {
  case "$1" in
    /* | ~*) true;;
    *) false;;
  esac
}
