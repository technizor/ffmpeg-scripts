#!/usr/bin/env bash

function process () {
  # Named Arguments Processing
  local in_vid in_bgm out keep=false

  local opt OPTARG OPTIND
  while getopts 'v:b:o:k:' opt
  do
    case "${opt}" in
      v) in_vid="${OPTARG}";;
      b) in_bgm="${OPTARG}";;
      o) out="${OPTARG}";;
      k) keep="${OPTARG:-$keep}";;
      *) return 1 # illegal option
    esac
  done

  echo "process(in_vid: \"$in_vid\", in_bgm: \"$in_bgm\", out: \"$out\")"
  echo

  if [[ -z "$in_vid" ]] || [[ -z "$in_bgm" ]] || [[ -z "$out" ]] ; then
    echo "Usage: process -v <inputVideo> -b <inputBgm> -o <outputVideo>"
    echo
    return 1
  fi


  uuid=$(uuidgen)
  in_vid_norm=${uuid}_vid_norm.mp4
  in_bgm_norm=${uuid}_bgm_norm.aac

  echo uuid: "$uuid"
  echo in_vid_norm: "$in_vid_norm"
  echo in_bgm_norm: "$in_bgm_norm"

  normalize -i "$in_vid" -o "$in_vid_norm" -l -15
  normalize -i "$in_bgm" -o "$in_bgm_norm"

  splice -v "$in_vid_norm" -b "$in_bgm_norm" -o "$out"

  if [[ ! "$keep" = true ]] ; then
    rm "$in_vid_norm"
    rm "$in_bgm_norm"
  fi
}

function normalize () {
  # Named Arguments Processing
  local in_file out_file level=-10

  local opt OPTARG OPTIND
  while getopts 'i:o:l:' opt
  do
    case "${opt}" in
      i) in_file="${OPTARG}";;
      o) out_file="${OPTARG}";;
      l) level="${OPTARG:-$level}";;
      *) return 1 # illegal option
    esac
  done

  echo "normalize(in_file: \"$in_file\", out_file: \"$out_file\", level: \"$level\")"
  echo

  if [[ -z "$in_file" ]] || [[ -z "$out_file" ]] ; then
    echo "Usage: normalize -i <input> -o <output> [-l <dbLevel>]"
    echo
    return 1
  fi

  # Processing
  db=$(ffmpeg -i "$in_file" -filter:a volumedetect -f null /dev/null 2>&1 | grep mean_volume | awk -F 'mean_volume: ' '{print $2}' | awk '{print $1}')

  if [[ -z "$db" ]] ; then
    echo "normalize: input not valid file"
    return 1
  fi
  db_off=$(echo - | awk "{print $level - $db}")

  if [[ -z "$db_off" ]] ; then
    echo "normalize: could not calculate db_off from level: $level and db: $db"
    return 1
  fi
  ffmpeg -i "$in_file" -filter:a "volume=$db_off dB" -c:v copy "$out_file"
}

function splice () {
  # Named Arguments Processing
  local in_vid in_bgm out

  local opt OPTARG OPTIND
  while getopts 'v:b:o:' opt
  do
    case "${opt}" in
      v) in_vid="${OPTARG}";;
      b) in_bgm="${OPTARG}";;
      o) out="${OPTARG}";;
      *) return 1 # illegal option
    esac
  done

  echo "process(in_vid: \"$in_vid\", in_bgm: \"$in_bgm\", out: \"$out\")"
  echo

  if [[ -z "$in_vid" ]] || [[ -z "$in_bgm" ]] || [[ -z "$out" ]] ; then
    echo "Usage: process -v <inputVideo> -b <inputBgm> -o <outputVideo>"
    echo
    return 1
  fi

  local def_bgm_delay=0 def_bgm_length=0 def_bgm_fade=1
  local bgm_delay=0 bgm_length=0 bgm_fade=1

  read -p "BGM Length [$def_bgm_length] s: " bgm_length
  read -p "BGM Fade Out [$def_bgm_fade] s: " bgm_fade
  read -p "BGM Delay [${def_bgm_delay}] ms: " bgm_delay

  if [[ -z "$bgm_length" ]] ; then bgm_fade="$def_bgm_length"; fi
  if [[ -z "$bgm_fade" ]] ; then bgm_fade="$def_bgm_fade"; fi
  if [[ -z "$bgm_delay" ]] ; then bgm_fade="$def_bgm_delay"; fi

  local bgm_fade_start ms_bgm_s
  bgm_fade_start=$(echo - | awk "{print $bgm_length - $bgm_fade}")

  ffmpeg -i "$in_vid" -i "$in_bgm" \
    -filter_complex "\
      [1:a]atrim=0:$bgm_length[a1];\
      [a1]afade=t=out:st=$bgm_fade_start:d=$bgm_fade[a2];\
      [a2]adelay=$bgm_delay|$bgm_delay[a3];\
      [0:a][a3]amix[a4]" \
    -map [a4]:a \
    -map 0:v \
    -c:v libx264 \
    -c:a aac -strict experimental \
    -r 50 \
    "$out"
}

process "$@"
