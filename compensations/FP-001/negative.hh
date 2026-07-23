// FP-001 negative corpus: the check must stay silent on non-template
// constexpr statics. Constant initialization is provable here, so a
// diagnostic on this shape means the detector broadened past the verified
// false-positive boundary (LLVM regression) and the compensation must be
// re-derived instead of silently retained.
#pragma once

struct Limits {
    static constexpr int kMax = 8;
};

inline constexpr int kAnswer = 42;
inline bool check_limits() { return Limits::kMax > 0 && kAnswer == 42; }
