// SPDX-License-Identifier: GPL-2.0-only
// A browser frontend for the SuperSprite demo: the LinApple core runs one
// Apple frame per animation frame, the picture goes to a <canvas> and the
// mixed sound to Web Audio, which pulls it through web_audio_fill().
#include <emscripten.h>

#include <cstddef>
#include <cstdint>
#include <vector>

#include "core/LinAppleCore.h"
#include "core/Registry.h"
#include "frontends/common/AppArgs.h"
#include "frontends/common/AppController.h"
#include "frontends/common/AudioMixer.h"

namespace {

constexpr uint32_t apple2_frame_cycles = 17030;
constexpr uint32_t audio_rate = 48000;

auto video_callback(const uint32_t* pixels, int width, int height,
                    int pitch) -> void {
  // clang-format off
  EM_ASM({
    if (Module.drawFrame) Module.drawFrame($0, $1, $2, $3);
  }, pixels, width, height, pitch);
  // clang-format on
}

auto title_callback(const char* /*title*/) -> void {}

auto frame() -> void { linapple_run_frame(apple2_frame_cycles); }

}  // namespace

extern "C" {

EMSCRIPTEN_KEEPALIVE void web_key(int apple_code, int down) {
  linapple_set_key_state(static_cast<uint8_t>(apple_code), down != 0);
}

// Fills frames stereo int16 samples at 48 kHz into buf.
EMSCRIPTEN_KEEPALIVE void web_audio_fill(int16_t* buf, int frames) {
  audio_mixer_get_samples(buf, static_cast<size_t>(frames) * 2);
}

}  // extern "C"

auto main() -> int {
  static char arg0[] = "linapple";
  static char arg1[] = "-c";
  static char arg2[] = "/demo/linapple.conf";
  static char arg3[] = "--program";
  static char arg4[] = "/demo/ssdemo.apl";
  static char* argv[] = {arg0, arg1, arg2, arg3, arg4, nullptr};

  AppConfig& config = Configuration::instance();
  if (app_args_parse(5, argv, &config) != 0) {
    return 1;
  }
  if (app_controller_initialize(&config) != 0) {
    return 1;
  }

  audio_mixer_initialize(audio_rate);
  linapple_set_audio_channel_callback(
      [](const char* peripheral_id, int slot, const float* const* channels,
         size_t num_channels, size_t num_samples) -> void {
        audio_mixer_upload_channels(peripheral_id, slot, channels,
                                    num_channels,
                                    static_cast<uint32_t>(num_samples));
      });
  linapple_set_audio_source_unregister_callback(
      [](int slot) -> void { audio_mixer_unregister_source(slot); });
  linapple_set_audio_source_register_callback(audio_mixer_register_source);
  linapple_set_video_callback(video_callback);
  linapple_set_title_callback(title_callback);

  app_controller_load_initial_media(&config);
  emscripten_set_main_loop(frame, 0, 1);
  return 0;
}
