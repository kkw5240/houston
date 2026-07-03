# MC Context Handover — Durable Automation

> **최종 갱신**: 2026-07-02 (T-HOU-028 자동주입 · T-HOU-035 크래시 복원력 snapshot/recover)
> **목적**: Mission Control(MC, `houston` apex 세션)의 컨텍스트 비대를 통제 가능한
> 핸드오버로 관리한다. 자동 compact 에 의존하지 않고, **문서(=AI 장기기억)** 로
> 상태를 남긴 뒤 `/clear` → **자동 재주입**으로 lean 하게 재개한다.

## Why

MC 는 장시간 운영되며 컨텍스트가 계속 커진다. 자동 compact 는 운영 세부(대기 결정,
함대 상태)를 손실할 수 있다. Houston 철학의 MC 자기적용: **상태를 `.houston/MC-STATE.md`
에 명시적으로 적재 → `/clear` → 재개 시 이 앵커를 다시 읽어 복원**한다.

기존에는 이 루프가 **완전 수동**이었다(갱신 → `/clear` → *기억해서* 다시 읽기).
T-HOU-028 은 이 중 (1) **재주입을 자동화**하고 (2) **절차를 성문화**한다.

## Components

| 구성요소 | 역할 |
| :--- | :--- |
| `.houston/MC-STATE.md` | MC 재개 앵커(lean 상태 문서). **MC 가 갱신**한다. |
| `scripts/houston-mc-state-inject.sh` | `SessionStart` 훅. **MC 세션 AND MISSION-CONTROL 윈도우(2-factor 신원)** 일 때만 앵커를 `additionalContext` 로 주입. 그 외 세션/윈도우/앵커 부재 = NO-OP. |
| `scripts/test-houston-mc-state-inject.sh` | 훅 회귀 스위트(8 게이트 — G1~G8, dock-node 윈도우 가드 G8 포함). |
| `.houston/templates/MC-STATE.template.md` | 앵커를 lean 하게 갱신하기 위한 작성 템플릿/체크리스트. |
| `.claude/settings.local.json` `SessionStart` 항목 | 훅 등록(§Registration — MC/Thomas 가 적용, self-config 가드). |

## How the auto-injection works

`SessionStart` 훅은 `startup` / `clear` / `resume` / `compact` 4개 소스에서 발화한다
(Claude Code hooks reference 확인). 훅은 **3개 게이트를 순서대로 통과할 때만** 앵커를
주입한다 (구현: `scripts/houston-mc-state-inject.sh:85-98`). 앞의 두 게이트가 **MC
신원 2-factor** 이고, 세 번째가 앵커 게이트다:

1. **MC 세션 게이트 (1)** — 현재 tmux 세션명이 `houston`(기본값, `HOUSTON_MC_SESSION`
   로 override 가능)일 때만. 미션/리프 세션은 **엄격히 NO-OP** → 컨텍스트 오염 없음.
2. **MC 윈도우 게이트 (1b)** — 현재 tmux 윈도우명이 `MISSION-CONTROL`
   (기본값, `HOUSTON_MC_WINDOW_MATCH` 로 override 가능)을 **포함**할 때만.
   `houston` 세션은 여러 윈도우(MISSION-CONTROL + dock-node 등)를 가질 수 있으므로,
   이 게이트가 없으면 dock-node 윈도우에서 열린 Claude 세션도 MC-STATE 를 주입받아
   **두 에이전트가 모두 자신을 Mission Control 로 오인**한다. 비-MC 윈도우 = **fail-closed
   NO-OP**. (세션명·윈도우명은 `TMUX_PANE` 기준으로 판정하며, tmux 밖/미가용이면 신원
   확인 불가로 NO-OP.)
3. **앵커 존재 게이트 (2)** — `.houston/MC-STATE.md` 가 있고 비어있지 않을 때만.

세 게이트를 모두 통과하면 stdout 으로 다음 JSON 을 출력한다(그 외 모든 경로 = 조용한
NO-OP, 항상 exit 0):

```json
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"<preamble>\n\n<MC-STATE.md 본문>"}}
```

