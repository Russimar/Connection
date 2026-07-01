# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`Connection` is a source-only Delphi library that provides Firebird database connectivity via FireDAC. It has no `.dproj`/`.dpr` of its own — it is distributed and consumed as a dependency through [BOSS](https://github.com/HashLoad/boss) (the Delphi package manager), declared in `boss.json`. Consuming projects add it under something like `SERVICO\modules\connection\src\` and reference the units directly; there is no standalone build, lint, or test command in this repo.

Dependency: `github.com/russimar/log` (provides the `GravarLog`/`TGravarLog` unit used for error logging).

## Architecture

Connection resolution flows through three layers, each behind an interface in `src/Provider.Interfaces.pas`:

1. **`Provider.ArquivoIni.pas`** (`IArquivoIni` / `TArquivoIni`) — reads connection parameters from an `.ini` file (`config.ini`, or `parceiro.ini` if present — see `TConnection.Config`) under a section named by `Tag`. Handles legacy/combined formats where host and port may be embedded inside the `Database` value (`"host:port:path"`) or inside `HostName` (`"host:port"`) — see `SplitStr`/`JoinStr` parsing in `BuscarParametro`. Passwords can be Base64-encoded (`usaCriptografia=S`) and are decoded via `Descriptografar`. Returns a `TDadosConexao` record (`Provider.DadosConexao.pas`).

2. **`Provider.Conexao.pas`** (`TConnection`) — implements `iConnection`. One instance per DB "tag". On `Connection`, it re-reads `TArquivoIni` config every call, populates a `TFDConnection` (driver `FB`/Firebird), and opens it. **On connect failure it logs via `TGravarLog` and returns `nil`** rather than propagating the exception — callers must check for `nil`. This is a known issue tracked in `plano_connection.md` (see below).

3. **`Provider.GerenciadorConexao.pas`** (`TGerenciadorConexao`) — a thread-local connection pool, also implementing `iConnection` as a drop-in replacement for `TConnection` (`TGerenciadorConexao.New('TAG')` instead of `TConnection.New('TAG')` in the consumer's Bootstrap — no other call sites need to change). Keyed by `TThread.CurrentThread.ThreadID`, it caches one `TConnection`/`TFDConnection` per thread and runs a background `TThreadLimpeza` that closes connections idle longer than `MaxIdleSegundos` (default 60s, checked every 30s). Intended for multi-threaded servers (e.g. Indy HTTP) where each request thread needs its own Firebird connection without cross-thread contention.

On top of `iConnection`, **`src/Query/Provider.Query.pas`** (`TQuery`, implementing `iQuery`) wraps a `TFDQuery`: `.SQL(...)`, `.AddParam(...)`, `.Open`, `.ExecSQL(...)`, all fluent (each returns `iQuery` / `Self`). If constructed with no parent connection, it defaults to `TConnection.New('PDV')`.

`iEntidade` is declared in `Provider.Interfaces.pas` but has no implementation in this repo — it's a contract for consumers to implement against.

## Known issues / active plan

`plano_connection.md` documents a set of correctness issues found in this library (blocking `MessageDlg` calls with no interactive session, uninitialized record returned on missing `.ini` file, unguarded `StrToInt`, missing validation of empty `Database`/section, and `TConnection.Connection` swallowing the real exception behind a `nil` return). Per that document, fixes belong in *this* repo (the library origin), not in consumer projects — read it before touching `Provider.ArquivoIni.pas` or `Provider.Conexao.pas` so changes address root cause rather than duplicating consumer-side workarounds.

## Conventions in this codebase

- Interfaces are prefixed lowercase `i`/`I` inconsistently (`iConnection`, `iQuery` vs `IArquivoIni`) — match whichever prefix the existing file already uses rather than normalizing across units.
- Classes expose a `class function New(...)` factory alongside the constructor; consumers call `New`, not `Create`, directly.
- FMX vs VCL is selected via `{$IFDEF FMX}` blocks in `uses` clauses (see `Provider.ArquivoIni.pas`, `Provider.Conexao.pas`) — keep both branches in sync when editing dialog/forms-related code.
