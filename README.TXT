Apple II PC - 데이터 파티션 (APPLE2)
=====================================

이 파티션은 윈도우에서도 열 수 있는 FAT32입니다.

disks\            디스크 이미지를 넣는 곳
                  5.25" : .dsk .do .po(140K) .nib .woz
                  3.5"  : .po .2mg (400K/800K)  -> UniDisk 3.5 드라이브
                  하드  : .po .hdv .2mg (32MB까지)
saves\            세이브 슬롯 0~9 (SaveStateN.aws + 저장 순간 화면 SaveStateN.bmp)
wifi.txt          무선랜 이름과 비밀번호 (시계 맞추기용, 유선 랜만 쓰면 비워 두기)
linapple.conf     에뮬레이터 설정 (기종, 속도, 슬롯 구성 등)

슬롯 구성
---------
슬롯 7  SmartPort     하드디스크 1, 2 + UniDisk 3.5 드라이브 1, 2 (먼저 부팅)
슬롯 6  Disk II       5.25" 드라이브 1, 2
슬롯 4  Mockingboard
부팅 순서: 하드디스크 1 -> (하드가 비어 있으면) 5.25" 드라이브 1
5.25" 드라이브 1이 비어 있으면 실기처럼 디스크를 기다리며 멈춥니다.
하드가 들어 있는데 플로피로 부팅하려면 Ctrl+F10(Reset) 뒤 PR#6 을 치세요.
SuperSprite(Synetix 스프라이트 카드) 소프트웨어를 쓰려면 linapple.conf에서
"Slot 7 = SuperSprite", "Slot 5 = SmartPort"로 바꾸세요.

키
---
Ctrl+Shift+0~9  그 슬롯에 저장 (화면 캡처 함께)
Ctrl+0~9        그 슬롯 불러오기
F11 / F10       저장 / 불러오기 슬롯을 썸네일 화면에서 고르기
                (숫자/방향키 선택, Enter 확인, Del 두 번 지우기, Esc 취소)
F3 / F4         드라이브 1 / 2에 디스크 넣기
                400K/800K 이미지는 UniDisk 3.5 드라이브로, 나머지는 5.25"로
Ctrl+F3 / F4    드라이브 1 / 2 꺼내기
Shift+F3 / F4   SmartPort 하드디스크 1 / 2에 이미지 넣기
Ctrl+Shift+F3/F4  하드디스크 꺼내기
F5              5.25" 드라이브 1, 2 맞바꾸기
Ctrl+F2         재부팅 (전원 껐다 켜기)
Ctrl+F10        Ctrl+Reset
F7              디버거
F8              스크린샷만 저장
F9              화면 모드 (컬러/흑백 등)
ScrollLock      최고 속도 토글
F12             종료하고 전원 끄기
Ctrl+Alt+F2     리눅스 셸 (Alt+F1로 복귀)