`preamble` 은 "이 앵커로 상태 복원 + `houston orbit tree` 로 live 함대 대조 + 대기
미션 보고/Commander 결정부터 처리" 를 지시한다. 따라서 `/clear` 직후 SessionStart 가
다시 발화하며 **앵커가 자동 로드**된다 — 수동 재-read 불필요.

> 훅은 **항상 exit 0** 이다. SessionStart 훅이 exit 2 를 내면 세션 시작을 막으므로,
> 어떤 실패(파일 I/O, python 부재 등)도 NO-OP 로 강등한다.

## Procedure — 컨텍스트 핸드오버 (MC 운영)

### 트리거 (컨텍스트 비대 신호)

아래 중 하나라도 관측되면 핸드오버를 수행한다:

- 컨텍스트 사용률 경고(하네스 표시) 또는 응답이 느려지고 과거 세부를 놓치기 시작.
- 완료된 미션/결정이 쌓여 현재 대기 항목이 노이즈에 묻힘.
- 큰 조사/덤프를 컨텍스트에 적재한 직후(1회성 대용량 읽기 후 정리).
- 트리거 키워드: **"MC 핸드오버"**, **"컨텍스트 비대"**, **"MC-STATE 갱신"**,
  **"/clear 재개"**, **"context handover"**, **"MC lean 재개"**.

### 단계

1. **앵커 갱신** — `.houston/MC-STATE.md` 를 `.houston/templates/MC-STATE.template.md`
   기준으로 최신화. **lean 필수** (아래 체크리스트).
2. **(공유 root) flush 판단** — 앵커는 governance 파일이다. leaf-never-pushes 원칙상
   MC 가 origin/master 로 flush 한다(필요 시). 앵커 자체는 로컬 root 에 있어도 훅은
   로컬 파일을 읽으므로 재주입에는 커밋이 필수는 아니다(단, 내구성은 flush 로 확보).
3. **`/clear`** — 컨텍스트를 비운다.
4. **자동 재개** — SessionStart 훅이 앵커를 재주입한다. `scripts/houston-orbit.sh tree`
   로 live 함대를 대조하고, 대기 미션 보고 / Commander 결정부터 처리한다.

### Lean 앵커 체크리스트 (무엇을 담아야 재개가 lean 한가)

`.houston/MC-STATE.md` 에는 **재개에 꼭 필요한 것만** 담는다:

- [ ] **함대 상태는 작성하지 않음** — live fleet/status source는 `houston orbit tree`.
      MC-STATE에는 `orbit tree` 로 파생 불가능한 재개 서사와 결정만 남긴다.
- [ ] **Commander 대기 결정** — 지금 Thomas 판단이 필요한 항목만(머지/삭제/외부발송/
      상태변경/새 effort 등).
- [ ] **완료(this session)** — 최근 세션에서 끝난 것 요약(다음 세션 컨텍스트용, 짧게).
- [ ] **MC 운영 원칙** — 이번 세션에서 확립/재확인된 불변 규칙(짧게).
- [ ] **재개 절차** — "이 문서 읽기 → `houston orbit tree` → 대기 처리" 3줄.
- [ ] **금지**: 완료된 미션의 상세 로그, 코드 덤프, 조사 원문 → 별도 `.houston/reports/`
      또는 docs 로 옮기고 앵커엔 **포인터**만 남긴다.

## Registration (MC/Thomas — self-config 가드로 에이전트 직접편집 불가)

> ✅ **이미 등록됨 (T-HOU-028, 2026-07-02)**: `.claude/settings.local.json` 의
> `hooks.SessionStart` 에 아래 항목이 **적용 완료**되어 있다
> (`bash "$CLAUDE_PROJECT_DIR/scripts/houston-mc-state-inject.sh"`). 아래 절차는
> 재적용 / 다른 머신 복제 / 실수 삭제 후 복구용 **참조 레시피**다.

훅 스크립트는 리포에 있으나 `.claude/settings.local.json` 등록은 "에이전트 자기설정
수정" 가드에 막힌다. 신규 적용·복구 시 **MC/Thomas 가 아래를 적용**한다.

**추가할 `SessionStart` 항목** (기존 `hooks` 객체의 `UserPromptSubmit`/`Stop` 과 형제):

