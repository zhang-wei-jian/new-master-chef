# Foundry Project — Agent Quick Reference

## Environment

- **Windows host** — all Foundry commands (`forge`, `anvil`, `cast`, `chisel`) must run inside **WSL**.
- Run from WSL shell, not Windows CMD/PowerShell.

## Commands

| Step | Command |
|------|---------|
| Build | `forge build` |
| Test | `forge test` |
| Format check | `forge fmt --check` |
| Format fix | `forge fmt` |
| Gas snapshot | `forge snapshot` |
| Local node | `anvil` |
| Deploy (script) | `forge script script/Counter.s.sol:CounterScript --rpc-url <url> --private-key <key>` |

CI runs in order: `forge fmt --check` → `forge build --sizes` → `forge test -vvv`.

## Architecture

- **Solidity**: `src/*.sol` — currently a single `Counter` contract (`pragma solidity ^0.8.13`).
- **Tests**: `test/*.t.sol` — use `forge-std` (`import {Test, console} from "forge-std/Test.sol"`).
- **Scripts**: `script/*.s.sol` — deployment/automation scripts using `forge-std`.
- **Libraries**: `lib/` (git submodules, e.g. `forge-std`). Always run `git submodule update --init --recursive` after clone.
- **Config**: `foundry.toml` — default profile, `src`, `out`, `libs`.
- **CI**: `.github/workflows/test.yml` (Ubuntu, FOUNDRY_PROFILE=ci).

## Gotchas

- `cache/`, `out/`, `.env` are gitignored. Do not commit them.
- Broadcast logs for port 31337 and dry-runs are ignored; other broadcast files are kept.
- `foundry.toml` has no extra profile overrides — the default profile is used everywhere.
