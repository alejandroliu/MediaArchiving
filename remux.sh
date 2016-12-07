#!/bin/sh
######################################################################
#start="-y -ss 00:05:00"
#duration="-t 00:02:00"

outputdir=""
plang="(eng)"
slang="(eng)"

if [ $# -eq 0 ] ; then
  echo "Usage: $0 [opts] --out=<output-dir> *.mkv"
  exit 1
fi


while [ $# -gt 0 ]
do
  case "$1" in
    --lang=*)
      plang="(${1#--lang=})"
      slang="$plang"
      ;;
    --slang=*)
      slang="(${1#--slang=})"
      ;;
    --alang=*)
      plang="(${1#--alang=})"
      ;;
    --out=*)
			outputdir="${1#--out=}"
			;;
		--sopts=*)
		  start="${1#--sopts=}"
		  ;;
		--dopts=*)
		  duration="${1#--dopts=}"
		  ;;
		*)
		  break
		  ;;
	esac
	shift
done

echo "Using $plang/$slang"
if [ -z "$outputdir" ] ; then
	echo "Must specify --out=<dir>"
  exit 1
fi

if [ ! -d "$outputdir" ] ; then
  mkdir -p "$outputdir" || exit 1
fi

get_map_options() {
  any=()
  audio=()
  subs=()
  video=()
	
	while read stream type ignore
	do
	  stream=$(echo $stream | cut -d: -f1-2)
	  lang=$(echo $stream | sed 's/^[:0-9]*//')
	  stream=$(echo $stream | tr -dc :0-9)
	  if [ -z "$lang" ] ; then
	    if [ "$type" = "Video:" ] ; then
			  video+=( "-map $stream" )
			else
				any+=( "-map $stream" )
			fi
			continue
		fi
	  
	  case "$type" in
	    Audio:)
	      if [ "$lang" = "$plang" ] ; then
	        audio=( "-map $stream" "${audio[@]}" )
	      else
					audio+=( "-map $stream" )
				fi
				;;
	    Subtitle:)
	      if [ "$lang" = "$slang" ] ; then
	        subs=( "-map $stream" "${subs[@]}" )
	      else
					subs+=( "-map $stream" )
				fi
				;;
			Video:)
			  video+=( "-map $stream" )
			  ;;
			*)
			  any+=( "-map $stream" )
		esac
	done
	echo "${video[@]}"
	echo "${audio[@]}"
	echo "${subs[@]}"
	echo "${any[@]}"
}

process_file() {
	local in="$1"
  local output="$outputdir/$(basename "$1")"
	
  local stream_info="$(ffmpeg -i "$in" 2>&1 | grep 'Stream #' | sed 's/Stream #//')"
  local mappings="$(echo "$stream_info" | get_map_options)"
  echo "$stream_info"
  echo "$mappings"

  ffmpeg $start -i "$in" \
			$mappings \
  -c:v copy \
  -c:a copy \
  -c:s copy \
  $duration \
  "$output"
}

for infile in "$@"
do
  process_file "$infile"
done

