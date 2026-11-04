# 완성 이미지 (버전별)

압축을 풀면 `apple2pc.img`가 나옵니다. Rufus에서 **DD 이미지 모드**로 굽거나, 맥에서는 QEMU로 바로 실행할 수 있습니다.

| 버전 | 날짜 | 파일 | 내용 |
|---|---|---|---|
| v1.7 | 2026-11-04 | `apple2pc-v1.7-2026-11-04.img.zip` | v1.6 + **Alt+F9** 화면 설정 메뉴: 해상도, 확대 방식, 모니터 모양을 고르고 저장, 해상도를 바꾸면 재부팅 여부를 물음 |
| v1.6 | 2026-11-04 | `apple2pc-v1.6-2026-11-04.img.zip` | v1.5 + `display.txt`로 LCD 해상도(`RESOLUTION`)와 확대 방식(`PRIORITY=aspect`/`sharp`)을 고르고 재부팅하면 적용 |
| v1.5 | 2026-11-04 | `apple2pc-v1.5-2026-11-04.img.zip` | v1.4 + 와이드 모니터가 4:3 화면을 늘려 보여줄 때 **Alt+F6**으로 모니터 모양(16:9, 16:10 등)을 골라 눈으로 4:3이 되게 보정 (`Monitor Aspect`, 저장됨) |
| v1.4 | 2026-11-04 | `apple2pc-v1.4-2026-11-04.img.zip` | v1.3 + 전체화면에서 애플 화면을 실기 모니터처럼 4:3으로 유지(와이드 화면이면 좌우 검은 띠). `linapple.conf`의 `Full Screen Aspect`로 바꿀 수 있음 |
| v1.3 | 2026-11-04 | `apple2pc-v1.3-2026-11-04.img.zip` | v1.2 + 더 큰 USB/디스크에 쓰면 처음 켤 때 APPLE2 파티션이 장치 끝까지 자동으로 늘어남 (`grow.txt`에 기록) |
| v1.2 | 2026-11-04 | `apple2pc-v1.2-2026-11-04.img.zip` | v1.1 + 사운드 카드 확장: 그 시절 PCI 카드 대부분(모듈), ISA 카드(PnP, 사운드 블래스터 표준 220h/IRQ 5·7/DMA 1·5, `sound.txt`로 포트·IRQ 지정). 잡힌 카드는 `sound-cards.txt`에 기록 |
| v1.1 | 2026-11-04 | `apple2pc-v1.1-2026-11-04.img.zip` | FujiNet 제거. 슬롯 7 SmartPort(하드 2 + UniDisk 3.5 2), 6 Disk II, 4 Mockingboard. 하드 1 → 5.25" 드라이브 1 순서로 부팅. SuperSprite 카드 포함(설정으로 선택) |
| v1.0 | 2026-10-20 | `apple2pc-v1.0-2026-10-20.img.zip` | 1차 완성본. 슬롯 7 FujiNet(부팅 시 FujiNet CONFIG), 6 Disk II, 5 SmartPort, 4 Mockingboard. GitHub Releases `apple2`와 같은 파일 |

해시는 `SHA256SUMS`에 있습니다 (`shasum -a 256 -c SHA256SUMS`).
