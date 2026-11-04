# Apple II PC — 작업 노트 (이어서 작업할 때 먼저 읽기)

> 원본 저장소: https://github.com/spadent-crypto/apple2pc (main 브랜치)
> 다시 시작할 때: "애플2 PC 이어서 하자"라고 하면 저장소에서 최신 상태를 받아 시작합니다.
> 작업 환경(클라우드 컨테이너)의 파일은 세션이 끝나면 사라지므로, **저장소가 원본**입니다.
> 완성 이미지는 `images/`에 버전별로 커밋합니다 (v1.0 2026-10-20, v1.1~v1.3 2026-11-04). 표는 `images/README.md`.

마지막 갱신: 2026-11-04 (v1.3: APPLE2 파티션 자동 확장)

## 1. 목표 (사용자 요구사항)

- 레거시 BIOS 구형 PC(윈도우 XP 시절, SATA일 수도 있음, AC'97, 내장 PCI 무선랜)에 설치
- 전원을 켜면 Apple II처럼 중간 화면 없이 빠르게 부팅
- 핫키로 화면 캡처와 함께 세이브 스테이트 저장·불러오기
- ~~FujiNet 지원~~ → 2026-11-04 사용자 요청으로 제거. 로컬 플로피·하드 이미지만 사용
- SmartPort 하드, UniDisk 3.5, 5.25"/3.5" 플로피 지원
- Rufus로 구울 수 있는 이미지

## 2. 현재 상태

### 완료 (1차, 2026-10-20)
- `apple2pc.img` (약 600MB, zip 29MB): MBR, 1번 ext4 시스템(읽기 전용 마운트), 2번 FAT32 `APPLE2` 데이터
- GRUB 메뉴 없음 → 커널 quiet → LinApple 전체화면 (프레임버퍼, X 없음) → F12로 전원 꺼짐
- 세이브 슬롯 0~9: Ctrl+Shift+N 저장(BMP 캡처 함께), Ctrl+N 불러오기, F11/F10 썸네일 화면
- (1차 당시) 슬롯 7 FujiNet, 6 Disk II, 5 SmartPort(하드 2 + UniDisk 3.5 2), 4 Mockingboard → 2026-11-04에 변경, 위 참고
- 네트워크: 유선 DHCP 자동, 무선은 `APPLE2\wifi.txt`(SSID/PASSWORD), NTP 시간 동기, `network.txt`에 IP 기록

### 추가 (2026-11-04, v1.3): APPLE2 파티션 자동 확장
- 사용자 요청: 4GB USB에 쓰면 남는 공간을 APPLE2가 쓰게
- `overlay/usr/bin/apple2-grow` (apple2-session이 마운트 전에 실행): APPLE2가 마지막 MBR 기본 파티션이고 뒤에 64MB 이상 비어 있으면 → 파일을 tmpfs로 복사(파일 크기×2+64MB가 MemAvailable보다 크면 건너뜀) → MBR 파티션 항목의 크기를 busybox dd로 직접 고침(시작·크기가 sysfs와 맞는지 먼저 확인) → `resizepart`로 커널에 알림(루트가 같은 디스크에 마운트돼 있어도 BLKPG로 됨) → `mkfs.fat -F 32 -n APPLE2`(볼륨 ID 유지) → 파일 되돌림. 로그는 `APPLE2\grow.txt`
- 추가 바이너리: util-linux의 `resizepart`, dosfstools의 `mkfs.fat` (둘 다 libc만 필요). sfdisk는 readline 등 라이브러리가 많아 안 씀
- QEMU 확인: 이미지를 2GB로 늘려 부팅 → APPLE2 256MB → 1.7GB, disks 안 파일·설정 유지, LinApple 정상 시작. 두 번째 부팅은 아무것도 안 함
- README의 "윈도우 디스크 관리로 늘리면 된다"는 틀린 안내(디스크 관리는 FAT32 확장 불가)를 고침

### 추가 (2026-11-04, v1.2): 사운드 카드 확장
- 사용자 요청: "PCI 카드 지원은 충분하게, ISA 카드도 기존 포트와 IRQ 설정을 기준으로 동작하게"
- 커널: 흔한 내장·PCI 칩은 그대로 내장(y), 그 밖의 PCI 사운드 드라이버 대부분과 ISA(`CONFIG_ISA`, `ISAPNP`) 사운드 드라이버 전부를 모듈로. 펌웨어 `ess/`, `yamaha/`, `korg/`, `ea/` 추가. WaveFront·MultiSound(펌웨어 없음), SB16 CSP는 뺌
- `overlay/usr/bin/apple2-sound` (LinApple 전에 동기 실행): PCI 오디오 장치(class 04xx) 모듈 로드 → 카드가 없을 때만 `APPLE2\sound.txt` 줄 → ISA PnP 드라이버(옵션 없이) → SB 표준 설정(220h, IRQ 5/7, DMA 1/5, MPU 330h, FM 388h) 순서. 결과를 `APPLE2\sound-cards.txt`(CRLF), 로그는 `/run/sound.log`
- 알게 된 것: ISA PnP 겸용 드라이버(sb16, sbawe, es18xx, opl3sa2, cs4236 등)는 `isapnp` 기본값이 1이라 레거시 포트를 아예 안 봄 → `port=`가 있으면 그 모듈이 `isapnp` 파라미터를 가질 때 `isapnp=0`을 자동으로 붙임(.ko 안 `parm=isapnp:` 확인). `snd-cs4231`은 `dma2`를 안 주면 자동 선택하다 실패 → 두 번째 DMA가 없으면 `dma2=-1`
- QEMU 확인: `-device sb16`(비PnP, 220h/5/1/5) 자동 인식, `-device cs4231a,irq=10` + sound.txt 한 줄로 인식, `-device AC97`은 내장 드라이버로 인식. QEMU에서는 IRQ 9가 ACPI라 WSS 예시는 IRQ 10
- 사용자 확인(2026-11-04, 맥 QEMU): v1.2 정상 부팅, 울티마 IV·V가 소리와 함께 실행됨
- 아직 실기 ISA 카드로는 확인 못 함

### 변경 (2026-11-04): FujiNet 제거
- 사용자 요청: "FujiNet 기능을 삭제하고 플로피와 HDD에 디스크 이미지 마운트해서 사용하는 것만"
- 이미지에서 FujiNet-PC 빌드·설치·실행 제거 (`build.sh` fujinet 단계, `overlay/usr/bin/apple2-fujinet`, `fujinet/fnconfig.ini`, 데이터 파티션 `fujinet\` 폴더)
- 슬롯: **7 SmartPort**(하드 2 + UniDisk 3.5 2), 6 Disk II, 5 비움, 4 Mockingboard. 부팅 순서 = 하드 1 → (비어 있으면, 펌웨어가 다음 슬롯으로 넘김) 5.25" 드라이브 1
- SuperSprite를 쓸 때는 `Slot 7 = SuperSprite`, `Slot 5 = SmartPort`
- LinApple 패치는 그대로 (FujiNet 카드 코드는 패치 3에 남아 있음, 설정에서 안 씀)
- 네트워크(유선/무선)는 시계(NTP) 맞추기용으로 남김
- QEMU 확인: 하드 1 + 5.25" 둘 다 넣으면 하드(슬롯 7)로, 하드 없이 5.25"만 넣으면 슬롯 6으로 부팅 (각각 메시지만 찍는 시험용 부트 블록 디스크로 확인)
- 빌드 고침: busybox `yes | make oldconfig`가 pipefail에서 141로 끝나던 것 수정, genimage.cfg에서 fujinet 폴더 제거
- 이미지 sha256: img e2458867…, zip fe3ae19f… (2026-11-04 대화에서 전달)
- 주의: 기존 이미지의 APPLE2 파티션 `linapple.conf`는 첫 부팅 때만 만들어지므로, 옛 이미지를 쓰던 경우 그 파일의 슬롯 줄을 직접 고쳐야 함

### 추가 (2026-10-24): SuperSprite 카드
- Synetix SuperSprite를 LinApple 카드로 구현 (패치 5). `linapple.conf`의 `Slot 7 = SuperSprite`로 고름 (그동안 FujiNet 꺼짐)
- TMS9918A VDP(16K VRAM, Graphics I/II·멀티컬러·텍스트, 스프라이트 32개·확대·early clock·라인당 4개·5번째 플래그·충돌·프레임 인터럽트)
- 화면 합성: 비디오 스위치 $C0n3~6 (애플 영상 입력 끔/켬, 애플만/VDP 합성). VDP 256x192를 애플 560x384 화면 전체에 늘려 덮음. 색 0은 애플 화면(입력 켬) 또는 검정
- AY-3-8912: $C0nC/D 데이터 쓰기, $C0nE/F 레지스터 선택·읽기. Mockingboard의 AY 코어 재사용, 모노
- Echo II(TMS5220) 음성은 미구현: $C0n2 상태는 항상 대기(0x7F)
- 세이브 스테이트에 VRAM·레지스터·AY·스위치 포함
- 데모: `related/supersprite-demo/` (6502 데모 `ssdemo.apl`, 브라우저판 빌드 방법). 데스크톱 SDL1 LinApple과 브라우저판에서 실행 확인 (합성·스위치·효과음)
- 레지스터 맵 출처: MAME `src/devices/bus/a2bus/ssprite.cpp` (매뉴얼 33쪽 기준)
- 테스트: `tests/test_supersprite.cpp` (칩 단위 + 슬롯 7 합성·AY·세이브). 헤드리스 빌드 전체 ctest 118개 중 117개 통과. 실패 1개(`test-peripheral-dependency-rule`)는 패치 3의 SmartPort 카드가 harddisk 헤더를 include해서 생기는 기존 문제

### 검증한 것
- QEMU(Pentium III, 512MB, IDE, AC'97, e1000/RTL8139): 부팅 → Apple //e → FujiNet CONFIG, 유선 DHCP, 웹 UI 접속, 세이브 핫키·썸네일·FAT 기록, F12 전원 끄기, 소리 출력, 무선 모듈 로드
- 데스크톱 LinApple: FujiNet SD의 Ultima IV 부팅·세이브, SmartPort 로컬 하드·3.5 부팅·세이브, 32비트 빌드에서 64비트 세이브 파일 호환

### 검증 못 한 것 (실기 테스트 필요)
- 실제 무선랜 접속(칩셋별), 실기 그래픽 카드의 VESA 모드, 실기 사운드 칩, 실기 부팅 시간
- ProDOS 2.4에서 SmartPort 유닛 3, 4가 보이는지

- SuperSprite: 실제 SuperSprite 소프트웨어(StarSprite 데모 디스크 등)로는 아직 시험 못 함 (작업 환경에서 asimov 접근 불가)

### 알려진 한계
- SuperSprite: VDP 화면은 VBL마다 한 번 통째로 그림 (프레임 중간 레지스터 변경은 다음 프레임에 반영). 실기처럼 애플 화면과 픽셀 단위로 맞물리지는 않음. 오프셋 7(frame reset)은 무시
- 구형 Broadcom b43(BCM4306/4311/4318): 펌웨어를 넣을 수 없어 미지원 (b43-fwcutter가 인터넷에서 받아야 함)
- 복사 방지 3.5" 원본(.woz 3.5")은 블록 방식이라 미지원
- 펌웨어 SmartPort 시그니처($Cn07=$00) 때문에 구형(비Enhanced) //e·II+ 자동 부팅 스캔에서는 안 잡힘 (기본 기종 Enhanced //e는 문제없음)
- (1차) QEMU(TCG)에서는 FujiNet CONFIG까지 약 45초

## 3. 구조

```
전원 → BIOS → GRUB(i386-pc, 메뉴 없음, VESA gfxpayload)
     → Linux 6.12.47 i386 (quiet, console=tty3)
     → busybox init (/etc/inittab) → /usr/bin/apple2-session (tty1)
         ├ APPLE2 파티션 마운트 (/media/apple2, vfat flush)
         ├ apple2-net & : 모듈 coldplug, udhcpc, wpa_supplicant, ntpd (시계용)
         └ linapple -c APPLE2/linapple.conf -f  (SDL1.2 fbcon, ALSA)
```

- (제거됨, 참고용) FujiNet 연결: LinApple의 FujiNet 카드가 127.0.0.1:1985에서 listen → FujiNet-PC가 접속 → INIT 스캔으로 유닛 수 파악 (마지막 유닛은 END OF CHAIN 응답)
- 프로토콜: SLIP 프레임, 요청 = 11바이트 헤더 [seq, cmd, pcount, devid, 0, 0, p0..p4] + payload, 응답 = [seq, status, data...] (FujiNet 펌웨어 lib/devrelay 기준)
- 카드 펌웨어(`src/apple2/peripherals/smartport/firmware/smartport.s`, 슬롯별 어셈블): 카드는 메모리를 읽기만 하고, 쓰기는 6502가 IO 레지스터($C0n9)에서 복사 → 뱅크 전환(보조 메모리, 랭귀지 카드)에 안전, CPU 레지스터 접근 불필요
- SmartPort(로컬) 카드와 FujiNet 카드는 같은 펌웨어·같은 코어(`SmartPortCard.cpp`)를 쓰고, 백엔드만 다름(`LocalDisks` / `FujiNetLink`)

## 4. 소스 위치와 버전 (build.sh에 고정)

| 구성 요소 | 출처 | 버전 |
|---|---|---|
| Linux | github.com/gregkh/linux | v6.12.47 |
| BusyBox | github.com/mirror/busybox | 371fe9f7 (Buildroot 2026.08 설정 + static + ntpd) |
| LinApple | github.com/linappleii/linapple | 86bee1c2 + `linapple/*.patch` 5개 |
| SDL 1.2 | github.com/libsdl-org/SDL-1.2 | 81490298 (fbcon + ALSA, 32비트) |
| wpa_supplicant | archive.ubuntu.com pool, wpa_2.11.orig | 2.11 |
| glibc, OpenSSL, ALSA, libnl, expat | Ubuntu 24.04 i386 패키지 | noble |
| 펌웨어 | Ubuntu linux-firmware-* 분할 패키지 | 20240318 |

LinApple 패치:
1. `sdl1`: 세이브 슬롯 + 스크린샷 + OSD 알림 + 썸네일 고르기 화면 (`SnapshotGallery.cpp`)
2. `snapshot`: 32비트 x86에서 .aws 구조 맞춤 (uint64/double에 alignas(8))
3. SmartPort·FujiNet 카드, `Screen Width/Height` 읽기, 전체화면 시작 시 커서 숨김, 세이브 후 sync
4. F3/F4로 넣은 디스크를 설정 파일에 바로 저장
5. SuperSprite 카드 (`src/apple2/chips/TMS9918A.*`, `src/apple2/peripherals/supersprite/`), HostInterface에 `SetVideoOverlay` 추가 (Video.cpp `video_set_overlay`)

## 5. 다시 빌드하는 법

Ubuntu 24.04 x86_64, root, 인터넷(archive.ubuntu.com, github.com):

```
./build.sh                 # 전체 (1~2시간)
./build.sh rootfs image    # 빌드된 것으로 이미지만 다시 조립
WORK=/경로 OUT=/경로 ./build.sh ...
```

빌드 중 알게 된 것:
- Buildroot 다운로드 사이트, kernel.org, Debian 미러는 이 작업 환경에서 막혀 있음. Ubuntu 아카이브와 GitHub는 됨
- Ubuntu noble의 i386은 일부 패키지만 있음: wpasupplicant, libzip-dev는 없음 → 직접 빌드
- 아키텍처 공통 패키지(libasound2-data 등)는 `:i386` 없이 받아야 함 (빠지면 ALSA 설정이 없어 소리 안 남)
- `make modules_install`은 호스트에 kmod(depmod)가 있어야 modules.dep가 생김
- 루트 파일시스템은 /lib → usr/lib 병합 구조 (Ubuntu 패키지가 /usr/lib/i386-linux-gnu에 설치됨)
- 이미지 안에서 펌웨어는 .zst를 풀어서 넣음 (커널에 zstd 펌웨어 압축 해제 옵션 없음)

## 6. 다음에 할 일 후보

- [ ] 실기 테스트 결과 반영 (그래픽 모드, 사운드 카드(`sound-cards.txt`), 무선랜 칩 모델)
- [ ] (선택) 맥 QEMU 확인용 저해상도(640x480) 부팅 옵션
- [ ] 무선랜 칩 모델 확인 → 필요한 드라이버·펌웨어 추가
- [ ] 부팅 시간 측정·단축 (커널 크기, 서비스 순서)
- [ ] (선택) 화면 하단 드라이브 LED 표시 끄기 옵션 (`Show Leds = 0`)
- [ ] (선택) 네트워크를 아예 빼서 부팅 가볍게 (지금은 시계 맞추기용으로만 남음)
- [ ] (선택) FujiNet을 다시 쓰고 싶으면 2026-11-04 이전 커밋의 build.sh·overlay 참고
- [ ] SuperSprite: StarSprite 데모·게임 디스크로 실제 동작 확인 (asimov `images/hardware/video/StarSprite-SuperSprite-Programs.zip`)
- [ ] (선택) SuperSprite Echo II 음성(TMS5220) 구현
- [ ] (선택) 비슷한 Third Millennium Arcade Board도 추가 (같은 VDP, 레지스터 배치만 다름, 슬롯 4)

## 7. 관련 작업

- **Ultima IV 하드 이식판(`ultima4_hd1440_iic_mb.po`) 세이브 오류:** 실기 IIc + Floppy Emu에서 Q 세이브 시 `CHECKSUM ERROR`가 남. 원인은 로더(U4)가 `BSAVE PRTY,A$0` 등을 제로페이지·language card 메모리에서 SmartPort 펌웨어로 직접 보내는 것. `patch_u4.py`로 $BC00 버퍼를 거쳐 쓰도록 패치함(로더의 사용하지 않는 $B700 영역에 44바이트). 에뮬레이터에서는 세이브 확인 완료. 실기 확인 대기 중. SD 카드에서 `file not contiguous`가 나면 카드를 정리하고 다시 복사.
- Digger Apple II 이식 프로젝트(Mockingboard, 64K/128K): 이 에뮬레이터 이미지로 시험 가능
