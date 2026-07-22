// FP-001 minimal repro: bugprone-dynamic-static-initializers fires on
// constexpr-initialized statics in headers when -fno-threadsafe-statics
// is set, even though constexpr guarantees constant initialization.
#pragma once

enum class WriteBehavior { NORMAL, ONE_TO_CLEAR };

template <bool CanRead, bool CanWrite, WriteBehavior Behavior = WriteBehavior::NORMAL>
struct AccessPolicy {
    static constexpr bool can_read = CanRead;
    static constexpr bool can_write = CanWrite;
    static constexpr auto write_behavior = Behavior;
};

using RW = AccessPolicy<true, true>;
inline bool probe() { return RW::can_read && RW::can_write; }
