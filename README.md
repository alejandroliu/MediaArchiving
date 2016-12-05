# MediaArchiving

Scripts for archiving media

Scripts:

- archive-dvd : Create an iso image from a DVD.
- alltitles : Extract titles/chapters from a DVD.
- auto.sh : Used to transcode titles/chapters extracted by `alltitles`

## archive-dvd

This script uses `vobcopy` and `mkisofs` to create an ISO file.
Just run the script and insert a DVD, you will get an ISO file
in return.

## alltitles

Usage:

    [option_vars] sh alltitles [chapter]

Option vars:

- drive=[device-path] defaults to /dev/sr0
- titles="01 02 03 ..." defaults to all titles in DVD (as listed by
  lsdvd)  
  You can also specify titles as:  
  `title="01,1-4 01,5-8"`  
  This will create two files, one with track 1, chaptes one trough
  four (inclusive)
  and another one with track 1, chapters five through eigth (inclusive)

Command options:

chapter: Leave blank for all chapters, otherwise:

    -chapter <start_chapter>[-<end_chapter>]

Will dump starting from <start_chapter> until <end_chapter>. (or end)
If you only want to extract chapter 7 by itself, use -chapter 7-7

## auto.sh

Usage:

    sh $0 [options] <vob files>

vob files must be the ones extracted from `alltitles`.

Options:

* --preview|-p : Only encode 30 seconds from 4 minutes in
* --copy|-c : Do only copy
* --interlace|-i : Force interlace filter
* --no-interlace|+i : Disables interlace filter

## Dependancies


- libdvdcss (or equivalent).  
  This is used by the dvdread library to decode CSS protected DVDs.
- libdvdread  
  This is used to read DVD by a number of binaries.
- [vobcopy](http://vobcopy.org/download/release_notes_and_download.shtml)  
  Used by `archive-dvd` to extract the data that will be used to create
  the ISO image.  Uses `libdvdread`.
- udisks or udisks2  
  Used by the scripts to detect when a CD/DVD is inserted.
- cdrkit
  Used to create the iso images by `archive-dvd`.
- lsdvd  
  Used by `alltitles.sh` to get track information.
- mplayer  
  Used by `alltitles.sh` to extract DVD titles/chapters.
- ffmpeg  
  Used by `alltitles.sh` to encode video.
