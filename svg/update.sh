#!/usr/bin/env bash

# Try to find Inkscape or ImageMagick's convert
find_converter() {
	if [ -z "$INKSCAPE" ]
	then
		INKSCAPE=$(which inkscape) ||
			INKSCAPE='/Applications/Inkscape.app/Contents/Resources/bin/inkscape'
	fi

	if [ -x "$INKSCAPE" ]
	then
		converter() {
			"$INKSCAPE" \
				"$PWD/$1" \
				-e "$PWD/$2" \
				-w "$3" \
				-h "$4"
		}
	elif which convert &>/dev/null
	then
		converter() {
			convert \
				-background none \
				"$1" \
				-thumbnail "${3}x${4}" \
				-strip \
				"$2"
		}
	else
		return 1
	fi
}

# Scale a length and cut off fraction
#
# @param 1 - length
# @param 2 - multiplier
scale() {
	echo "$1*$2" | bc -l | cut -d '.' -f 1
}

# Make sure $DIR exists
check_dir() {
	[ -d "$DIR" ] || mkdir -p "$DIR" || {
		echo "error: couldn't create $DIR" >&2
		return $?
	}
}

# Returns true if source is older than target file
#
# @param 1 - target file
# @param 2 - source file
newer_than() {
	[ -r "$1" ] && [ -z "$(find "$2" -type f -newer "$1")" ]
}

# Convert SVG files in multiple resolutions to PNG
#
# @param 1 - output path
update() {
	local SVG SIZE NEGATE
	while read -r SVG SIZE NEGATE
	do
		SIZE=${SIZE:-24}

		local DPI MULTIPLIER DIR PNG
		while read -r DPI MULTIPLIER
		do
			DIR="$1-$DPI"
			check_dir || return $?

			PNG=${SVG##*/}
			PNG="$DIR/${PNG%.*}.png"

			newer_than "$PNG" "$SVG" && continue

			converter \
				"$SVG" \
				"$PNG" \
				"$(scale "${SIZE%%x*}" "$MULTIPLIER")" \
				"$(scale "${SIZE##*x}" "$MULTIPLIER")"

			if (( NEGATE ))
			then
				convert "$PNG" -negate "$PNG"
			fi
		done <<EOF
xxxhdpi 4
xxhdpi 3
xhdpi 2
hdpi 1.5
mdpi 1
ldpi .75
EOF
	done
}

type converter &>/dev/null || find_converter || {
	echo "error: no Inkscape and no ImageMagick convert" >&2
	exit 1
}

# debug mipmap SVGs to PNGs
update app/src/debug/res/mipmap << EOF
svg/debug/ic_launcher.svg 48
EOF

# mipmap SVGs to PNGs
update app/src/main/res/mipmap << EOF
svg/ic_launcher.svg 48
EOF

# drawable SVGs to PNGs
update app/src/main/res/drawable << EOF
svg/ic_action_add.svg
svg/ic_action_remove.svg
svg/ic_action_sort.svg
svg/ic_issue_incomplete.svg
svg/ic_issue_yes.svg
svg/ic_issue_maybe.svg
svg/ic_issue_no.svg
svg/ic_edit_enter.svg
svg/ic_empty_arguments.svg 174x128
svg/ic_empty_issues.svg 200x175
svg/ic_splash.svg 128
svg/scale_bar.svg 102x68
svg/scale_frame.svg 96x142
svg/scale_pan.svg 30x48
svg/swipe_left.svg 120x24
svg/swipe_right.svg 120x24
EOF
