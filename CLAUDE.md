# Apple II PC

이 저장소는 레거시 BIOS 구형 PC를 부팅 즉시 Apple //e로 만드는 부팅 이미지의 빌드 키트입니다.
사용자(James)는 시간이 날 때마다 띄엄띄엄 이어서 작업합니다.

## 작업을 시작할 때
- 먼저 `PROJECT_NOTES.md`를 읽고 현재 상태, 알려진 한계, 다음 할 일을 파악하세요.
- 대화는 한국어로 합니다.

## 작업을 마칠 때
- 바뀐 내용을 커밋하고 푸시하세요.
- `PROJECT_NOTES.md`의 "현재 상태", "다음에 할 일", 마지막 갱신 날짜를 고치세요.
- LinApple을 고쳤다면 `linapple/*.patch`를 다시 만드세요. 기준 커밋은 `build.sh`의 `LINAPPLE_COMMIT`입니다.

## 이미지 파일
- 완성 이미지는 사용자 요청(2026-11-04)에 따라 `images/apple2pc-vX.Y-YYYY-MM-DD.img.zip`으로 버전별 커밋합니다. `images/SHA256SUMS`와 `images/README.md` 표도 함께 고칩니다.
- `out/`, `work/`, 그 밖의 `*.img`, `*.img.zip`은 커밋하지 않습니다(.gitignore).
- 이 작업 환경에서는 GitHub Releases를 만들 수 없습니다(REST API도 403). 대화에서도 파일로 전달합니다.

## 빌드 환경 메모
- Ubuntu 24.04 x86_64, root. `./build.sh` (전체) 또는 `./build.sh rootfs image`.
- 작업 컨테이너에서는 kernel.org, Buildroot, Debian 미러가 막혀 있고 Ubuntu 아카이브와 GitHub는 됩니다.
