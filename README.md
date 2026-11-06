# Apple II PC

레거시 BIOS 구형 PC(윈도우 XP 시절)를 **켜자마자 Apple //e가 되는 기계**로 만드는 부팅 이미지입니다.
리눅스나 메뉴 화면은 보이지 않고, F12로 끄면 PC 전원도 꺼집니다.

| 기능 | 내용 |
|---|---|
| 바로 부팅 | GRUB 메뉴·대기 없음, 커널 메시지 숨김, 화면 해상도에 맞춰 전체화면. 애플 화면은 실기 모니터처럼 4:3으로, 남는 부분은 검게 (`linapple.conf`의 `Full Screen Aspect`로 `pixel`·`stretch`·`W:H`도 가능). 와이드 모니터가 4:3 화면을 늘려 보여주면 **Alt+F6**으로 모니터 모양(16:9, 16:10 등)을 골라 눈으로 4:3이 되게 맞춤 |
| 세이브 | Ctrl+Shift+0~9 저장(화면 캡처 함께), Ctrl+0~9 불러오기, F11/F10 썸네일 화면 |
| SmartPort | 슬롯 7. 하드디스크 2개 + UniDisk 3.5 드라이브 2개. 먼저 부팅하고, 비어 있으면 5.25"로 넘어감 |
| 5.25" | 슬롯 6. Disk II 드라이브 2개 (.dsk .do .po .nib .woz) |
| 소리 | Mockingboard(슬롯 4) + 스피커. 내장 AC'97/HD Audio, 그 시절 PCI 사운드 카드, ISA 사운드 카드(PnP 또는 `sound.txt`로 포트·IRQ 지정) |
| SuperSprite | 슬롯 7에 넣고 SmartPort는 슬롯 5로 옮겨 사용. TMS9918A 스프라이트 화면을 애플 화면 위에 합성, AY-3-8912 소리 (Echo II 음성은 미지원) |
| 네트워크 | 시계 맞추기용. 유선 랜 자동(DHCP), 내장 PCI/USB 무선랜은 `wifi.txt`에 이름·비밀번호 |

## 굽는 법 (Rufus)

1. `apple2pc.img.zip`의 압축을 풀어 `apple2pc.img`를 꺼냅니다.
2. Rufus에서 장치(USB 메모리, CF 카드, 또는 USB 어댑터로 연결한 IDE/SATA 디스크)를 고르고, 부트 선택에서 `apple2pc.img`를 고릅니다.
3. **DD 이미지 모드로 쓰기**를 묻는 창이 나오면 DD를 고르고 시작합니다. 그 장치의 기존 내용은 모두 지워집니다.
4. 구형 PC의 BIOS에서 그 장치를 첫 번째 부팅 장치로 정합니다. USB 메모리라면 USB-HDD 부팅을 켜 주세요.

이미지는 약 600MB입니다. 1GB 이상의 장치면 됩니다.
더 큰 장치에 쓰면 **처음 켤 때 데이터 파티션(APPLE2)이 장치 끝까지 저절로 늘어납니다**(한 번만, 몇 초~수십 초). 결과는 `APPLE2\grow.txt`에 남습니다.
- APPLE2 안의 파일을 잠시 메모리에 옮겼다가 FAT32를 새로 만들고 되돌려 놓는 방식이라, 처음 켜기 전에 넣어 둔 파일이 PC 메모리보다 많으면 늘리지 않습니다. 그때는 파일을 빼고 한 번 켠 뒤 다시 넣으세요.
- APPLE2 뒤에 다른 파티션을 만들어 두면 늘리지 않습니다.
- (참고) 윈도우 기본 "디스크 관리"는 FAT32 파티션을 늘리지 못합니다.

## 디스크 구성

| 파티션 | 형식 | 내용 |
|---|---|---|
| 1 | ext4, 읽기 전용으로 마운트 | 리눅스, 에뮬레이터 |
| 2 | FAT32 `APPLE2` | 디스크 이미지, 세이브, 설정 파일 (윈도우에서도 열림) |

시스템 파티션은 읽기 전용이라 실행 중에 전원을 그냥 꺼도 망가지지 않습니다.
세이브와 디스크 쓰기는 1초 안에 디스크에 기록합니다.

`APPLE2` 파티션 안:

