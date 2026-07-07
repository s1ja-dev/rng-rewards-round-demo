# RNG Rewards + Round Manager Demo

A server-authoritative weighted-RNG reward system plus a reusable round state machine for Roblox, built in Luau with [Rojo](https://rojo.space/). Part of a Roblox scripting portfolio.

## What it demonstrates

- **Server-authoritative RNG** — the client's `RequestSpin` remote carries no payload; the server rolls the reward and tells the client what it *already won* via `SpinResult`. The client only ever plays a reveal animation for a result it can neither pick nor preview.
- **Weighted reward table** — `RewardTableConfig.PickWeighted` is a pure function (takes an already-drawn number in `[0, totalWeight)`) so the odds themselves are unit-testable independent of the RNG source. Verified statistically over 100k rolls: distribution matches the configured 50/30/15/4/1 weights within a fraction of a percent.
- **Generic round state machine** — `RoundManagerService` cycles Waiting → Intermission → InRound → Ended on a server clock and broadcasts `{Phase, TimeRemaining}`. It has zero opinion about what happens *during* a round, so it's reusable for battle-royale lobbies, minigame rotations, or PvP arenas.
- **Drift-free client display** — the round status chip renders whatever the server broadcasts each tick; it never runs its own countdown that could drift from the server clock.

## Structure

```
src/shared/    Classes, Net, Config (RewardTable weights, RoundConfig durations)
src/server/    RewardRollService (weighted roll + cooldown), RoundManagerService (state machine)
src/client/    HUD coins, SpinWheelUI (spin + reveal), RoundStatusUI (phase + countdown)
```

See [`UI_REQUIREMENTS.md`](UI_REQUIREMENTS.md) for the full remote/data contract — visuals can be reskinned without touching game logic.

## Running

Needs an empty Roblox Studio place with the Rojo plugin connected:

```
rojo serve
```

Press **Spin!** to roll a reward (1s cooldown, server-enforced). The status chip at the top shows the current round phase and countdown.
