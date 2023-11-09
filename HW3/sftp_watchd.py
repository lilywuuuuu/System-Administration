#!/usr/local/bin/python3.9

import os
import pwd
import time
import logging
import subprocess
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler


class ExeFileHandler(FileSystemEventHandler):
    def on_created(self, event):
        if event.is_directory:
            return None
        elif event.src_path.endswith('.exe'):
            file_stats = os.stat(event.src_path)
            uid = file_stats.st_uid
            upload_user = pwd.getpwuid(uid).pw_name
            # logging.info('%s violate file detected. Uploaded by %s.', event.src_path, upload_user)
            subprocess.run(['mv', event.src_path, '/home/sftp/hidden/.exe/'])
            subprocess.run(['echo', event.src_path, " violate file detected. Uploaded by ", upload_user, "."], '| logger -p local1.warning')
    def move_existing_files(self, directory):
        for root, dirs, files in os.walk(directory):
            for file in files:
                if file.endswith('.exe'):
                    file_path = os.path.join(root, file)
                    file_stats = os.stat(file_path)
                    uid = file_stats.st_uid
                    upload_user = pwd.getpwuid(uid).pw_name
                    # logging.info('%s violate file detected. Uploaded by %s.', file_path, upload_user)
                    subprocess.run(['mv', file_path, '/home/sftp/hidden/.exe/'])
                    subprocess.run(['echo', file_path, " violate file detected. Uploaded by ", upload_user, "."], '| logger -p local1.warning')



if __name__ == "__main__":
    with open('/var/run/sftp_watchd.pid', 'w') as f:
        f.write(str(os.getpid()))

    # Start the observer
    event_handler = ExeFileHandler()
    event_handler.move_existing_files("/home/sftp/public/")
    observer = Observer()
    observer.schedule(event_handler, path='/home/sftp/public/', recursive=False)
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()

    # logging
    logging.basicConfig(
        filename='/var/log/sftp_watchd.log', 
        level=logging.INFO, 
        format='%(asctime)s %(hostname)s sftp_watchd: %(message)s', 
        datefmt='%m/%d/%Y %I:%M:%S %p')
    
    os.remove('/var/run/sftp_watchd.pid')
