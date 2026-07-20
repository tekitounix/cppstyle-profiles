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

SL1 最小禁止集合の候補は、上位設計と同じ次の九分類とする。

- `unsafe-buffer-operation`: raw pointer の演算・添字操作と危険な C buffer API
- `unchecked-span-construction`: 検証されていない pointer と長さからの span 構築
- `manual-lifetime`: placement new、`std::launder`、byte storage による手動寿命管理
- `uninitialized-state`: 未初期化状態の生成・読出し・伝播
- `unsafe-cast`: C cast、`reinterpret_cast`、未検査 narrowing、外部整数から enum への変換
- `volatile-synchronization`: `volatile` を同期・排他・順序保証として使う処理
- `ignored-result`: 検査が必要な戻り値・状態値の無視
- `unsafe-coroutine-capture`: 寿命を保証できない coroutine capture と suspend 越し参照
- `realtime-forbidden-operation`: RT / ISR 到達面の heap、例外、RTTI、blocking、動的所有

最後の分類には `std::function`、`std::string`、`dynamic_cast`、virtual dispatch、動的確保、
blocking 同期を含む。ただし、これらを判定する checker と負例集は未実装である。

例外を許せるのは、一般の業務コードでは代替できない処理を隔離した安全核だけとする。安全核の例外は
`owner`、`symbol`、`reason`、`expires` をすべて持つ台帳と、境界外では必ず失敗する負例で限定する。
現在はこの負例集と台帳検証が未実装なので、path だけを根拠に SL1 例外を有効化してはならない。

現在の clang-tidy adapter は上記の未実装規則を強制せず、profile override も生成物へ反映しない。
この候補では未強制規則を `[rules]` に書かず、SL1 を保護済みとは扱わない。realtime-safety plugin も
`interrupt` / `gnu::interrupt` / `annotate("interrupt")` 属性だけを入口とし、UMI の無属性 IRQ
handler や `naked` handler を保護しないため有効化しない。

## 例外台帳候補

| path | symbol | 候補除外 | reason | owner / expires |
|---|---|---|---|---|
| `packages/platform/port/**` | 未確定 | `performance-enum-size`, `performance-no-int-to-ptr`, `clang-analyzer-core.FixedAddressDereference` | MMIO とレジスタ定義 | 未確定 / 導入時に期限設定 |
| `packages/platform/port/include/umiport/platform/embedded/**` | 未確定 | `misc-const-correctness` | register asm の出力 operand | 未確定 / 導入時に期限設定 |
| `packages/runtime/os/app/include/umios/app/**` | 未確定 | `performance-no-int-to-ptr` | SVC syscall ABI | 未確定 / 導入時に期限設定 |
| `packages/runtime/os/app/src/**` | 未確定 | `performance-no-int-to-ptr` | CRT0 と linker symbol 算術 | 未確定 / 導入時に期限設定 |

cppstyle が override を実消費し、owner と expires を検証できるまでは、この表は採用候補であり
実際の抑制でも SL1 の安全核台帳でもない。既存の UMI child `.clang-tidy` を削除してはならない。
