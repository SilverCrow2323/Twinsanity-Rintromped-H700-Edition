#include "app/host/launcher.h"

#include <SDL.h>

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>

#include "app/host/game_files_stamp.h"
#include "app/host/launcher_settings.h"
#include "app/host/user_data.h"
#include "backends/imgui_impl_opengl3.h"
#include "backends/imgui_impl_sdl2.h"
#include "engine/core/config/config.h"
#include "engine/core/config/settings_file.h"
#include "engine/platform/host/platform.h"
#include "engine/platform/sdl/gl_context.h"
#include "engine/platform/sdl/input/muos_mapping.h"
#include "engine/title/title_profile.h"
#include "imgui.h"
#include PS2R_GL_HEADER

namespace ps2r::app {
namespace {
#if PS2R_HOST_GLES
constexpr int kWidth = 640, kHeight = 480;
constexpr const char* kImGuiGlslVersion = "#version 300 es";
#else
constexpr int kWidth = 860, kHeight = 560;
constexpr const char* kImGuiGlslVersion = "#version 410 core";
#endif
const char* kPages[] = {"Play", "Display", "Controls", "Save states", "Fixes", "Data"};

void ApplyTwinsanityStyle() {
    ImGui::StyleColorsDark();
    ImGuiStyle& style = ImGui::GetStyle();
    style.WindowRounding = 8.0f;
    style.ChildRounding = 7.0f;
    style.FrameRounding = 5.0f;
    style.PopupRounding = 7.0f;
    style.ScrollbarRounding = 8.0f;
    style.GrabRounding = 5.0f;
    style.WindowBorderSize = 0.0f;
    style.FrameBorderSize = 1.0f;
    style.ItemSpacing = ImVec2(9.0f, 8.0f);
    style.FramePadding = ImVec2(11.0f, 8.0f);
    ImVec4* colors = style.Colors;
    colors[ImGuiCol_Text] = ImVec4(0.94f, 0.98f, 0.88f, 1.0f);
    colors[ImGuiCol_TextDisabled] = ImVec4(0.68f, 0.78f, 0.61f, 1.0f);
    colors[ImGuiCol_WindowBg] = ImVec4(0.035f, 0.15f, 0.07f, 0.96f);
    colors[ImGuiCol_ChildBg] = ImVec4(0.025f, 0.11f, 0.05f, 0.72f);
    colors[ImGuiCol_Border] = ImVec4(0.35f, 0.65f, 0.25f, 0.65f);
    colors[ImGuiCol_FrameBg] = ImVec4(0.09f, 0.25f, 0.11f, 1.0f);
    colors[ImGuiCol_FrameBgHovered] = ImVec4(0.16f, 0.39f, 0.15f, 1.0f);
    colors[ImGuiCol_FrameBgActive] = ImVec4(0.21f, 0.46f, 0.18f, 1.0f);
    colors[ImGuiCol_Button] = ImVec4(0.13f, 0.34f, 0.11f, 1.0f);
    colors[ImGuiCol_ButtonHovered] = ImVec4(0.22f, 0.48f, 0.14f, 1.0f);
    colors[ImGuiCol_ButtonActive] = ImVec4(0.31f, 0.56f, 0.16f, 1.0f);
    colors[ImGuiCol_Header] = ImVec4(0.13f, 0.34f, 0.11f, 0.95f);
    colors[ImGuiCol_HeaderHovered] = ImVec4(0.22f, 0.48f, 0.14f, 1.0f);
    colors[ImGuiCol_HeaderActive] = ImVec4(0.31f, 0.56f, 0.16f, 1.0f);
    colors[ImGuiCol_CheckMark] = ImVec4(0.97f, 0.86f, 0.24f, 1.0f);
    colors[ImGuiCol_SliderGrab] = ImVec4(0.88f, 0.64f, 0.14f, 1.0f);
    colors[ImGuiCol_SliderGrabActive] = ImVec4(1.0f, 0.78f, 0.20f, 1.0f);
    colors[ImGuiCol_Separator] = ImVec4(0.35f, 0.62f, 0.23f, 0.70f);
}

void DrawTwinsanityBackdrop(const ImVec2& size) {
    ImDrawList* draw = ImGui::GetBackgroundDrawList();
    draw->AddRectFilledMultiColor(ImVec2(0, 0), size,
        IM_COL32(24, 115, 34, 255), IM_COL32(13, 83, 26, 255),
        IM_COL32(3, 39, 17, 255), IM_COL32(8, 65, 24, 255));
    const float time = static_cast<float>(SDL_GetTicks64()) * 0.00035f;
    for (int spiral = 0; spiral < 2; ++spiral) {
        std::vector<ImVec2> points;
        points.reserve(96);
        const float cx = size.x * (spiral == 0 ? 0.30f : 0.63f);
        const float cy = size.y * 0.20f;
        for (int i = 0; i < 96; ++i) {
            const float t = static_cast<float>(i) * 0.115f;
            const float radius = 4.0f + static_cast<float>(i) * 0.72f;
            const float angle = t + time * (spiral == 0 ? 1.0f : -0.78f) + (spiral ? 2.3f : 0.0f);
            points.emplace_back(cx + std::cos(angle) * radius, cy + std::sin(angle) * radius * 0.58f);
        }
        const ImU32 tint = spiral == 0 ? IM_COL32(194, 245, 81, 86) : IM_COL32(255, 205, 45, 66);
        draw->AddPolyline(points.data(), static_cast<int>(points.size()), tint, 0, 3.0f);
    }
    draw->AddCircleFilled(ImVec2(size.x * 0.88f, size.y * 0.16f), 42.0f,
                          IM_COL32(159, 212, 61, 22), 36);
}

bool FileExists(const std::string& path) {
    std::FILE* f = std::fopen(path.c_str(), "rb");
    if (!f) return false;
    std::fclose(f);
    return true;
}
}  // namespace

bool Launcher::Wanted(const Config& cfg, const TitleProfile& title, bool harness_cli, bool forced) {
    if (cfg.harness.headless) return false;
    if (forced) return true;   // --launcher wins over the harness flags (a pinned launcher leg)
    if (harness_cli) return false;
    if (!FirstRun::GameFilesPresent(cfg, title)) return true;
    return cfg.launcher.show;
}

Launcher::Launcher(Config& cfg, const TitleProfile& title, std::string build_id)
    : cfg_(cfg), title_(title), build_id_(std::move(build_id)) {}

void Launcher::SetScreenshot(const std::string& ppm_path, bool then_play) {
    screenshot_ = ppm_path;
    then_play_ = then_play;
}

void Launcher::SetHarnessPage(const std::string& page) {
    static const char* kNames[] = {"play", "display", "controls", "saves", "fixes", "data"};
    for (int i = 0; i < 6; i++)
        if (page == kNames[i]) { page_ = i; return; }
    std::fprintf(stderr, "launcher: unknown --launcher-page '%s' (play|display|controls|saves|fixes|data)\n", page.c_str());
}

Launcher::~Launcher() {
    if (worker_.joinable()) {
        if (extract_) extract_->cancel.store(true);
        worker_.join();
    }
    CloseWindow();
}

std::string Launcher::DiscPath() const {
    return !cfg_.paths.iso.empty() ? cfg_.paths.iso : cfg_.paths.game_files + "/" + title_.disc_image_file;
}

bool Launcher::OpenWindow(std::string& error) {
    SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1");
    if (!SDL_WasInit(SDL_INIT_VIDEO)) {
        if (SDL_InitSubSystem(SDL_INIT_VIDEO) != 0) { error = SDL_GetError(); return false; }
        video_inited_ = true;
    }
    platform::GlContext::RequestAttributes();
    Uint32 window_flags = SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN;
#if !PS2R_HOST_GLES
    window_flags |= SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI;
#endif
    window_ = SDL_CreateWindow("Crash Twinsanity - Rintromped H700", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                               kWidth, kHeight, window_flags);
    if (!window_) { error = SDL_GetError(); return false; }
    gl_context_ = SDL_GL_CreateContext(window_);
    if (!gl_context_) { error = SDL_GetError(); return false; }
    SDL_GL_MakeCurrent(window_, gl_context_);
    SDL_GL_SetSwapInterval(1);
    SDL_EventState(SDL_DROPFILE, SDL_ENABLE);
    IMGUI_CHECKVERSION();
    imgui_ = ImGui::CreateContext();
    ImGui::SetCurrentContext(imgui_);
    ImGuiIO& io = ImGui::GetIO();
    io.IniFilename = nullptr;
    io.LogFilename = nullptr;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard | ImGuiConfigFlags_NavEnableGamepad;
    ApplyTwinsanityStyle();
    if (!ImGui_ImplSDL2_InitForOpenGL(window_, gl_context_) || !ImGui_ImplOpenGL3_Init(kImGuiGlslVersion)) {
        error = "ImGui backend init failed";
        return false;
    }
    SDL_RaiseWindow(window_);
    return true;
}

void Launcher::CloseWindow() {
    if (imgui_) {
        SDL_GL_MakeCurrent(window_, gl_context_);
        ImGui::SetCurrentContext(imgui_);
        ImGui_ImplOpenGL3_Shutdown();
        ImGui_ImplSDL2_Shutdown();
        ImGui::DestroyContext(imgui_);
        imgui_ = nullptr;
    }
    if (gl_context_) { SDL_GL_DeleteContext(gl_context_); gl_context_ = nullptr; }
    if (window_) { SDL_DestroyWindow(window_); window_ = nullptr; }
    for (void* h : controller_handles_) SDL_GameControllerClose(static_cast<SDL_GameController*>(h));
    controller_handles_.clear();
    if (controllers_inited_) { SDL_QuitSubSystem(SDL_INIT_GAMECONTROLLER); controllers_inited_ = false; }
    if (video_inited_) { SDL_QuitSubSystem(SDL_INIT_VIDEO); video_inited_ = false; }
}

// Every present controller is OPENED (SDL delivers SDL_CONTROLLERBUTTONDOWN /
// AXISMOTION for open handles only -- the Controls page's press-to-bind reads
// them) and closed with the window; the game's InputSystem opens its own later.
void Launcher::DetectControllers() {
    controllers_.clear();
    for (void* h : controller_handles_) SDL_GameControllerClose(static_cast<SDL_GameController*>(h));
    controller_handles_.clear();
    if (!SDL_WasInit(SDL_INIT_GAMECONTROLLER)) {
        if (SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER) != 0) return;
        controllers_inited_ = true;
    }
    SDL_GameControllerEventState(SDL_ENABLE);
    SDL_JoystickEventState(SDL_ENABLE);
    for (int i = 0; i < SDL_NumJoysticks(); i++) {
        const char* joystick_name = SDL_JoystickNameForIndex(i);
        // SETUP_APP has already applied the user's muOS Retro/Modern choice.
        // Add that exact GUID row before SDL classifies the device; this keeps
        // the pre-launch Controls page identical to in-game controller input.
        const auto muos_map = ps2r::platform::sdl::muos_mapping::Apply(i);
        bool generic_mapping = false;
        if (muos_map.added) {
            std::fprintf(stderr, "[muos.launcher.input] muOS %s map: %s from %s (GUID %s)\n",
                         muos_map.andromeda ? "Andromeda" : "active",
                         muos_map.layout.c_str(), muos_map.source.c_str(), muos_map.guid.c_str());
        }
        if (muos_map.andromeda && muos_map.muos_keys && !muos_map.added) {
            std::fprintf(stderr, "[muos.launcher.input] Andromeda muOS-Keys map failed; refusing stale mapping (%s)\n",
                         muos_map.guid.c_str());
            continue;
        }
        if (!SDL_IsGameController(i)) {
            // Never map Andromeda muOS-Keys as Xbox b0/b1: those are volume
            // controls, while the official DB assigns face buttons to b2-b5
            // and MENU/START/SELECT to b12/b11.
            if (muos_map.andromeda && muos_map.muos_keys) {
                std::fprintf(stderr, "[muos.launcher.input] refusing incorrect generic fallback for Andromeda muOS-Keys (%s)\n",
                             muos_map.guid.c_str());
                continue;
            }
            char guid[64] = {};
            SDL_JoystickGetGUIDString(SDL_JoystickGetDeviceGUID(i), guid, sizeof(guid));
            const std::string mapping = std::string(guid) + "," +
                (joystick_name ? joystick_name : "Generic Controller") +
                ",a:b0,b:b1,x:b2,y:b3,back:b4,guide:b5,start:b6,"
                "leftstick:b7,rightstick:b8,leftshoulder:b9,rightshoulder:b10,"
                "dpup:b11,dpdown:b12,dpleft:b13,dpright:b14,"
                "leftx:a0,lefty:a1,rightx:a2,righty:a3,lefttrigger:a4,righttrigger:a5";
            if (SDL_GameControllerAddMapping(mapping.c_str()) < 0) {
                std::fprintf(stderr, "[muos.launcher.input] generic mapping failed for %s (%s): %s\n",
                             joystick_name ? joystick_name : "unknown", guid, SDL_GetError());
                continue;
            }
            generic_mapping = true;
        }
        SDL_GameController* gc = SDL_GameControllerOpen(i);
        if (!gc) {
            std::fprintf(stderr, "[muos.launcher.input] cannot open controller %d (%s): %s\n",
                         i, joystick_name ? joystick_name : "unknown", SDL_GetError());
            continue;
        }
        const char* name = SDL_GameControllerName(gc);
        controllers_.push_back(name ? name : (joystick_name ? joystick_name : "controller"));
        controller_handles_.push_back(gc);
        char* active_mapping = SDL_GameControllerMapping(gc);
        std::fprintf(stderr, "[muos.launcher.input] controller %d: %s%s\n", i,
                     name ? name : "unknown", generic_mapping ? " [generic mapping]" : "");
        if (active_mapping) {
            std::fprintf(stderr, "[muos.launcher.input] mapping: %s\n", active_mapping);
            SDL_free(active_mapping);
        }
    }
}

