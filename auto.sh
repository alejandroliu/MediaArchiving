#!/bin/sh
#
# sh $0 [options] <vob files>
#
# vob files must be the ones extracted from alltitles.
#
# Options:
# --preview|-p : Only encode 30 seconds from 4 minutes in
# --copy|-c : Do only copy
# --interlace|-i : Force interlace filter
# --no-interlace|+i : Disables interlace filter
#
preview=""
flags="-fflags +genpts -analyzeduration 1000000k -probesize 1000000k"
vopts="-map 0:v -c:v libx264 -crf 25"
aopts="-map 0:a -c:a aac"
detect=yes
interlaced=
sopts=""
vf=""
langs="$(dirname $(readlink -f $0))/codes.txt"

while [ $# -gt 0 ]
do
  case "$1" in
    --preview|-p)
      preview="-t 30 -ss 00:04:04"
      ;;
    --copy|-c)
      vopts="-map 0 -c copy"
      aopts=""
      detect=no
      ;;
    --interlace|-i)
	  interlaced=yes
	  ;;
	--no-interlace|+i)
	  interlaced=no
	  ;;
    *)
      break
      ;;
  esac
  shift
done

get_metadata() {
  local tag="$1"

  eval $(grep '^ID_' "$tag" | grep '_LANG=')

  sed -n -e '/^Input #0,/,$p' \
    | sed -e '/^Output #0,/,$d' \
    | grep ' Stream #' | cut -d: -f 2-3 \
    | sed -e 's/: \([A-Z]\)[a-z]*$/ \1/' -e 's/\[/ /' -e 's/\]//' | (
    A=0;S=0
    while read num id tag
    do
      [ x"$tag" = x"A" -o x"$tag" = x"S" ] || continue
      eval 'q=$'$tag
      eval $tag'=$(expr $q + 1)'

      eval id='$(('$id'))'
      [ x"$tag" = x"S" ] && id=$(expr $id - 32)
      eval z='$ID_'$tag'ID_'$id'_LANG'
      [ -z "$z" ] && continue
      tri=$(grep ','"$z"'$' < $langs | cut -d, -f1)
      [ -z "$tri" ] && continue
      ltag=$(tr A-Z a-z <<<"$tag")
      #echo " -metadata:$ltag:$q language=$tri ($num $id $tag $q)"
      echo " -metadata:s:$ltag:$q language=$tri"
    done
  )
}

idet() {
  local src="$1"
  ffmpeg -filter:v idet \
    -frames:v 2000 \
    -f rawvideo -y /dev/null \
    -i "$src" 2>&1 | grep 'idet' | grep 'frame detection' \
    |sed -e 's/^.*frame detection: //' \
    |awk 'BEGIN {
		xFF=0
		Pro=0
		Und=0
	  }
	  {
		xFF=xFF + $2 + $4
		Pro=Pro + $6
		Und=Und + $8
	  }
	  END {
		total = xFF + Pro + Und;
		xFF = int(xFF*10/total+0.5);
		Pro = int(Pro*10/total+0.5);
		Und = int(Und*10/total+0.5);
		#print "xFF:",xFF,"Pro:",Pro,"Und",Und; 
		if (Und > 6)
		  print "undetermined";
		else if (Pro > xFF)
		  print "simple";
		else if (xFF > Pro)
		  print "interlaced";
		else
		  print "error ",xFF,Pro,Und;
	  }
	'
}


for src in "$@"
do
  dst="$(sed -e 's/\.vob$/.mkv/' <<<"$src")"
  [ "$dst" = "$src" ] && dst="$dst.mkv"

  # Analyze input...
  if [ "$detect" = yes ] ; then
    echo -n "Analyzing $src..."
    ffprobe=$(ffprobe $flags "$src" 2>&1)
    subs=$(grep ': Subtitle: ' <<<"$ffprobe" | wc -l)
    if [ -z "$interlaced" ] ; then
      srctype=$(idet "$src")
    elif [ "$interlaced" = yes ] ; then
      srctype="interlaced"
    elif [ "$interlaced" = no ] ; then
      srctype="simple"
    else
      srctype="undetermined"
    fi
    echo " Subs: $subs ($srctype)"

    if [ $subs -gt 0 ] ; then
      sopts="-map 0:s -c:s copy"
    else
      sopts=""
    fi
    if [ x"$srctype" = x"interlaced" ] ; then
      vf="-vf yadif"
    else
      vf=""
    fi
  fi
  tag="$(sed -e 's/\.vob$/.txt/' <<<"$src")"
  metatags=""
  if [ -f "$tag" ] ; then
    metatags="$(get_metadata "$tag" <<<"$ffprobe")"
    echo "META: $metatags"
  fi

  ffmpeg \
    $flags \
    $preview \
    -i "$src" \
    $vopts $vf \
    $aopts \
    $sopts \
    $metatags \
    "$dst"
done
