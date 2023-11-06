echo "Initial OPTIND: $OPTIND"
while getopts abcf: op 2>/dev/null; do
	case $op in 
		a|b|c)
			echo "one of ABC" 
			;;
		f)
			echo $OPTARG 
			;;
		*)
			echo "Default"
			;;
		
	esac
	echo "${OPTIND}-th arg"
done

