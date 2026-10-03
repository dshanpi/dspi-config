#!/usr/bin/env bash
set -euo pipefail

source_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
armbian_env="$test_root/armbianEnv.txt"
armbian_release="$test_root/armbian-release"
profile_root="$test_root/profiles"
overlay_dir="$test_root/overlays"
dshanpi_source="$test_root/dshanpi.sources"
ubuntu_source="$test_root/ubuntu.sources"
fake_bin="$test_root/bin"
apt_log="$test_root/apt-get.log"
mkdir -p "$profile_root/dshanpi-a1-cm5" "$overlay_dir" "$fake_bin"

cat > "$armbian_env" <<'EOF'
verbosity=1
fdtfile=rockchip/rk3576-100ask-dshanpi-a1-cm5.dtb
overlays=existing
custom_key=keep-me
EOF
cat > "$armbian_release" <<'EOF'
BOARD=dshanpi-a1-cm5
OVERLAY_DIR="/boot/dtb/rockchip/overlay"
EOF
cat > "$profile_root/dshanpi-a1-cm5/overlays.tsv" <<'EOF'
pcie1|dshanpi-a1-cm5-pcie1|PCIe1 模式|禁用 USB1 并启用 PCIe1|
camera|dshanpi-a1-cm5-camera|测试摄像头|冲突测试|pcie1
EOF
cat > "$profile_root/dshanpi-a1-cm5/system.conf" <<'EOF'
apt_components=common dshanpi-a1-cm5
release_meta_core=dshanpi-a1-cm5-release-core
release_meta_desktop=dshanpi-a1-cm5-release-desktop
EOF
touch "$overlay_dir/dshanpi-a1-cm5-pcie1.dtbo" "$overlay_dir/dshanpi-a1-cm5-camera.dtbo"
cat > "$dshanpi_source" <<'EOF'
Types: deb deb-src
URIs: https://dl.100ask.net/apt
Suites: noble
Components: common dshanpi-a1-cm5
Architectures: arm64 all
Signed-By: /usr/share/keyrings/dshanpi-archive-keyring.gpg
EOF
cat > "$ubuntu_source" <<'EOF'
Types: deb
URIs: https://ports.ubuntu.com/ubuntu-ports
Suites: noble noble-updates noble-backports noble-security
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF

cat > "$fake_bin/apt-get" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DSPI_TEST_APT_LOG"
EOF
cat > "$fake_bin/apt-cache" <<'EOF'
#!/usr/bin/env bash
[[ ${1:-} == madison ]] || exit 2
cat <<OUT
 ${2:-package} | 3.0.0-1 | https://dl.100ask.net/apt noble/main arm64 Packages
 ${2:-package} | 2.0.0-1 | https://dl.100ask.net/apt noble/main arm64 Packages
 ${2:-package} | 1.0.0-1 | https://dl.100ask.net/apt noble/main arm64 Packages
OUT
EOF
cat > "$fake_bin/dpkg-query" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *dshanpi-a1-cm5-release-desktop*) exit 1 ;;
  *db:Status-Status*) echo installed ;;
  *dshanpi-a1-cm5-release-core*) echo 2.0.0-1 ;;
  *) exit 1 ;;
