# 완성 이미지 (버전별)

압축을 풀면 `apple2pc.img`가 나옵니다. Rufus에서 **DD 이미지 모드**로 굽거나, 맥에서는 QEMU로 바로 실행할 수 있습니다.

| 버전 | 날짜 | 파일 | 내용 |
|---|---|---|---|
| v1.1 | 2026-11-04 | `apple2pc-v1.1-2026-11-04.img.zip` | FujiNet 제거. 슬롯 7 SmartPort(하드 2 + UniDisk 3.5 2), 6 Disk II, 4 Mockingboard. 하드 1 → 5.25" 드라이브 1 순서로 부팅. SuperSprite 카드 포함(설정으로 선택) |
| v1.0 | 2026-10-20 | `apple2pc-v1.0-2026-10-20.img.zip` | 1차 완성본. 슬롯 7 FujiNet(부팅 시 FujiNet CONFIG), 6 Disk II, 5 SmartPort, 4 Mockingboard. GitHub Releases `apple2`와 같은 파일 |

해시는 `SHA256SUMS`에 있습니다 (`shasum -a 256 -c SHA256SUMS`).
