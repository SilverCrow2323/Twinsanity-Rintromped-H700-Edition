#pragma once
#include <cstring>
#include <string>

struct SDL_Joystick {};
struct SDL_JoystickGUID { unsigned char data[16]{}; };

inline std::string SDL_TEST_GUID = "6d750000000000006f73000000000000";
inline std::string SDL_TEST_NAME = "muOS-Keys";
inline std::string SDL_TEST_LAST_MAPPING;
inline int SDL_TEST_AXES = 4;
inline int SDL_TEST_BUTTONS = 15;
inline int SDL_TEST_ADD_MAPPING_RESULT = 0;
inline int SDL_TEST_ADD_MAPPING_CALLS = 0;
inline int SDL_TEST_JOYSTICK_OPEN_COUNT = 0;
inline int SDL_TEST_JOYSTICK_CLOSE_COUNT = 0;
inline SDL_Joystick SDL_TEST_JOYSTICK;

inline SDL_JoystickGUID SDL_JoystickGetDeviceGUID(int) { return {}; }
inline void SDL_JoystickGetGUIDString(SDL_JoystickGUID, char* output, int length) {
    if (length <= 0) return;
    std::strncpy(output, SDL_TEST_GUID.c_str(), static_cast<size_t>(length - 1));
    output[length - 1] = '\0';
}
inline const char* SDL_JoystickNameForIndex(int) { return SDL_TEST_NAME.c_str(); }
inline SDL_Joystick* SDL_JoystickOpen(int) {
    ++SDL_TEST_JOYSTICK_OPEN_COUNT;
    return &SDL_TEST_JOYSTICK;
}
inline int SDL_JoystickNumAxes(SDL_Joystick*) { return SDL_TEST_AXES; }
inline int SDL_JoystickNumButtons(SDL_Joystick*) { return SDL_TEST_BUTTONS; }
inline void SDL_JoystickClose(SDL_Joystick*) { ++SDL_TEST_JOYSTICK_CLOSE_COUNT; }
inline int SDL_GameControllerAddMapping(const char* mapping) {
    ++SDL_TEST_ADD_MAPPING_CALLS;
    SDL_TEST_LAST_MAPPING = mapping ? mapping : "";
    return SDL_TEST_ADD_MAPPING_RESULT;
}
