# Apple II PC

레거시 BIOS 구형 PC(윈도우 XP 시절)를 **켜자마자 Apple //e가 되는 기계**로 만드는 부팅 이미지입니다.
리눅스나 메뉴 화면은 보이지 않고, F12로 끄면 PC 전원도 꺼집니다.

| 기능 | 내용 |
|---|---|
| 바로 부팅 | GRUB 메뉴·대기 없음, 커널 메시지 숨김, 화면 해상도에 맞춰 전체화면 |
| 세이브 | Ctrl+Shift+0~9 저장(화면 캡처 함께), Ctrl+0~9 불러오기, F11/F10 썸네일 화면 |
| FujiNet | 슬롯 7. FujiNet-PC를 이 PC 안에서 함께 실행. CONFIG 메뉴, TNFS 서버, N: 장치, 웹 설정 |
| SmartPort | 슬롯 5. 하드디스크 2개 + UniDisk 3.5 드라이브 2개 |
| 5.25" | 슬롯 6. Disk II 드라이브 2개 (.dsk .do .po .nib .woz) |
| 소리 | Mockingboard(슬롯 4) + 스피커, AC'97/HD Audio 등 |
| 네트워크 | 유선 랜 자동(DHCP), 내장 PCI/USB 무선랜은 `wifi.txt`에 이름·비밀번호 |

## 굽는 법 (Rufus)

1. `apple2pc.img.zip`의 압축을 풀어 `apple2pc.img`를 꺼냅니다.
2. Rufus에서 장치(USB 메모리, CF 카드, 또는 USB 어댑터로 연결한 IDE/SATA 디스크)를 고르고, 부트 선택에서 `apple2pc.img`를 고릅니다.
3. **DD 이미지 모드로 쓰기**를 묻는 창이 나오면 DD를 고르고 시작합니다. 그 장치의 기존 내용은 모두 지워집니다.
4. 구형 PC의 BIOS에서 그 장치를 첫 번째 부팅 장치로 정합니다. USB 메모리라면 USB-HDD 부팅을 켜 주세요.

이미지는 약 600MB입니다. 1GB 이상의 장치면 되고, 남는 공간은 비어 있습니다.
데이터 파티션(APPLE2)을 늘리려면 윈도우 디스크 관리나 GParted로 2번 파티션을 늘리면 됩니다.

## 디스크 구성

| 파티션 | 형식 | 내용 |
|---|---|---|
| 1 | ext4, 읽기 전용으로 마운트 | 리눅스, 에뮬레이터, FujiNet-PC |
| 2 | FAT32 `APPLE2` | 디스크 이미지, 세이브, FujiNet SD·설정, 설정 파일 (윈도우에서도 열림) |

시스템 파티션은 읽기 전용이라 실행 중에 전원을 그냥 꺼도 망가지지 않습니다.
세이브와 디스크 쓰기는 1초 안에 디스크에 기록합니다.

`APPLE2` 파티션 안:

```
disks\            디스크 이미지
saves\            세이브 슬롯 (SaveStateN.aws + SaveStateN.bmp)
fujinet\SD\       FujiNet SD 카드
fujinet\fnconfig.ini
wifi.txt          무선랜 SSID / PASSWORD
linapple.conf     에뮬레이터 설정
network.txt       연결되면 IP와 FujiNet 웹 주소가 적힘
README.TXT        키 안내
```

## 키

| 키 | 동작 |
|---|---|
| Ctrl+Shift+0~9 / Ctrl+0~9 | 그 슬롯에 저장(화면 캡처 함께) / 불러오기 |
| F11 / F10 | 저장 / 불러오기 슬롯을 썸네일 화면에서 고르기 |
| F3 / F4 | 드라이브 1 / 2에 디스크 넣기. 400K·800K 이미지는 UniDisk 3.5로, 나머지는 5.25"로 |
| Ctrl+F3 / F4 | 드라이브 1 / 2 꺼내기 |
| Shift+F3 / F4 | SmartPort 하드디스크 1 / 2 |
| F5 | 5.25" 드라이브 맞바꾸기 |
| Ctrl+F2 / Ctrl+F10 | 재부팅 / Ctrl+Reset |
| F7 / F8 / F9 | 디버거 / 스크린샷 / 화면 모드 |
| ScrollLock | 최고 속도 |
| F12 | 종료, 전원 꺼짐 |
| Ctrl+Alt+F2 | 리눅스 셸 (Alt+F1로 복귀) |

