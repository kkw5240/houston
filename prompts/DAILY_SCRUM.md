# Daily Scrum Report Generator (Commander / Backend View)

Sync가 완료된 상태에서 사령관(백엔드 개발자) 개인의 Daily Scrum 보고서를 생성합니다.
데이터 수집은 **로컬 문서 기반**으로, GitHub API 호출을 최소화합니다.
이 리포트는 철저히 사령관님 개인의 작업 트래킹과 코딩 진척도를 추적하기 위해 사용됩니다.

> **Language**: Korean (한국어)
> **Output Path**: `daily_scrum/{YYYY}/{MM}/{YYYY.MM.DD}.md`

---

## Prerequisite: Sync 확인

보고서 생성 전, 오늘 Sync가 실행되었는지 확인한다.

```
확인 방법:
1. 오늘 날짜의 Sync Report가 대화 내에서 출력된 적 있는지 확인
2. 또는 TASK_BOARD.md의 최근 수정 시각이 오늘인지 확인

미실행 시:
→ "먼저 prompts/SYNC.md 기반으로 동기화를 실행하세요." 안내 후 중단.
→ 유저가 Sync 없이 진행을 요청하면, 그 사실을 보고서 하단에 기록하고 진행.
```

---

## Phase 1: Data Collection (로컬 문서)

### 스캔 범위

사령관님(백엔드 개발자) 개인 뷰이므로 아래 범위만 수집한다.

- **포함**: 사령관님이 assignee이거나, 직접 작업 중인 티켓 (전 프로젝트)
- **포함**: 사령관님 티켓이 아니더라도 Blocker/Dependency 관계가 있는 티켓
- **제외**: 타 담당자 전용 티켓 (FE, QA 등) — PM View(`PM_SCRUM.md`)에서 관리

### 1-1. TASK_BOARD.md 읽기

`tasks/TASK_BOARD.md`에서 위 스캔 범위에 해당하는 티켓 상태를 수집한다.

| 수집 항목 | 소스 |
|:---|:---|
| 티켓 목록 (Backlog/Active/Hold/Stage/Done) | TASK_BOARD.md 섹션별 |
| 프로젝트별 그룹 | 섹션 헤더 (### My Project, ### Third Project 등) |
| 상태 주석 | `<-` 뒤의 인라인 메모 |
| GitHub Issue 링크 | `[#number](url)` 패턴 |

### 1-2. CHANGESETS.md 읽기

`tasks/CHANGESETS.md`에서 최근 WIP/Review/Done 항목을 수집한다.

| 수집 항목 | 필터 |
|:---|:---|
| WIP Change Sets | Status = WIP |
| Review 대기 | Status = Review |
| 오늘 완료된 CS | Status = Done, Date = today |
| PR 링크 | Proof 컬럼 |

### 1-3. 어제 Daily Scrum 읽기

`daily_scrum/{YYYY}/{MM}/{전일}.md`를 읽어 delta 비교에 사용한다.

- 어제 "익일 계획"에 있던 항목 중 오늘 완료된 것 → "금일 수행 업무"로 이동
- 어제 "특이 사항" 중 해결된 것 → 제거 또는 갱신

---

## Phase 2: Priority Score 계산

각 Active 티켓에 대해 Priority Score를 산정한다.

### Priority Matrix

| Factor | Weight | Scoring | Source |
|:---|:---|:---|:---|
| **Urgency (Label)** | 35% | P0=100, P1=70, P2=40, P3=20, None=30 | GitHub Label (`priority:P0`~`P3`, `critical`, `urgent`) |
| **Due Date** | 25% | 오늘=100, 내일=80, 이번주=60 | GitHub Milestone `due_on` 또는 Issue 본문의 마감일 |
| **Quick Win** | 15% | 1시간 이내=100, 반나절=70, 하루=50, 이틀+=30 | Ticket Notes 또는 AI 추정 (이슈 복잡도 기반) |
| **Dependency** | 10% | 독립 실행=100, 외부 의존=30, Blocked=0 | TASK_BOARD 인라인 메모 (`← **프론트 대기` 등) |
| **Age (Idle)** | 15% | 0~3일=0, 4~7일=30, 8~14일=60, 22일 이상=100 | GitHub Issue `updated_at` 기준 경과일 |

### 멀티 프로젝트 우선순위

여러 프로젝트(BW, EH, PR, BD 등) 티켓이 섞여 있을 때, Priority Score만으로 결정이 어려우면 아래 추가 기준을 적용한다.

1. **현재 스프린트 포커스 프로젝트** 우선 — `tasks/SPRINT.md`의 Focus 필드 참조
2. **Hotfix / Prod 장애** — 프로젝트 무관, 항상 최우선
3. **동일 점수대**일 때 — 컨텍스트 스위칭 최소화를 위해 같은 프로젝트 티켓을 연속 처리

| Score Range | Tag | 의미 |
|:---|:---|:---|
| 80-100 | `[🔴 긴급]` | 오늘 반드시 처리 |
| 60-79 | `[🟠 높음]` | 오늘 중 착수 |
| 40-59 | `[🟡 보통]` | 이번 주 내 처리 |
| 0-39 | `[🟢 낮음]` | 여유 있을 때 처리 |

---

## Phase 3: Report Generation (Output Structure)

```markdown
# Daily Scrum: {YYYY-MM-DD} ({요일})

---

## 1. 금일 수행 업무 (Work Done)
### {Project} — {Summary}
*   **{Description}** — {Detail}
    - CS/PR/commit 정보

## 2. 익일 계획 (Planned Work)
### 🚨 장기 미결 및 지연 (Overdue & High Risk)
| Priority | Issue | Title | Status | Note |
|:---|:---|:---|:---|:---|
| [🔴 긴급] | [#{ID}](url) | {Title} | {Status} | {Note} |

### 🛠 Main Track & Others
| Priority | Issue | Title | Status | Note |
|:---|:---|:---|:---|:---|
| [🟠 높음] | [#{ID}](url) | {Title} | {Status} | {Note} |

## 3. Sync Summary & 특이사항 (Special Notes)
- 마지막 Sync: {date}
- 동기화된 항목: {N}건
- {Critical Issues, Blockers, 의존성, 일정 리스크 등 백엔드 작업 시 유의점}

```

---

## Execution

### 실행 방법
```
prompts/DAILY_SCRUM.md 기반으로 Daily Scrum 보고서를 생성해줘.
```
