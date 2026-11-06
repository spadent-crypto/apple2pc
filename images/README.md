# 완성 이미지 (버전별)

압축을 풀면 `apple2pc.img`가 나옵니다. Rufus에서 **DD 이미지 모드**로 굽거나, 맥에서는 QEMU로 바로 실행할 수 있습니다.

| 버전 | 날짜 | 파일 | 내용 |
|---|---|---|---|
| v2.5 | 2026-11-06 | `apple2pc-v2.5-2026-11-06.img.zip` | v2.4 + 게임 저장·세이브 슬롯·설정이 약 2초 안에 USB에 기록됨(전엔 최대 30초). 그냥 끄거나 USB를 뽑아도 잃는 것이 거의 없음 |
| v2.4 | 2026-11-06 | `apple2pc-v2.4-2026-11-06.img.zip` | v2.3 + USB 오디오(USB Audio Class: USB 사운드카드, 헤드셋, DAC) 지원. 꽂고 켜면 내장 사운드 대신 USB로 소리가 나고 볼륨 키도 그 장치에 적용 |
| v2.3 | 2026-11-06 | `apple2pc-v2.3-2026-11-06.img.zip` | v2.2 + 모킹보드 화음이 빠지던 것 대응: `linapple.conf`의 `Mockingboard Stereo`(0~100). 기본값 0은 6음을 좌우 모두로 내서 노트북 스피커 하나에서도 다 들림, 100은 실제 카드처럼 왼쪽/오른쪽 분리 |
| v2.2 | 2026-11-06 | `apple2pc-v2.2-2026-11-06.img.zip` | v2.1 + 느린 PC에서 모킹보드 소리가 끊기던 것 대응: 화면에서 바뀐 줄만 다시 그리고(정지 화면 CPU 7%→2%), 모킹보드 소리 처리 부담을 줄임(스트레스 9%→5%). F12로 끌 때 `system-info.txt`에 10초마다의 프레임 지연·소리 모자람 통계, CPU 온도. `linapple.conf`에 `Sound Buffer`, `Sound Device` 설정 |
| v2.1 | 2026-11-06 | `apple2pc-v2.1-2026-11-06.img.zip` | v2.0 + 게임이 너무 빨라지던 문제 수정(소리가 나는 동안은 디스크 가속 안 함, AppleWin 방식). F3/F4로 넣은 플로피와 Shift+F3/F4로 넣은 하드 이미지가 재부팅 뒤에도 그대로 유지. 키패드 +/-/*·ScrollLock 속도 변경을 화면에 표시 |
| v2.0 | 2026-11-06 | `apple2pc-v2.0-2026-11-06.img.zip` | v1.9 + **볼륨 조절**: Alt+F7/Alt+F8(5%씩), 노트북·키보드의 볼륨·음소거 키(ThinkPad 볼륨 버튼 포함), 화면에 표시하고 `linapple.conf`의 `Master Volume`에 저장. 화면 확대 계산을 고쳐 CPU 사용이 1024x768에서 약 1/4로 줄어듦(그림은 똑같음) |
| v1.9 | 2026-11-05 | `apple2pc-v1.9-2026-11-05.img.zip` | v1.8 + 실기 성능 개선: CPU를 항상 최대 클럭으로, 화면 메모리를 쓰기 결합 방식으로(실기에서 화면 그리기가 빨라짐). 부팅할 때마다 `system-info.txt`에 CPU·화면·사운드 상태 기록 |
| v1.8 | 2026-11-04 | `apple2pc-v1.8-2026-11-04.img.zip` | v1.7 + 화면 설정 메뉴의 해상도 목록에 3:2(1152x768, 1280x854, 1440x960, 1920x1280, 2160x1440)와 1920x1200 추가 |
| v1.7 | 2026-11-04 | `apple2pc-v1.7-2026-11-04.img.zip` | v1.6 + **Alt+F9** 화면 설정 메뉴: 해상도, 확대 방식, 모니터 모양을 고르고 저장, 해상도를 바꾸면 재부팅 여부를 물음 |
| v1.6 | 2026-11-04 | `apple2pc-v1.6-2026-11-04.img.zip` | v1.5 + `display.txt`로 LCD 해상도(`RESOLUTION`)와 확대 방식(`PRIORITY=aspect`/`sharp`)을 고르고 재부팅하면 적용 |
| v1.5 | 2026-11-04 | `apple2pc-v1.5-2026-11-04.img.zip` | v1.4 + 와이드 모니터가 4:3 화면을 늘려 보여줄 때 **Alt+F6**으로 모니터 모양(16:9, 16:10 등)을 골라 눈으로 4:3이 되게 보정 (`Monitor Aspect`, 저장됨) |
| v1.4 | 2026-11-04 | `apple2pc-v1.4-2026-11-04.img.zip` | v1.3 + 전체화면에서 애플 화면을 실기 모니터처럼 4:3으로 유지(와이드 화면이면 좌우 검은 띠). `linapple.conf`의 `Full Screen Aspect`로 바꿀 수 있음 |
| v1.3 | 2026-11-04 | `apple2pc-v1.3-2026-11-04.img.zip` | v1.2 + 더 큰 USB/디스크에 쓰면 처음 켤 때 APPLE2 파티션이 장치 끝까지 자동으로 늘어남 (`grow.txt`에 기록) |
| v1.2 | 2026-11-04 | `apple2pc-v1.2-2026-11-04.img.zip` | v1.1 + 사운드 카드 확장: 그 시절 PCI 카드 대부분(모듈), ISA 카드(PnP, 사운드 블래스터 표준 220h/IRQ 5·7/DMA 1·5, `sound.txt`로 포트·IRQ 지정). 잡힌 카드는 `sound-cards.txt`에 기록 |
| v1.1 | 2026-11-04 | `apple2pc-v1.1-2026-11-04.img.zip` | FujiNet 제거. 슬롯 7 SmartPort(하드 2 + UniDisk 3.5 2), 6 Disk II, 4 Mockingboard. 하드 1 → 5.25" 드라이브 1 순서로 부팅. SuperSprite 카드 포함(설정으로 선택) |
| v1.0 | 2026-10-20 | `apple2pc-v1.0-2026-10-20.img.zip` | 1차 완성본. 슬롯 7 FujiNet(부팅 시 FujiNet CONFIG), 6 Disk II, 5 SmartPort, 4 Mockingboard. GitHub Releases `apple2`와 같은 파일 |

해시는 `SHA256SUMS`에 있습니다 (`shasum -a 256 -c SHA256SUMS`).