```json
"SessionStart": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "bash \"$CLAUDE_PROJECT_DIR/scripts/houston-mc-state-inject.sh\""
      }
    ]
  }
]
```

> `matcher` 없음 = 모든 소스(startup/clear/resume/compact)에서 발화(설계 의도).
> `$CLAUDE_PROJECT_DIR` 미가용이 우려되면 절대경로
> `~/workspace/scripts/houston-mc-state-inject.sh` 로 대체 가능(동일 스크립트).

**안전 적용 명령** (백업 + jq 병합 + 원자적 교체 — 기존 훅 보존):

```bash
! cd ~/workspace && \
  cp .claude/settings.local.json ".claude/settings.local.json.bak.$(date +%s)" && \
  jq '.hooks.SessionStart = [{"hooks":[{"type":"command","command":"bash \"$CLAUDE_PROJECT_DIR/scripts/houston-mc-state-inject.sh\""}]}]' \
     .claude/settings.local.json > /tmp/settings.local.merged.json && \
  python3 -m json.tool /tmp/settings.local.merged.json >/dev/null && \
  mv /tmp/settings.local.merged.json .claude/settings.local.json && \
  echo "✅ SessionStart hook registered (backup written)"
```

적용 후 **새 `houston` 세션을 시작하거나 `/clear`** 하면 앵커가 자동 주입된다.

## Testing

```bash
scripts/test-houston-mc-state-inject.sh -v      # 8 게이트 회귀 (G1~G8; G8 = dock-node 윈도우 가드)
```

수동 확인(실제 앵커로 주입 시뮬레이션 — MC 세션 흉내):

```bash
printf '{}' | HOUSTON_MC_SESSION_NAME_OVERRIDE=houston bash scripts/houston-mc-state-inject.sh | python3 -m json.tool
# 미션 세션 흉내 → 빈 출력(NO-OP):
printf '{}' | HOUSTON_MC_SESSION_NAME_OVERRIDE=mission-x bash scripts/houston-mc-state-inject.sh
```

## Crash resilience — snapshot + recover (T-HOU-035)

SessionStart 자동주입은 **정상 `/clear` 재개** 를 lean 하게 만든다. 그러나 MC 가
**비정상 종료(크래시 / 컨텍스트 유실)** 하면 앵커가 최신이 아닐 수 있다. T-HOU-035 는
이를 두 스크립트로 보완한다 (외부 초단위 타이머·tmux-continuum 없이, manifest + Stop
스냅샷만으로 충분 — Commander 결정).

| 구성요소 | 역할 |
| :--- | :--- |
| `scripts/houston-snapshot.sh` | fleet **machine 상태**(orbit tree + manifest 요약 + live `tmux ls`)를 `.omx/logs/snapshots/fleet-<epoch>.md` 로 고정. **매 MC 턴 종료(Stop 훅)** 시 실행되는 복원 앵커. 데몬 無, 항상 exit 0(hook-safe), 최신 N개 rotate(`HOUSTON_SNAPSHOT_KEEP`, 기본 20). |
| `scripts/test-houston-snapshot.sh` | 스냅샷 회귀 스위트(7 게이트 — 생성/포맷/rotate/hook-safe). |
| `scripts/houston-recover.sh` | 크래시 후 **READ-ONLY 복원 + 내부 reconcile**. 생존 아티팩트(최신 스냅샷 + manifest)로 "있었던 함대" 재구성 → 라이브 `tmux ls` 대조 → 3축 reconcile. **아무것도 kill/재기동/편집하지 않음** — PROPOSED(manual) 만 출력. |
| `scripts/test-houston-recover.sh` | 복원 회귀 스위트(9 게이트 — 3축 + 분류 + exit-code). |

**recover 3-reconcile 축** (HOUSTON_SYNC 의 외부축 reconcile 패턴 — claim vs 실측,
분류, 제안, 자동적용 없음 — 을 **내부축으로 확장**):

- **Axis A — manifest ↔ tmux**: 각 manifest 세션 vs live tmux →
  `LIVE` / `DEAD(expected: lifecycle_phase=closed)` / `🔴 DEAD-UNEXPECTED`(기록은
  active 인데 non-live) / `ORPHAN`(parent_mission → unknown·dead) / `UNTRACKED-LIVE`
  (live 인데 manifest 없음).
