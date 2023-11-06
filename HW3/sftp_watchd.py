#!/usr/bin/env python3

import os
import shutil
import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class ExeFileHandler(FileSystemEventHandler):
    def on_created(self, event):
        if event.is_directory:
            return None
        elif event.src_path.endswith('.exe'):
            shutil.move(event.src_path, '/home/sftp/hidden/.exe/')

if __name__ == "__main__":
    event_handler = ExeFileHandler()
    observer = Observer()
    observer.schedule(event_handler, path='/home/sftp/public', recursive=False)
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()