void Launcher::OpenDataFolder() {
    const std::string root = cfg_.paths.user_data;
    if (root.empty() || root.find('\'') != std::string::npos) return;
#if defined(__APPLE__)
    const std::string cmd = "open '" + root + "'";
#elif defined(_WIN32)
    const std::string cmd = "explorer \"" + root + "\"";
#else
    const std::string cmd = "xdg-open '" + root + "' >/dev/null 2>&1";
#endif
    (void)std::system(cmd.c_str());
}

Launcher::Outcome Launcher::Run() {
    std::string error;
    if (!OpenWindow(error)) {
        std::fprintf(stderr, "launcher: cannot open the window: %s\n", error.c_str());
        CloseWindow();
        return Outcome::Failed;
    }
    settings_ = std::make_unique<LauncherSettings>(cfg_, UserData::SettingsFile(cfg_), cfg_.paths.user_data);
    DetectControllers();
    screen_ = FirstRun::GameFilesPresent(cfg_, title_) ? Screen::Ready : Screen::NeedDisc;
    // When muOS forces this screen alongside --iso, keep the selected image in
    // the first-run field too; the user only needs to confirm extraction once.
    if (!cfg_.paths.iso.empty()) {
        std::snprintf(path_buffer_, sizeof(path_buffer_), "%s", cfg_.paths.iso.c_str());
        copy_disc_ = false;  // muOS already selected an image in the app folder; do not duplicate it.
    }
    std::fprintf(stderr, "launcher: %s (user data %s)\n", screen_ == Screen::Ready ? "settings screen" : "first run: no game files",
                 cfg_.paths.user_data.c_str());
    if (!scripted_drop_.empty()) {
        // The scripted drop (--launcher-disc): the same path a drop on the window takes.
        image_path_ = scripted_drop_;
        std::snprintf(path_buffer_, sizeof path_buffer_, "%s", image_path_.c_str());
        std::fprintf(stderr, "launcher: scripted drop %s\n", image_path_.c_str());
        StartExtraction(image_path_);
    }
    // Harness screenshot mode is bounded: three presented frames normally take
    // well under a second; a window that never presents (occluded swap, a stuck
    // compositor) fails here by name instead of hanging the Root pin to its timeout.
    const uint64_t harness_start_ms = SDL_GetTicks64();
    constexpr uint64_t kHarnessDeadlineMs = 30000;
    while (running_) {
        PumpEvents();
        if (screen_ == Screen::Extracting && extract_) {
            bool finished = false;
            {
                std::lock_guard<std::mutex> lock(extract_->mutex);
                finished = extract_->finished;
            }
            if (finished && worker_.joinable()) FinishExtraction();
        }
        DrawFrame();
        if (auto_play_ && screen_ == Screen::Ready && screenshot_.empty()) {
            // --launcher-then-play without a screenshot: Play the moment the Ready
            // screen is up (one presented frame of it, so the hand-off is seen).
            running_ = false;
            outcome_ = Outcome::Play;
            std::fprintf(stderr, "launcher: Play (auto)\n");
        } else if (auto_play_ && screen_ == Screen::NeedDisc && !worker_.joinable() && !scripted_drop_.empty()) {
            // The scripted drop was refused: nothing to play.
            std::fprintf(stderr, "launcher: scripted drop refused; no game files -- leaving\n");
            running_ = false;
            outcome_ = Outcome::Failed;
        }
        if (!screenshot_.empty() && ++frames_ == 3) {
            const bool ok = DumpFrame(screenshot_);
            std::fprintf(stderr, "launcher: screenshot %s: %s\n", screenshot_.c_str(), ok ? "written" : "FAILED");
            running_ = false;
            outcome_ = then_play_ && screen_ == Screen::Ready ? Outcome::Play : Outcome::Quit;
            if (outcome_ == Outcome::Play) std::fprintf(stderr, "launcher: Play (harness)\n");
        } else if (!screenshot_.empty() && SDL_GetTicks64() - harness_start_ms > kHarnessDeadlineMs) {
            std::fprintf(stderr, "launcher: screenshot %s: FAILED (%d presented frames in %llu ms)\n", screenshot_.c_str(), frames_,
                         (unsigned long long)kHarnessDeadlineMs);
            running_ = false;
            outcome_ = Outcome::Failed;
        }
    }
    // Stop and join any first-run worker before freeing the state it references.
    // The Play path then enters the game with the UI model and its temporary
    // controller/session allocations already released.
    if (worker_.joinable()) {
        if (extract_) extract_->cancel.store(true);
        worker_.join();
    }
    CloseWindow();
    settings_.reset();
    extract_.reset();
    std::vector<std::string>().swap(controllers_);
    std::vector<void*>().swap(controller_handles_);
    std::string().swap(image_path_);
    std::string().swap(last_extract_summary_);
    std::string().swap(verify_message_);
    return outcome_;
}

