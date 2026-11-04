#!/bin/bash
# Builds apple2pc.img: a disk image for a legacy-BIOS PC (Windows XP era)
# that boots straight into an Apple //e (LinApple) with a SmartPort card
# (hard disks, UniDisk 3.5), a Disk II and a Mockingboard.
#
# Host: Ubuntu 24.04 x86_64, as root, with Internet access to
# archive.ubuntu.com and github.com. Everything for the target is 32-bit
# x86 (i686): the kernel, busybox and the programs are built here, the C
# library and a few libraries come from Ubuntu's i386 packages.
#
#   ./build.sh            all stages
#   ./build.sh image      only re-assemble the image from what is built
#
# Stages: deps sources kernel busybox libs linapple wpa rootfs image
set -euo pipefail

KIT=$(cd "$(dirname "$0")" && pwd)
WORK=${WORK:-$KIT/work}
OUT=${OUT:-$KIT/out}
JOBS=${JOBS:-$(nproc)}
P32=$WORK/prefix32                     # 32-bit libraries built here
ROOT=$WORK/rootfs

LINUX_TAG=v6.12.47
BUSYBOX_COMMIT=371fe9f71d445d18be28c82a2a6d82115c8af19d
SDL12_COMMIT=81490298a02fe6806c05ac7b5afde7d88fcc7bf9
SDLIMAGE_COMMIT=2ffb2e3e1eba037897164e3ac6c67570d8bccd79
ZLIB_TAG=v1.3.1
LIBZIP_TAG=v1.11.4
LINAPPLE_COMMIT=86bee1c2b59bd4706185ceddddaf383b3416726f
WPA_VERSION=2.11

CFLAGS32="-m32 -march=i686 -mtune=generic -O2"
export PKG_CONFIG_LIBDIR=/usr/lib/i386-linux-gnu/pkgconfig:$P32/lib/pkgconfig

log() { printf '\n=== %s\n' "$*"; }

clone() {  # url dir ref
	[ -d "$WORK/src/$2/.git" ] && return
	git clone -q "$1" "$WORK/src/$2"
	git -C "$WORK/src/$2" checkout -q "$3"
}

stage_deps() {
	log "host packages"
	dpkg --add-architecture i386
	apt-get update -q
	apt-get install -y -q build-essential gcc-multilib g++-multilib git cmake \
		pkg-config flex bison bc libelf-dev libssl-dev lz4 zstd \
		python3 imagemagick cc65 grub-pc-bin genimage mtools dosfstools \
		e2fsprogs fdisk xz-utils curl kmod zip
	apt-get install -y -q libc6-dev:i386 libasound2-dev:i386 libpng-dev:i386 \
		libx11-dev:i386 libxext-dev:i386 libssl-dev:i386 libexpat1-dev:i386 \
		libmbedtls-dev:i386 libnl-3-dev:i386 libnl-genl-3-dev:i386 zlib1g-dev:i386
}