```
disks\            디스크 이미지
saves\            세이브 슬롯 (SaveStateN.aws + SaveStateN.bmp)
wifi.txt          무선랜 SSID / PASSWORD
display.txt       화면 설정 (LCD 해상도, 비율/선명함 우선), 재부팅하면 적용
sound.txt         ISA 사운드 카드 설정
sound-cards.txt   잡힌 사운드 카드 (부팅마다 새로 적힘)
linapple.conf     에뮬레이터 설정
network.txt       연결되면 IP가 적힘
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
| Alt+F7 / Alt+F8 | 볼륨 내리기 / 올리기 (5%씩, 화면에 표시, `linapple.conf`의 `Master Volume`에 저장). 노트북의 볼륨·음소거 키도 같은 일을 함. ThinkPad는 `thinkpad_acpi`로 볼륨 버튼을 받음 |
| Alt+F9 | 화면 설정 메뉴 (해상도, 확대 방식, 모니터 모양; 해상도를 바꾸면 재부팅 여부를 물음) |
| Alt+F6 | 모니터 모양 바꾸기 (auto/16:9/16:10/5:4/3:2/4:3, 저장됨) |
| ScrollLock | 최고 속도 |
| F12 | 종료, 전원 꺼짐 |
| Ctrl+Alt+F2 | 리눅스 셸 (Alt+F1로 복귀) |

## 부팅 순서

- 슬롯 7 SmartPort 하드디스크 1 → (하드가 비어 있으면) 슬롯 6 5.25" 드라이브 1 순서로 부팅합니다.
- 5.25" 드라이브 1도 비어 있으면 실기처럼 디스크를 기다리며 멈춥니다. `F3`으로 넣으면 됩니다.
- 하드가 들어 있는데 플로피로 부팅하려면 Ctrl+F10(Reset) 뒤 `PR#6`을 칩니다.
- SuperSprite 소프트웨어(StarSprite 등)를 쓰려면 `linapple.conf`에서 `Slot 7 = SuperSprite`, `Slot 5 = SmartPort`로 바꿉니다.
- (2026-11-04) FujiNet은 이미지에서 뺐습니다. LinApple의 FujiNet 카드 코드는 패치 3에 남아 있습니다.

## SmartPort와 3.5" 디스크

