#!/usr/bin/env bash

function process () {
  # Named Arguments Processing
  local in out frate=50 start stop

  local opt OPTARG OPTIND
  while getopts 'i:o:r:s:t' opt
  do
    case "${opt}" in
      i) in="${OPTARG}";;
      b) out="${OPTARG}";;
      r) frate="${OPTARG:-$frate}";;
      s) start="${OPTARG}";;
      t) stop="${OPTARG}";;
      *) return 1 # illegal option
    esac
  done

  echo "process(in: \"$in\", out: \"$out\", frate: \"$frate\")"
  echo

  if [[ -z "$in_vid" ]] || [[ -z "$in_bgm" ]] || [[ -z "$out" ]] ; then
    echo "Usage: process -v <inputVideo> -b <inputBgm> -o <outputVideo>"
    echo
    return 1
  fi

}