esac
EOF
chmod 0755 "$fake_bin"/*

run_config() {
	PATH="$fake_bin:$PATH" \
	DSPI_ARMBIAN_ENV="$armbian_env" \
	DSPI_ARMBIAN_RELEASE="$armbian_release" \
	DSPI_PROFILE_ROOT="$profile_root" \
	DSPI_OVERLAY_DIR="$overlay_dir" \
	DSPI_DSHANPI_SOURCE="$dshanpi_source" \
	DSPI_UBUNTU_SOURCE="$ubuntu_source" \
	DSPI_MIRRORS_FILE="$source_root/config/mirrors.tsv" \
	DSPI_ALLOW_NON_ROOT=yes DSPI_SKIP_APT_UPDATE=yes DSPI_ASSUME_YES=yes \
	DSPI_TEST_APT_LOG="$apt_log" \
	bash "$source_root/bin/dspi-config" "$@"
}

run_config overlay enable pcie1 >/dev/null
grep -Fx 'overlays=existing pcie1' "$armbian_env" >/dev/null
grep -Fx 'custom_key=keep-me' "$armbian_env" >/dev/null
[[ -f "$armbian_env.dspi-config.bak" ]]
if run_config overlay enable camera >/dev/null 2>&1; then
	echo "Conflicting overlay unexpectedly passed" >&2
	exit 1
fi
run_config overlay disable pcie1 >/dev/null
grep -Fx 'overlays=existing' "$armbian_env" >/dev/null

# The overlay path comes from the BSP-generated armbian-release file, so the
# same package also works on Allwinner products without a Rockchip path baked
# into dspi-config.
cat > "$armbian_release" <<'EOF'
BOARD=avaota-a1
OVERLAY_DIR="/boot/dtb/allwinner/overlay"
EOF
mkdir -p "$profile_root/avaota-a1"
cat > "$profile_root/avaota-a1/overlays.tsv" <<'EOF'
# No product overlays are enabled yet.
EOF
cat > "$profile_root/avaota-a1/system.conf" <<'EOF'
apt_components=common avaota-a1
release_meta_core=avaota-a1-release-core
release_meta_desktop=avaota-a1-release-desktop
EOF
PATH="$fake_bin:$PATH" \
	DSPI_ARMBIAN_ENV="$armbian_env" \
	DSPI_ARMBIAN_RELEASE="$armbian_release" \
	DSPI_PROFILE_ROOT="$profile_root" \
	bash "$source_root/bin/dspi-config" overlay list | grep -F 'TOKEN' >/dev/null

# Continue update/source tests with the CM5 fixture.
cat > "$armbian_release" <<'EOF'
BOARD=dshanpi-a1-cm5
OVERLAY_DIR="/boot/dtb/rockchip/overlay"
EOF

run_config source channel testing >/dev/null
grep -Fx 'Suites: noble-testing' "$dshanpi_source" >/dev/null
run_config source channel stable >/dev/null
grep -Fx 'Suites: noble' "$dshanpi_source" >/dev/null
run_config source mirror tuna >/dev/null
grep -Fx 'URIs: https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports' "$ubuntu_source" >/dev/null
grep -Fx 'Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg' "$ubuntu_source" >/dev/null

run_config update install 3.0.0-1 >/dev/null
grep -Fx -- '--simulate install --allow-downgrades dshanpi-a1-cm5-release-core=3.0.0-1' "$apt_log" >/dev/null
grep -Fx -- 'install --allow-downgrades dshanpi-a1-cm5-release-core=3.0.0-1' "$apt_log" >/dev/null
run_config update rollback >/dev/null
grep -Fx -- 'install --allow-downgrades dshanpi-a1-cm5-release-core=1.0.0-1' "$apt_log" >/dev/null

printf 'Trusted: yes\n' >> "$dshanpi_source"
if run_config source channel testing >/dev/null 2>&1; then
	echo "Unsafe Trusted: yes source unexpectedly passed" >&2
	exit 1
fi
sed -i '/Trusted: yes/d; s/^Components:.*/Components: main/' "$dshanpi_source"
if run_config source channel testing >/dev/null 2>&1; then
	echo "Unexpected APT component set passed validation" >&2
	exit 1
fi

output_dir="$test_root/output"
bash "$source_root/packaging/build-deb.sh" "$output_dir" >/dev/null
package="$output_dir/dspi-config_$(< "$source_root/VERSION")_all.deb"
[[ $(dpkg-deb -f "$package" Package) == dspi-config ]]
[[ $(dpkg-deb -f "$package" Architecture) == all ]]
dpkg-deb --contents "$package" | grep -F './usr/sbin/dspi-config' >/dev/null
dpkg-deb --contents "$package" | grep -F './usr/share/dspi-config/mirrors.tsv' >/dev/null

echo "dspi-config tests passed"
