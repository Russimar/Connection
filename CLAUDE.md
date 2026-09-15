# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`Connection` is a source-only Delphi library that provides Firebird database connectivity via FireDAC. It has no `.dproj`/`.dpr` of its own — it is distributed and consumed as a dependency through [BOSS](https://github.com/HashLoad/boss) (the Delphi package manager), declared in `boss.json`. Consuming projects add it under something like `SERVICO\modules\connection\src\` and reference the units directly; there is no standalone build, lint, or test command in this repo.

Dependency: `github.com/russimar/log` (provides the `GravarLog`/`TGravarLog` unit used for error logging).

## Architecture

Connection resolution flows through three layers, each behind an interface in `src/Provider.Interfaces.pas`:

1. **`Provider.ArquivoIni.pas`** (`IArquivoIni` / `TArquivoIni`) — reads connection parameters from an `.ini` file (`config.ini`, or `parceiro.ini` if present — see `TConnection.Config`) under a section named by `Tag`. Handles legacy/combined formats where host and port may be embedded inside the `Database` value (`"host:port:path"`) or inside `HostName` (`"host:port"`) — see `SplitStr`/`JoinStr` parsing in `BuscarParametro`. Passwords can be Base64-encoded (`usaCriptografia=S`) and are decoded via `Descriptografar`. Returns a `TDadosConexao` record (`Provider.DadosConexao.pas`).

2. **`Provider.Conexao.pas`** (`TConnection`) — implements `iConnection`. One instance per DB "tag". On `Connection`, it reads `TArquivoIni` config, populates a `TFDConnection` (driver `FB`/Firebird), and opens it. **If the connection is already open, `Connection` returns it as-is without re-reading the `.ini` and without reassigning `Params`** — reassigning `Params` on a live connection silently drops the current transaction, and the failure only surfaced later at `Commit` as Firebird error `-514`. To apply new parameters at runtime, call `Reconectar`. **On connect failure it logs via `TGravarLog` and raises `EConnectionException`; it never returns `nil`** — callers must not write `nil` guards.

3. **`Provider.GerenciadorConexao.pas`** (`TGerenciadorConexao`) — a thread-local connection pool, also implementing `iConnection` as a drop-in replacement for `TConnection` (`TGerenciadorConexao.New('TAG')` instead of `TConnection.New('TAG')` in the consumer's Bootstrap — no other call sites need to change). Keyed by `TThread.CurrentThread.ThreadID`, it caches one `TConnection`/`TFDConnection` per thread and runs a background `TThreadLimpeza` that closes connections idle longer than `MaxIdleSegundos` (default 60s, checked every 30s). Intended for multi-threaded servers (e.g. Indy HTTP) where each request thread needs its own Firebird connection without cross-thread contention. Creating a pooled connection is wrapped in `try/except` that frees the `TItemConexao` and re-raises the original exception: previously the item was created before the connection attempt and leaked on every failure, and the pool could hand back `nil`, contradicting the `iConnection` contract. Pool creation and disposal are written to the log with the thread id.

On top of `iConnection`, **`src/Query/Provider.Query.pas`** (`TQuery`, implementing `iQuery`) wraps a `TFDQuery`: `.SQL(...)`, `.AddParam(...)`, `.Open`, `.ExecSQL(...)`, all fluent (each returns `iQuery` / `Self`). **The parent connection is mandatory**: `TQuery.New(nil)` raises `EConnectionException`. It used to fall back to a `'PDV'` tag hardcoded in the library, which silently connected consumers to a database they never asked for.

`iEntidade` is declared in `Provider.Interfaces.pas` but has no implementation in this repo — it's a contract for consumers to implement against.

## The `iConnection` contract

`Provider.Interfaces.pas` states the rules every implementation must honour; read the comment there before writing a new one:

1. `Connection` **never returns `nil`** — failure is signalled by `EConnectionException` (`src/Provider.Excecoes.pas`), which carries `Tag`, `ArquivoIni` and `DataBase` for diagnostics and still descends from `Exception`, so existing `except on E: Exception` blocks keep working.
2. `Connection` is safe to call repeatedly: once open, it returns the existing connection untouched. Use `Reconectar` to re-read the `.ini` and apply new parameters.
3. The returned `TCustomConnection` belongs to the implementation — callers must not free or close it.

`ArquivoConfiguracao(const AValue)` lets the consumer pick the `.ini` explicitly; without it the historical precedence still applies (`parceiro.ini` overrides `config.ini`), and the resolved path is now written to the log instead of being silently chosen. The parameterless `ArquivoConfiguracao` returns that resolved path, available before any connection is opened.

Note on `usaCriptografia=S`: it triggers **Base64 decoding only** — obfuscation, not encryption. Anyone holding the `.ini` recovers the password trivially, so the file must never be versioned or treated as secure.

## Tests

There is a DUnitX console suite in `tests/` (Delphi 10.4, Win32):

- `tests\build.bat` — compiles the suite. It tries MSBuild first and falls back to `dcc32.exe` with the lean `tests\dcc32.cfg`, because the `.dproj` inherits the IDE's global search path and MSBuild fails with `MSB6003` ("command-line too long").
- `tests\run.bat` — runs the suite **once per Firebird version installed on the machine**, passing `--firebird=2_5|4_0|5_0`. A single process loads a single `fbclient.dll`, and a 2.5 client cannot talk to a 5.0 server, so the versions cannot share one run.

The harness detects the installed versions itself (scanning `Firebird_*` folders and reading `RemoteServicePort` from each `firebird.conf`), creates its own temporary database via that version's `isql.exe`, generates a temporary `.ini`, and deletes both at the end — no pre-existing `config.ini` is needed and no credentials are ever versioned. **A version that is absent from the machine is marked as skipped and does not fail the suite**; a missing Firebird altogether does fail it, since that is an environment precondition. SYSDBA's password defaults to the standard one and can be overridden with the `FB_TEST_PASSWORD` environment variable.

## Conventions in this codebase

- Interfaces are prefixed lowercase `i`/`I` inconsistently (`iConnection`, `iQuery` vs `IArquivoIni`) — match whichever prefix the existing file already uses rather than normalizing across units.
- Classes expose a `class function New(...)` factory alongside the constructor; consumers call `New`, not `Create`, directly.
- FMX vs VCL is selected via `{$IFDEF FMX}` blocks in `uses` clauses (see `Provider.ArquivoIni.pas`, `Provider.Conexao.pas`) — keep both branches in sync when editing dialog/forms-related code.
