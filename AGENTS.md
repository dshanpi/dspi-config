# 仓库强制工作要求

开始修改、打包或评审前必须读取 [三仓统一交付门禁](DELIVERY_POLICY.md)，并运行
`python3 tools/check-delivery-policy.py`。

本仓库维护用户端工具 dspi-config（用户也称 dshanpi-config），读取 BSP 提供的板卡
profile，管理 Overlay、签名 APT 源、整组升级和回滚。构建/发布由 dshanpi-build 编排，
镜像由 ArmBianOS 组装并预装工具；不得在客户端实现另一套发布或不受 APT 管理的下载器。

共享修复必须覆盖 A1、A1 CM5、R1、Avaota A1 的 profile。Overlay 来自板级 DEB；
必须检查 DTBO、依赖与冲突，备份启动配置并说明重启要求。
源写入使用运行时锁和原子替换，保留 Signed-By；测试旧版本迁移、升级和回滚。

任何会改变已发布 DEB 字节的修改（包括打包进 DEB 的 README）必须提高 VERSION，
并由 dshanpi-build 为受影响产品更新精确依赖元包；单独升级客户端不得破坏系统元包。
仅调整门禁文件和不打入包的测试时，验证重建字节一致后可保留软件包版本。

提交前运行 `bash tests/test.sh`、shell 语法和 `git diff --check`；跨仓政策更新使用
`python3 tools/check-delivery-policy.py --peer /path/to/repo` 核对。实板未验证项必须明示。
