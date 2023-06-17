#!/bin/bash

movies="/mnt/Data/Filmler"

PS3="Please enter your choice: "
options=(
	"MKV Films"
	"MP4 Films"
	"Quit"
)
select options in "${options[@]}"; do
	case $REPLY in
	1)
		# movie=$(find "$movies" -name "*.mkv" -printf "\n%f" | uniq -u | fzf --height=100% --reverse --header-first)
		movie=$(find "$movies" -name "*.mkv" | uniq -u | fzf --height=100% --reverse --header-first)
		kitty nohup mpv "$movie" >/dev/null 2>&1
		break
		;;
	2)
		movie=$(find "$movies" -name "*.mp4" | uniq -u | fzf --height=100% --reverse --header-first)
		kitty nohup mpv "$movie" >/dev/null 2>&1
		break
		;;
	3)
		echo "Have a nice day..."
		exit
		break
		;;
	*)
		echo "Invalid option $REPLY"
		break
		;;
	esac
done