stage_sources() {
	log "sources"
	mkdir -p "$WORK/src"
	[ -d "$WORK/src/linux/.git" ] || git clone -q --depth 1 --branch "$LINUX_TAG" \
		https://github.com/gregkh/linux.git "$WORK/src/linux"
	clone https://github.com/mirror/busybox.git busybox "$BUSYBOX_COMMIT"
	clone https://github.com/libsdl-org/SDL-1.2.git sdl12 "$SDL12_COMMIT"
	clone https://github.com/libsdl-org/SDL_image.git sdlimage "$SDLIMAGE_COMMIT"
	clone https://github.com/madler/zlib.git zlib "$ZLIB_TAG"
	clone https://github.com/nih-at/libzip.git libzip "$LIBZIP_TAG"
	if [ ! -d "$WORK/src/linapple/.git" ]; then
		clone https://github.com/linappleii/linapple.git linapple "$LINAPPLE_COMMIT"
		git -C "$WORK/src/linapple" -c user.name=build -c user.email=build@localhost \
			am -q "$KIT"/linapple/*.patch
	fi
	if [ ! -d "$WORK/src/wpa-$WPA_VERSION" ]; then
		curl -sSf -o "$WORK/src/wpa.tar.xz" \
			"http://archive.ubuntu.com/ubuntu/pool/main/w/wpa/wpa_$WPA_VERSION.orig.tar.xz"
		tar -C "$WORK/src" -xf "$WORK/src/wpa.tar.xz"
	fi
}

stage_kernel() {
	log "kernel"
	local k=$WORK/build/kernel
	mkdir -p "$k"
	(cd "$WORK/src/linux" &&
		ARCH=i386 scripts/kconfig/merge_config.sh -m -O "$k" \
			arch/x86/configs/i386_defconfig "$KIT/kernel/linux-fragment.config" &&
		make ARCH=i386 O="$k" olddefconfig &&
		make ARCH=i386 O="$k" -j"$JOBS" bzImage modules)
}

stage_busybox() {
	log "busybox (static)"
	local b=$WORK/src/busybox
	cp "$KIT/busybox/busybox.config" "$b/.config"
	{ yes "" || true; } | make -C "$b" CC="gcc -m32" HOSTCC=gcc oldconfig >/dev/null
	make -C "$b" CC="gcc -m32" HOSTCC=gcc -j"$JOBS"
}

stage_libs() {
	log "32-bit zlib, libzip, SDL 1.2, SDL_image"
	mkdir -p "$WORK/build"
	(cd "$WORK/build" &&
		CFLAGS="$CFLAGS32" cmake -S "$WORK/src/zlib" -B zlib -DCMAKE_INSTALL_PREFIX="$P32" \
			-DCMAKE_BUILD_TYPE=Release && cmake --build zlib -j"$JOBS" && cmake --install zlib &&
		CFLAGS="$CFLAGS32" cmake -S "$WORK/src/libzip" -B libzip -DCMAKE_INSTALL_PREFIX="$P32" \
			-DCMAKE_PREFIX_PATH="$P32" -DENABLE_BZIP2=OFF -DENABLE_LZMA=OFF -DENABLE_ZSTD=OFF \
			-DENABLE_OPENSSL=OFF -DENABLE_GNUTLS=OFF -DENABLE_MBEDTLS=OFF -DBUILD_TOOLS=OFF \
			-DBUILD_REGRESS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_DOC=OFF -DBUILD_OSSFUZZ=OFF &&
		cmake --build libzip -j"$JOBS" && cmake --install libzip)
	(cd "$WORK/src/sdl12" && make distclean >/dev/null 2>&1 || true
		./configure --host=i686-linux-gnu --build=x86_64-linux-gnu CC="gcc -m32" \
			CFLAGS="$CFLAGS32" LDFLAGS="-m32 -L$P32/lib" --prefix="$P32" \
			--enable-video-fbcon --enable-video-x11 --disable-video-opengl \
			--enable-audio --enable-alsa --disable-alsa-shared --disable-oss \
			--disable-pulseaudio --disable-esd --disable-arts --disable-nas &&
		make -j"$JOBS" && make install)
	(cd "$WORK/src/sdlimage" && make distclean >/dev/null 2>&1 || true
		./configure --host=i686-linux-gnu --build=x86_64-linux-gnu CC="gcc -m32" \
			CFLAGS="$CFLAGS32" LDFLAGS="-m32 -L$P32/lib" --prefix="$P32" \
			--with-sdl-prefix="$P32" --disable-jpg --disable-tif --disable-webp \
			--disable-png-shared &&
		make -j"$JOBS" && make install)
}

stage_linapple() {
	log "LinApple (SDL 1.2, 32-bit)"
	cmake -S "$WORK/src/linapple" -B "$WORK/build/linapple" \
		-DCMAKE_C_FLAGS="$CFLAGS32" -DCMAKE_CXX_FLAGS="$CFLAGS32" \
		-DCMAKE_EXE_LINKER_FLAGS="-m32" -DCMAKE_PREFIX_PATH="$P32" \
		-DSDL_INCLUDE_DIR="$P32/include/SDL" -DSDL_LIBRARY="$P32/lib/libSDL.so" \
		-DSDL_IMAGE_INCLUDE_DIR="$P32/include/SDL" -DSDL_IMAGE_LIBRARY="$P32/lib/libSDL_image.so" \
		-DFRONTEND=sdl1 -DBUILD_TESTING=OFF -DENABLE_FTP=OFF -DENABLE_LTO=OFF \
		-DENABLE_STRICT_WARNINGS=OFF -DCMAKE_BUILD_TYPE=Release
	cmake --build "$WORK/build/linapple" -j"$JOBS"
}

stage_wpa() {
	log "wpa_supplicant (32-bit)"
	local w=$WORK/src/wpa-$WPA_VERSION/wpa_supplicant
	cp "$KIT/wpa/wpa_supplicant.config" "$w/.config"
	make -C "$w" clean >/dev/null
	make -C "$w" -j"$JOBS" CC="gcc -m32" \
		PKG_CONFIG="env PKG_CONFIG_LIBDIR=/usr/lib/i386-linux-gnu/pkgconfig pkg-config" \
		EXTRA_CFLAGS="-I/usr/include/libnl3 -march=i686" LDFLAGS="-m32"
}

# Ubuntu i386 packages whose files go into the image as they are.
DEBS="libc6 libgcc-s1 libstdc++6 libasound2t64 libasound2-data libssl3t64
libexpat1 libnl-3-200 libnl-genl-3-200 alsa-utils"

# Firmware for the Wi-Fi, Ethernet and sound card drivers (from Ubuntu's linux-firmware).
FW_DEBS="linux-firmware-misc linux-firmware-realtek linux-firmware-intel-wireless
linux-firmware-broadcom-wireless linux-firmware-mediatek
linux-firmware-qualcomm-wireless wireless-regdb"
FW_FILES="rt2561.bin rt2561s.bin rt2661.bin rt2860.bin rt2870.bin rt3070.bin
rt3071.bin rt3090.bin rt3290.bin rt73.bin rtlwifi rtl_nic tigon bnx2
ipw2100-1.3.fw ipw2100-1.3-i.fw ipw2100-1.3-p.fw ipw2200-bss.fw ipw2200-ibss.fw
iwlwifi-3945-2.ucode iwlwifi-4965-2.ucode iwlwifi-5000-5.ucode iwlwifi-5150-2.ucode
iwlwifi-6000-4.ucode iwlwifi-6000g2a-6.ucode iwlwifi-6000g2b-6.ucode
iwlwifi-6050-5.ucode iwlwifi-1000-5.ucode iwlwifi-100-5.ucode iwlwifi-105-6.ucode
iwlwifi-135-6.ucode iwlwifi-2000-6.ucode iwlwifi-2030-6.ucode
ath9k_htc htc_7010.fw htc_9271.fw carl9170-1.fw ar5523.bin mt7601u.bin zd1211
brcm/bcm43xx-0.fw brcm/bcm43xx_hdr-0.fw regulatory.db regulatory.db.p7s
ess yamaha korg ea"

stage_rootfs() {
	log "root filesystem"
	rm -rf "$ROOT"
	mkdir -p "$ROOT"/{bin,sbin,usr/bin,usr/sbin,usr/lib/firmware,usr/share,etc,proc,sys,dev,run,tmp,root,var,media/apple2,boot/grub}
	ln -s usr/lib "$ROOT/lib"            # merged /usr, as Ubuntu's packages expect
	ln -s /tmp "$ROOT/var/tmp"
	ln -s /run "$ROOT/var/run"

	# busybox and its applets
	install -m 755 "$WORK/src/busybox/busybox" "$ROOT/bin/busybox"
	for a in $("$ROOT/bin/busybox" --list-full); do
		[ -e "$ROOT/$a" ] || ln -s /bin/busybox "$ROOT/$a"
	done

	# libraries and tools from Ubuntu
	local d=$WORK/debs
	mkdir -p "$d" && rm -rf "$d/x"
	# i386 packages, or the architecture-independent ones (alsa data) as such
	(cd "$d" && for p in $DEBS; do
		apt-get download -q "$p:i386" 2>/dev/null || apt-get download -q "$p"
	done)
	for f in "$d"/*.deb; do dpkg-deb -x "$f" "$d/x"; done
	cp -a "$d/x/usr/." "$ROOT/usr/"
	[ -d "$d/x/lib" ] && cp -a "$d/x/lib/." "$ROOT/usr/lib/"
	[ -d "$d/x/etc" ] && cp -a "$d/x/etc/." "$ROOT/etc/"
	[ -e "$ROOT/usr/lib/ld-linux.so.2" ] || ln -s i386-linux-gnu/ld-linux.so.2 "$ROOT/usr/lib/ld-linux.so.2"
	rm -rf "$ROOT/usr/share/doc" "$ROOT/usr/share/man" "$ROOT/usr/share/locale" \
		"$ROOT/usr/share/lintian" "$ROOT/usr/share/sounds" "$ROOT/usr/lib/systemd" \
		"$ROOT/usr/lib/udev" "$ROOT/usr/sbin/alsa"* "$ROOT/usr/share/bash-completion"

	# our 32-bit builds
	install -m 755 "$WORK/build/linapple/linapple" "$ROOT/usr/bin/linapple"
	mkdir -p "$ROOT/usr/share/linapple"
	cp "$WORK/src/linapple/res/icon.bmp" "$WORK/src/linapple/res/Master.dsk" "$ROOT/usr/share/linapple/"
	cp -a "$P32"/lib/lib{SDL-1.2,zip,z}.so* "$ROOT/usr/lib/"
	install -m 755 "$WORK/src/wpa-$WPA_VERSION/wpa_supplicant/wpa_supplicant" \
		"$WORK/src/wpa-$WPA_VERSION/wpa_supplicant/wpa_cli" "$ROOT/usr/sbin/"

	# kernel and modules
	install -m 644 "$WORK/build/kernel/arch/x86/boot/bzImage" "$ROOT/boot/bzImage"
	make -C "$WORK/src/linux" ARCH=i386 O="$WORK/build/kernel" \
		INSTALL_MOD_PATH="$ROOT" INSTALL_MOD_STRIP=1 modules_install >/dev/null
	rm -f "$ROOT"/lib/modules/*/build "$ROOT"/lib/modules/*/source
	local kver
	kver=$(basename "$ROOT"/usr/lib/modules/*)
	depmod -b "$ROOT/usr" "$kver" 2>/dev/null || depmod -b "$ROOT" "$kver"
	[ -s "$ROOT/usr/lib/modules/$kver/modules.dep" ] || { echo "depmod failed"; exit 1; }

	# firmware, uncompressed
	local fw=$WORK/firmware
	mkdir -p "$fw" && rm -rf "$fw/x"
	(cd "$fw" && for p in $FW_DEBS; do [ -f "${p}_"*.deb ] 2>/dev/null || apt-get download -q "$p"; done)
	for f in "$fw"/*.deb; do dpkg-deb -x "$f" "$fw/x"; done
	for f in $FW_FILES; do
		for src in "$fw/x/lib/firmware/$f" "$fw/x/lib/firmware/$f.zst"; do
			[ -e "$src" ] || continue
			mkdir -p "$ROOT/lib/firmware/$(dirname "$f")"
			cp -a "$src" "$ROOT/lib/firmware/$(dirname "$f")/"
		done
	done
	find "$ROOT/lib/firmware" -name '*.zst' -exec zstd -q -d --rm {} \;

	# our scripts and settings
	cp -a "$KIT/overlay/." "$ROOT/"
	cp "$KIT/grub.cfg" "$ROOT/boot/grub/grub.cfg"
	chmod 755 "$ROOT"/usr/bin/apple2-*

	# every program finds its libraries?
	local missing=0
	for b in "$ROOT/usr/bin/linapple" "$ROOT/usr/sbin/wpa_supplicant" "$ROOT/usr/bin/amixer"; do
		for lib in $(readelf -d "$b" | sed -n 's/.*NEEDED.*\[\(.*\)\]/\1/p'); do
			if ! find "$ROOT/lib" "$ROOT/usr/lib" -name "$lib" | grep -q .; then
				echo "missing for $(basename "$b"): $lib"; missing=1
			fi
		done
	done
	[ -f "$ROOT/usr/share/alsa/alsa.conf" ] || { echo "missing: alsa.conf"; missing=1; }
	[ $missing -eq 0 ] || exit 1
	du -sh "$ROOT"
}

stage_image() {
	log "disk image"
	local img=$WORK/images
	rm -rf "$img" && mkdir -p "$img"

	grub-mkimage -d /usr/lib/grub/i386-pc -O i386-pc -o "$img/grub.img" \
		-p "(hd0,msdos1)/boot/grub" \
		boot linux ext2 part_msdos normal biosdisk vbe video video_fb
	cp /usr/lib/grub/i386-pc/boot.img "$img/"

	mkfs.ext4 -q -F -L apple2sys -d "$ROOT" "$img/rootfs.ext2" 320M

	# What the APPLE2 data partition holds the first time.
	local data=$img/apple2-data
	mkdir -p "$data/disks" "$data/saves"
	cp "$KIT/overlay/etc/linapple/linapple.conf" "$data/linapple.conf"
	cp "$KIT/README.TXT" "$data/README.TXT"
	cp "$KIT/saves-readme.txt" "$data/saves/README.TXT"
	cp "$KIT/wifi.txt" "$data/wifi.txt"
	cp "$KIT/sound.txt" "$data/sound.txt"
	for f in "$data/linapple.conf" "$data/README.TXT" "$data/saves/README.TXT" "$data/wifi.txt" "$data/sound.txt"; do
		sed -i 's/\r*$/\r/' "$f"
	done

	mkdir -p "$WORK/gtmp" "$WORK/groot"
	rm -rf "$WORK/gtmp"/*
	genimage --rootpath "$WORK/groot" --tmppath "$WORK/gtmp" --inputpath "$img" \
		--outputpath "$img" --config "$KIT/genimage.cfg"

	mkdir -p "$OUT"
	cp "$img/disk.img" "$OUT/apple2pc.img"
	(cd "$OUT" && rm -f apple2pc.img.zip && zip -q -9 apple2pc.img.zip apple2pc.img &&
		sha256sum apple2pc.img apple2pc.img.zip > SHA256SUMS)
	ls -la "$OUT"
}

ALL="deps sources kernel busybox libs linapple wpa rootfs image"
STAGES=${*:-$ALL}
for s in $STAGES; do "stage_$s"; done
