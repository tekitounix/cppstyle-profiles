# cppstyle-profiles

Canonical C++ coding-style profiles consumed by
[cppstyle](https://github.com/tekitounix/cppstyle).

## Layout

- `profiles/base/<name>.toml` — base profiles other profiles can extend.
- `profiles/projects/<org>/<repo>.toml` — project-specific profiles
  (e.g. `profiles/projects/umi/host.toml`).

## Pinning

`cppstyle.toml` records the profile source as:

```toml
style_source = "git+https://github.com/tekitounix/cppstyle-profiles.git"
```

`cppstyle sync` fetches the commit and writes `cppstyle.lock` with the
exact `commit` + `tree_digest`. `cppstyle verify --no-drift` confirms
the cached checkout still matches the recorded digest, exiting 4
(SUPPLY) on tampering.

## Contributing

Open a PR against `main` with the rule diff. CI re-imports the affected
upstream `.clang-format` / `.clang-tidy` fixtures via `cppstyle init
--import` to confirm lift parity, then runs `cppstyle sync` against
the proposed profile in a sandbox.

Profiles are licensed under the same terms as cppstyle itself
(Apache-2.0). See [LICENSE](LICENSE).
