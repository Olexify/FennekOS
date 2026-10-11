# Fennek OS base image: Universal Blue's Kinoite (Fedora KDE atomic + full codecs, hardware video decode)
# + Fennek OS defaults.
FROM ghcr.io/ublue-os/kinoite-main:44

COPY system_files/ /
# Second copy only as a file list, so build.sh can fix permissions (a Windows checkout has none).
COPY system_files/ /tmp/system_files/
COPY build.sh /tmp/build.sh
RUN bash /tmp/build.sh && rm -rf /tmp/build.sh /tmp/system_files && bootc container lint
