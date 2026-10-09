#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
source_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'result=$?; if ((result != 0)) && [[ -f "$test_root/apt.log" ]]; then cat "$test_root/apt.log" >&2; fi; rm -rf -- "$test_root"; exit "$result"' EXIT
mkdir -p "$test_root/sources" "$test_root/profiles/dshanpi-a1" "$test_root/lists/partial"
cat > "$test_root/profiles/dshanpi-a1/system.conf" <<'EOF'
apt_components=common dshanpi-a1
EOF
cat > "$test_root/sources/dshanpi.sources" <<'EOF'
Types: deb
URIs: https://apt.100ask.net
Suites: noble
Components: common dshanpi-a1
Architectures: arm64
Signed-By: /usr/share/keyrings/dshanpi-archive-keyring.gpg
EOF
export DSPI_BOARD=dshanpi-a1 DSPI_PROFILE_ROOT="$test_root/profiles"
export DSPI_DSHANPI_SOURCE="$test_root/sources/dshanpi.sources"
export DSPI_SOURCE_LOCK_DIR="$test_root/locks"
export DSPI_ALLOW_NON_ROOT=yes DSPI_SKIP_APT_UPDATE=yes

bash "$source_root/bin/dspi-config" source channel testing >/dev/null
[[ ! -e "$DSPI_DSHANPI_SOURCE.dspi-config.lock" ]]
[[ $(find "$test_root/sources" -type f | wc -l) -eq 1 ]]
grep -Fx 'Suites: noble-testing' "$DSPI_DSHANPI_SOURCE" >/dev/null
[[ $(stat -c %a "$DSPI_DSHANPI_SOURCE") == 644 ]]

# A concurrent writer must wait on the persistent runtime lock, even though
# source updates replace the target inode atomically.
locks=("$DSPI_SOURCE_LOCK_DIR"/*.lock)
[[ ${#locks[@]} -eq 1 && -f "${locks[0]}" ]]
exec {held_lock}> "${locks[0]}"
flock -x "$held_lock"
if timeout 1 bash "$source_root/bin/dspi-config" source channel stable {held_lock}>&- >/dev/null; then
	echo 'Source writer ignored its lock' >&2
	exit 1
else
	[[ $? -eq 124 ]]
fi
grep -Fx 'Suites: noble-testing' "$DSPI_DSHANPI_SOURCE" >/dev/null
exec {held_lock}>&-
bash "$source_root/bin/dspi-config" source channel stable >/dev/null
grep -Fx 'Suites: noble' "$DSPI_DSHANPI_SOURCE" >/dev/null

# Every supported board uses the same source writer, with its own component
# validation. Exercise channel and Ubuntu mirror changes for all four profiles.
for board in dshanpi-a1 dshanpi-a1-cm5 dshanpi-r1 avaota-a1; do
	board_dir="$test_root/products/$board"
	mkdir -p "$board_dir" "$test_root/profiles/$board"
	printf 'apt_components=common %s\n' "$board" > "$test_root/profiles/$board/system.conf"
	sed "s/Components: common dshanpi-a1$/Components: common $board/" \
		"$DSPI_DSHANPI_SOURCE" > "$board_dir/dshanpi.sources"
	printf 'Types: deb\nURIs: https://ports.ubuntu.com/ubuntu-ports\nSuites: noble\nComponents: main\nSigned-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg\n' > "$board_dir/ubuntu.sources"
	(
		export DSPI_BOARD="$board" DSPI_DSHANPI_SOURCE="$board_dir/dshanpi.sources"
		export DSPI_UBUNTU_SOURCE="$board_dir/ubuntu.sources" DSPI_MIRRORS_FILE="$source_root/config/mirrors.tsv"
		bash "$source_root/bin/dspi-config" source channel testing >/dev/null
		grep -Fx 'Suites: noble-testing' "$DSPI_DSHANPI_SOURCE" >/dev/null
		bash "$source_root/bin/dspi-config" source channel stable >/dev/null
		grep -Fx 'Suites: noble' "$DSPI_DSHANPI_SOURCE" >/dev/null
		bash "$source_root/bin/dspi-config" source mirror tuna >/dev/null
		grep -Fx 'URIs: https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports' "$DSPI_UBUNTU_SOURCE" >/dev/null
		[[ $(find "$board_dir" -type f | wc -l) -eq 2 ]]
	)
done

# Exercise the real APT source scanner without contacting any repository.
printf 'legacy lock fixture\n' > "$DSPI_DSHANPI_SOURCE.dspi-config.lock"
printf 'unrelated invalid source fixture\n' > "$test_root/sources/unrelated.invalid"
mv "$DSPI_DSHANPI_SOURCE" "$test_root/checked.sources"
apt -c "$source_root/config/20dspi-config" \
	-o quiet=0 \
	-o Dir::Etc::sourcelist=/dev/null \
	-o Dir::Etc::sourceparts="$test_root/sources" \
	-o Dir::State::status=/dev/null \
	-o Dir::State::lists="$test_root/lists" \
	-o Dir::Cache="$test_root/cache" update > "$test_root/apt.log" 2>&1
if grep -F 'Ignoring file' "$test_root/apt.log" | grep -F 'dspi-config.lock'; then
	echo 'APT still warns about a legacy dspi-config lock' >&2
	exit 1
fi
grep -F 'Ignoring file' "$test_root/apt.log" | grep -F 'unrelated.invalid' >/dev/null
[[ -f "$DSPI_DSHANPI_SOURCE.dspi-config.lock" ]]
echo 'Source lock, concurrent writer and real APT scanner tests passed'
