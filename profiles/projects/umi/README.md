# UMI 四対象 profile 候補

`common.toml` に現在 cppstyle が実際に生成できる整形・clang-tidy・命名方針を集約し、
`host.toml`、`stm32.toml`、`rp235x.toml`、`wasm.toml` は同じ共通方針を継承する。
論理対象名は UMI 側 `cppstyle.toml` の `[targets.*]` が所有する。

## 対象と除外

profile schema には対象ファイル集合を記述する欄がない。対象ごとの `path_include` と
`path_exclude` は UMI 側 manifest の `[targets.<name>.scope]` に置く。すべての対象で少なくとも
`vendor/**`、`external/**`、`build/**`、`.cppstyle/**` を除外する。profile の `[scan]` も
`packages`、`platforms`、`examples`、`tests`、`web` だけを対象にし、system header を除外する。

host と STM32 は一つの論理対象に複数の実 triple を含む。現在の profile `[target]` と clangd
生成器は一つの `triple` を全翻訳単位へ注入するため、leaf では triple、CPU、FPU を固定しない。
実際の処理系・ABI・system root は UMI の実 compile database と target discovery を正本とする。

## SL1 候補と現在の上限

SL1 最小禁止集合の候補は次の七項目とする。

- 実時間到達範囲での動的確保
- 実時間到達範囲での blocking 同期
- 実時間到達範囲での例外
- 実時間到達範囲での `std::function`
- 実時間到達範囲での `std::string`
- 実時間到達範囲での `dynamic_cast`
- 実時間到達範囲での virtual dispatch

これらに対応する checker と負例集は未実装である。現在の clang-tidy adapter は `cpp.rt.*` を
強制せず、profile override も生成物へ反映しない。この候補では未強制規則を `[rules]` に書かず、
SL1 を保護済みとは扱わない。realtime-safety plugin も `interrupt` / `gnu::interrupt` /
`annotate("interrupt")` 属性だけを入口とし、UMI の無属性 IRQ handler や `naked` handler を
保護しないため有効化しない。

## 例外台帳候補

| path | 候補除外 | 理由 | owner / expires |
|---|---|---|---|
| `packages/platform/port/**` | `performance-enum-size`, `performance-no-int-to-ptr`, `clang-analyzer-core.FixedAddressDereference` | MMIO とレジスタ定義 | UMI owner / 導入時に期限設定 |
| `packages/platform/port/include/umiport/platform/embedded/**` | `misc-const-correctness` | register asm の出力 operand | UMI owner / 導入時に期限設定 |
| `packages/runtime/os/app/include/umios/app/**` | `performance-no-int-to-ptr` | SVC syscall ABI | UMI owner / 導入時に期限設定 |
| `packages/runtime/os/app/src/**` | `performance-no-int-to-ptr` | CRT0 と linker symbol 算術 | UMI owner / 導入時に期限設定 |

cppstyle が override を実消費し、owner と expires を検証できるまでは、この表は採用候補であり
実際の抑制ではない。既存の UMI child `.clang-tidy` を削除してはならない。