bool Launcher::DumpFrame(const std::string& path) {
    // The back buffer of the frame just drawn (DrawFrame swapped it to the front:
    // read the FRONT buffer -- the presented image).
    int w = 0, h = 0;
    SDL_GL_GetDrawableSize(window_, &w, &h);
    if (w <= 0 || h <= 0) return false;
    std::vector<uint8_t> rgba(static_cast<size_t>(w) * h * 4);
    glReadBuffer(GL_FRONT);
    glPixelStorei(GL_PACK_ALIGNMENT, 1);
    glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, rgba.data());
    std::FILE* f = std::fopen(path.c_str(), "wb");
    if (!f) return false;
    std::fprintf(f, "P6\n%d %d\n255\n", w, h);
    for (int y = h - 1; y >= 0; --y)
        for (int x = 0; x < w; ++x) std::fwrite(rgba.data() + (static_cast<size_t>(y) * w + x) * 4, 1, 3, f);
    std::fclose(f);
    return true;
}

void Launcher::PumpEvents() {
    SDL_Event e;
    while (SDL_PollEvent(&e)) {
        ImGui_ImplSDL2_ProcessEvent(&e);
        if (e.type == SDL_WINDOWEVENT && e.window.event == SDL_WINDOWEVENT_FOCUS_LOST) {
            muos_menu_down_ = false;
            muos_start_down_ = false;
        } else if (e.type == SDL_CONTROLLERBUTTONDOWN || e.type == SDL_CONTROLLERBUTTONUP) {
            const bool down = e.type == SDL_CONTROLLERBUTTONDOWN;
            static bool logged_buttons[SDL_CONTROLLER_BUTTON_MAX] = {};
            const unsigned button = e.cbutton.button;
            if (down && button < SDL_CONTROLLER_BUTTON_MAX && !logged_buttons[button]) {
                logged_buttons[button] = true;
                const char* name = SDL_GameControllerGetStringForButton(static_cast<SDL_GameControllerButton>(button));
                std::fprintf(stderr, "[muos.launcher.input] first SDL button %u (%s), instance=%d\n",
                             button, name ? name : "unknown", e.cbutton.which);
            }
            if (button == SDL_CONTROLLER_BUTTON_GUIDE) muos_menu_down_ = down;
            if (button == SDL_CONTROLLER_BUTTON_START) muos_start_down_ = down;
            if (muos_menu_down_ && muos_start_down_ && !muos_exit_requested_) {
                muos_exit_requested_ = true;
                std::fprintf(stderr, "[muos.hotkey] MENU + START: leaving launcher for muOS\n");
                outcome_ = Outcome::Quit;
                running_ = false;
            }
        } else if (e.type == SDL_QUIT || (e.type == SDL_WINDOWEVENT && e.window.event == SDL_WINDOWEVENT_CLOSE)) {
            running_ = false;
            outcome_ = Outcome::Quit;
        } else if (e.type == SDL_DROPFILE) {
            image_path_ = e.drop.file;
            SDL_free(e.drop.file);
            std::snprintf(path_buffer_, sizeof path_buffer_, "%s", image_path_.c_str());
            verify_message_.clear();
            if (screen_ == Screen::Ready) page_ = 5;   // Data page: "change disc"
            if (screen_ == Screen::NeedDisc || screen_ == Screen::Ready) StartExtraction(image_path_);
        } else if (e.type == SDL_KEYDOWN && settings_ && settings_->KeyBindingArmed() && !e.key.repeat) {
            settings_->OfferKey(SDL_GetScancodeName(e.key.keysym.scancode));
        } else if (e.type == SDL_KEYDOWN && settings_ && settings_->PadBindingArmed() && e.key.keysym.scancode == SDL_SCANCODE_ESCAPE) {
            settings_->CancelBinding();   // Escape leaves the armed pad row as it was
        } else if (e.type == SDL_KEYDOWN && e.key.keysym.scancode == SDL_SCANCODE_ESCAPE && page_ != 0) {
            page_ = 0;
        } else if ((e.type == SDL_CONTROLLERBUTTONDOWN || e.type == SDL_CONTROLLERAXISMOTION) && settings_ && settings_->PadBindingArmed()) {
            // Press-to-bind from the pad: a button edge, or a trigger past 25 % travel.
            const std::string control = e.type == SDL_CONTROLLERBUTTONDOWN
                ? ControlsBindings::PadControlFromEvent(true, e.cbutton.button, 0)
                : ControlsBindings::PadControlFromEvent(false, e.caxis.axis, e.caxis.value);
            settings_->OfferPadControl(control);
        } else if (e.type == SDL_CONTROLLERDEVICEADDED || e.type == SDL_CONTROLLERDEVICEREMOVED) {
            DetectControllers();
        }
    }
}

