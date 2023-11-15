#!/bin/sh

# PROVIDE: sftp_watchd
# REQUIRE: DAEMON
# KEYWORD: shutdown

. /etc/rc.subr

name="sftp_watchd"
rcvar=sftp_watchd_enable

command="/usr/sbin/daemon"
command_args="-P /var/run/${name}.pid -r /usr/local/bin/sftp_watchd -f"
pidfile="/var/run/${name}.pid"

load_rc_config $name
run_rc_command "$1"