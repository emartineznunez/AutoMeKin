awk '/Zero-point vibrational energy/{getline;print $1;exit}' $1
