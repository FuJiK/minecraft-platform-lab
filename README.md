# Minecraft Platform Lab

Minecraft Java Server を題材に、Docker・LAN・永続化・バックアップ・監視・CI/CD を実践的に学ぶためのハンズオン用リポジトリです。

## Goal

単に Minecraft Server を起動するのではなく、宅内 LAN 上の小さな Platform Engineering / SRE ラボとして段階的に育てます。

- Docker / Docker Compose
- TCP/IP と LAN 内通信
- Port / Firewall
- 設定のコード化
- データ永続化
- Backup / Restore
- Health Check
- Observability
- CI/CD
- 将来的な IaC 化

> このラボは Minecraft の認証回避を目的としません。`ONLINE_MODE=TRUE` を前提にします。

## Architecture

```text
                 GitHub
                   |
             GitHub Actions
                   |
             compose validation
                   |
                   v
+-----------------------------------------+
| Docker Host                             |
|                                         |
|  +-----------------------------------+  |
|  | Minecraft Java Server            |  |
|  | TCP :25565                       |  |
|  | /data -> ./data                  |  |
|  +-----------------------------------+  |
|                 |                       |
|           built-in healthcheck          |
|                 |                       |
|           backup script                 |
+-----------------|-----------------------+
                  |
             Wi-Fi / LAN
                  |
        +---------+---------+
        |                   |
   Minecraft PC A      Minecraft PC B
```

ルーターで TCP/25565 をインターネット向けに Port Forwarding しなければ、基本的には宅内 LAN 用として運用できます。

## Prerequisites

- Docker Engine または Docker Desktop
- Docker Compose v2
- 実際にプレイして接続確認する場合は Minecraft Java Edition の正規クライアント
- 同一 LAN / Wi-Fi

## Quick Start

### 1. Clone

```bash
git clone https://github.com/FuJiK/minecraft-platform-lab.git
cd minecraft-platform-lab
```

### 2. 環境変数を作る

```bash
cp .env.example .env
```

`.env` の `RCON_PASSWORD` は必ず変更してください。

### 3. Compose を検証する

```bash
docker compose config
```

### 4. Server を起動する

```bash
docker compose up -d
```

### 5. 状態とログを確認する

```bash
docker compose ps
docker compose logs -f minecraft
```

### 6. Docker Host の LAN IP を確認する

Linux:

```bash
hostname -I
```

macOS:

```bash
ipconfig getifaddr en0
```

Windows PowerShell:

```powershell
ipconfig
```

例えば Docker Host が `192.168.1.20` の場合、同じ LAN の Minecraft Java Edition から次に接続します。

```text
192.168.1.20:25565
```

## TCP 疎通確認

macOS / Linux:

```bash
nc -vz 192.168.1.20 25565
```

Windows PowerShell:

```powershell
Test-NetConnection 192.168.1.20 -Port 25565
```

## Health Check

```bash
bash scripts/healthcheck.sh
```

## Backup

```bash
bash scripts/backup.sh
```

バックアップは `./backups/` に保存されます。

## Stop

```bash
docker compose down
```

`./data` は Git 管理対象外で、`docker compose down` では削除されません。

## Learning Roadmap

1. Docker Compose で Minecraft Server を起動
2. LAN 内の別端末から TCP/25565 へ接続
3. world データの永続化を確認
4. Backup / Restore を実装
5. Health Check と障害切り分け
6. Prometheus / Grafana などで Observability を追加
7. GitHub Actions で構成検証
8. Terraform / Ansible などで再構築可能にする

詳細は [`docs/learning-roadmap.md`](docs/learning-roadmap.md) を参照してください。

## Security baseline

- Minecraft の `online-mode` は有効のままにする
- RCON (`25575`) はホストへ公開しない
- ルーターで `25565` を WAN に Port Forwarding しない
- `.env`、world データ、backup は Git に commit しない

## EULA

初回起動には Minecraft EULA への同意が必要です。本ラボでは Compose の `EULA=TRUE` により同意を明示します。利用前に Minecraft の EULA を確認してください。

## Next

まずは Phase 1 として、`docker compose up -d` で Server を起動し、LAN 内の別端末から接続できるところまで進めます。
