#!/bin/bash

# decode <input.mp3> <output.wav>
function decode {
    mpg123 -w "$2" "$1"
}

# encode <input.wav> <output.mp3>
function encode {
    lame --preset 64 -h "$1" "$2"
}

# copytags <source.mp3> <dest.mp3>
function copytags {
    id3cp "$1" "$2"
}


function usage {
    if [ "$1" ]; then
	echo "Error:  $1" >&2
	echo >&2
    fi
    echo "Usage:  $0 <input_dir> <output_dir> [convert_options]" >&2
    echo
    echo "WARNING:  If <input_dir> and <output_dir> are the same, the original"
    echo "          files will be overwritten."
    exit 1
}


AUDIOBOOKPACER=$(dirname $0)/audiobookpacer.rb

INPUT="$1"
OUTPUT="$2"
[ $# -lt 2 ] && usage
[ -d "$INPUT" ] || usage "'$INPUT' is not a directory"
[ -d "$OUTPUT" ] || usage "'$OUTPUT' is not a directory"
shift 2

TMP1=$(tempfile -s .wav)
TMP2=$(tempfile -s .wav)

for file in "$INPUT"/*.[mM][pP]3; do
    echo
    echo "******  Converting $file  ******"
    echo
    out="$OUTPUT/$(basename "$file")"
    decode "$file" "$TMP1"
    ruby $AUDIOBOOKPACER "$@" "$TMP1" "$TMP2"
    encode "$TMP2" "$out"
    copytags "$file" "$out"
done

rm -f "$TMP1" "$TMP2"
