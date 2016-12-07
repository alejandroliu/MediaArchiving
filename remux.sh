#!/bin/sh
######################################################################
#start="-y -ss 00:05:00"
#duration="-t 00:02:00"

outputdir=""
plang="(eng)"


while [ $# -gt 0 ]
do
  case "$1" in
    --lang=*)
      plang="(${1#--lang=})"
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

echo "Using $plang"
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
	
	while read stream type ignore
	do
	  stream=$(echo $stream | cut -d: -f1-2)
	  lang=$(echo $stream | sed 's/^[:0-9]*//')
	  stream=$(echo $stream | tr -dc :0-9)
	  if [ -z "$lang" ] ; then
			any+=( "-map $stream" )
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
	      if [ "$lang" = "$plang" ] ; then
	        subs=( "-map $stream" "${subs[@]}" )
	      else
					subs+=( "-map $stream" )
				fi
				;;
			*)
			  any+=( "-map $stream" )
		esac
	done
	echo "${any[@]}"
	echo "${audio[@]}"
	echo "${subs[@]}"
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

