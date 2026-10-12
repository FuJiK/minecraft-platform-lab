# Learning Roadmap

このリポジトリは、Minecraft Server を題材に Platform Engineering / SRE の要素を段階的に学ぶためのラボです。

## Phase 1: Containerize

### Goal

Docker Compose で Minecraft Java Server を起動する。

### Tasks

1. `.env.example` を `.env` にコピーする
2. `RCON_PASSWORD` を変更する
3. `docker compose config` で構成を確認する
4. `docker compose up -d` で起動する
5. `docker compose ps` で状態を確認する
6. `docker compose logs -f minecraft` でログを見る

### Check

```bash
docker compose ps
bash scripts/healthcheck.sh
```

Minecraft コンテナが `healthy` になれば完了です。

---

## Phase 2: Networking

### Goal

LAN 内の別端末から TCP/25565 に到達できることを理解する。

### Tasks

1. Docker Host の LAN IP を確認する
2. Client から `25565/tcp` を疎通確認する
3. Minecraft Java Edition から接続する
4. Host Firewall を確認する
5. Router の Port Forwarding が不要であることを確認する

### Check

macOS / Linux:

```bash
nc -vz <DOCKER_HOST_LAN_IP> 25565
```

Windows PowerShell:

```powershell
Test-NetConnection <DOCKER_HOST_LAN_IP> -Port 25565
```

---

## Phase 3: Persistence

### Goal

Container と永続データのライフサイクルを分離する。

### Tasks

1. Minecraft で world に変更を加える
2. `docker compose down` する
3. 再度 `docker compose up -d` する
4. world が保持されていることを確認する
5. `./data` と Container の `/data` の関係を確認する

### Check

```bash
ls -la data
```

---

## Phase 4: Backup / Restore

### Goal

データを保存するだけでなく、復元可能性を考える。

### Tasks

1. `bash scripts/backup.sh` を実行する
2. `backups/` に archive が作成されることを確認する
3. Backup の中身を確認する
4. Restore 手順を別途検証する
5. Retention policy を考える

### Check

```bash
ls -lh backups
```

重要なのは「Backup がある」ことではなく「Restore できる」ことです。

---

## Phase 5: Health / Troubleshooting

### Goal

プロセスが起動していることと、サービスが正常であることの違いを理解する。

### Tasks

1. Docker health status を見る
2. Minecraft Server のログを見る
3. TCP/25565 の listen を確認する
4. 意図的に設定ミスを入れて障害を再現する
5. 原因切り分けを行う

### Check

```bash
docker compose ps
docker compose logs --tail=100 minecraft
bash scripts/healthcheck.sh
```

---

## Phase 6: Observability

### Goal

Metrics / Logs / Alerting を追加する。

候補:

- Prometheus
- Grafana
- Loki
- node_exporter
- cAdvisor

見る指標の例:

- CPU
- Memory
- Disk
- Container restart count
- Server availability
- Player count

---

## Phase 7: CI

### Goal

構成変更を GitHub 上で自動検証する。

初期 CI では以下を検証します。

- `docker compose config`
- Shell script の構文

将来的には以下も候補です。

- hadolint
- ShellCheck
- YAML lint
- Trivy
- Renovate / Dependabot

---

## Phase 8: Reproducible Platform

### Goal

Host が壊れても再構築できる状態を目指す。

候補:

- Ansible: OS / Docker setup
- Terraform: Cloud infrastructure
- Restic: Backup
- Tailscale / VPN: private remote access
- GitHub Actions: controlled deployment

最終的には、Minecraft 自体ではなく「再現可能なサービス運用基盤」が学習成果になります。
