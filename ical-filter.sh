#!/bin/bash
TMPDIR="$(mktemp -d)"

# Parse command options
TEMP="$(getopt -n "$(basename "$0")" \
		-o d: \
		--long delete:,delete-tentatives: \
		-- "$@")"
if [ $? != 0 ]; then 
	echo "Terminating..." >&2
	exit 1
fi
eval set -- "$TEMP"
unset TEMP
FILE=
DELETEFILTER='^$'
while true; do
  case "$1" in
    -d | --delete ) DELETEFILTER="$DELETEFILTER\\|\t$2\t"; shift 2 ;;
    --delete-tentatives ) DELETEFILTER="$DELETEFILTER\\|\tX-MICROSOFT-CDO-BUSYSTATUS:TENTATIVE\t"; shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done
FILE="$1"
if [ -z "$FILE" ]; then
	echo "No file: terminating..." >&2
	exit 2
fi

# Get the file
if [ -e "$FILE" ]; then
	cp "$FILE" "$TMPDIR/calendar.ics"
else
	wget "$FILE" -O "$TMPDIR/calendar.ics"
fi

# Filter the file's contents
sed -e "$(nl -ba -nln "$TMPDIR/calendar.ics" | tr -d '\r' | tr '\n' '\t' | sed -e 's,\t\([0-9][0-9]*\)[[:blank:]]*\(\tBEGIN:VEVENT\t\),\n\1\2,g' -e 's,\(\t[0-9][0-9]*\)[[:blank:]]*\(\tEND:VEVENT\)\t,\1\2\n,g' | grep -e "$DELETEFILTER" | sed -e 's/^\([0-9][0-9]*\).*\t\([0-9][0-9]*\)[[:blank:]]*\t[[:blank:]]*END:VEVENT[[:blank:]]*$/\1,\2d;/')" "$TMPDIR/calendar.ics"


