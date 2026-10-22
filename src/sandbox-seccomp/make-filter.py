#!/usr/bin/python3
"""Fennek OS sandbox seccomp filter (for fennek-run-exe's bubblewrap sandbox), written at image build time.

Everything is allowed except the system calls a sandboxed program has no business with and that sandbox escapes and
kernel exploits lean on (close to Flatpak's list, which runs Wine/Proton games fine): kernel keyrings, ptrace and
reading other processes' memory, kernel modules and kexec, BPF, userfaultfd, io_uring, perf events, handle-based
opens, NUMA memory moves, the kernel log, clocks, swap, accounting, quotas, and typing into the terminal
(TIOCSTI/TIOCLINUX). Namespaces and mounting stay possible: Proton's runtime builds its own container inside the
sandbox (pressure-vessel), still confined by the sandbox around it.
Blocked calls fail with "operation not permitted", so programs see an error rather than a crash.

  make-filter.py OUT.bpf
"""
import errno, platform, sys
import seccomp as sc

BLOCK = """
    syslog uselib acct quotactl quotactl_fd add_key keyctl request_key
    move_pages mbind get_mempolicy set_mempolicy set_mempolicy_home_node migrate_pages
    ptrace process_vm_readv process_vm_writev kcmp
    kexec_load kexec_file_load init_module finit_module delete_module create_module
    bpf userfaultfd perf_event_open lookup_dcookie open_by_handle_at name_to_handle_at
    io_uring_setup io_uring_enter io_uring_register
    vhangup swapon swapoff reboot settimeofday clock_settime clock_adjtime adjtimex stime
    nfsservctl vm86 vm86old iopl ioperm
""".split()
TIOCSTI, TIOCLINUX = 0x5412, 0x541C


def build():
    f = sc.SyscallFilter(defaction=sc.ALLOW)
    native = sc.Arch()   # this machine's
    if platform.machine() == "x86_64":   # 32-bit Windows programs run through the i386 ABI on older Protons
        f.add_arch(sc.Arch.X86)          # (x32 is left out: its calls are refused outright as a foreign architecture)
    for name in BLOCK:
        try:
            f.add_rule(sc.ERRNO(errno.EPERM), name)
        except (RuntimeError, ValueError):
            pass   # not a system call on this architecture
    for req in (TIOCSTI, TIOCLINUX):   # typing commands into the terminal that started it
        f.add_rule(sc.ERRNO(errno.EPERM), "ioctl", sc.Arg(1, sc.MASKED_EQ, 0xFFFFFFFF, req))
    return f, native


if __name__ == "__main__":
    out = sys.argv[1]
    f, _ = build()
    with open(out, "wb") as fh:
        f.export_bpf(fh)
    print("seccomp filter written:", out)
