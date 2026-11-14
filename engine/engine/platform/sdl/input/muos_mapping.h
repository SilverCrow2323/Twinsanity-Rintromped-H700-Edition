#pragma once

// MustardOS / muOS controller mapping bridge.
// SETUP_APP() exports the active SDL GameController row and database path.
// On Andromeda (2606.0+) that row is authoritative: it already reflects the
// selected Retro/Modern layout, the board's muOS-Keys GUID and any remapping.
#include <SDL.h>

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <fstream>
#include <initializer_list>
#include <string>

namespace ps2r::platform::sdl::muos_mapping {

struct Result {
    bool andromeda = false;
    bool muos_keys = false;
    bool added = false;
    std::string guid;
    std::string layout;
    std::string source;
};

inline std::string ReadLine(const char* path) {
    if (!path || !*path) return {};
    std::ifstream file(path);
    std::string line;
    if (!std::getline(file, line)) return {};
    if (!line.empty() && line.back() == '\r') line.pop_back();
    return line;
}

inline std::string Lower(std::string value) {
    std::transform(value.begin(), value.end(), value.begin(),
                   [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return value;
}

inline std::string Version() {
    return ReadLine("/opt/muos/config/system/version");
}

inline bool IsAndromeda() {
    // Use the release codename rather than a numeric >= check: a future muOS
    // release may change its input contract, and must not inherit this layout
    // merely because its version number is newer than 2606.0.
    if (Lower(Version()).find("andromeda") != std::string::npos) return true;
    std::ifstream os_file("/etc/os-release");
    std::string line;
    while (std::getline(os_file, line))
        if (Lower(line).find("andromeda") != std::string::npos) return true;
    return false;
}

inline std::string GuidForDevice(int device_index) {
    char guid[64] = {};
    SDL_JoystickGetGUIDString(SDL_JoystickGetDeviceGUID(device_index), guid, sizeof(guid));
    return Lower(guid);
}

inline bool IsMuosKeysGuid(const std::string& guid) {
    // BUS_VIRTUAL muOS-Keys GUIDs encode vendor "mu" and version "os".
    return guid.find("6d750000") != std::string::npos &&
           guid.find("6f730000") != std::string::npos;
}

inline bool IsMuosKeysDevice(int device_index, const std::string& guid) {
    const char* name = SDL_JoystickNameForIndex(device_index);
    return (name && Lower(name).find("muos-keys") != std::string::npos) || IsMuosKeysGuid(guid);
}

inline bool LineMatchesGuid(const std::string& line, const std::string& guid) {
    if (line.empty() || line[0] == '#') return false;
    const size_t comma = line.find(',');
    return comma != std::string::npos && Lower(line.substr(0, comma)) == guid;
}

inline std::string FindLineInFile(const char* path, const std::string& guid) {
    if (!path || !*path) return {};
    std::ifstream file(path);
    std::string line;
    while (std::getline(file, line)) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (LineMatchesGuid(line, guid)) return line;
    }
    return {};
}

inline std::string SelectedLayout() {
    const std::string run_selection = ReadLine("/run/muos/controller");
    if (run_selection == "retro" || run_selection == "modern") return run_selection;
    const std::string system_layout = ReadLine("/opt/muos/config/settings/remap/layout");
    return system_layout == "1" ? "modern" : "retro";
}

inline bool HasRightStick(int device_index) {
    // SDL exposes physical capabilities on an opened joystick, not by device
    // index. Open/close a temporary handle before the long-lived controller.
    SDL_Joystick* joystick = SDL_JoystickOpen(device_index);
    if (!joystick) return false;
    const bool has_right_stick = SDL_JoystickNumAxes(joystick) >= 6 ||
                                 SDL_JoystickNumButtons(joystick) >= 15;
    SDL_JoystickClose(joystick);
    return has_right_stick;
}

inline std::string BuildAndromedaH700Fallback(const std::string& guid, const char* name,
                                               bool has_sticks, const std::string& layout) {
    const bool modern = layout == "modern";
    std::string mapping = guid + "," + (name && *name ? name : "muOS-Keys") + ",";
    mapping += modern
        ? "a:b3,b:b2,x:b5,y:b4,"
        : "a:b2,b:b3,x:b4,y:b5,";
    mapping += "leftshoulder:b6,rightshoulder:b7,lefttrigger:b8,righttrigger:b9,"
               "guide:b12,start:b11,back:b10,"
               "dpup:h0.1,dpleft:h0.8,dpright:h0.2,dpdown:h0.4,"
               "volumedown:b0,volumeup:b1,leftx:a0,lefty:a1,";
    if (has_sticks) mapping += "rightx:a2,righty:a3,leftstick:b13,rightstick:b14,";
    mapping += "platform:Linux,";
    return mapping;
}

inline Result Apply(int device_index) {
    Result result;
    result.guid = GuidForDevice(device_index);
    result.andromeda = IsAndromeda();
    result.muos_keys = IsMuosKeysDevice(device_index, result.guid);
    if (result.guid.empty()) return result;

    auto install = [&](const std::string& candidate, const std::string& source) {
        if (candidate.empty() || SDL_GameControllerAddMapping(candidate.c_str()) < 0) return false;
        result.source = source;
        result.layout = candidate.find(",a:b3,b:b2,x:b5,y:b4,") != std::string::npos ? "modern" : "retro/system";
        result.added = true;
        return true;
    };

    // Prefer the exact mapping injected by SETUP_APP. It carries the user's
    // selected content/system scheme and any per-device remapping from muOS.
    const char* active = std::getenv("SDL_GAMECONTROLLERCONFIG");
    if (active && LineMatchesGuid(active, result.guid) && install(active, "SDL_GAMECONTROLLERCONFIG"))
        return result;

    // SETUP_SDL_ENVIRONMENT also exports the selected Retro/Modern database.
    const char* selected_file = std::getenv("SDL_GAMECONTROLLERCONFIG_FILE");
    if (install(FindLineInFile(selected_file, result.guid),
                selected_file ? selected_file : "SDL controller database"))
        return result;

    for (const char* db_path : {"/usr/lib/gamecontrollerdb.txt", "/usr/lib32/gamecontrollerdb.txt"}) {
        if (install(FindLineInFile(db_path, result.guid), db_path)) return result;
    }

    // Only the Andromeda H700 fallback is synthesized locally. Older firmware
    // retains the pre-existing generic fallback and future muOS codenames must
    // wait for their own verified mapping contract.
    if (result.andromeda && result.muos_keys) {
        const std::string layout = SelectedLayout();
        const char* name = SDL_JoystickNameForIndex(device_index);
        const bool has_sticks = HasRightStick(device_index);
        install(BuildAndromedaH700Fallback(result.guid, name, has_sticks, layout),
                "Andromeda H700 canonical fallback");
    }
    return result;
}

}  // namespace ps2r::platform::sdl::muos_mapping
