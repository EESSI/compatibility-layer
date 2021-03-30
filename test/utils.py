from collections import namedtuple
import subprocess
import pytest

Command = namedtuple('Command', ['exit_code', 'output'])

def run_local(cmd):
    """Run a command locally."""
    run_cmd = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return Command(run_cmd.returncode, run_cmd.stdout.decode('utf-8').strip())

def run_prefix(cmd):
    """Run a command inside a Gentoo Prefix environment using its startprefix script."""
    run_cmd = subprocess.run(pytest.startprefix, input=bytes(cmd, 'utf-8'), stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    stdout_lines = run_cmd.stdout.decode('utf-8').strip().split('\n')
    exit_code = int(stdout_lines[-1].split(' ')[-1])
    return Command(exit_code, '\n'.join(stdout_lines[1:-1]))
