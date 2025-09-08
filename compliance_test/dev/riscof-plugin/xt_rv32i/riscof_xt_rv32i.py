import os
import re
import shutil
import subprocess
import shlex
import logging
import random
import string
from string import Template
import sys

import riscof.utils as utils
import riscof.constants as constants
from riscof.pluginTemplate import pluginTemplate

logger = logging.getLogger()


class xt_rv32i(pluginTemplate):
    __model__ = "xt_rv32i"

    # TODO: please update the below to indicate family, version, etc of your DUT.
    __version__ = "0.0.1"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        config = kwargs.get("config")

        # If the config node for this DUT is missing or empty. Raise an error. At minimum we need
        # the paths to the ispec and pspec files
        if config is None:
            print("Please enter input file paths in configuration.")
            raise SystemExit(1)

        # In case of an RTL based DUT, this would be point to the final binary executable of your
        # test-bench produced by a simulator (like verilator, vcs, incisive, etc). In case of an iss or
        # emulator, this variable could point to where the iss binary is located. If 'PATH variable
        # is missing in the config.ini we can hardcode the alternate here.
        self.dut_exe = os.path.abspath(
            os.path.join(
                config["PATH"] if "PATH" in config else "",
                config["dut"] if "dut" in config else "xt_rv32i",
            )
        )

        # Number of parallel jobs that can be spawned off by RISCOF
        # for various actions performed in later functions, specifically to run the tests in
        # parallel on the DUT executable. Can also be used in the build function if required.
        self.num_jobs = str(config["jobs"] if "jobs" in config else 1)

        # Path to the directory where this python file is located. Collect it from the config.ini
        self.pluginpath = os.path.abspath(config["pluginpath"])

        # Collect the paths to the  riscv-config absed ISA and platform yaml files. One can choose
        # to hardcode these here itself instead of picking it from the config.ini file.
        self.isa_spec = os.path.abspath(config["ispec"])
        self.platform_spec = os.path.abspath(config["pspec"])

        # We capture if the user would like the run the tests on the target or
        # not. If you are interested in just compiling the tests and not running
        # them on the target, then following variable should be set to False
        if "target_run" in config and config["target_run"] == "0":
            self.target_run = False
        else:
            self.target_run = True

    def initialise(self, suite, work_dir, archtest_env):

        # capture the working directory. Any artifacts that the DUT creates should be placed in this
        # directory. Other artifacts from the framework and the Reference plugin will also be placed
        # here itself.
        self.work_dir = work_dir

        # capture the architectural test-suite directory.
        self.suite_dir = suite

        # Capture the environment.
        self.archtest_env = archtest_env

    def build(self, isa_yaml, platform_yaml):

        # load the isa yaml as a dictionary in python.
        ispec = utils.load_yaml(isa_yaml)["hart0"]

        # capture the XLEN value by picking the max value in 'supported_xlen' field of isa yaml. This
        # will be useful in setting integer value in the compiler string (if not already hardcoded);
        self.xlen = "64" if 64 in ispec["supported_xlen"] else "32"

        # for xt_rv32i start building the '--isa' argument. the self.isa is dutnmae specific and may not be
        # useful for all DUTs
        self.isa = "rv" + self.xlen
        for ext in ["I", "M", "C", "F", "D"]:
            if ext in ispec["ISA"]:
                self.isa += ext.lower()

        # Note the march is not hardwired here, because it will change for each test.
        # Similarly the output elf name and compile macros will be assigned later in the runTests function.
        self.mabi = "lp64 " if self.xlen == "64" else "ilp32 "
        self.compile_exe = f"riscv{self.xlen}-unknown-elf-gcc"
        self.objcopy_exe = f"riscv{self.xlen}-unknown-elf-objcopy"
        self.objdump_exe = f"riscv{self.xlen}-unknown-elf-objdump"
        self.symbols_exe = f"riscv{self.xlen}-unknown-elf-nm"

    def runTests(self, testList):

        # TUDO: figure out why there is an extra character in the name.
        name = self.name[:-1]

        # Delete Makefile if it already exists.
        if os.path.exists(self.work_dir + "/Makefile." + name):
            os.remove(self.work_dir + "/Makefile." + name)
        # create an instance the makeUtil class that we will use to create targets.
        make = utils.makeUtil(
            makefilePath=os.path.join(self.work_dir, "Makefile." + name)
        )

        # set the make command that will be used. The num_jobs parameter was set in the __init__
        # function earlier
        make.makeCommand = "make -k -j" + self.num_jobs

        # we will iterate over each entry in the testList. Each entry node will be refered to by the
        # variable testname.
        for testname in testList:

            # for each testname we get all its fields (as described by the testList format)
            testentry = testList[testname]

            # we capture the path to the assembly file of this test
            test = testentry["test_path"]

            # capture the directory where the artifacts of this test will be dumped/created. RISCOF is
            # going to look into this directory for the signature files
            test_dir = testentry["work_dir"]

            # name of the elf file after compilation of the test
            elf = "my.elf"

            # Name of the signature file as per requirement of RISCOF.
            # RISCOF expects the signature to be named as DUT-<dut-name>.signature.
            # The below variable creates an absolute path of signature file.
            sig_file = os.path.join(test_dir, name + ".signature")

            # for each test there are specific compile macros that need to be enabled. The macros in
            # the testList node only contain the macros/values. For the gcc toolchain we need to
            # prefix with "-D". The following does precisely that.
            compile_macros = " ".join([f"-D{macro}" for macro in testentry["macros"]])

            # substitute all variables in the compile command that we created in the initialize
            # function
            compile_cmd = self.compile_exe + (
                f" -mabi={self.mabi}"
                f" -march={testentry['isa'].lower()}"
                f" -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -g"
                f" -T {self.pluginpath}/env/link.ld"
                f" -I {self.pluginpath}/env/"
                f" -I {self.archtest_env}"
                f" {test} -o {elf} {compile_macros}"
            )

            # Command for converting elf file into a binary/hex file for loading into HDL testbench memory.
            # Uncomment either the binary or hex version, depending on your.
            objcopy_cmd = self.objcopy_exe + f" -O binary {elf} {elf}.bin"
            # objcopy_cmd = self.objcopy_exe + f' -O binary {elf} {elf}.hex'

            # Disassemble the ELF file for debugging purposes
            objdump_cmd = self.objdump_exe + (
                f" -M no-aliases -M numeric" f" -D {elf} > {elf}.disass"
            )

            # extract listed symbols
            symbols_list = [
                "rvtest_entry_point",
                "begin_signature",
                "end_signature",
                "tohost",
                "fromhost",
            ]
            # construct dictionary of listed symbols
            symbols_cmd = []
            # get symbol list from elf file
            symbols_cmd.append(self.symbols_exe + f" {elf} > dut.symbols")
            for symbol in symbols_list:
                # get symbols from symbol list file
                symbols_cmd.append(
                    f"{symbol}=$$(grep -w {symbol} dut.symbols | cut -c 1-8)"
                )

            # Construct Verilog plusargs dictionary containing file paths.
            firmware = os.path.join(test_dir, elf) + ".bin"
            simulate_plusargs_dict = {
                "firmware": firmware,
                "signature": sig_file,
            }

            # provide ELF symbols as plusargs
            for symbol in symbols_list:
                simulate_plusargs_dict.update({symbol: f"$${symbol}"})

            # Other DUT testbench specific Verilog plusargs can be added here.
            # simulate_plusargs_dict.update({})

            simulate_plusargs = " ".join(
                [f"+{key}={val}" for key, val in simulate_plusargs_dict.items()]
            )

            # if the user wants to disable running the tests and only compile the tests, then
            # the "else" clause is executed below assigning the sim command to simple no action
            # echo statement.
            if self.target_run:
                # set up the simulation command. Template is for spike. Please change.
                simcmd = self.dut_exe + (f" {simulate_plusargs}")
            else:
                simcmd = 'echo "NO RUN"'

            # concatenate all commands that need to be executed within a make-target.
            execute = []
            execute.append(f"cd {test_dir}")
            execute.append(compile_cmd)
            execute.append(objcopy_cmd)
            execute.append(objdump_cmd)
            execute += symbols_cmd
            execute.append(simcmd)

            # create a target. The makeutil will create a target with the name "TARGET<num>" where num
            # starts from 0 and increments automatically for each new target that is added
            # make.add_target(execute)
            make.add_target("@" + ";\\\n".join(execute))

        # if you would like to exit the framework once the makefile generation is complete uncomment the
        # following line. Note this will prevent any signature checking or report generation.
        # raise SystemExit

        # once the make-targets are done and the makefile has been created, run all the targets in
        # parallel using the make command set above.
        make.execute_all(self.work_dir)

        # if target runs are not required then we simply exit as this point after running all
        # the makefile targets.
        if not self.target_run:
            raise SystemExit(0)