## FujiNet

- 전원을 켜면 FujiNet CONFIG가 먼저 뜹니다. 실제 FujiNet을 단 Apple II와 같습니다.
- 1번 호스트 `SD`는 `APPLE2\fujinet\SD\` 폴더입니다. 나머지는 인터넷의 TNFS 서버입니다.
- FujiNet 메뉴에서 바꾼 설정(호스트 목록, 마운트)은 `APPLE2\fujinet\fnconfig.ini`에 남습니다.
- 같은 네트워크의 폰/PC 브라우저로 `http://(이 PC의 IP):8000`에 접속하면 웹 설정 화면이 나옵니다. IP는 `network.txt`에 있습니다.
- CONFIG의 Wi-Fi 설정은 실제로는 쓰이지 않습니다. 이 PC의 네트워크(유선 또는 `wifi.txt`)를 그대로 씁니다.
- 구조상 SmartPort 장치만 다룹니다. 실제 FujiNet의 Disk II(5.25") 에뮬레이션은 없습니다. 5.25" 디스크는 슬롯 6의 Disk II로 쓰세요.
- FujiNet 없이 로컬 디스크로 바로 부팅하려면 `linapple.conf`에서 `Slot 7 = FujiNet`을 `Slot 7 = None`으로 바꿉니다.

## SmartPort와 3.5" 디스크

- 슬롯 5의 SmartPort 카드에 유닛 4개가 있습니다. 1, 2는 하드디스크, 3, 4는 UniDisk 3.5 드라이브입니다.
- SmartPort 호출과 ProDOS 블록 호출을 모두 받습니다. ProDOS 블록 장치(드라이브 1, 2)로는 디스크가 든 처음 두 유닛이 보이고, 나머지 유닛은 SmartPort를 직접 부르는 프로그램이 씁니다.
- 이미지: ProDOS 순서 블록 이미지(.po .hdv), ProDOS 순서 .2mg, MacBinary로 감싼 이미지, 이것들을 담은 .zip/.gz(읽기 전용).
- 3.5" 디스크는 블록 단위로 다룹니다. 복사 방지가 걸린 3.5" 원본(.woz 3.5")은 안 됩니다.
- 3.5" 드라이브의 이미지는 `linapple.conf`의 `SmartPort 3.5 Image 1/2`에, 하드디스크는 `Harddisk Image 1/2`에 기억됩니다.

## 네트워크

- 유선 랜: 케이블만 꽂으면 DHCP로 붙습니다. 그 시절 Intel, Realtek, VIA, SiS, nVidia, Broadcom, Marvell, Atheros 칩을 넣었습니다.
- 무선랜: `APPLE2\wifi.txt`에 `SSID=`와 `PASSWORD=`를 적고 다시 켭니다. 2.4GHz만 됩니다.
  - 넣은 드라이버: Atheros(ath5k, ath9k), Ralink(rt2400/2500/rt61/rt2800), Realtek(rtl8180/8185, rtl8187, rtl8192ce/se/de, rtl8188ee), Intel PRO/Wireless 2100/2200, Intel 3945/4965/5000 계열, Broadcom(brcmsmac, b43), Intersil Prism54, ADMtek, USB 무선랜 일부.
  - **Broadcom b43(BCM4306/4311/4318 등 구형)은 펌웨어를 함께 넣을 수 없어서 동작하지 않습니다.** 그 카드라면 다른 무선랜이나 유선 랜을 쓰세요.
- 특이한 설정이 필요하면 `wifi.txt` 대신 `APPLE2\wpa_supplicant.conf`를 직접 두면 그것을 씁니다.

## 문제가 생기면

- **에뮬레이터가 오류로 멈추면** 화면에 로그가 나오고 Enter(다시) / p(끄기) / s(셸)를 고를 수 있습니다. 로그는 `APPLE2\linapple.log`에도 남습니다.
- **화면이 안 나오면** `grub.cfg`의 `gfxpayload`에서 `800x600x16`이나 `640x480x16`을 맨 앞에 두고 다시 만드세요.
- **소리가 안 나면** Ctrl+Alt+F2 셸에서 `cat /proc/asound/cards`, `amixer`를 확인하세요.
- **네트워크가 안 되면** 셸에서 `cat /run/net.log`, `ip addr`를 확인하세요. FujiNet-PC 로그는 `/run/fujinet.log`입니다.
- **시계:** 윈도우처럼 BIOS 시계를 현지 시각(한국 시간)으로 읽습니다. 네트워크에 붙으면 인터넷 시간으로 맞추고 BIOS 시계도 고칩니다.
- **CPU:** 32비트 i686 이상(Pentium Pro, Pentium III, Athlon 이상)이면 됩니다.

## 확인한 것과 못 한 것

QEMU(Pentium III, 512MB, IDE 디스크, AC'97, e1000/RTL8139 랜)로 이 이미지 자체를 부팅해 확인했습니다.

- 메뉴 없이 부팅 → "Apple //e" → FujiNet CONFIG까지 그대로 진행
- 유선 랜 DHCP, `network.txt` 기록, 다른 기기에서 FujiNet 웹 설정 화면(포트 8000) 접속
- 세이브 핫키(화면 캡처 포함)와 썸네일 화면, APPLE2 파티션에 기록, F12로 전원 꺼짐
- AC'97 소리 출력, 무선랜 드라이버 모듈 로드(ath5k, ath9k, rt2800pci, ipw2200, rtl8192ce)
- 데스크톱에서 같은 에뮬레이터로: FujiNet SD의 Ultima IV 부팅과 세이브, SmartPort 하드·3.5" 드라이브 부팅과 세이브

실제 무선랜 접속, 실기 그래픽 카드·사운드 칩별 동작, QEMU보다 빠른 실기에서의 부팅 시간은 직접 확인이 필요합니다.

## 직접 만들기

Ubuntu 24.04 x86_64에서 root로 `./build.sh`를 실행하면 `out/apple2pc.img`가 나옵니다(인터넷 필요, 1~2시간).

```
kernel/linux-fragment.config   커널 설정 (i386_defconfig 위에 덮어씀)
busybox/busybox.config         busybox 설정 (정적 빌드)
linapple/*.patch               LinApple 패치 4개
fujinet/fnconfig.ini           FujiNet 기본 설정
wpa/wpa_supplicant.config      wpa_supplicant 빌드 설정
overlay/                       inittab, 부팅·네트워크·FujiNet 스크립트, 기본 설정
grub.cfg, genimage.cfg         부트로더, 디스크 구성
```

LinApple 패치:

1. 세이브 슬롯 화면 캡처, 알림, 썸네일 고르기 화면
2. 32비트 x86에서 세이브 파일 구조가 64비트와 같도록 수정 (원래 소스는 32비트 x86에서 빌드가 안 됨)
3. SmartPort 카드(하드 2 + UniDisk 3.5 2)와 FujiNet 카드, 전체화면 해상도, 세이브 즉시 기록
4. 넣은 디스크를 다음 부팅 때 그대로 넣기

구성 요소와 라이선스: Linux(GPL-2.0), BusyBox(GPL-2.0), LinApple(GPL-2.0), FujiNet 펌웨어(GPL-3.0), SDL 1.2(LGPL-2.1), wpa_supplicant(BSD), GRUB(GPL-3.0), Ubuntu 패키지의 glibc·OpenSSL·ALSA 등, linux-firmware(각 펌웨어 라이선스). Apple II ROM은 LinApple 소스에 들어 있는 것을 씁니다.