- 슬롯 7의 SmartPort 카드에 유닛 4개가 있습니다. 1, 2는 하드디스크, 3, 4는 UniDisk 3.5 드라이브입니다.
- SmartPort 호출과 ProDOS 블록 호출을 모두 받습니다. ProDOS 블록 장치(드라이브 1, 2)로는 디스크가 든 처음 두 유닛이 보이고, 나머지 유닛은 SmartPort를 직접 부르는 프로그램이 씁니다.
- 이미지: ProDOS 순서 블록 이미지(.po .hdv), ProDOS 순서 .2mg, MacBinary로 감싼 이미지, 이것들을 담은 .zip/.gz(읽기 전용).
- 3.5" 디스크는 블록 단위로 다룹니다. 복사 방지가 걸린 3.5" 원본(.woz 3.5")은 안 됩니다.
- 3.5" 드라이브의 이미지는 `linapple.conf`의 `SmartPort 3.5 Image 1/2`에, 하드디스크는 `Harddisk Image 1/2`에 기억됩니다.

## 화면

실행 중 **Alt+F9**로 화면 설정 메뉴를 열어 해상도, 확대 방식(ASPECT/SHARP), 모니터 모양을 고를 수 있습니다. 위/아래로 항목, 왼쪽/오른쪽으로 값을 바꾸고 Enter로 저장합니다. 확대 방식과 모니터 모양은 바로 적용되고, 해상도를 바꾸면 지금 재부팅할지 묻습니다(Y면 재부팅). 메뉴는 `APPLE2\display.txt`와 `linapple.conf`에 저장하므로, 이 파일들을 직접 고치고 재부팅해도 됩니다.

| 항목 | 값 | 뜻 |
|---|---|---|
| `RESOLUTION` | `1024x768`(기본), `800x600`, `1280x1024`, `1280x800` … | LCD 패널의 원래 해상도. GRUB이 부팅할 때 이 파일을 직접 읽어 그 해상도로 켭니다. 그래픽 카드에 없으면 1024x768, 800x600, 640x480 순서로 내려갑니다 |
| | `auto` | 모니터가 알려주는(EDID) 원래 해상도. 해상도가 높으면 오래된 PC에서 느릴 수 있음 |
| `PRIORITY` | `aspect`(기본) | 비율 우선: 4:3으로 화면을 가득 채움. 배율이 정수가 아니면 줄 높이가 조금씩 다를 수 있음 |
| | `sharp` | 선명함 우선: 세로를 정수배로 키워 모든 줄 높이를 같게, 4:3 유지. 그림이 작아지고 테두리가 생길 수 있음 |

예: 800x600 패널 → aspect 800×600 꽉 참, sharp 512×384 가운데 / 1280x1024 → aspect 1280×960, sharp 1024×768 / 1024x768 → 둘 다 1024×768.

와이드 모니터가 4:3 신호를 옆으로 늘려 보여주면 실행 중 **Alt+F6**으로 모니터 모양을 고르세요(`linapple.conf`의 `Monitor Aspect`, 저장됨).

## 사운드 카드

부팅할 때 `apple2-sound`가 아래 순서로 사운드 카드를 찾습니다. 결과는 `APPLE2\sound-cards.txt`에 적힙니다.

1. **메인보드 내장과 흔한 PCI 카드(커널에 들어 있음):** 인텔·SiS·nVidia·AMD AC'97(`intel8x0`), VIA AC'97, ATI IXP, HD Audio, Sound Blaster Live!/Audigy, Ensoniq AudioPCI·SB PCI 64/128, C-Media CMI8338/8738, Fortemedia FM801, Cirrus CS46xx
2. **그 밖의 PCI 카드(모듈, 꽂혀 있으면 불러옴):** Aureal Vortex 1/2(AU8810/8820/8830), ESS Maestro 1/2/2E/3·Allegro·Solo-1(ES1938), Yamaha YMF7xx(DS-XG), Trident 4DWave·SiS 7018, ALi M5451, Avance ALS300/ALS4000, Aztech AZF3328, Creative CA0106·SB Live! 5.1 Dell(EMU10K1X)·X-Fi, Cirrus CS4281, VIA Envy24(ICE1712/1724), NeoMagic NM256, C-Media CMI8788(Oxygen/Asus Xonar), S3 SonicVibes, Conexant Riptide, Korg 1212, Echo Audio 일부
3. **ISA 카드(내장·PCI 카드가 없을 때만):** `APPLE2\sound.txt`에 적은 줄 → ISA PnP 카드 → 사운드 블래스터 표준 설정(220h, IRQ 5/7, DMA 1/5, MPU 330h, FM 388h) 순서
   - 드라이버: Sound Blaster 1.x/2.0/Pro/16/AWE32/AWE64, ESS ES688/1688/18xx, Crystal CS4231/4232/4236, AD1848/AD1816A, Yamaha OPL3-SA2/SA3, OPTi 82C92x/93x, C-Media CMI8328/8330, Avance ALS100, Aztech AZT1605/2316/2320, Gravis UltraSound Classic/Extreme/MAX/InterWave, Ensoniq SoundScape, Media Vision Jazz16, miro PCM, Gallant SC-6000, Aztech Galaxy, AdLib
   - 점퍼로 설정하는 카드는 `sound.txt`의 예에서 맞는 줄의 `#`을 지우고 숫자를 카드 설정(DOS의 `SET BLASTER` 값)에 맞춥니다.
   - 빠진 것: Turtle Beach Maui/Tropez(WaveFront)와 Pinnacle/Fiji(MultiSound)는 펌웨어를 넣을 수 없어 뺐습니다. Sound Blaster 16의 ASP(CSP) 칩도 쓰지 않습니다.

## 네트워크

- 유선 랜: 케이블만 꽂으면 DHCP로 붙습니다. 그 시절 Intel, Realtek, VIA, SiS, nVidia, Broadcom, Marvell, Atheros 칩을 넣었습니다.
- 무선랜: `APPLE2\wifi.txt`에 `SSID=`와 `PASSWORD=`를 적고 다시 켭니다. 2.4GHz만 됩니다.
  - 넣은 드라이버: Atheros(ath5k, ath9k), Ralink(rt2400/2500/rt61/rt2800), Realtek(rtl8180/8185, rtl8187, rtl8192ce/se/de, rtl8188ee), Intel PRO/Wireless 2100/2200, Intel 3945/4965/5000 계열, Broadcom(brcmsmac, b43), Intersil Prism54, ADMtek, USB 무선랜 일부.
  - **Broadcom b43(BCM4306/4311/4318 등 구형)은 펌웨어를 함께 넣을 수 없어서 동작하지 않습니다.** 그 카드라면 다른 무선랜이나 유선 랜을 쓰세요.
- 특이한 설정이 필요하면 `wifi.txt` 대신 `APPLE2\wpa_supplicant.conf`를 직접 두면 그것을 씁니다.

## 문제가 생기면

- **에뮬레이터가 오류로 멈추면** 화면에 로그가 나오고 Enter(다시) / p(끄기) / s(셸)를 고를 수 있습니다. 로그는 `APPLE2\linapple.log`에도 남습니다.
- **화면이 안 나오면** `APPLE2\display.txt`의 `RESOLUTION`을 `800x600`이나 `640x480`으로 바꾸고 다시 켜세요.
- **소리가 안 나면** Ctrl+Alt+F2 셸에서 `cat /proc/asound/cards`, `amixer`를 확인하세요.
- **네트워크가 안 되면** 셸에서 `cat /run/net.log`, `ip addr`를 확인하세요.
- **시계:** 윈도우처럼 BIOS 시계를 현지 시각(한국 시간)으로 읽습니다. 네트워크에 붙으면 인터넷 시간으로 맞추고 BIOS 시계도 고칩니다.
- **CPU:** 32비트 i686 이상(Pentium Pro, Pentium III, Athlon 이상)이면 됩니다.

## 확인한 것과 못 한 것

QEMU(Pentium III, 512MB, IDE 디스크, AC'97, e1000/RTL8139 랜)로 이 이미지 자체를 부팅해 확인했습니다.

- 메뉴 없이 부팅 → "Apple //e" → 슬롯 7 SmartPort 하드, 비어 있으면 5.25" 드라이브 1로 부팅
- 유선 랜 DHCP, `network.txt` 기록
- 세이브 핫키(화면 캡처 포함)와 썸네일 화면, APPLE2 파티션에 기록, F12로 전원 꺼짐
- AC'97 소리 출력, 무선랜 드라이버 모듈 로드(ath5k, ath9k, rt2800pci, ipw2200, rtl8192ce)
- 데스크톱에서 같은 에뮬레이터로: SmartPort 하드·3.5" 드라이브 부팅과 세이브

실제 무선랜 접속, 실기 그래픽 카드·사운드 칩별 동작, QEMU보다 빠른 실기에서의 부팅 시간은 직접 확인이 필요합니다.

## 직접 만들기

Ubuntu 24.04 x86_64에서 root로 `./build.sh`를 실행하면 `out/apple2pc.img`가 나옵니다(인터넷 필요, 1~2시간).

```
kernel/linux-fragment.config   커널 설정 (i386_defconfig 위에 덮어씀)
busybox/busybox.config         busybox 설정 (정적 빌드)
linapple/*.patch               LinApple 패치 8개
wpa/wpa_supplicant.config      wpa_supplicant 빌드 설정
overlay/                       inittab, 부팅·네트워크 스크립트, 기본 설정
grub.cfg, genimage.cfg         부트로더, 디스크 구성
```

LinApple 패치:

1. 세이브 슬롯 화면 캡처, 알림, 썸네일 고르기 화면
2. 32비트 x86에서 세이브 파일 구조가 64비트와 같도록 수정 (원래 소스는 32비트 x86에서 빌드가 안 됨)
3. SmartPort 카드(하드 2 + UniDisk 3.5 2)와 FujiNet 카드(이미지에서는 쓰지 않음), 전체화면 해상도, 세이브 즉시 기록
4. 넣은 디스크를 다음 부팅 때 그대로 넣기
5. SuperSprite 카드
6. 전체화면에서 애플 화면 모양 유지(기본 4:3, `Full Screen Aspect`), 모니터 모양 보정(`Monitor Aspect`, Alt+F6), 확대 방식(`Scale Mode` aspect/sharp), 전체화면으로 시작할 때도 적용
7. 화면 설정 메뉴(Alt+F9): display.txt와 설정을 고치고 필요하면 재부팅 요청
8. 볼륨 키(Alt+F7/Alt+F8, 키보드의 볼륨·음소거 키): amixer로 사운드 카드 볼륨, 화면 표시, 저장
9. 빠른 소프트웨어 확대: 열 위치 표 + 원본 줄을 한 번만 확대해 복사 (1024x768에서 CPU 약 1/4, 그림은 같음)
10. 소리가 나는 동안은 디스크 가속을 하지 않음(AppleWin과 같은 규칙: 스피커 0.2초, 모킹보드 0.1초). 키패드 +/-/*, ScrollLock 속도 변경을 화면에 표시
11. 고른 플로피·하드디스크 이미지를 다음 부팅에도 유지 (SmartPort 상태 질의가 결과를 돌려주지 않던 버그 수정, 하드 선택·꺼내기 때 바로 저장)
12. 10초마다 프레임 지연·소리 모자람 통계를 로그에 남김(`system-info.txt`에 들어감), `Sound Buffer`(ms) 설정
13. 바뀐 줄만 다시 그리기(안 바뀐 화면은 비교만), 모킹보드 6채널을 좌우로 먼저 섞은 뒤 리샘플링

구성 요소와 라이선스: Linux(GPL-2.0), BusyBox(GPL-2.0), LinApple(GPL-2.0), SDL 1.2(LGPL-2.1), wpa_supplicant(BSD), GRUB(GPL-3.0), Ubuntu 패키지의 glibc·OpenSSL·ALSA 등, linux-firmware(각 펌웨어 라이선스). Apple II ROM은 LinApple 소스에 들어 있는 것을 씁니다.
