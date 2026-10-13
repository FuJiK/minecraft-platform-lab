# Bedrock Cross-Play (Geyser + Floodgate)

このラボでは、Java Edition サーバーを Paper で動かし、Geyser + Floodgate をプラグインとして読み込みます。

目的:

```text
Minecraft Java Client
        |
        | TCP/25565
        v
+---------------------------+
| Paper Server              |
|  + Geyser                 |
|  + Floodgate              |
+---------------------------+
        ^
        | UDP/19132
        |
Minecraft Bedrock Client
```

## ポート

Java Edition:

```text
TCP/25565
```

Bedrock Edition:

```text
UDP/19132
```

このリポジトリの `compose.yaml` では両方をホストへ公開します。

## 初回起動

```bash
cp .env.example .env
```

`.env` のRCONパスワードを変更:

```text
RCON_PASSWORD=<十分に長いランダム値>
```

構成確認:

```bash
docker compose config
```

起動:

```bash
docker compose up -d
```

ログ:

```bash
docker compose logs -f minecraft
```

Paperの起動後に、Geyser/Floodgateプラグインが読み込まれたことをログで確認してください。

## 生成ファイル

初回起動後、永続化ディレクトリ `./data` 配下にPaperと各プラグインの設定が生成されます。

確認例:

```bash
find data/plugins -maxdepth 2 -type f | sort
```

Geyser/Floodgate関連のディレクトリが存在することを確認します。

## 接続先

UbuntuホストのLAN IP:

```bash
hostname -I
```

例:

```text
192.168.1.20
```

Java Edition:

```text
192.168.1.20:25565
```

Bedrock Edition:

```text
Address: 192.168.1.20
Port: 19132
```

## Firewall

UFWを使っている場合、LAN内だけに絞る例です。

以下はLANが `192.168.1.0/24` の場合です。実環境に合わせて変更してください。

```bash
sudo ufw allow from 192.168.1.0/24 to any port 25565 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 19132 proto udp
```

確認:

```bash
sudo ufw status numbered
```

## PS5について

PS5版MinecraftはBedrock系ですが、コンソール版では任意の外部サーバーアドレスを直接追加できない場合があります。

そのため、まずはスマホ・タブレット・Windows Bedrock Editionなど、LAN上で任意サーバーを指定できるBedrockクライアントで `UDP/19132` の疎通とGeyser動作を確認してください。

PS5から参加させる場合は、PS5側のサーバー追加仕様に応じて追加の中継手段が必要になる可能性があります。この部分はサーバー側Geyser設定とは別レイヤーとして切り分けます。

## 疎通確認

Java TCP:

```bash
nc -vz 127.0.0.1 25565
```

Bedrock UDPはTCPのような単純な `nc -vz` では成立確認が難しいため、次を併用します。

```bash
ss -lunp | grep 19132
```

Docker:

```bash
docker compose ps
docker compose logs --tail=200 minecraft
```

## トラブルシュート

### Javaは入れるがBedrockは入れない

確認順:

```text
1. UDP/19132 がLISTENしているか
2. Geyserプラグインがロードされているか
3. Floodgateプラグインがロードされているか
4. UFWがUDP/19132を遮断していないか
5. クライアントとサーバーが同一LANにいるか
```

### サーバーが重い

まず `.env` を以下から開始します。

```text
MINECRAFT_MEMORY=2G
CONTAINER_MEMORY_LIMIT=3G
MAX_PLAYERS=5
VIEW_DISTANCE=6
SIMULATION_DISTANCE=4
```

それでも重ければ、先に下げるのは次の2つです。

```text
VIEW_DISTANCE=4
SIMULATION_DISTANCE=3
```

## セキュリティ

- WAN側ルーターでTCP/25565をPort Forwardしない
- WAN側ルーターでUDP/19132をPort Forwardしない
- RCON TCP/25575をホスト公開しない
- `.env` をGitへcommitしない
- Java側の `ONLINE_MODE=TRUE` は維持する
