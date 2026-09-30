# dspi-config

`dspi-config` 是 DShanPI Ubuntu/Armbian/Debian 系统默认预装的板级配置工具。
它提供类似 `raspi-config` 的终端菜单，同时保留可脚本化的命令行接口。

职责：

- 按板卡 BSP 提供的清单启用或禁用设备树 overlay；
- 管理 DShanPI APT stable/testing 和 Ubuntu Ports 镜像；
- 按系统版本元包整组升级或回滚内核、DTB、BSP 和驱动；
- 显示当前板卡、基础 DTB、overlay、软件源和系统版本状态。

它不生成 DTBO、不发布 APT 仓库、不保存仓库私钥，也不允许关闭 APT 签名校验。

## 命令

```bash
sudo dspi-config
dspi-config status
dspi-config overlay list
sudo dspi-config overlay enable pcie1
sudo dspi-config overlay disable pcie1
dspi-config source show
sudo dspi-config source channel stable
sudo dspi-config source channel testing
sudo dspi-config source mirror official
dspi-config update list
sudo dspi-config update install <version>
sudo dspi-config update rollback
```

overlay 修改写入 `/boot/armbianEnv.txt`，生效前会验证 DTBO 文件与冲突关系，原文件备份为
`/boot/armbianEnv.txt.dspi-config.bak`，并在操作完成后提示重启。

## BSP 接口

工具从 `/etc/armbian-release` 的 `BOARD=` 识别板卡，然后读取 BSP 安装的两个数据文件：

```text
/usr/share/dspi-config/boards/<board>/overlays.tsv
/usr/share/dspi-config/boards/<board>/system.conf
```

每行格式为：

```text
token|dtbo-basename|中文名称|说明|conflict-token-list
```

`token` 是写入 `armbianEnv.txt` 的 overlay 名称；`dtbo-basename` 是
`/boot/dtb/rockchip/overlay/` 下不带 `.dtbo` 的实际文件名；冲突列表使用逗号分隔。

`system.conf` 只允许数据项，不会被当作 shell 脚本执行：

```text
apt_components=common dshanpi-a1-cm5
release_meta_core=dshanpi-a1-cm5-release-core
release_meta_desktop=dshanpi-a1-cm5-release-desktop
```

## 软件源

DShanPI 软件源固定为 `https://dl.100ask.net/apt`，stable 使用 suite `noble`，testing 使用
`noble-testing`；components 必须与板卡 `system.conf` 一致。Ubuntu Ports 提供官方、清华和
中科大三个预设。所有源都保留 `Signed-By`，不支持 `Trusted: yes`。

## 构建与测试

```bash
bash tests/test.sh
packaging/build-deb.sh output
```

生成 `output/dspi-config_<version>_all.deb`。
