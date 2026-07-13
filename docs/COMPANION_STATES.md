# Companion State Model

`CompanionState` represents semantic product state. Motion preferences modify
rendering and never replace semantic state. In particular, pausing animation is
not the same as sleeping.

| State | Entry | Visual and accessibility output | Exit |
| --- | --- | --- | --- |
| `idle` | No active task or timer | Neutral eyes, low drift, “Ready” | Hover, action, timer, sleep, hide |
| `curious` | Local pointer hover or actions open | Small tilt, local eye movement, “Curious” | Hover end or higher-priority work |
| `thinking` | Short evaluation/planning phase | Measured pulse/ellipsis, “Thinking” | Work, result, cancel |
| `working` | Deterministic action executing | Focused eyes, taut tail, working overlay | Success or error |
| `success` | Action or timer completed | Brief lift, closed positive eyes, sparkles | Personality-scaled timeout |
| `error` | Action failed truthfully | Brief contraction, concerned expression | Personality-scaled timeout |
| `sleeping` | Explicit future inactivity policy | Closed eyes and dim aura | Direct interaction |
| `waiting` | Countdown running or input pending | Calm low movement and timer overlay | Timer completion/cancel or action |
| `surprised` | Direct activation reaction | Brief wider eyes and scale change | Higher-priority state or timeout |
| `hidden` | User hides Veya | Panel is ordered out; effects stop | Show restores previous visible state |

## Priority and interruption

1. `hidden` overrides all visual output.
2. `working` overrides hover and timer waiting visuals.
3. `success` and `error` replace working feedback and remain visible for the
   selected personality’s reaction duration.
4. After temporary feedback, an active timer returns Veya to `waiting`;
   otherwise Veya returns to `idle`.
5. Hover may change only `idle` and `curious`; it cannot interrupt work, results,
   waiting, sleeping, or hidden state.
6. System/user reduced motion modifies animation only; it is not a state.

`CompanionStateMachine` owns these deterministic transitions. `AppEnvironment`
maps executor, timer, hover, and visibility events into the machine and owns one
cancellable temporary-feedback task. Business logic never manipulates low-level
animation values.

## Test expectations

Logic tests cover default state, hover behavior, non-interruption, hide/show
restoration, and timer-aware feedback reset. UI/manual checks must also cover
action success/failure, timer completion, animation pause, system Reduce Motion,
hide/show, and VoiceOver state output.

