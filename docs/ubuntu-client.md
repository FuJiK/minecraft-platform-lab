# Ubuntu 26.04 Client Setup

MacBookPro11,1 + Ubuntu 26.04 LTS で Minecraft Java Edition を軽量に動かすためのクライアント側手順です。

## 方針

このラボでは、Ubuntu側のクライアントは Java Edition を使います。

推奨構成:

```text
Ubuntu 26.04
  └─ Prism Launcher
      └─ Minecraft Java Edition
          └─ Fabric Loader
              ├─ Sodium
              ├─ Lithium
              ├─ FerriteCore
              └─ ImmediatelyFast
```

Minecraft本体の正規ライセンスは必要です。

## 1. Java確認

Minecraftのバージョンに応じて必要Javaが変わるため、まずランチャー側の自動Java管理を優先します。

OS側の確認だけする場合:

```bash
java -version
```

## 2. Prism Launcher

Prism Launcherは複数のMinecraftインスタンス、Fabric、Mod管理を分離しやすいため、このラボでは推奨します。

UbuntuではFlatpak版が管理しやすいです。

Flatpakがない場合:

```bash
sudo apt update
sudo apt install -y flatpak
```

Flathubを追加していない場合:

```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

Prism Launcherを導入:

```bash
flatpak install -y flathub org.prismlauncher.PrismLauncher
```

起動:

```bash
flatpak run org.prismlauncher.PrismLauncher
```

## 3. Microsoftアカウントでログイン

Prism Launcher上でMinecraftを購入済みのMicrosoftアカウントを追加します。

認証情報をGitリポジトリへ保存しないでください。

## 4. Fabricインスタンスを作る

Prism Launcher:

```text
Add Instance
  -> Minecraft
  -> 対象バージョン
  -> Mod Loader: Fabric
```

## 5. 軽量化Mod

まずは次の4つだけで十分です。

- Sodium: 描画最適化
- Lithium: ゲームロジック最適化
- FerriteCore: メモリ使用量削減
- ImmediatelyFast: GUI/描画系最適化

ModはMinecraft/Fabricのバージョンに一致するものを使用してください。

## 6. メモリ設定

MacBookPro11,1はRAM 8GBなので、クライアントへ過剰に割り当てない方が安定します。

開始値:

```text
Minimum memory: 512 MiB
Maximum memory: 2048 MiB
```

サーバーも同一ホストで動かす場合、クライアント2GB + サーバー2GB程度から始めます。

## 7. 描画設定

古いIntel内蔵GPU向けの開始値:

```text
Render Distance: 6 chunks
Simulation Distance: 4 chunks
Graphics: Fast
Clouds: Off
Particles: Minimal
Entity Shadows: Off
VSync: 状況によりOff
FPS Limit: 60
```

## 8. Java Serverへ接続

Docker HostとMinecraft Clientが同じUbuntuマシンなら:

```text
localhost:25565
```

別端末からならUbuntuホストのLAN IPを確認:

```bash
hostname -I
```

例:

```text
192.168.1.20:25565
```

## 9. 切り分け

サーバー確認:

```bash
cd ~/path/to/minecraft-platform-lab
docker compose ps
docker compose logs --tail=200 minecraft
```

ポート確認:

```bash
ss -lntup | grep -E '25565|19132'
```

Javaポート:

```bash
nc -vz 127.0.0.1 25565
```

## 10. 性能確認

同一ホストでクライアントとサーバーを動かす場合:

```bash
free -h
uptime
htop
```

Docker側:

```bash
docker stats minecraft-platform-lab
```

TPS低下、GC、メモリ逼迫が見えたら、まずView DistanceとSimulation Distanceを下げます。
