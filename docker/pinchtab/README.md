## Run

```bash
docker run -d \
  --name pinchtab \
  -p 127.0.0.1:9867:9867 \
  -v pinchtab-data:/data \
  --shm-size=2g \
  pinchtab/pinchtab
```

## Docker Compose

```yaml
services:
  pinchtab:
    build: .
    container_name: pinchtab
    ports:
      - "9867:9867"
    volumes:
      - pinchtab-data:/data
    environment:
      PINCHTAB_TOKEN: ${PINCHTAB_TOKEN:-}
    restart: unless-stopped
    # Shared memory is critical for Chrome stability
    shm_size: "2gb"
    read_only: true
    tmpfs:
      - /tmp:size=512m,noexec,nosuid,nodev
      - /run:size=64m,noexec,nosuid,nodev
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    # Limit resources
    mem_limit: 2g
    cpus: "2.0"

volumes:
  pinchtab-data:
```

## Security Options

| Option | Description |
|--------|-------------|
| `read_only: true` | Container root filesystem is read-only. Writes only allowed via `volumes` or `tmpfs`. Prevents attackers from modifying binaries or planting backdoors. |
| `security_opt: no-new-privileges:true` | Prevents processes from gaining additional privileges via setuid/setgid or file capabilities. Even if suid binaries exist, they cannot escalate privileges. |
| `cap_drop: ALL` | Removes all Linux capabilities. Docker grants a default set of capabilities (e.g., `NET_RAW` for raw sockets). Dropping all and adding back only what's needed minimizes the attack surface. |
