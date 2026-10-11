/* Sandbox probe: a Windows program that tries to read each path given and writes OK or BLOCKED
   per path into OUTFILE (Proton doesn't pass console output through).
   Usage: probe.exe OUTFILE PATH...
   Build: x86_64-w64-mingw32-gcc -O2 -static -o probe.exe probe.c */
#include <stdio.h>

int main(int argc, char **argv) {
    if (argc < 2) return 2;
    FILE *out = fopen(argv[1], "w");
    if (!out) return 1;
    for (int i = 2; i < argc; i++) {
        FILE *f = fopen(argv[i], "rb");
        fprintf(out, "%s %s\n", f ? "OK" : "BLOCKED", argv[i]);
        if (f) fclose(f);
    }
    fclose(out);
    return 0;
}
