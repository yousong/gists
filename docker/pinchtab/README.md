## Run

```bash
docker run -d \
  --name pinchtab-vnc \
  -p 127.0.0.1:9867:9867 \
  -p 127.0.0.1:5800:5800 \
  -p 127.0.0.1:5900:5900 \
  -v pinchtab-vnc-data:/data \
  --shm-size=2g \
  pinchtab/pinchtab-vnc
```

Access the VNC web interface at http://localhost:5800

## Docker Compose

```yaml
services:
  pinchtab-vnc:
    build:
      context: .
      dockerfile: Dockerfile.vnc
    container_name: pinchtab-vnc
    ports:
      - "9867:9867"
      - "5800:5800"
      - "5900:5900"
    volumes:
      - pinchtab-vnc-data:/data
    environment:
      PINCHTAB_TOKEN: ${PINCHTAB_TOKEN:-}
      VNC_RESOLUTION: ${VNC_RESOLUTION:-1920x1080}
    restart: unless-stopped
    shm_size: "2gb"
    tmpfs:
      - /tmp:size=512m,noexec,nosuid,nodev
      - /run:size=64m,noexec,nosuid,nodev
    # Uncomment for Intel GPU acceleration
    # devices:
    #   - /dev/dri:/dev/dri
    security_opt:
      - no-new-privileges:true
    mem_limit: 4g
    cpus: "2.0"

volumes:
  pinchtab-vnc-data:
```

## Security Options

| Option | Description |
|--------|-------------|
| `security_opt: no-new-privileges:true` | Prevents processes from gaining additional privileges via setuid/setgid or file capabilities. Even if suid binaries exist, they cannot escalate privileges. |
| `tmpfs` | Mounts `/tmp` and `/run` as temporary filesystems with security restrictions. Prevents persistent writes to sensitive directories. |

### Why Some Options Are Omitted

Compared to the headless `Dockerfile`, the VNC image omits these security hardening options:

| Omitted Option | Reason |
|----------------|--------|
| `read_only: true` | The jlesage baseimage-gui requires write access to `/config`, `/tmp/.X11-unix`, `/var/run`, and other paths for X11 socket files, VNC state, and window manager configuration. A read-only root filesystem would break the VNC stack. |
| `cap_drop: ALL` | Xvnc requires `IPC_LOCK` for shared memory operations, and openbox may require `SYS_NICE` for process scheduling. Dropping all capabilities would cause the VNC server or window manager to fail at startup. |

These trade-offs are necessary to support the graphical environment. The container still provides isolation via cgroups, seccomp, and the `no-new-privileges` flag.
