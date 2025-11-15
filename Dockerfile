FROM debian:12-slim

ENV GOGS_VERSION=0.12.11 \
    GOGS_HOME=/gogs

# 1) System deps – rarely change
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        tini \
        xorg \
        fluxbox \
        tigervnc-standalone-server \
        tigervnc-tools \
        firefox-esr \
        novnc \
        websockify \
        sqlite3 \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf vnc.html /usr/share/novnc/index.html

# 2) Gogs binary – vendored tarball (no external network dependency)
# Place the tarball in your repo at: vendor/gogs_0.12.11_linux_amd64.tar.gz
COPY vendor/gogs_0.12.11_linux_amd64.tar.gz /tmp/gogs.tar.gz

RUN mkdir -p "$GOGS_HOME" && \
    cd /tmp && \
    tar -xzf gogs.tar.gz && \
    mv gogs/* "$GOGS_HOME"/ && \
    rm -rf gogs gogs.tar.gz

# 3) Users + dirs – rare
RUN useradd -m -d /home/git -s /bin/bash git && \
    mkdir -p \
      "$GOGS_HOME/data/repositories" \
      "$GOGS_HOME/data/sessions" \
      "$GOGS_HOME/log" \
      "$GOGS_HOME/custom/conf" && \
    chown -R git:git "$GOGS_HOME" && \
    chmod -R 755 "$GOGS_HOME"

# 4) CONFIG + SCRIPTS – these change most often (best cache behaviour)
COPY start.sh /usr/local/bin/start.sh
COPY gogs/custom/conf/app.ini "$GOGS_HOME/custom/conf/app.ini"

# Add helper scripts for grader
COPY scripts/gogs_login /usr/local/bin/gogs_login
COPY scripts/gogs_pull_data /usr/local/bin/gogs_pull_data
COPY scripts/gogs_push_data /usr/local/bin/gogs_push_data


RUN chmod +x \
      /usr/local/bin/start.sh \
      /usr/local/bin/gogs_login \
      /usr/local/bin/gogs_pull_data \
      /usr/local/bin/gogs_push_data \
    && chown git:git \
      "$GOGS_HOME/custom/conf/app.ini" \
      /usr/local/bin/start.sh \
      /usr/local/bin/gogs_login \
      /usr/local/bin/gogs_pull_data \
      /usr/local/bin/gogs_push_data

# (Optional) 5) Pre-initialize DB + admin at build time for faster runtime startup
# Once you’ve tested the CLI flags for your Gogs build, you can uncomment this
# to bake an initial SQLite DB and admin user directly into the image.
#
# RUN set -e; \
#     cd "$GOGS_HOME"; \
#     GOGS_CUSTOM="$GOGS_HOME/custom" ./gogs admin create-user \
#       --name admin \
#       --password engineer123 \
#       --email admin@example.com \
#       --admin || true

USER git
WORKDIR /gogs

EXPOSE 3000 6080

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/start.sh"]
