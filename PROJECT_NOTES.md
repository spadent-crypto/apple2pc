# Apple II PC — 작업 노트 (이어서 작업할 때 먼저 읽기)

> 원본 저장소: https://github.com/spadent-crypto/apple2pc (main 브랜치)
> 다시 시작할 때: "애플2 PC 이어서 하자"라고 하면 저장소에서 최신 상태를 받아 시작합니다.
> 작업 환경(클라우드 컨테이너)의 파일은 세션이 끝나면 사라지므로, **저장소가 원본**입니다.
> 완성 이미지는 `images/`에 버전별로 커밋합니다 (v1.0 2026-10-20, v1.1~v1.8 2026-11-04, v1.9 2026-11-05, v2.0~v2.5 2026-11-06, v2.6~v2.8·v3.0·v3.1 2026-11-07). 표는 `images/README.md`.

마지막 갱신: 2026-11-07 (v3.1: X61s 소리 안 남 대응 — 내장 사운드 카드를 기다림, USB는 재생 장치만)

## 1. 목표 (사용자 요구사항)

- 레거시 BIOS 구형 PC(윈도우 XP 시절, SATA일 수도 있음, AC'97, 내장 PCI 무선랜)에 설치
- 전원을 켜면 Apple II처럼 중간 화면 없이 빠르게 부팅
- 핫키로 화면 캡처와 함께 세이브 스테이트 저장·불러오기
- ~~FujiNet 지원~~ → 2026-11-04 사용자 요청으로 제거. 로컬 플로피·하드 이미지만 사용
- SmartPort 하드, UniDisk 3.5, 5.25"/3.5" 플로피 지원
- Rufus로 구울 수 있는 이미지

## 2. 현재 상태

### 완료 (1차, 2026-10-20)
- `apple2pc.img` (약 336MB, zip 24MB): MBR, 1번 squashfs 시스템(xz, 64MB 파티션), 2번 FAT32 `APPLE2` 데이터 (v3.0부터; 그 전엔 ext4 320MB)
- GRUB 메뉴 없음 → 커널 quiet → LinApple 전체화면 (프레임버퍼, X 없음) → F12로 전원 꺼짐
- 세이브 슬롯 0~9: Ctrl+Shift+N 저장(BMP 캡처 함께), Ctrl+N 불러오기, F11/F10 썸네일 화면
- (1차 당시) 슬롯 7 FujiNet, 6 Disk II, 5 SmartPort(하드 2 + UniDisk 3.5 2), 4 Mockingboard → 2026-11-04에 변경, 위 참고
- 네트워크: 기본 꺼짐(v3.0). `APPLE2\wifi.txt`의 `WIRED=on` 또는 SSID가 있으면 부팅 20초 뒤 apple2-net(모듈 coldplug, 유선 DHCP, 무선, NTP), `network.txt`에 IP 기록

### 추가 (2026-11-07, v3.1): X61s에서 소리가 안 나고 볼륨 버튼이 안 됨
- 사용자 보고(v3.0): "X61에서는 소리가 나는데 X61s에서는 소리가 안 나고, 볼륨 버튼 동작이 없어졌어", USB 사운드카드는 없음
- 확인: HDA·AD1984 코덱은 커널에 그대로(y), thinkpad_acpi와 의존 모듈 모두 이미지에 있음
- 추정 원인: v3.0이 빨라져서 apple2-sound가 내장 HDA 카드 등록(커널이 백그라운드로 probe) 전에 `/proc/asound/cards`를 봄 → 카드 없음으로 판단, ISA 탐색, LinApple은 소리 장치 없이 시작, 볼륨 키는 컨트롤이 없음. CPU가 느린 X61s에서만 드러날 수 있음. QEMU에서는 카드가 먼저 떠서 재현 못 함
- apple2-sound: PCI 오디오 장치(class 04)가 있으면 카드가 생길 때까지 최대 8초(0.2초 간격) 기다림, 기다린 시간을 기록. sound-cards.txt에 "[What was tried]"로 /run/sound.log 전체
- 함께: USB 오디오는 재생 PCM(/proc/asound/cardN/pcm*p)이 있는 카드만 씀(웹캠·마이크 제외), sound.txt에 `USB_AUDIO=off`
- 다음: X61s의 v3.0 sound-cards.txt(카드 없음/ISA 시도였는지)와 v3.1 결과

### 변경 (2026-11-07, v3.0): USB 1.1 부팅 시간 줄이기
- 사용자: "USB 1.1 구형 노트북을 활용하려고 시작한 프로젝트인데 실제 해보니 부팅에 시간이 많이 걸려"
- 잴 방법: QEMU에서 UHCI(USB 1.1) usb-storage로 부팅(`-device piix3-usb-uhci -device usb-storage`), `-drive ...,throttling.bps-read=`로 속도 제한, `info blockstats` rd_bytes와 화면(1024 폭, 밝은 픽셀)으로 LinApple까지 시간·바이트. 스크래치 `bootbench.py`. `-trace blk_co_preadv -D log`로 읽은 오프셋을 debugfs icheck/ncheck(ext4)로 파일에 매핑(`mapreads.py`)
- 한계: QEMU는 CPU 흉내가 느려 시간보다 **읽은 바이트**가 의미 있음. 300KB/s 제한에서는 SeaBIOS가 USB에서 멈춤(흉내 불가)
- v2.8: 20.1MB (bzImage 8.6MB 전부 + busybox 2.1 + libc 2.0 + libstdc++ 1.6 + linapple 1.3 + libasound 1.1 ...: 미리 읽기 때문에 파일 통째로)
- 바꾼 것과 효과(읽은 양): 커널 LZ4→ZSTD, IPv6·KALLSYMS 끔 (bzImage 6.2MB) → 유선 랜 드라이버 25개 모듈로, MD/DM·9P 끔 (5.4MB) → 16.9MB; 미리 읽기 16KB(inittab에서 sysfs 마운트 직후) → 14.1MB; busybox 동적(libc 공유, 2.09→0.76MB) → 13.7MB; 루트를 squashfs(xz, -Xbcj x86) + EXT4 끔 (bzImage 5.2MB) → 블록 64K 9.5 / 32K 9.3 / 16K 9.7 / 128K 9.8MB → 32K 선택
- 네트워크 기본 끔: `wifi.txt`에 `WIRED=off`(새 항목), SSID나 WIRED=on, 또는 wpa_supplicant.conf가 있을 때만 `sleep 20` 뒤 apple2-net. `usb-storage.delay_use=0`. apple2-sound USB 안정 대기 0.5→0.3초. network.txt의 FujiNet 줄 지움
- GRUB 코어 모듈: ext2 → squash4 xzio (GRUB squash4는 zlib/lzo/xz만, zstd 없음 → squashfs는 xz). 파티션 1 시작 섹터 370, 크기 64M 고정(이미지 604MB → 336MB)
- 확인(QEMU IDE, 1GB 디스크): 부팅, APPLE2 959MB로 늘림, 사운드, F12 확인 뒤 전원 꺼짐; WIRED=on이면 20초 뒤 e1000 모듈 로드·DHCP(network.txt)
- 남은 큰 것: bzImage 5.2MB(커널 core·net·sound·fs). XZ 커널 압축은 ~15% 작지만 옛 CPU에서 풀기가 느려 비슷할 것으로 보고 안 함

### 추가 (2026-11-07, v2.8): 게임별 세이브 슬롯
- 사용자 요청: "세이브 로드에서 게임별로 10개라야 할 거 같은데... 지금은 모두 10개", "게임별로도 폴더를 만들고 거기에 10개씩 저장하게"
- LinApple 패치 18: `gallery_slot_path`가 `<save dir>/<게임>/SaveStateN.*`. 게임 = 부팅 디스크(하드 1이 있으면 하드 1, 아니면 플로피 1) 파일 이름에서 확장자를 뺀 것, FAT에 못 쓰는 글자는 _, 64자. 시작(enter_message_loop), Ctrl+F2(reset_machine_state, 로고 화면 리셋)에서 정함 → 게임 중 디스크를 바꿔도 같은 폴더(울티마 시나리오 디스크 등). 저장할 때 폴더를 만듦. 슬롯 화면 제목 "SAVE - <게임>"/"LOAD - <게임>". F1 도움말에서 F10, F11을 따로 적음
- 예전 `saves/SaveStateN.*`는 그대로 남음(어느 게임 것인지 알 수 없어 옮기지 않음)
- QEMU 확인: test-fd.dsk 부팅 → Ctrl+Shift+3 → `saves/test-fd/SaveState3.aws|bmp`, F11 제목 "SAVE - test-fd"

### 추가 (2026-11-07, v2.7): F1 도움말
- 사용자 질문: "F1 누르면 전체 핫키 도움말 나오나?" → 원래 LinApple 목록이라 Apple II PC에서 더한 키(볼륨, Alt+F9, Alt+F6, 디스크 빼기, 세이브 슬롯, F12 확인)가 없었음
- LinApple 패치 17: `HelpText.h`를 Apple II PC 머리말과 32줄 목록(키 칸 16자 오른쪽 맞춤)으로, `HelpFeature`에 새 항목 5개(TUI는 제외 목록에 넣음). sdl1 도움말 줄 간격을 줄 수에 맞춰 줄임(최대 13)
- QEMU 스크린샷으로 확인

### 추가 (2026-11-07, v2.6): F12 확인 창
- 사용자 요청: "F12 버튼 누르면 확인창 있어야 하지 않아? 컴퓨터를 종료하시겠습니까? 같은..."
- LinApple 패치 16: `frame_confirm_power_off()`(Frame.cpp) — 화면을 어둡게 하고 노란 테두리 상자에 "TURN THE COMPUTER OFF?", Enter/Y 예, Esc/N 아니오. 글꼴이 영문뿐이라 영어. 에뮬레이터 F12(btn_quit), 도움말 화면, 디스크 선택, 화면 설정 메뉴의 F12 모두 거침. 시스템이 보낸 SDL_QUIT은 묻지 않음. 아니오면 그림 전체 다시 그림
- 테스트: 도움말·디스크 선택 F12 테스트가 확인 창에서 멈춤(이벤트 대기) → F12 뒤 Enter를 넣도록, F12 뒤 Esc면 안 꺼지는 테스트 추가
- QEMU 확인: F12 → 창, Esc → 원래 화면, F12 → Enter → 전원 꺼짐

### 추가 (2026-11-06, v2.5): 그냥 끄거나 USB를 뽑을 때
- 사용자 질문: "게임하다가 그냥 끄거나 usb를 뽑으면 파티션이나 fs이 망가지지 않아?"
- (v2.5 당시) 루트 ext4는 ro. APPLE2(FAT32)는 `rw,noatime,flush`. 플로피 쓰기는 모터가 멈출 때 트랙을 fwrite+fflush(커널까지만), SmartPort는 pwrite 후 1초 넘게 지났으면 fsync. 커널 기본 writeback은 30초라 마지막 저장이 최대 30초 메모리에 머묾
- 세션: `vm.dirty_expire_centisecs=100`, `dirty_writeback_centisecs=100` → 쓴 것이 약 2초 안에 USB로. system-info.txt에 값
- QEMU 확인: Alt+F7 두 번 뒤 4초 만에 QEMU quit(전원 끊기) → conf에 새 볼륨이 남아 있음, `fsck.fat -n`은 dirty bit 말고 오류 없음
- 남는 것: 리눅스 vfat가 마운트 중 dirty bit를 켜서, 그냥 끄면 Windows가 검사를 물음(무해). 쓰는 바로 그 순간 끊기면 그 파일은 깨질 수 있음. 첫 부팅 파티션 늘리기 중에는 끄면 안 됨

### 추가 (2026-11-06, v2.4): USB 오디오
- 사용자 질문: "USB audio class 사운드는 지원하니?" → 커널 조각에 `CONFIG_SND_USB=n`이 있어 안 됐음
- 커널: `CONFIG_SND_USB=y`, `CONFIG_SND_USB_AUDIO=m`
- `apple2-sound`: USB 장치 목록이 멈출 때까지(최대 3초) 기다린 뒤 인터페이스 클래스 01(오디오)이 있으면 `snd-usb-audio`를 올리고, /proc/asound/cards의 USB-Audio 카드 번호를 /run/alsa-card에. 세션이 `ALSA_CARD`로 내보냄 → alsa.conf의 default pcm/ctl이 그 카드(amixer, SDL 모두). 즉 USB 오디오가 꽂혀 있으면 내장 대신 씀. 켠 뒤에 꽂은 것은 다음 부팅부터
- USB 장치의 볼륨 컨트롤 이름이 다를 수 있음(QEMU: 'Audio Output Volume Control') → 세션과 볼륨 키(LinApple 패치 15)가 이름 목록에 없으면 첫 컨트롤을 씀. system-info.txt에 쓰는 카드의 컨트롤 목록
- QEMU 확인: AC'97 + `-device qemu-xhci -device usb-audio`(EHCI는 속도 안 맞음) → card 1 USB 선택, 소리가 USB wav로 녹음됨, Alt+F7로 85→80 저장

### 추가 (2026-11-06, v2.3): 모킹보드 화음이 빠짐
- 사용자 보고(v2.2, X61s): "음악을 들어보니 뭔가 화음이 빠지는게 있어"
- 확인: 두 칩에 다른 음(249Hz, 664Hz)을 내는 `mb2tone.dsk`로 패치 13 전후 WAV 비교 → 둘 다 왼쪽 249, 오른쪽 664로 같음. 믹서 변경 탓 아님
- 원인 추정: 모킹보드는 첫 칩 3음을 왼쪽만, 둘째 칩 3음을 오른쪽만(실제 카드와 같음). X61s 내장 스피커가 한쪽만 내면 3음이 통째로 빠짐(스피커가 모노인지, 어느 채널을 내는지는 확인 못 함)
- LinApple 패치 14: `Mockingboard Stereo`(0~100). 100 = 카드 그대로, 0 = 모든 음을 양쪽으로. 소스 기본 팬을 섞음(own=0.5+w/200). 스피커처럼 가운데인 소스는 그대로. 게인은 등록 때 기본 팬으로 정해지므로 바뀌지 않음(합이 같음)
- Apple II PC 기본값 0. 세션이 기존 conf에 없으면 넣음
- 사용자 확인(v2.3, X61s): "이제 잘 나와" → 화음 빠짐은 스피커 한쪽 채널 문제였던 것으로 봄. 끊김·느림도 함께 해결

### 추가 (2026-11-06, v2.2): 모킹보드 소리가 끊기고 느림 (X61s)
- 사용자 보고: v2.1, X61s, 모킹보드 소리가 "툭툭 끊기면서 아주 느림"
- 이 서버(2.1GHz Xeon 1코어)에서 모킹보드 톤을 계속 내는 부트 디스크(`mbtone.dsk`, 레지스터를 쉬지 않고 쓰는 `mbstress.dsk`, 둘 다 스크래치에서 python으로 만듦: 부트 섹터 $0801, 슬롯 4 VIA $C400/$C480, 모터 끄기 $C0E8)로 재 봄: 7% → 8~9%. 칩 에뮬레이션만으로는 무겁지 않음
- QEMU(TCG, 느린 CPU)에서는 600프레임/10초 중 270만 돌고 소리가 계속 모자람 = X61s 증상과 같은 모양 → 느린 CPU에서 못 따라가는 것
- callgrind(valgrind i386, SIGINT로 정상 종료시켜야 덤프됨): 화면 확대 34% + SDL_BlitCopy 18% + 믹서 리샘플 18% + 모킹보드 12%
- 알게 된 것: SDL1 fbcon은 SWSURFACE를 요청하면 항상 그림자 표면을 만들고 SDL_Flip마다 전체를 프레임버퍼로 복사·변환(16비트 모드면 32→16). 즉 프레임마다 전체 화면 3번 처리(확대→texture, texture→그림자, 그림자→fb)
- LinApple 패치 13: 출력을 줄 단위로 이전 프레임과 비교해 바뀐 줄 띠만 그림자 표면에 바로 확대하고 SDL_UpdateRect로 그 띠만 보냄. 안 바뀌면 비교만. 메시지(OSD)가 떠 있거나 디버거면 예전 전체 경로, `frame_refresh()`(전체 플립)와 메뉴들의 SDL_Flip 뒤에는 다음 프레임을 전체로. 믹서: 3채널 이상 소스는 소스 주파수에서 좌우로 먼저 섞은 뒤 2채널만 리샘플(선형이라 같음), 박스 필터 빠른 길
- 결과: 정지 화면 7% → 2%, 모킹보드 스트레스 9% → 5%. QEMU 스트레스 270 → 480프레임/10초
- LinApple 패치 12: 10초마다 `timing: N frames, late, dropped; audio: calls, short, skipped, longest wait`를 stderr(→ /run/linapple.log)에. 오디오 장치 열린 값도 한 줄. `apple2-sysinfo now`를 LinApple 종료 뒤 세션이 실행 → system-info.txt에 통계, 온도(thermal_zone), 열 스로틀 횟수
- 알게 된 것: 기본 ALSA 장치(dmix)가 주기를 정해서 SDL 버퍼는 `Sound Buffer`와 상관없이 940샘플(48k의 1024)로 됨. 더 큰 버퍼를 쓰려면 `Sound Device = plughw:0,0`(세션이 AUDIODEV로 넘김)
- 다음: X61s의 system-info.txt를 받아 late/dropped(CPU 부족)인지 short만 있는지(장치 쪽) 보기

### 추가 (2026-11-06, v2.1): 너무 빠름, 디스크 이미지 유지
- 사용자 보고(v2.0 실기): "너무 빨라서 게임을 할 수가 없어" → `Enhance Disk Speed = 0`으로 바꾸니 속도 정상. 원인은 디스크 가속: Disk II 모터가 돌면 프레임당 최대 100프레임(LinAppleCore `full_speed_disk_iterations`)을 돌림. 모터를 켠 채로 진행되는 게임은 플레이 중에도 가속. 예전엔 화면 확대가 CPU를 다 써서 가려져 있었음
- LinApple 패치 10: AppleWin 규칙(`g_bFullSpeed = 모터 && !Spkr_IsActive() && !MB IsActiveToPreventFullSpeed()`)을 따라 스피커가 0.2초, 모킹보드(VIA 쓰기)가 0.1초 안에 쓰였으면 디스크 가속 안 함. 가속 중에도 소리가 나면 바로 멈춤. `Peripheral_Internal.h`의 `peripheral_note_*_activity`, `peripheral_sound_recently_active`. 테스트 `tests/test_disk_turbo_sound.cpp`. 키패드 +/-/*, ScrollLock 속도 변경에 OSD 표시(노트북 내장 키패드로 모르게 눌릴 수 있음)
- 부팅 비프음이 이제 1배속으로 돌아서 `test_harddisk_firmware`의 PR#n 테스트가 DOS 로딩 중에 키를 치게 됨 → 드라이브가 멈출 때까지 기다리도록 테스트 수정
- 사용자 요청: "floppy, hdd 이미지 마운트한 설정을 재부팅하더라도 유지" → 원인 두 가지
  - 플로피: F3/F4 선택은 `[Slots] Disk Image 1`에 저장되지만 `Slot 6 Autoload = 0`이면 시작 때 읽지 않고 Master.dsk를 넣음 → 기본 conf를 1로, 세션이 기존 conf의 0을 1로 바꿈
  - 하드: SmartPort 카드의 `harddisk_query_status`가 지역 변수만 채우고 `out`에 복사하지 않음(패치 3의 버그) → 프론트엔드가 드라이브를 비어 있다고 보고 빈 값을 기록. 복사 추가. 하드 선택·꺼내기·플로피 꺼내기 때 바로 `Configuration::save()`(시작 때 마운트는 파일을 건드리지 않음: `test_harddisk_config_startup`이 확인)
  - LinApple 패치 11. SmartPort 기록 테스트를 `test_harddisk_config_runtime_insert.cpp`에 추가
- 알아둘 것: LinApple의 `Configuration::save()`는 linapple.conf를 주석 없이 다시 씀(원래 동작)
- 사용자 보고: 속도는 정상인데 "소리가 비정상" → `system-info.txt`(ALSA hw_params)와 증상(끊김/지직거림/느림/음 높이) 받아서 볼 것

### 추가 (2026-11-06, v2.0): 볼륨 조절, 화면 확대 속도
- 사용자 보고: "볼륨 조절이 안 되네?" → 그동안 세션이 amixer로 85%만 고정하고 키가 없었음
- LinApple 패치 8 (`sdl1/Volume.{h,cpp}`, SDL_Input.cpp KEYDOWN 맨 앞에서 호출): Alt+F7/Alt+F8 = 5%씩 내리기/올리기, 키보드 볼륨 다운/업/음소거 키. `amixer -M sset <첫 컨트롤>`(Master→PCM→Speaker→Front→Headphone), OSD 막대 표시, `linapple.conf`의 `Master Volume`에 저장(음소거는 0)
- 알게 된 것: SDL1 fbcon은 리눅스 키코드를 scancode로 넘김(113 음소거, 114 다운, 115 업). 커널 키맵 때문에 음소거(113)는 SDLK_UNKNOWN이 아닌 키 심볼을 받음 → fbcon에서는 scancode만으로 판단. X11에서는 키코드+8이라(113=왼쪽 화살표) fbcon일 때만 그렇게 함
- 세션: `Master Volume`(기본 85, 100 상한)을 첫 컨트롤에 적용, 나머지 주요 컨트롤은 100%. Lenovo/IBM이면 `thinkpad_acpi` 로드(볼륨 버튼이 이 드라이버로 들어옴). 커널에 `THINKPAD_ACPI=m`(+DRM/I2C/BACKLIGHT m)
- QEMU 확인(AC'97): Alt+F7 74%, Alt+F8 89%, 음소거 "muted", 볼륨 업 94%, F12 뒤 conf에 `Master Volume = 94`. Alt+F7가 디버거(F7)로 새던 버그 고침
- 사용자 질문: "1024x768에서 가로세로 2배 정수배로만 확대하면 부담이 덜하지 않나?" → 가로 2배는 1120이라 1024에 안 들어감. 실제 비용은 배율이 아니라 확대 코드가 **픽셀마다 64비트 나눗셈**(32비트 x86에서 `__divdi3` 함수 호출)을 하던 것
- LinApple 패치 9 (`common/VideoStretch.cpp`): 열 위치는 캐시한 표로, 원본 한 줄은 한 번만 RAM의 줄 버퍼에 확대한 뒤 그 줄을 보여주는 화면 줄마다 memcpy(프레임버퍼는 쓰기만). 결과는 픽셀 단위로 같음(옛 공식과 비교하는 테스트 추가, 16/32비트, 잘림 포함)
- 측정(2.1GHz Xeon 1코어, dummy 드라이버, 20초 평균 CPU): 1024x768 26% → 7%, 800x600 17% → 6%, 640x480 12% → 5%, SHARP 1024x768 25% → 6%. 펜티엄 3 1GHz에서도 1024x768 실시간이 될 것으로 예상(실기 확인 대기)

### 변경 (2026-11-05, v1.9): 실기 성능
- 사용자 보고: ThinkPad X61s(Core 2 Duo LV, GMA X3100, HDA AD1984)에서 부팅·실행은 되지만 **게임과 소리가 모두 느림** → 에뮬레이션이 실시간보다 느림
- 원인 후보 1: 커널 기본 cpufreq 거버너가 userspace(i386_defconfig 기본) → CPU가 BIOS가 둔 클럭(노트북은 흔히 최저)에 머묾. `CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE=y`, 세션에서도 모든 CPU에 performance
- 원인 후보 2: vesafb는 `mtrr` 기본값 0이라 프레임버퍼를 `ioremap`(uncached)으로 매핑 → 실기에서 화면 쓰기가 매우 느림(QEMU에서는 안 드러남). 커널 명령줄에 `video=vesafb:mtrr:3`(쓰기 결합, PAT 없으면 MTRR WC)
- `overlay/usr/bin/apple2-sysinfo`: LinApple 시작 12초 뒤 `APPLE2\system-info.txt`에 CPU 모델·클럭·거버너·드라이버, 화면 모드와 vesafb/MTRR/PAT 메시지, 사운드 카드와 hw_params·status, 메모리, LinApple 마지막 메시지
- QEMU 확인: 부팅·화면 정상, system-info.txt 생성(QEMU HDA는 dmix 48000Hz, period 1024, buffer 16384). 실기 효과는 사용자 확인 대기
- 다음 후보(효과 부족하면): 사운드를 dmix 대신 plughw로, 화면 16비트 유지 확인, LinApple 프레임 그리기 비용 측정

### 변경 (2026-11-04, v1.8): 3:2 해상도
- 메뉴 해상도 목록에 3:2(1152x768, 1280x854, 1440x960, 1920x1280, 2160x1440)와 1920x1200 추가, display.txt 예시를 비율별로 정리. Monitor shape에는 원래 3:2가 있었음
- QEMU 확인: 메뉴로 1440x960 저장 → 재부팅 → QEMU의 VGA BIOS에 그 모드가 없어 1024x768로 내려감(의도한 대체 동작). 3:2 실제 모드는 실기에서만 확인 가능

### 추가 (2026-11-04, v1.7): 화면 설정 메뉴 (Alt+F9)
- 사용자 요청: 단축키로 메뉴를 불러 해상도와 비율/선명을 고르고 저장한 뒤 재부팅할지 선택
- LinApple 패치 7: `src/frontends/sdl1/DisplayMenu.{h,cpp}` (SnapshotGallery와 같은 블로킹 전체화면 방식, 내장 폰트라 영어). 항목: Resolution(목록 + 파일에 있던 값), Scaling(ASPECT/SHARP), Monitor shape. Enter 저장 → `APPLE2PC_DISPLAY_FILE`(display.txt)의 RESOLUTION/PRIORITY 줄만 바꿔 씀(주석·CRLF 유지, .new에 쓰고 rename + fsync), linapple.conf의 Scale Mode/Monitor Aspect 저장, 그림 다시 맞춤(`frame_refit_picture`, Alt+F6도 이걸 씀). 해상도가 바뀌었으면 "Restart now?" Y → `APPLE2PC_REBOOT_FLAG` 파일을 만들고 종료
- apple2-session: 두 환경 변수를 넘기고, LinApple이 끝났을 때 플래그가 있으면 poweroff 대신 reboot (오류 종료여도)
- 테스트: display_file_get/set 단위 테스트(주석의 같은 글자는 안 건드림, CRLF 유지, 없는 키는 그 파일 줄끝 방식으로 추가). 33개 중 32개 통과(기존 실패 1개 그대로)
- QEMU 확인: Alt+F9 → 800x600 / SHARP → Enter → "Restart now to use 800x600?" → Y → 재부팅 후 800x600 화면에 512x384@(144,108). display.txt는 두 값만 바뀌고 CRLF·주석 17줄 유지

### 추가 (2026-11-04, v1.6): display.txt로 해상도·확대 방식 선택
- 사용자 요청: 설정에서 LCD 패널 해상도와 "선명함 우선/비율 우선"을 고르고 재부팅하면 적용
- `APPLE2\display.txt` (CRLF): `RESOLUTION=1024x768|WxH|auto`, `PRIORITY=aspect|sharp`. 주석 줄만 있고 빈 줄은 없게(GRUB이 source하므로)
- GRUB: `fat regexp test configfile` 모듈을 core 이미지에 넣음 → grub.img가 커져서 **파티션 시작이 267 → 328섹터로 옮겨짐**(PARTUUID는 디스크 서명이라 상관없음). grub.cfg가 `$root`에서 디스크 이름을 뽑아 `(hdN,msdos2)/display.txt`를 source, `regexp '^(auto|[0-9]+x[0-9]+)'`로 값만 꺼냄(줄 끝 CR 무시). WxH면 `WxHx16,WxHx32,` + 기존 목록, auto면 `gfxpayload=auto`(EDID)
- LinApple 패치 6에 `Scale Mode`(aspect/sharp) 추가: sharp는 높이 = 384의 정수배 중 화면에 들어가는 최대, 폭은 그 높이에 맞는 4:3(Monitor Aspect 반영). 테스트 추가(800x600→512x384@144,108, 1280x1024→1024x768@128,128, 1024x768→꽉 참)
- apple2-session: display.txt가 없으면 /etc/linapple/display.txt를 복사, PRIORITY를 linapple.conf의 `Scale Mode`로 옮김
- QEMU 확인(빌드가 만든 CRLF display.txt 그대로): 기본 1024x768 꽉 참 / 800x600 aspect 800x600 / 800x600 sharp 512x384@(144,108) / 1280x1024 sharp 1024x768@(128,128) / auto → QEMU EDID 1280x800, 1066x800@107

### 추가 (2026-11-04, v1.5): 모니터 모양 보정
- 사용자 요청: "사람이 보는 관점에서 해상도와 화면 비율 무관하게 실기 비율만 맞춰주면 돼"
- 한계: 프로그램은 모니터가 4:3 신호를 늘리는지(Full) 비율을 지키는지(Aspect)를 알 수 없음. VESA 프레임버퍼라 EDID도 리눅스에서 안 보임. 그래서 자동 대신 눈으로 맞추는 방식
- 패치 6에 `Monitor Aspect`(auto=화면 모드 픽셀을 정사각으로 봄 / 16:9 / 16:10 / 5:4 / 3:2 / 4:3) 추가. 그림 폭/높이 = 그림 비율 × (모드 폭/높이) ÷ 모니터 비율. **Alt+F6**으로 돌아가며 바꾸고 즉시 다시 맞춤, `Configuration::instance().save()`로 저장, 화면 알림
- 테스트: 1024x768 모드 + Monitor Aspect 16:10 → 853x768@85, auto → 1024x768. QEMU에서 Alt+F6: auto 1024x768 → 16:9 768x768@128 → 16:10 853x768@85, conf에 저장 확인
- 다른 방법(안 함): GRUB `gfxpayload=auto`로 EDID 기본 해상도(패널 원래 해상도)로 켜면 모니터 늘림 자체가 없어지지만, 펜티엄 3에서 1280x1024x32 이상 소프트웨어 확대는 느릴 수 있고 옛 VBE에 와이드 모드가 없는 경우가 많음

### 추가 (2026-11-04, v1.4): 전체화면에서 실기처럼 4:3
- 사용자 요청: 화면이 16:9·16:10·3:2여도 실기 느낌 그대로
- LinApple 패치 6 (`sdl1/Frame.cpp`): `Full Screen Aspect` = `4:3`(기본) / `pixel`(560:384 정사각 픽셀) / `stretch` / `W:H`. 남는 곳은 검게, 그림은 가운데
- 알게 된 것: 원래 SDL1 프런트엔드는 `-f`로 **전체화면으로 시작하면** 화면 맞춤(`compute_aspect_fit_rect`)을 안 하고 화면 전체로 늘렸음(나중에 F6로 바꿀 때만 비율 유지). 그래서 v1.3까지는 늘 부팅 해상도에 꽉 차게 늘어났음(1024x768에서는 결과적으로 4:3). 시작할 때도 맞춤을 하도록 고침
- 테스트: `tests/test_frontend_sdl1.cpp`에 전체화면 시작 테스트 추가(1280x800에서 4:3=1066x800@107, pixel=1166x800@57, stretch). 32비트 테스트 빌드(`-DBUILD_TESTING=ON`, `--target test-frontend-sdl1`, `SDL_VIDEODRIVER=dummy`)에서 32개 중 31개 통과. 실패 1개("Alt+1 ... quick-save modifier")는 이 변경 전에도 실패하던 기존 문제
- QEMU 확인(흰 화면 시험 디스크로 측정): 1024x768 → 1024x768 꽉 참, 1280x800(GRUB 모드를 바꾼 시험용 사본) → 4:3은 1066x800 가운데, pixel은 1166x800
- 남은 것: GRUB은 여전히 1024x768을 1순위로 고름 → 와이드 모니터에서는 4:3 신호를 모니터가 늘릴 수 있음. 와이드 해상도를 앞에 둘지는 사용자 선택 대기

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
| LinApple | github.com/linappleii/linapple | 86bee1c2 + `linapple/*.patch` 9개 |
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
6. 전체화면 4:3(`Full Screen Aspect`), 모니터 모양(`Monitor Aspect`, Alt+F6), 확대 방식(`Scale Mode` aspect/sharp)
7. 화면 설정 메뉴(Alt+F9, `DisplayMenu.cpp`)
8. 볼륨 키(Alt+F7/F8, 키보드 볼륨·음소거 키, `Volume.cpp`)
9. 빠른 소프트웨어 확대(열 표 + 원본 줄 한 번만 확대)
10. 소리 나는 동안 디스크 가속 안 함, 속도 변경 OSD
11. 고른 플로피·하드 이미지 유지(SmartPort 상태 질의 버그 수정)
12. 소리·타이밍 통계(10초마다), `Sound Buffer`
13. 바뀐 줄만 그리기, 모킹보드 좌우 먼저 섞기
14. `Mockingboard Stereo` 스테레오 폭
15. 볼륨 키: 첫 컨트롤로 폴백(USB 사운드)
16. F12 전원 끄기 확인 창
17. F1 도움말 Apple II PC 키
18. 게임별 세이브 폴더(10개씩)

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
- [ ] X61s에서 v2.1 확인: 게임 속도(디스크 가속 켠 채로), 볼륨 버튼(thinkpad_acpi), 디스크 유지
- [x] X61s v2.3: 모킹보드 소리 정상 (2026-11-06 사용자 확인), 아니면 F12로 끈 뒤 `system-info.txt`의 timing 줄 받기 (late/dropped가 많으면 CPU, short만 많으면 장치 → `Sound Device = plughw:0,0` 시험)
- [ ] LG gram 14Z970: BIOS(Boot Mode/CSM) 진입 결과 대기
- [ ] (선택) 맥 QEMU 확인용 저해상도(640x480) 부팅 옵션
- [ ] 실기에서 해상도별 속도 확인 (특히 auto·1280x1024 이상)
- [ ] LinApple 기존 테스트 실패(Alt+1 quick-save 이름) 원인 확인
- [ ] 무선랜 칩 모델 확인 → 필요한 드라이버·펌웨어 추가
- [ ] 부팅 시간 측정·단축 (커널 크기, 서비스 순서)
- [ ] (선택) 화면 하단 드라이브 LED 표시 끄기 옵션 (`Show Leds = 0`)
- [x] 네트워크 기본 끔 (v3.0, `WIRED=on`이나 SSID로 켬)
- [ ] 실기 USB 1.1 노트북에서 v3.0 부팅 시간 재기 (전원 → LinApple 화면)
- [ ] X61s v3.1: 소리와 볼륨 버튼이 돌아왔는지, sound-cards.txt의 "waited N ms"
- [ ] (선택) FujiNet을 다시 쓰고 싶으면 2026-11-04 이전 커밋의 build.sh·overlay 참고
- [ ] SuperSprite: StarSprite 데모·게임 디스크로 실제 동작 확인 (asimov `images/hardware/video/StarSprite-SuperSprite-Programs.zip`)
- [ ] (선택) SuperSprite Echo II 음성(TMS5220) 구현
- [ ] (선택) 비슷한 Third Millennium Arcade Board도 추가 (같은 VDP, 레지스터 배치만 다름, 슬롯 4)

## 7. 관련 작업

- **Ultima IV 하드 이식판(`ultima4_hd1440_iic_mb.po`) 세이브 오류:** 실기 IIc + Floppy Emu에서 Q 세이브 시 `CHECKSUM ERROR`가 남. 원인은 로더(U4)가 `BSAVE PRTY,A$0` 등을 제로페이지·language card 메모리에서 SmartPort 펌웨어로 직접 보내는 것. `patch_u4.py`로 $BC00 버퍼를 거쳐 쓰도록 패치함(로더의 사용하지 않는 $B700 영역에 44바이트). 에뮬레이터에서는 세이브 확인 완료. 실기 확인 대기 중. SD 카드에서 `file not contiguous`가 나면 카드를 정리하고 다시 복사.
- Digger Apple II 이식 프로젝트(Mockingboard, 64K/128K): 이 에뮬레이터 이미지로 시험 가능
