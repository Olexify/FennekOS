// Mouse and keyboard for the test desktop (tools/screens.sh), through KWin's fake input protocol. Same commands as
// xdotool: mousemove X Y | click N | mousedown N | mouseup N | sleep S | key Escape|ctrl+q | type [--delay MS] TEXT
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <wayland-client.h>
#include "fake-input.h"

static struct org_kde_kwin_fake_input *fi;
static struct wl_display *dpy;

static void global(void *d, struct wl_registry *r, uint32_t name, const char *iface, uint32_t ver) {
    if (!strcmp(iface, org_kde_kwin_fake_input_interface.name))
        fi = wl_registry_bind(r, name, &org_kde_kwin_fake_input_interface, ver < 4 ? ver : 4);
}
static void global_remove(void *d, struct wl_registry *r, uint32_t name) {}
static const struct wl_registry_listener listener = {global, global_remove};

static void button(int n, int down) {   // 1 left, 3 right
    org_kde_kwin_fake_input_button(fi, n == 3 ? 0x111 : 0x110, down);
    wl_display_roundtrip(dpy);
}
static void keycode(int code, int down) {
    org_kde_kwin_fake_input_keyboard_key(fi, code, down);
    wl_display_roundtrip(dpy);
}
static int letter(char c) {   // Linux key codes by keyboard row
    const char *p;
    if ((p = strchr("qwertyuiop", c))) return 16 + (p - "qwertyuiop");
    if ((p = strchr("asdfghjkl", c))) return 30 + (p - "asdfghjkl");
    if ((p = strchr("zxcvbnm", c))) return 44 + (p - "zxcvbnm");
    fprintf(stderr, "no key for %c\n", c);
    exit(2);
}
static void tap(int code) { keycode(code, 1); usleep(30000); keycode(code, 0); }

int main(int argc, char **argv) {
    dpy = wl_display_connect(NULL);
    if (!dpy) { fprintf(stderr, "no Wayland display\n"); return 1; }
    wl_registry_add_listener(wl_display_get_registry(dpy), &listener, NULL);
    wl_display_roundtrip(dpy);
    if (!fi) { fprintf(stderr, "no fake input protocol\n"); return 1; }
    org_kde_kwin_fake_input_authenticate(fi, "fennek-screens", "test screenshots");
    for (int i = 1; i < argc; i++) {
        const char *c = argv[i];
        if (!strcmp(c, "mousemove")) {
            org_kde_kwin_fake_input_pointer_motion_absolute(fi, wl_fixed_from_int(atoi(argv[i + 1])), wl_fixed_from_int(atoi(argv[i + 2])));
            wl_display_roundtrip(dpy);
            i += 2;
        } else if (!strcmp(c, "click")) {
            int n = atoi(argv[++i]);
            button(n, 1); usleep(30000); button(n, 0);
        } else if (!strcmp(c, "mousedown")) button(atoi(argv[++i]), 1);
        else if (!strcmp(c, "mouseup")) button(atoi(argv[++i]), 0);
        else if (!strcmp(c, "sleep")) usleep(atof(argv[++i]) * 1e6);
        else if (!strcmp(c, "key")) {
            const char *k = argv[++i];
            if (!strcmp(k, "Escape")) tap(1);
            else if (!strncmp(k, "ctrl+", 5)) { keycode(29, 1); tap(letter(k[5])); keycode(29, 0); }
            else tap(letter(k[0]));
        } else if (!strcmp(c, "type")) {
            int delay = 80000;
            if (!strcmp(argv[i + 1], "--delay")) { delay = atoi(argv[i + 2]) * 1000; i += 2; }
            for (const char *t = argv[++i]; *t; t++) { tap(letter(*t)); usleep(delay); }
        } else { fprintf(stderr, "unknown command %s\n", c); return 2; }
    }
    wl_display_flush(dpy);
    return 0;
}
