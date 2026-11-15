#define PS2R_MUOS_MAPPING_TEST 1
#include "engine/platform/sdl/input/muos_mapping.h"

#include <cassert>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>

namespace {
using ps2r::platform::sdl::muos_mapping::Apply;
std::filesystem::path root;
std::filesystem::path version_file, os_release_file, selection_file, layout_file, selected_db_file, fallback_db_file;

void write_file(const std::filesystem::path& path, const std::string& contents) {
    std::ofstream out(path, std::ios::binary | std::ios::trunc);
    assert(out.good());
    out << contents;
    out.close();
    assert(out.good());
}

void reset_sdl() {
    SDL_TEST_GUID = "6d750000000000006f73000000000000";
    SDL_TEST_NAME = "muOS-Keys";
    SDL_TEST_LAST_MAPPING.clear();
    SDL_TEST_AXES = 4;
    SDL_TEST_BUTTONS = 15;
    SDL_TEST_ADD_MAPPING_RESULT = 0;
    SDL_TEST_ADD_MAPPING_CALLS = 0;
    SDL_TEST_JOYSTICK_OPEN_COUNT = 0;
    SDL_TEST_JOYSTICK_CLOSE_COUNT = 0;
}

void prepare() {
    std::filesystem::create_directories(root);
    version_file = root / "version";
    os_release_file = root / "os-release";
    selection_file = root / "controller-selection";
    layout_file = root / "layout";
    selected_db_file = root / "selected-db.txt";
    fallback_db_file = root / "fallback-db.txt";
    setenv("TW_MUOS_TEST_VERSION_FILE", version_file.c_str(), 1);
    setenv("TW_MUOS_TEST_OS_RELEASE_FILE", os_release_file.c_str(), 1);
    setenv("TW_MUOS_TEST_CONTROLLER_SELECTION_FILE", selection_file.c_str(), 1);
    setenv("TW_MUOS_TEST_LAYOUT_FILE", layout_file.c_str(), 1);
    setenv("TW_MUOS_TEST_CONTROLLER_DB", fallback_db_file.c_str(), 1);
    setenv("SDL_GAMECONTROLLERCONFIG_FILE", selected_db_file.c_str(), 1);
    unsetenv("SDL_GAMECONTROLLERCONFIG");
    write_file(version_file, "muOS 2606.0 Andromeda\n");
    write_file(os_release_file, "ID=muos\n");
    write_file(selection_file, "retro\n");
    write_file(layout_file, "0\n");
    write_file(selected_db_file, "");
    write_file(fallback_db_file, "");
    reset_sdl();
}

std::string row(bool modern, const std::string& name = "Test Controller") {
    return SDL_TEST_GUID + "," + name + "," +
        (modern ? "a:b3,b:b2,x:b5,y:b4," : "a:b2,b:b3,x:b4,y:b5,") +
        "platform:Linux,";
}

void test_active_environment_mapping_has_highest_priority() {
    prepare();
    const std::string active = row(true, "Active mapping");
    setenv("SDL_GAMECONTROLLERCONFIG", active.c_str(), 1);
    write_file(selected_db_file, row(false, "Selected file"));
    write_file(fallback_db_file, row(false, "Fallback database"));
    const auto result = Apply(0);
    assert(result.added && result.source == "SDL_GAMECONTROLLERCONFIG" && result.layout == "modern");
    assert(SDL_TEST_LAST_MAPPING == active && SDL_TEST_ADD_MAPPING_CALLS == 1);
}

void test_selected_database_precedes_system_database() {
    prepare();
    write_file(selected_db_file, row(true, "Selected file"));
    write_file(fallback_db_file, row(false, "Fallback database"));
    const auto result = Apply(0);
    assert(result.added && result.source == selected_db_file.string() && result.layout == "modern");
    assert(SDL_TEST_LAST_MAPPING.find("Selected file") != std::string::npos);
}

void test_system_database_is_used_when_selected_file_has_no_guid() {
    prepare();
    write_file(fallback_db_file, row(false, "System database"));
    const auto result = Apply(0);
    assert(result.added && result.source == fallback_db_file.string() && result.layout == "retro/system");
    assert(SDL_TEST_LAST_MAPPING.find("System database") != std::string::npos);
}

void test_retro_fallback_preserves_system_choice_and_right_stick() {
    prepare();
    write_file(selection_file, "retro\n");
    write_file(layout_file, "1\n");
    const auto result = Apply(0);
    assert(result.andromeda && result.muos_keys && result.added);
    assert(result.source == "Andromeda H700 canonical fallback" && result.layout == "retro/system");
    assert(SDL_TEST_LAST_MAPPING.find("a:b2,b:b3,x:b4,y:b5,") != std::string::npos);
    assert(SDL_TEST_LAST_MAPPING.find("guide:b12,start:b11,back:b10,") != std::string::npos);
    assert(SDL_TEST_LAST_MAPPING.find("rightx:a2,righty:a3,leftstick:b13,rightstick:b14,") != std::string::npos);
    assert(SDL_TEST_JOYSTICK_OPEN_COUNT == 1 && SDL_TEST_JOYSTICK_CLOSE_COUNT == 1);
}

void test_modern_fallback_uses_system_layout_and_omits_absent_sticks() {
    prepare();
    write_file(selection_file, "system\n");
    write_file(layout_file, "1\n");
    SDL_TEST_AXES = 2;
    SDL_TEST_BUTTONS = 12;
    const auto result = Apply(0);
    assert(result.added && result.layout == "modern");
    assert(SDL_TEST_LAST_MAPPING.find("a:b3,b:b2,x:b5,y:b4,") != std::string::npos);
    assert(SDL_TEST_LAST_MAPPING.find("rightx:") == std::string::npos);
    assert(SDL_TEST_LAST_MAPPING.find("rightstick:") == std::string::npos);
}

void test_os_release_can_identify_andromeda_when_version_file_is_empty() {
    prepare();
    write_file(version_file, "\n");
    write_file(os_release_file, "ID=muos\nNAME=muOS Andromeda\n");
    const auto result = Apply(0);
    assert(result.andromeda && result.added);
}

void test_future_muos_release_does_not_inherit_andromeda_fallback() {
    prepare();
    write_file(version_file, "muOS 2700.0 Orion\n");
    write_file(os_release_file, "ID=muos\nVERSION_CODENAME=orion\n");
    const auto result = Apply(0);
    assert(!result.andromeda && result.muos_keys && !result.added && SDL_TEST_ADD_MAPPING_CALLS == 0);
}

void test_failed_andromeda_mapping_is_reported_as_not_added() {
    prepare();
    SDL_TEST_ADD_MAPPING_RESULT = -1;
    const auto result = Apply(0);
    assert(result.andromeda && result.muos_keys && !result.added);
    assert(SDL_TEST_ADD_MAPPING_CALLS == 1);
}

void test_non_muos_controller_never_gets_the_h700_fallback() {
    prepare();
    SDL_TEST_GUID = "00112233445566778899aabbccddeeff";
    SDL_TEST_NAME = "USB Gamepad";
    const auto result = Apply(0);
    assert(result.andromeda && !result.muos_keys && !result.added && SDL_TEST_ADD_MAPPING_CALLS == 0);
}

void test_wrong_guid_active_mapping_is_ignored() {
    prepare();
    const std::string wrong = "00112233445566778899aabbccddeeff,Wrong pad,a:b0,b:b1,platform:Linux,";
    setenv("SDL_GAMECONTROLLERCONFIG", wrong.c_str(), 1);
    const auto result = Apply(0);
    assert(result.added && result.source == "Andromeda H700 canonical fallback");
    assert(SDL_TEST_LAST_MAPPING.find("a:b2,b:b3,x:b4,y:b5,") != std::string::npos);
}
}  // namespace

int main() {
    const char* directory = std::getenv("TW_MUOS_TEST_DIR");
    if (!directory || !*directory) {
        std::cerr << "TW_MUOS_TEST_DIR is required\n";
        return 2;
    }
    root = directory;
    test_active_environment_mapping_has_highest_priority();
    test_selected_database_precedes_system_database();
    test_system_database_is_used_when_selected_file_has_no_guid();
    test_retro_fallback_preserves_system_choice_and_right_stick();
    test_modern_fallback_uses_system_layout_and_omits_absent_sticks();
    test_os_release_can_identify_andromeda_when_version_file_is_empty();
    test_future_muos_release_does_not_inherit_andromeda_fallback();
    test_failed_andromeda_mapping_is_reported_as_not_added();
    test_non_muos_controller_never_gets_the_h700_fallback();
    test_wrong_guid_active_mapping_is_ignored();
    std::cout << "muOS Andromeda SDL mapping contract: 10 tests passed\n";
    return 0;
}
