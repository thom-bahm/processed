import time
import subprocess
import psutil

# Threshold for long process in seconds (e.g., 5 seconds for testing)
LONG_PROCESS_THRESHOLD = 5

def send_notification(message):
    try:
        subprocess.run(['notify-send', message], check=True)
    except FileNotFoundError:
        print("notify-send not found. Install it to receive notifications.")

def send_popup(message):
    try:
        subprocess.run(['zenity', '--info', '--text', message, '--title', 'Process Notification'], check=True)
    except FileNotFoundError:
        print("zenity not found. Install it to receive pop-up notifications.")

def is_system_process(cmdline):
    system_processes = ['/sbin/init', '/lib/systemd', '/usr/sbin', '/sbin/']
    for system_process in system_processes:
        if cmdline.startswith(system_process):
            return True
    return False

def monitor_processes():
    seen_processes = set()
    while True:
        print("Checking for finished long-running processes...")
        for proc in psutil.process_iter(['pid', 'create_time', 'cmdline']):
            try:
                pid = proc.info['pid']
                create_time = proc.info['create_time']
                cmdline = ' '.join(proc.info['cmdline'])

                # Skip if it's a system process or kernel thread
                if is_system_process(cmdline) or cmdline.startswith('['):
                    continue

                # Calculate elapsed time
                elapsed_time = time.time() - create_time

                # Check if process has been seen before and if it's finished
                if pid not in seen_processes and elapsed_time >= LONG_PROCESS_THRESHOLD:
                    seen_processes.add(pid)
                    message = f'Process "{cmdline}" (PID: {pid}) finished after running for {int(elapsed_time)} seconds.'
                    print(message)
                    send_popup(message)

            except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                continue
        
        time.sleep(1)  # Check every second

if __name__ == '__main__':
    monitor_processes()