void Launcher::StartExtraction(const std::string& image) {
    if (worker_.joinable()) return;
    extract_ = std::make_unique<ExtractState>();
    const FirstRun::Plan plan = FirstRun::PlanFor(cfg_, title_, build_id_, image, copy_disc_);
    screen_ = Screen::Extracting;
    ExtractState* st = extract_.get();
    worker_ = std::thread([st, plan] {
        platform::host::RegisterSelf();
        const FirstRun::Result r = FirstRun::Run(plan, [st](const FirstRun::Progress& p) {
            std::lock_guard<std::mutex> lock(st->mutex);
            if (!p.message.empty() || p.stage != st->progress.stage) st->progress.message = p.message;
            st->progress.stage = p.stage;
            st->progress.done = p.done;
            st->progress.total = p.total;
        }, &st->cancel);
        std::lock_guard<std::mutex> lock(st->mutex);
        st->result = r;
        st->finished = true;
    });
}

void Launcher::FinishExtraction() {
    worker_.join();
    const FirstRun::Result& r = extract_->result;
    if (r.ok) {
        // The game starts from THIS Config: the referenced image (or the copy).
        cfg_.paths.iso = r.disc_referenced ? r.disc_path : std::string();
        verify_ok_ = true;
        verify_message_ = r.verify.message;
        last_extract_summary_ = "Extracted: " + r.elf_path + "; disc " + r.disc_path + (r.disc_referenced ? " (referenced)" : " (copied)") +
                                "; stamp " + r.stamp_path;
        std::fprintf(stderr, "launcher: %s\n", last_extract_summary_.c_str());
        screen_ = Screen::Ready;
        page_ = 0;
    } else {
        verify_ok_ = false;
        verify_message_ = r.error;
        std::fprintf(stderr, "launcher: extraction refused: %s\n", r.error.c_str());
        screen_ = FirstRun::GameFilesPresent(cfg_, title_) ? Screen::Ready : Screen::NeedDisc;
    }
}

