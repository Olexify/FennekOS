# Fennek OS base image: Universal Blue's Kinoite (Fedora KDE atomic + full codecs, hardware video decode)
# + Fennek OS defaults. Build with podman/buildah (the base has ~256 layers; Docker's limit is ~127).
# Builds pass the signature-verified digest (see verify-base.sh); never build FROM the bare tag.
ARG BASE_IMAGE=ghcr.io/ublue-os/kinoite-main:44
FROM ${BASE_IMAGE}

# Version (tools/fennek-version.py, from the milestones file) and an immutable build id (date + commit), set by CI.
ARG FENNEK_VERSION=0.0.0
ARG FENNEK_BUILD=local
# "nvidia": the edition for NVIDIA graphics (built FROM Universal Blue's kinoite-nvidia, with NVIDIA's driver)
ARG FENNEK_EDITION=
LABEL org.opencontainers.image.version="${FENNEK_VERSION}" \
      org.fennek.build="${FENNEK_BUILD}"
LABEL org.opencontainers.image.title="Fennek OS" \
      org.opencontainers.image.description="Linux desktop for people who want a familiar, classic desktop: familiar, private, secure." \
      org.opencontainers.image.source="https://github.com/Olexify/FennekOS" \
      org.opencontainers.image.licenses="GPL-3.0-only"

# One layer for everything we add: the build context is mounted, not copied.
RUN --mount=type=bind,source=.,target=/ctx,ro \
    cp -a --no-preserve=ownership /ctx/system_files/. / && \
    FENNEK_VERSION="${FENNEK_VERSION}" FENNEK_BUILD="${FENNEK_BUILD}" FENNEK_EDITION="${FENNEK_EDITION}" \
        bash /ctx/build.sh /ctx/system_files && \
    bootc container lint
