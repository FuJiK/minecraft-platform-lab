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

## Local Quick Start

Ubuntu上で最短起動する場合はこれだけです。

```bash
git clone https://github.com/FuJiK/minecraft-platform-lab.git
cd minecraft-platform-lab
bash scripts/local-up.sh
```

`local-up.sh` は以下を自動実行します。

- Docker / Docker Compose v2 の存在確認
- Docker daemon の疎通確認
- `.env` が無ければ `.env.example` から自動生成
- RCON password をランダム生成
- `data/` / `backups/` 作成
- `docker compose config` 検証
- Image pull
- Server 起動
- Health Check が `healthy` になるまで待機
- localhost / LAN の接続先表示

起動後の状態確認:

```bash
bash scripts/local-status.sh
```

ログ追跡:

```bash
docker compose logs -f minecraft
```

停止:

```bash
bash scripts/local-down.sh
```

`./data` は残るため、停止しても world は保持されます。

## Manual Start

手動で各ステップを確認したい場合:

```bash
cp .env.example .env
nano .env

docker compose config
docker compose pull
docker compose up -d
docker compose ps
docker compose logs -f minecraft
```

## Connection

同じUbuntu機のJavaクライアント:

```text
localhost:25565
```

Docker Host のLAN IP確認:

```bash
hostname -I
```

例えば `192.168.1.20` の場合:

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

## Health Check

```bash
bash scripts/healthcheck.sh
```

## Backup

```bash
bash scripts/backup.sh
```

バックアップは `./backups/` に保存されます。

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

詳細: [`docs/ubuntu-client.md`](docs/ubuntu-client.md)

## PS5 / Bedrock

サーバー側は Geyser + Floodgate で Bedrock を受けられる構成です。

ただしPS5版は任意の外部サーバーアドレスを直接追加する操作に制約があるため、まずスマホ・タブレット・Windows BedrockなどでLAN内の `UDP/19132` を検証してから、PS5側の接続経路を切り分けます。

詳細: [`docs/bedrock-crossplay.md`](docs/bedrock-crossplay.md)

## Learning Roadmap

1. `local-up.sh` でローカル起動
2. Ubuntu上のJava Editionから `localhost:25565` へ接続
3. LAN 内のJava Editionから TCP/25565 へ接続
4. world データの永続化を確認
5. Geyser/FloodgateでBedrock接続を確認
6. Backup / Restore を実装
7. Health Check と障害切り分け
8. Prometheus / Grafana などで Observability を追加
9. GitHub Actions で構成検証
10. Terraform / Ansible などで再構築可能にする

詳細は [`docs/learning-roadmap.md`](docs/learning-roadmap.md) を参照してください。

## Security baseline

- Java側の `online-mode` は有効のままにする
- RCON (`25575`) はホストへ公開しない
- ルーターで `25565/tcp` を WAN に Port Forwarding しない
- ルーターで `19132/udp` を WAN に Port Forwarding しない
- `.env`、world データ、backup は Git に commit しない

## EULA

初回起動には Minecraft EULA への同意が必要です。本ラボでは Compose の `EULA=TRUE` により同意を明示します。利用前に Minecraft の EULA を確認してください。