- **Axis B — CHANGESETS ↔ git**: `tasks/CHANGESETS.md` 가 인용한 merge-commit SHA 를
  git ref(기본 `origin/master`)에서 도달 가능성 검사. 인용됐지만 도달 불가 = **drift**
  (Done 주장이 도달 가능한 커밋으로 뒷받침되지 않음). ⚠️ stale refspec false-negative
  주의(`reference_git_stale_refspec_branch_analysis`) — `git ls-remote` 교차검증 권고.
  `HOUSTON_RECOVER_SHA_MAX`(기본 200) 초과분은 **명시 로깅**(silent cap 금지).
- **Axis C — MC-STATE ↔ tmux**: `.houston/MC-STATE.md`(SessionStart 훅이 주입하는 그
  앵커) 가 주장하는 함대 세션 vs live tmux → 주장했으나 dead(stale) / live 인데
  미기록(unrecorded).

Exit: `0` clean · `2` usage · `3` reconcile 이슈 발견(호출자 신호; 리포트는 항상 완전 출력).

```bash
scripts/houston-recover.sh                 # 3축 전체 진단 리포트 (stdout)
scripts/houston-recover.sh --axis a        # manifest ↔ tmux 만
scripts/houston-recover.sh --write         # 리포트를 .omx/logs/recover-<epoch>.md 로도 저장
```

### snapshot Stop-hook 등록 (MC/Thomas — self-config 가드)

스냅샷은 **매 MC 턴 종료마다 자동**이어야 앵커가 최신이다. **기존 `Stop` 훅
(`houston-stop.sh` = 터미널 타이틀/사운드)을 보존**하도록 배열에 **append** 한다
(교체 금지). 아래는 안전 적용 레시피 — self-config 가드로 에이전트가 직접 편집 불가,
**MC/Thomas 가 `!` 로 적용**한다:

```bash
# IDEMPOTENT: the `if any(... contains houston-snapshot) then . else += end` guard
# prevents a duplicate registration on re-apply (would otherwise run snapshot 2× per
# turn). `+=` (not `=`) preserves the existing houston-stop Stop hook.
! cd ~/workspace && \
  cp .claude/settings.local.json ".claude/settings.local.json.bak.$(date +%s)" && \
  jq 'if (.hooks.Stop // [] | any(.hooks[]?.command? // "" | contains("houston-snapshot"))) then . else .hooks.Stop += [{"hooks":[{"type":"command","command":"bash \"$CLAUDE_PROJECT_DIR/scripts/houston-snapshot.sh\"","timeout":10}]}] end' \
     .claude/settings.local.json > /tmp/settings.local.snap.json && \
  python3 -m json.tool /tmp/settings.local.snap.json >/dev/null && \
  mv /tmp/settings.local.snap.json .claude/settings.local.json && \
  echo "✅ Stop hook: houston-snapshot registered idempotently (기존 houston-stop 보존, backup written)"
```

> `+=` 는 배열 **추가**다(`=` 은 교체 → 기존 Stop 훅 파괴하므로 금지). 스냅샷 훅은
> MC 세션 밖에서도 발화하지만, machine-state 스냅샷은 세션 무관하게 안전(read-only,
> 항상 exit 0)하며 `HOUSTON_SNAPSHOT_DIR` 는 공용이라 어느 세션이 찍든 동일 앵커가
> 최신화된다. MC 전용으로 좁히려면 `houston-snapshot.sh` 앞에 세션 게이트를 두는
> 별도 래퍼를 쓸 수 있으나, 현재는 불필요(비용 무시 가능).

## Optional follow-up — skill-ification

핸드오버 절차를 트리거 가능한 Houston 스킬(`.houston/skills/houston-mc-handover.md`)
로도 노출할 수 있다. 단, 스킬 등록은 `.houston/build.sh` 실행이 필요하고 build 는
**모든 어댑터(CLAUDE.md, AGENTS.md, .cursorrules …)를 재생성**하므로 대규모 diff 를
만든다. 본 프로세스 문서로 성문화는 충분하며, 스킬화는 MC 판단에 맡긴다.
