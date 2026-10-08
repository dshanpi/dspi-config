# dspi-config

`dspi-config` 是 DShanPI Ubuntu/Armbian/Debian 系统默认预装的板级配置工具。
它提供类似 `raspi-config` 的终端菜单，同时保留可脚本化的命令行接口。

职责：

- 按板卡 BSP 提供的清单启用或禁用设备树 overlay；
- 管理 DShanPI APT stable/testing 和 Ubuntu Ports 镜像；
- 按系统版本元包整组升级或回滚内核、DTB、BSP 和驱动；
- 显示当前板卡、基础 DTB、overlay、软件源和系统版本状态。

它不生成 DTBO、不发布 APT 仓库、不保存仓库私钥，也不允许关闭 APT 签名校验。

当前产品标识及板卡名统一为：`dshanpi-a1-cm5`、`dshanpi-a1`、`dshanpi-r1` 和
`avaota-a1`。用户口头所称的 “AvaotaA1” 在配置、包名和 APT component 中均使用
规范名称 `avaota-a1`。

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

`token` 是写入 `armbianEnv.txt` 的 overlay 名称；`dtbo-basename` 是板卡
`/etc/armbian-release` 中 `OVERLAY_DIR` 目录下不带 `.dtbo` 的实际文件名；Rockchip
通常为 `/boot/dtb/rockchip/overlay`，Allwinner 通常为
`/boot/dtb/allwinner/overlay`。冲突列表使用逗号分隔。空清单表示该产品当前只使用主
设备树，仍可使用软件源和系统版本管理功能。

`system.conf` 只允许数据项，不会被当作 shell 脚本执行：

```text
apt_components=common dshanpi-a1-cm5
release_meta_core=dshanpi-a1-cm5-release-core
release_meta_desktop=dshanpi-a1-cm5-release-desktop
```

各产品的实际 `apt_components` 和 release 元包名由对应 BSP 提供，不能在
`dspi-config` 程序中硬编码。

## 软件源

DShanPI 软件源固定为 `https://apt.100ask.net`，stable 使用 suite `noble`，testing 使用
`noble-testing`；components 必须与板卡 `system.conf` 一致。Ubuntu Ports 提供官方、清华和
中科大三个预设。所有源都保留 `Signed-By`，不支持 `Trusted: yes`。

旧镜像中的 `https://dl.100ask.net/apt` 仍可识别；使用新版工具执行
`sudo dspi-config source channel stable`（或 `testing`）时会将地址迁到
`https://apt.100ask.net`，保留官方签名校验和板卡 components。
从 `1.0.2-1` 起，安装指定系统版本前也会迁移旧地址并刷新 APT 索引。
升级与回滚会从元包读取全部精确依赖，并将整组版本显式交给 APT，避免只降级版本标记却保留较新的依赖包。

## 构建与测试

```bash
bash tests/test.sh
packaging/build-deb.sh output
```

生成 `output/dspi-config_<version>_all.deb`。
