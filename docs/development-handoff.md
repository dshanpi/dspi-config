# dspi-config 开发交接

本仓库负责设备端交互，遵守 [DELIVERY_POLICY.md](../DELIVERY_POLICY.md)。维护时读取
[仓库 skill](../.agents/skills/maintain-dspi-config/SKILL.md)，无需全局个人配置。

## 版本和已经处理的问题

当前包版本为 `1.0.2-3`。功能包括 BSP profile 驱动的 Overlay、签名源管理、精确包集升级回滚。
已修复旧域名迁移、apt-cache 管道 SIGPIPE、sources.list.d 中新建锁文件造成 APT 提示等问题。
源锁移到 /run/dspi-config；不盲删可能被旧进程持有的锁。
四板 profile 的自动化测试不代表四块实板都已经验收。

## 开发和打包

从 checkout 根执行，输出可换为任意新目录：

```bash
python3 tools/check-delivery-policy.py
bash -n bin/dspi-config packaging/build-deb.sh tests/*.sh
bash tests/test.sh
bash packaging/build-deb.sh output
python3 tools/check-repository-hygiene.py
git diff --check
```

README.md、bin/dspi-config、config/mirrors.tsv、config/20dspi-config 会进入包内容。
开发记录放 docs，技能放 .agents/skills，避免纯交接修改进入已发布 DEB。
本次不改变 VERSION 或有效负载；需记录新旧构建 SHA 相同。
未来修改维护脚本、依赖或包内文件时提高 VERSION，并由 dshanpi-build 更新受影响板型精确元包。
板卡 profile 与 DTBO 由 ArmBianOS BSP 交付，本仓库不复制硬件清单或内核源码。

新服务器三仓入口见 [统一手册](https://github.com/dshanpi/dshanpi-build/blob/main/docs/new-server.md)。
安装、重启、升级及回滚的实板证据存入 dshanpi-build 对应发行目录。
