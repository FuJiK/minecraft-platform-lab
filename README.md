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
- Java / Bedrock クロスプレイのGateway構成
- 将来的な IaC 化

> このラボは Minecraft の認証回避を目的としません。Java側は `ONLINE_MODE=TRUE` を前提にします。

## Architecture

```text
                         GitHub
                           |
                     GitHub Actions
                           |
                    compose validation
                           |
                           v
+--------------------------------------------------+
| Ubuntu 26.04 / MacBookPro11,1                    |
|                                                  |
|  +--------------------------------------------+  |
|  | Docker                                     |  |
|  |                                            |  |
|  |  Paper Minecraft Server                   |  |
|  |    + Geyser                               |  |
|  |    + Floodgate                            |  |
|  |                                            |  |
|  |  TCP :25565  <- Java Edition              |  |
|  |  UDP :19132  <- Bedrock Edition           |  |
|  |  /data -> ./data                          |  |
|  +--------------------------------------------+  |
|                         |                        |
|                    health check                 |
|                         |                        |
|                    backup script                |
|                                                  |
|  Prism Launcher                                  |
|    -> Fabric                                     |
|       -> Sodium / Lithium / FerriteCore          |
|          / ImmediatelyFast                       |
+--------------------------------------------------+
             |                     |
        Java client          Bedrock client
```

ルーターで TCP/25565 / UDP/19132 をインターネット向けに Port Forwarding しなければ、宅内 LAN 用として運用できます。

## Server Stack

- Minecraft Java Server
- Paper
- Geyser
- Floodgate
- Docker Compose

古い MacBookPro11,1 / RAM 8GB を想定して、初期値は軽めにしています。

```text
Server memory: 2G
Container limit: 3G
View distance: 6
Simulation distance: 4
Max players: 5
```

## Prerequisites

- Docker Engine
- Docker Compose v2
- Java Editionを実際にプレイする場合はMinecraftの正規ライセンス
- 同一 LAN / Wi-Fi

Ubuntuクライアント側のセットアップは [`docs/ubuntu-client.md`](docs/ubuntu-client.md) を参照してください。

Bedrock/Geyser側は [`docs/bedrock-crossplay.md`](docs/bedrock-crossplay.md) を参照してください。

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
docker compose pull
docker compose up -d
```

### 5. 状態とログを確認する

```bash
docker compose ps
docker compose logs -f minecraft
```

ログ上で Paper / Geyser / Floodgate が読み込まれていることを確認します。

### 6. Docker Host の LAN IP を確認する

Linux:

```bash
hostname -I
```

例えば Docker Host が `192.168.1.20` の場合:

Java Edition:

```text
192.168.1.20:25565
```

Bedrock Edition:

```text
Address: 192.168.1.20
Port: 19132
```

## Port

| 用途 | Protocol | Port |
|---|---|---:|
| Java Edition | TCP | 25565 |
| Bedrock / Geyser | UDP | 19132 |
| RCON | TCP | 25575 |

RCON 25575 はコンテナ内部でのみ利用し、ホストには公開しません。

## TCP 疎通確認

Java側:

```bash
nc -vz 127.0.0.1 25565
```

Bedrock側の待受確認:

```bash
ss -lunp | grep 19132
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

## Ubuntu Client

MacBookPro11,1 + Ubuntu 26.04 では、クライアント側は Java Edition + Fabric の軽量構成を推奨します。

```text
Prism Launcher
  -> Fabric
     -> Sodium
     -> Lithium
     -> FerriteCore
     -> ImmediatelyFast
```

詳細:

[`docs/ubuntu-client.md`](docs/ubuntu-client.md)

## PS5 / Bedrock

サーバー側は Geyser + Floodgate で Bedrock を受けられる構成です。

ただしPS5版は、任意の外部サーバーアドレスを直接追加する操作に制約があるため、まずスマホ・タブレット・Windows BedrockなどでLAN内の `UDP/19132` を検証してから、PS5側の接続経路を切り分けます。

詳細:

[`docs/bedrock-crossplay.md`](docs/bedrock-crossplay.md)

## Learning Roadmap

1. Docker Compose で Paper Server を起動
2. LAN 内のJava Editionから TCP/25565 へ接続
3. world データの永続化を確認
4. Geyser/FloodgateでBedrock接続を確認
5. Backup / Restore を実装
6. Health Check と障害切り分け
7. Prometheus / Grafana などで Observability を追加
8. GitHub Actions で構成検証
9. Terraform / Ansible などで再構築可能にする

詳細は [`docs/learning-roadmap.md`](docs/learning-roadmap.md) を参照してください。

## Security baseline

- Java側の `online-mode` は有効のままにする
- RCON (`25575`) はホストへ公開しない
- ルーターで `25565/tcp` を WAN に Port Forwarding しない
- ルーターで `19132/udp` を WAN に Port Forwarding しない
- `.env`、world データ、backup は Git に commit しない

## EULA

初回起動には Minecraft EULA への同意が必要です。本ラボでは Compose の `EULA=TRUE` により同意を明示します。利用前に Minecraft の EULA を確認してください。

## First Run

```bash
git pull
cp .env.example .env
nano .env

docker compose config
docker compose pull
docker compose up -d
docker compose ps
docker compose logs -f minecraft
```

まずは Paper + Geyser + Floodgate が正常に起動し、Ubuntu上のJava Clientから `localhost:25565` へ入れるところまでをPhase 1とします。
