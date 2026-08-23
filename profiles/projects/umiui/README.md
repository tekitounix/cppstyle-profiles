# umiui プロファイル

**umiui は umi の C++ 規約に完全準拠する。** ルール本体は
[`../umi/common.toml`](../umi/common.toml) と同一に保つこと。

`common.toml` に許される umi との差分は次の 3 点だけ:

| 差分 | 理由 |
|---|---|
| `[scan] header_filter_regex` | umiui の構造 (`include/` `sim/` `tests/`) に合わせる。加えて **C ABI ヘッダ `include/umiui/abi/` を除外**する — C として妥当であることが唯一の要件で、C++ の命名規約や modernize を当てるのは誤り。健全性は `tests/test_abi_c.c` の C11 コンパイル + 全フィールド static assert が担保する |
| `cpp.cppcore.macro-usage` の `AllowedRegexp` | 接頭辞が `UMIUI_`。`^UMI_.*` では `UMIUI_` にマッチしない |
| `cpp.format.include-order` の `groups` | `<umiui/abi/...>` `<umiui/...>` の並び |

これ以外の差分は「規約の分岐」であり許されない。umi 側 `common.toml` が更新されたら、
上の 3 点を除いて追従する。

leaf: `host.toml` (ネイティブ TU: tests / host smoke) / `wasm.toml` (Emscripten TU: sim)。
