#include "engine/engine/render/backends/gl/gl_texture_pool.h"

#include <cstdlib>
#include <iostream>

int main() {
    using Pool = ps2r::render::GlTexturePool;
    if (Pool::CanRefillInPlace(Pool::FenceState::Unavailable)) {
        std::cerr << "FAIL: missing/failed fence was treated as idle\n";
        return EXIT_FAILURE;
    }
    if (Pool::CanRefillInPlace(Pool::FenceState::Pending)) {
        std::cerr << "FAIL: pending fence was treated as idle\n";
        return EXIT_FAILURE;
    }
    if (!Pool::CanRefillInPlace(Pool::FenceState::Signaled)) {
        std::cerr << "FAIL: signalled fence did not permit in-place refill\n";
        return EXIT_FAILURE;
    }
    std::cout << "Texture pool fence safety: all checks passed.\n";
    return EXIT_SUCCESS;
}
