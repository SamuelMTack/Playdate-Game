import re
import subprocess
try:
    import click
except ModuleNotFoundError as e:
    print(f"Module not found: {e}, please install the required package using pip.")
    exit(1)

"""
    SETUP:
        1. pip3 install click
        2. make sure arm-none-eabi-addr2line is in your $PATH

    USAGE:
        python3 firmware_symbolizer.py crashlog.txt game.elf

"""


@click.command()
@click.argument("crashlog", type=click.Path(exists=True))
@click.argument("elf", type=click.Path(exists=True))
def symbolize(crashlog, elf):
    cl_contents = open(crashlog, "r").read()

    cl_blocks = re.split(r"\n\n", cl_contents)

    for block in cl_blocks:
        matches = re.search(r"lr:([0-9a-f]{8})\s+pc:([0-9a-f]{8})", block)

        if matches:
            print(block, "\n")

            lr = matches.group(1)
            pc = matches.group(2)

            cmd = f"arm-none-eabi-addr2line -f -i -p -e \"{elf}\" '0x{pc}' '0x{lr}'"
            stack = subprocess.check_output(cmd, shell=True).decode("ASCII")
            print(stack)


if __name__ == "__main__":
    symbolize()
