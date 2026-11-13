// Presses Ctrl+V in the window that has the keyboard, through the compositor's fake input (the same way remote
// control tools type): the Clipboard tab pastes what was picked. Nothing else: no mouse, no typing of text.
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <wayland-client.h>
#include "fake-input.h"

static struct org_kde_kwin_fake_input *fi;

static void global(void *d, struct wl_registry *r, uint32_t name, const char *iface, uint32_t ver) {
    if (!strcmp(iface, org_kde_kwin_fake_input_interface.name) && ver >= 4)   // keyboard keys came in version 4
        fi = wl_registry_bind(r, name, &org_kde_kwin_fake_input_interface, 4);
}
static void global_remove(void *d, struct wl_registry *r, uint32_t name) {}
static const struct wl_registry_listener listener = {global, global_remove};

int main(void) {
    struct wl_display *dpy = wl_display_connect(NULL);
    if (!dpy) { fprintf(stderr, "no Wayland display\n"); return 1; }
    wl_registry_add_listener(wl_display_get_registry(dpy), &listener, NULL);
    wl_display_roundtrip(dpy);
    if (!fi) { fprintf(stderr, "no fake input protocol\n"); return 1; }
    org_kde_kwin_fake_input_authenticate(fi, "fennek-paste", "paste what you picked from the clipboard history");
    // ponytail: key codes, not letters: V's place on the classic layout. On a layout like Dvorak that key is another letter.
    const int ctrl = 29, v = 47;
    org_kde_kwin_fake_input_keyboard_key(fi, ctrl, 1); wl_display_roundtrip(dpy);
    org_kde_kwin_fake_input_keyboard_key(fi, v, 1);    wl_display_roundtrip(dpy);
    usleep(30000);
    org_kde_kwin_fake_input_keyboard_key(fi, v, 0);    wl_display_roundtrip(dpy);
    org_kde_kwin_fake_input_keyboard_key(fi, ctrl, 0); wl_display_roundtrip(dpy);
    wl_display_disconnect(dpy);
    return 0;
}
