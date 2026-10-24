# SuperSprite 데모

슬롯 7 SuperSprite 카드 시험용 6502 프로그램입니다. 공 8개(TMS9918A 스프라이트)가 애플 텍스트 화면 위를 튀어다니고, 벽에 부딪칠 때 AY-3-8912가 울립니다.

- SPACE: 애플 영상 입력 켜기/끄기 ($C0F4/$C0F3)
- M: VDP 합성 / 애플만 ($C0F6/$C0F5)
- S: 효과음 켜기/끄기

## 실행

`linapple.conf`에서 `Slot 7 = SuperSprite`로 바꾸고:

```
linapple -c linapple.conf --program ssdemo.apl
```

`ssdemo.apl`은 4바이트 헤더(적재 주소 $0800, 길이) + 기계어입니다.

## 다시 어셈블

```
cl65 -t none --start-addr '$0800' -o ssdemo.bin ssdemo.s
python3 -c "import struct;d=open('ssdemo.bin','rb').read();open('ssdemo.apl','wb').write(struct.pack('<HH',0x0800,len(d))+d)"
```

## 브라우저판 (2026-10-24에 만든 방법)

Ubuntu의 `emscripten` 패키지(3.1.6)로 LinApple 코어를 빌드했습니다. 디스크·하드·SmartPort·시리얼·프린터 카드는 뺐습니다.

1. LinApple 소스(패치 1~5 적용)를 복사하고, 복사본에서만:
   - `src/frontends/headless/Main.cpp`를 `web-main.cpp`로 교체
   - `<linux/limits.h>` → `<limits.h>`
   - `src/apple2/Memory.*`의 `PAGE_SIZE` → `A2_PAGE_SIZE` (Emscripten 헤더 매크로와 충돌)
   - `CMakeLists.txt`의 `CMAKE_CXX_STANDARD 11` → `20`
2. `webfs/demo/`에 `ssdemo.apl`과 웹용 `linapple.conf`(Slot 6·5 = None, Slot 7 = SuperSprite, Singlethreaded = 1, Joystick 0 = 0)
3. ```
   emcmake cmake -S . -B build-web -G Ninja -DFRONTEND=headless -DBUILD_TESTING=OFF -DENABLE_FTP=OFF \
     -DENABLE_LTO=OFF -DCMAKE_BUILD_TYPE=Release -DENABLE_STRICT_WARNINGS=OFF \
     -DENABLE_PERIPHERAL_DISK=OFF -DENABLE_PERIPHERAL_HARDDISK=OFF -DENABLE_PERIPHERAL_SMARTPORT=OFF \
     -DENABLE_PERIPHERAL_SUPER_SERIAL=OFF -DENABLE_PERIPHERAL_PRINTER=OFF \
     -DCMAKE_EXE_LINKER_FLAGS="-sALLOW_MEMORY_GROWTH=1 -sINITIAL_MEMORY=64MB \
       -sEXPORTED_FUNCTIONS=_main,_web_key,_web_audio_fill,_malloc,_free \
       -sEXPORTED_RUNTIME_METHODS=HEAPU8,HEAP16 -sENVIRONMENT=web -sSINGLE_FILE=1 \
       --embed-file webfs/demo@/demo"
   ninja -C build-web linapple
   ```
4. `web-page.html`의 `/*LINAPPLE_JS*/` 자리에 `build-web/linapple.js` 내용을 넣으면 한 파일짜리 페이지가 됩니다.