void Launcher::DrawFrame() {
    SDL_GL_MakeCurrent(window_, gl_context_);
    ImGui::SetCurrentContext(imgui_);
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplSDL2_NewFrame();
    ImGui::NewFrame();
    const ImVec2 display = ImGui::GetIO().DisplaySize;
    DrawTwinsanityBackdrop(display);
    ImGui::SetNextWindowPos(ImVec2(0, 0));
    ImGui::SetNextWindowSize(display);
    ImGui::Begin("launcher", nullptr, ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoMove |
                                     ImGuiWindowFlags_NoBringToFrontOnFocus | ImGuiWindowFlags_NoSavedSettings |
                                     ImGuiWindowFlags_NoBackground);
    ImGui::TextColored(ImVec4(1.0f, 0.82f, 0.22f, 1.0f), "CRASH TWINSANITY");
    ImGui::SameLine();
    ImGui::TextDisabled("// RINTROMPED H700");
    ImGui::SameLine(display.x - 150.0f);
    ImGui::TextDisabled("%s", build_id_.c_str());
    ImGui::Separator();
    switch (screen_) {
        case Screen::NeedDisc: DrawNeedDisc(); break;
        case Screen::Extracting: DrawExtracting(); break;
        case Screen::Ready: DrawReady(); break;
    }
    ImGui::End();
    ImGui::Render();
    int w = 0, h = 0;
    SDL_GL_GetDrawableSize(window_, &w, &h);
    glViewport(0, 0, w, h);
    glClearColor(0.08f, 0.08f, 0.1f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
    SDL_GL_SwapWindow(window_);
}

void Launcher::DrawNeedDisc() {
    ImGui::Spacing();
    ImGui::TextWrapped("No Crash Twinsanity game files found under %s.", cfg_.paths.game_files.c_str());
    ImGui::TextWrapped("This application ships no game data. Drop your own Crash Twinsanity disc image (PAL SLES-52568 or NTSC-U SLUS-20909; .iso or "
                       ".bin) on this window, or type its path below. The image is verified (ISO9660 volume, SLUS_123.45 present, "
                       "ELF SHA-256 equal to the one this build was made from) before anything is written.");
    ImGui::Spacing();
    ImGui::SetNextItemWidth(-130);
    ImGui::InputTextWithHint("##path", "/path/to/the title.iso", path_buffer_, sizeof path_buffer_);
    ImGui::SameLine();
    if (ImGui::Button("Verify & extract", ImVec2(120, 0)) && path_buffer_[0]) {
        image_path_ = path_buffer_;
        StartExtraction(image_path_);
    }
    ImGui::Checkbox("Copy the disc image into the data folder (recommended; a .bin is converted to .iso). Off: reference it in place.",
                    &copy_disc_);
    if (!verify_message_.empty()) {
        ImGui::Spacing();
        ImGui::PushStyleColor(ImGuiCol_Text, verify_ok_ ? ImVec4(0.5f, 1, 0.5f, 1) : ImVec4(1, 0.55f, 0.45f, 1));
        ImGui::TextWrapped("%s", verify_message_.c_str());
        ImGui::PopStyleColor();
    }
    ImGui::Spacing();
    ImGui::SeparatorText("Controllers");
    if (controllers_.empty()) ImGui::TextDisabled("none detected -- keyboard + mouse drive the pad (W/A/S/D, mouse camera, Space jump)");
    for (const std::string& c : controllers_) ImGui::BulletText("%s", c.c_str());
    ImGui::Spacing();
    ImGui::TextDisabled("Data folder: %s", cfg_.paths.user_data.c_str());
    ImGui::TextDisabled("Harness use: nativeee --extract-disc <image> (no window); --game-files / --profile / --set bypass this screen.");
}

void Launcher::DrawExtracting() {
    FirstRun::Progress p;
    {
        std::lock_guard<std::mutex> lock(extract_->mutex);
        p = extract_->progress;
    }
    ImGui::Spacing();
    ImGui::Text("Extracting %s", image_path_.c_str());
    const char* stages[] = {"verify", "elf", "disc", "memcards", "settings", "stamp"};
    for (int i = 0; i < 6; i++) {
        const bool done = static_cast<int>(p.stage) > i, now = static_cast<int>(p.stage) == i;
        ImGui::TextColored(done ? ImVec4(0.5f, 1, 0.5f, 1) : now ? ImVec4(1, 1, 0.6f, 1) : ImVec4(0.5f, 0.5f, 0.5f, 1),
                           "%s %s", done ? "[x]" : now ? "[>]" : "[ ]", stages[i]);
    }
    const float fraction = p.total > 0 ? static_cast<float>(static_cast<double>(p.done) / static_cast<double>(p.total)) : 0.0f;
    char label[96];
    if (p.stage == FirstRun::Stage::Disc && p.total > 0)
        std::snprintf(label, sizeof label, "%.1f / %.1f MB", p.done / 1048576.0, p.total / 1048576.0);
    else
        std::snprintf(label, sizeof label, "%s", FirstRun::StageName(p.stage));
    ImGui::ProgressBar(fraction, ImVec2(-1, 0), label);
    ImGui::TextWrapped("%s", p.message.c_str());
    if (ImGui::Button("Cancel")) extract_->cancel.store(true);
}

void Launcher::DrawReady() {
    const GameFilesStamp::Check stamp = GameFilesStamp::Verify(cfg_.paths.game_files, build_id_);
    const bool disc_missing = !FileExists(DiscPath());
    std::string warning;
    if (stamp.state == GameFilesStamp::State::Mismatch)
        warning = GameFilesStamp::Warning(stamp, build_id_);
    else if (stamp.state != GameFilesStamp::State::Match)
        warning = "Game files have no matching extraction stamp: " + GameFilesStamp::MetaValue(stamp);
    if (disc_missing) warning += (warning.empty() ? "" : "; ") + std::string("disc image not found: " + DiscPath());

    if (!last_extract_summary_.empty()) ImGui::TextDisabled("%s", last_extract_summary_.c_str());
    if (page_ == 0) {
        ImGui::BeginChild("twinsanity-home-hero", ImVec2(0, 102), true);
        ImGui::TextColored(ImVec4(1.0f, 0.82f, 0.22f, 1.0f), "RINTROMPED");
        ImGui::SameLine();
        ImGui::TextDisabled("H700 EDITION");
        ImGui::TextWrapped("The twins are ready. Configure your controls, adjust the graphics and jump straight into the adventure.");
        ImGui::EndChild();

        if (!warning.empty()) {
            ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.0f, 0.80f, 0.30f, 1.0f));
            ImGui::TextWrapped("%s", warning.c_str());
            ImGui::PopStyleColor();
            ImGui::SameLine();
            if (ImGui::SmallButton("OPEN DATA")) page_ = 5;
        }

        ImGui::Spacing();
        ImGui::BeginDisabled(disc_missing);
        if (ImGui::Button("START GAME", ImVec2(180, 52))) {
            outcome_ = Outcome::Play;
            running_ = false;
            std::fprintf(stderr, "launcher: Play\n");
        }
        ImGui::EndDisabled();
        ImGui::SameLine();
        if (ImGui::Button("DISPLAY", ImVec2(104, 52))) page_ = 1;
        ImGui::SameLine();
        if (ImGui::Button("CONTROLS", ImVec2(112, 52))) page_ = 2;
        ImGui::SameLine();
        if (ImGui::Button("QUIT", ImVec2(82, 52))) {
            outcome_ = Outcome::Quit;
            running_ = false;
        }
        ImGui::Spacing();
        if (ImGui::Button("SAVE STATES", ImVec2(118, 34))) page_ = 3;
        ImGui::SameLine();
        if (ImGui::Button("FIXES", ImVec2(118, 34))) page_ = 4;
        ImGui::SameLine();
        if (ImGui::Button("GAME DATA", ImVec2(118, 34))) page_ = 5;

        ImGui::Spacing();
        if (controllers_.empty()) ImGui::TextDisabled("Controller not detected // keyboard input remains available");
        else {
            ImGui::TextDisabled("CONTROLLER");
            for (const std::string& controller : controllers_) ImGui::SameLine(), ImGui::Text("%s", controller.c_str());
        }
        ImGui::Separator();
        ImGui::TextDisabled("SYSTEM EXIT: MENU + START");
        if (!verify_message_.empty() && !verify_ok_)
            ImGui::TextColored(ImVec4(1.0f, 0.55f, 0.45f, 1.0f), "%s", verify_message_.c_str());
        return;
    }

    ImGui::BeginChild("twinsanity-settings-overlay", ImVec2(0, 0), true);
    if (ImGui::Button("< BACK", ImVec2(70, 32))) page_ = 0;
    ImGui::SameLine();
    for (int i = 1; i < 6; ++i) {
        if (i > 1) ImGui::SameLine();
        if (ImGui::Button(kPages[i], ImVec2(80, 32))) page_ = i;
    }
    ImGui::Separator();
    switch (page_) {
        case 1:
            settings_->DrawDisplayPage();
            break;
        case 2:
            settings_->DrawControlsPage(controllers_);
            break;
        case 3:
            settings_->DrawSaveStatesPage();
            break;
        case 4:
            settings_->DrawFixesPage();
            break;
        case 5: {
            const std::string request = settings_->DrawDataPage(
                cfg_.paths.game_files, DiscPath(), GameFilesStamp::MetaValue(stamp));
            ImGui::Spacing();
            ImGui::SetNextItemWidth(-130);
            ImGui::InputTextWithHint("##newdisc", "drop a disc image here or type its path", path_buffer_, sizeof path_buffer_);
            ImGui::SameLine();
            if (ImGui::Button("Verify & extract", ImVec2(120, 0)) && path_buffer_[0]) StartExtraction(path_buffer_);
            ImGui::Checkbox("Copy the disc image into the data folder", &copy_disc_);
            if (request == "open-folder") OpenDataFolder();
            else if (request == "re-extract" && !DiscPath().empty()) StartExtraction(DiscPath());
            if (!verify_message_.empty()) {
                ImGui::PushStyleColor(ImGuiCol_Text, verify_ok_ ? ImVec4(0.5f, 1, 0.5f, 1) : ImVec4(1, 0.55f, 0.45f, 1));
                ImGui::TextWrapped("%s", verify_message_.c_str());
                ImGui::PopStyleColor();
            }
            break;
        }
        default:
            break;
    }
    if (!settings_->Log().empty()) {
        ImGui::Separator();
        for (const std::string& line : settings_->Log()) ImGui::TextDisabled("%s", line.c_str());
    }
    ImGui::EndChild();
}

}  // namespace ps2r::app
