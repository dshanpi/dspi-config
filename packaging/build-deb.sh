#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source_root=$(cd "$script_dir/.." && pwd)
output_dir=${1:-$source_root/output}
version=$(< "$source_root/VERSION")
source_date_epoch=${SOURCE_DATE_EPOCH:-1790726400}
dpkg --validate-version "$version" 2>/dev/null || { echo "Invalid package version: $version" >&2; exit 1; }
mkdir -p "$output_dir"
output_dir=$(realpath "$output_dir")
work_dir=$(mktemp -d)
trap 'rm -rf -- "$work_dir"' EXIT

mkdir -p "$work_dir/DEBIAN" "$work_dir/usr/sbin" \
	"$work_dir/usr/share/dspi-config" "$work_dir/usr/share/doc/dspi-config" \
	"$work_dir/etc/apt/apt.conf.d"
cat > "$work_dir/DEBIAN/control" <<- EOF
Package: dspi-config
Version: $version
Architecture: all
Maintainer: DShanPI <support@dshanpi.com>
Depends: apt, bash, coreutils, dpkg, util-linux, whiptail
Section: admin
Priority: optional
Description: DShanPI device-tree and system configuration utility
 Manage board-specific device-tree overlays, signed software sources and
 release meta-package upgrades from a terminal menu or command line.
EOF
install -m 0755 "$source_root/bin/dspi-config" "$work_dir/usr/sbin/dspi-config"
install -m 0644 "$source_root/config/mirrors.tsv" "$work_dir/usr/share/dspi-config/mirrors.tsv"
install -m 0644 "$source_root/README.md" "$work_dir/usr/share/doc/dspi-config/README.md"
install -m 0644 "$source_root/config/20dspi-config" "$work_dir/etc/apt/apt.conf.d/20dspi-config"
printf '/etc/apt/apt.conf.d/20dspi-config\n' > "$work_dir/DEBIAN/conffiles"
find "$work_dir" -print0 | xargs -0 touch --date="@$source_date_epoch"
SOURCE_DATE_EPOCH=$source_date_epoch dpkg-deb --root-owner-group --build \
	"$work_dir" "$output_dir/dspi-config_${version}_all.deb" >/dev/null
sha256sum "$output_dir/dspi-config_${version}_all.deb"
