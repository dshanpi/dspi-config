# dspi-config 开发维护指南

本文面向源码开发者、发行维护者和 AI 编码工具。面向使用者的功能、架构、业务流程和操作说明见 [README](../README.md)。
原有开发要求和门禁继续保留，新增图文说明不替代这些要求。

## 开发入口与规则来源

开始工作前读取 [AGENTS.md](../AGENTS.md)、[三仓统一交付门禁](../DELIVERY_POLICY.md) 和 [仓库维护 skill](../.agents/skills/maintain-dspi-config/SKILL.md)。
统一政策 G01～G14 是完整要求；本指南是开发入口，不能缩减政策或将软件测试等同于实板验收。
AI 工具从 AGENTS.md 进入本指南；当前限制与接续事项见 [开发交接](development-handoff.md)。

## 必须保留的开发与交付门禁

| 规则 | 开发与发行要求 | 政策条款 |
| --- | --- | --- |
| 源码归属 | 板级/内核/DT/BSP 归 ArmBianOS，可选组件配方与发行归 dshanpi-build，设备交互归 dspi-config；不复制一套更新器或发布流程 | G01、G13 |
| 四板隔离 | 共享修改评估 A1、CM5、R1、Avaota A1；仅 common 加本板 component，CM5 保留独立内核命名空间 | G02 |
| 固定输入与历史 | 固定完整源码 SHA、版本、架构和哈希；历史 lock、tag、包字节不覆盖；安装内容、依赖、维护脚本及包内 README 变化使用新 DEB 版本 | G03、G13 |
| Overlay | 数据和 DTBO 来自本板 BSP；按适用规则校验、备份并说明重启，不能用手工拷贝替代正式交付 | G04 |
| 完整镜像 | 安装同一套精确 DEB、工具、profile、公钥、软件源和元包；验证全部变体、镜像来源、公开下载及 Release 资产 | G05、G06 |
| APT 与密钥 | 签名、包集、身份、权限、RPATH、本地客户端及历史不变性检查；使用并发保护与原子发布；私钥/凭据留在受保护环境，保留 Signed-By | G07 |
| 持续维护 | 新版精确元包绑定所有受影响产品；升级及回滚操作完整依赖集合，保留旧包和恢复路径 | G08 |
| stable 晋级 | 先 testing；核对候选清单及日志哈希，具备适用板型实板证据后只晋级相同包和 SHA-256，不重新构建 | G09 |
| 验证与完成标准 | 静态、软件模拟、包/镜像、公共端点及实板分别记录；未完成自动化或未做硬件验证不得宣称交付完成 | G10、G11 |
| 内核头文件 | 每个镜像提供精确匹配的 headers DEB，关联源码、配置、版本、ABI、Module.symvers、大小和 SHA-256，以及 APT 安装命令和外部模块编译验证 | G12 |
| 会话记录与源码卫生 | 每次修改有 REQ、业务流程、失败分支、测试和未完成项；运行记录门禁，只暂存审查文件，检查索引，不提交缓存/输出/密钥/个人配置 | G13、G14 |

上述是规则要求，具体实现边界及缺失环节应按源码、测试与交接记录如实记录。当前 testing Actions 负责 DEB/APT；完整镜像由受控本机组装，不能据此把完整自动 Release 的交付要求删除。

## 开发打包与验证

从仓库根运行，先读取 `AGENTS.md`、统一交付政策及仓库维护 skill。推荐 Ubuntu 24.04，打包需 `dpkg-deb` 等工具。

```bash
python3 tools/check-delivery-policy.py
python3 tools/check-change-record.py
bash -n bin/dspi-config packaging/build-deb.sh tests/*.sh
bash tests/test.sh
(umask 0002; bash packaging/build-deb.sh output)
python3 tools/check-repository-hygiene.py
git diff --check
```

生成 `output/dspi-config_<VERSION>_all.deb`，版本取自根目录 `VERSION`。包架构为 `all`，板级差异由运行时 profile 提供；DTBO 和板卡 profile 不由本包打入。

README、本体脚本、镜像源表和 APT 配置均属于 DEB 有效负载。修改这些文件必须提高版本，并由 dshanpi-build 的后续正式发行固定新源码 commit、为受影响产品生成新精确元包。开发 checkout 的版本不等于公共 APT 已发布版本。

测试使用临时 profile 与模拟 APT / dpkg 输出，并覆盖源锁并发及真实 APT 源扫描。四板 profile 的软件回归不代表四块实板都已验收；DTBO 生效、硬件功能、升级后重启和硬件回滚须另行验证。

历史包复现的 umask 与环境条件，以及未完成项，见仓库中的 `docs/development-handoff.md`；构建发布流程见 [dshanpi-build README](https://github.com/dshanpi/dshanpi-build/blob/main/README.md)。本仓库不单独承担 APT 或镜像发布。

本文 SVG 插图源文件位于 `docs/images/`，与 README 一起安装到 `/usr/share/doc/dspi-config/` 下的对应相对路径；离线查看无需请求远端图片。Mermaid 图直接维护在本文中，需查看器支持 Mermaid 渲染。

## 开发测试接口

`DSPI_ALLOW_NON_ROOT`、`DSPI_SKIP_APT_UPDATE` 和路径覆盖变量仅用于开发测试。生产设备不能依靠它们跳过权限或索引刷新。

## 改写前 README 原文保留

以下内容来自本仓库提交 `33df6984da07d101c6e949989b2e0203db0d959c` 的 `README.md`，完整保留原有说明、要求、门禁与历史记录，仅将相对链接调整为从本目录访问。
这些历史记录中的候选状态、工作流实现和产物位置对应当时上下文；操作现版本时参照用户 README 与当前源码。历史记录不能作为本次发布或实板验收证据；其中的开发规则继续受统一政策约束。

<details>
<summary>展开改写前 README 全文</summary>

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

发行元包会记录该版本对应的可选硬件选择包。升级或回滚时，`dspi-config`
只同步本机已经安装的选择包及其驱动/运行库，不会在没有相应硬件的设备上自动安装可选套件。

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

从 `1.0.2-3` 起，软件源写入锁存放在 `/run/dspi-config/`，以源文件完整路径区分，
更新源文件使用原子替换。软件包携带 APT 配置，仅忽略旧版本遗留的
`.dspi-config.lock` 辅助文件，不删除可能仍被使用的锁，不影响软件源或签名校验。

## 构建与测试

```bash
bash tests/test.sh
packaging/build-deb.sh output
```

生成 `output/dspi-config_<version>_all.deb`。

</details>
