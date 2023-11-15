#!/bin/sh
#
# PROVIDE: sftp_watchd
# REQUIRE: LOGIN
# KEYWORD: shutdown

. /etc/rc.subr

name="sftp_watchd"
rcvar=${name}_enable

load_rc_config $name

: ${sftp_watchd_enable:="NO"}

pidfile="/var/run/sftp_watchd.pid"

sftp_watchd_status() {
    if [ -f $pidfile ]; then
        pid=$(cat $pidfile)
        echo "sftp_watchd is running as pid $pid."
    else
        echo "$name is not running."
    fi
}

sftp_watchd_stop() {
    if [ -f $pidfile ]; then
        pid=$(cat $pidfile)
        echo "Kill: $pid"
        kill $pid
        rm -f $pidfile
    else
        echo "$name is not running."
    fi
}
sftp_watchd_start(){
	echo "Starting sftp_watchd"
	/usr/sbin/daemon -f -p /var/run/sftp_watchd.pid /usr/local/bin/sftp_watchd
}
case "$1" in
    start)
        sftp_watchd_start
	;;
    stop)
        sftp_watchd_stop
        ;;
    restart)
        sftp_watchd_stop
	sleep 0.5
        sftp_watchd_start
	;;
    status)
        sftp_watchd_status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac

exit 0