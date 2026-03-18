# PM Scrum Report Generator (Team-Wide Management View)

전체 팀원(FE, BE, QA, Design)의 작업 현황을 GitHub에서 직접 조회하여,
역산 스케줄링 기반의 일정 리스크 중심 데일리 미팅 스크립트를 생성합니다.

> **Language**: Korean (한국어)
> **Output Path**: `daily_scrum/{YYYY}/{MM}/{YYYY.MM.DD}-PM-View.md`
> **Snapshot**: `tasks/PM_TASK_BOARD.md` (GitHub 스냅샷, 매회 갱신)

---

## Data Policy: GitHub = Single Source of Truth

PM View는 **GitHub 상태를 그대로** 따릅니다.
Backend View(`DAILY_SCRUM.md`)와 달리, Houston SYNC 프로세스를 거치지 않습니다.

| 원칙 | 설명 |
|:---|:---|
| Source of Truth | GitHub Issue/PR 상태가 곧 진실 |
| Sync 불필요 | `prompts/SYNC.md` 프로세스를 거치지 않음 |
| 담당자 위임 | 각 담당자가 자기 이슈 상태를 GitHub에서 관리. PM은 조회만 |
| 스냅샷 유지 | `tasks/PM_TASK_BOARD.md`에 조회 결과를 저장 (히스토리 추적용) |

---

## 📅 역산 스케줄링(Reverse Scheduling) 원칙

### 1. Sprint & Milestone 마감 원칙

- **Sprint 종료일:** 스프린트에 속한 모든 티켓은 해당 종료일까지 Closed(Done)
- **Milestone 마감일:** 마일스톤 종료 날짜에 맞춰 운영기 배포(Production Deployment) 완료

### 2. 역산 공식 (Backward Estimation)

배포일(Milestone)을 기준으로 역산하여 각 Phase 데드라인을 도출합니다.

```
배포일 (D-Day)
  └── -0.5일: 배포 준비 (롤아웃 + 스모크 테스트)
  └── -2.5일: QA 완료 마감 (수동 검증 2~3 영업일)  ← 병목
  └── -3일:   코드 리뷰 완료 마감 (0.5 영업일)
  └── -4일:   개발 완료 마감 (1 영업일, AI 기반)
  └── -4일 이전: 개발 시작 가능 시점 (Max Limits)
```

**기본 버퍼값**은 `tasks/SPRINT.md`의 **Effort Defaults** 테이블에서 읽습니다.

### 3. AI 공수 추정 규칙

GitHub Issue에 effort/estimate 라벨 또는 본문에 공수 정보가 있으면 해당 값을 사용합니다.
**없으면** AI가 이슈 내용을 기반으로 추정합니다. 추정 기준은 `tasks/SPRINT.md`의 **AI 공수 추정 기준** 테이블을 참조합니다.

추정 시 주의점:
- 개발(Dev)은 모든 개발자가 Claude Code를 사용하므로 기간을 단축 산정
- QA 테스트는 사람이 수동으로 진행하므로 **병목(Bottleneck) 구간으로 간주**, 넉넉한 버퍼 배정
- AI 추정값은 보고서에 `(AI 추정)` 표시를 붙여 명시적 공수와 구분

### 4. 일정 상태 판정

현재 시점과 역산 데드라인을 비교하여 상태를 판정합니다.

| 상태 | 조건 | 표시 |
|:---|:---|:---|
| 🔴 지연 | 역산 데드라인 초과 | `🔴 D+{N}일 지연` |
| 🟠 임박 | 데드라인까지 1일 이내 | `🟠 오늘/내일 마감` |
| 🟡 주의 | 데드라인까지 2~3일 | `🟡 이번 주 내` |
| 🟢 정상 | 여유 있음 | `🟢 정상 진행` |
| ⚪ 미정 | Milestone 미배정 | `⚪ 스프린트 미배정` |

---

## Phase 1: Data Collection (GitHub API)

### 1-1. Sprint/Milestone 정보 로드

```
1. tasks/SPRINT.md 읽기 → Current Sprint, Current Milestone 정보 추출
2. 파일이 없거나 "(미설정)"이면:
   → GitHub Milestone API에서 관리 대상 프로젝트의 활성 Milestone 조회
3. 둘 다 없으면:
   → Output 헤더에 "⚠️ Milestone 미설정 — 역산 스케줄링 불가" 경고
```

### 1-2. 관리 대상 프로젝트 확인

```
1. tasks/SPRINT.md의 "PM 관리 대상 프로젝트" 테이블을 읽는다
2. 각 프로젝트의 GitHub Issue Repo와 GitHub Project(Board) 정보를 추출한다
3. 프로젝트가 없으면: "tasks/SPRINT.md에 관리 대상 프로젝트를 등록하세요." 안내 후 중단
```

### 1-3. GitHub Issue 전체 스캔

관리 대상 프로젝트별로 **전체 팀원**의 이슈를 조회합니다. (assignee 필터 없음)

```
각 프로젝트에 대해:
  - GitHub Project(Board)가 설정 → Board 기반 스캔
  - Board 미설정 → issue_repo에서 open 이슈 전체 조회

수집 항목:
  - Issue number, title, state (open/closed)
  - Assignee (담당자)
  - Labels (priority, bug, qa, frontend, backend 등)
  - Milestone (name, due_date)
  - Linked PR (상태: open/merged/closed)
  - Updated at
```

### 1-4. 파트(Part) 추론 규칙

GitHub Issue에 명시적 파트 태그가 없는 경우, 아래 규칙을 순서대로 적용합니다.

| 우선순위 | 소스 | 추론 규칙 |
|:---|:---|:---|
| 1 | GitHub Label | `frontend`/`fe` → `[FE]`, `backend`/`be` → `[BE]`, `qa`/`bug` → `[QA]`, `design` → `[Design]` |
| 2 | Issue Title | `[FE]`, `[BE]`, `[QA]`, `[Design]` 접두사 패턴 |
| 3 | Assignee | `tasks/SPRINT.md`의 Team Members 테이블에서 Part 매칭 |
| 4 | 추정 불가 | `[?]`로 표시, 보고서에서 "파트 미지정" 경고 |

### 1-5. CHANGESETS.md 참조 (PR 리뷰 병목 감지)

`tasks/CHANGESETS.md`에서 Review 상태의 CS를 수집하여 PR 리뷰 적체를 감지합니다.

| 수집 항목 | 필터 |
|:---|:---|
| Review 대기 CS | Status = Review |
| Review 장기 적체 | Status = Review, 3일 이상 경과 |

### 1-6. 전일 PM 뷰 읽기 (Delta 비교)

`daily_scrum/{YYYY}/{MM}/{전일}-PM-View.md`를 읽어 변화를 추적합니다.

- 전일 PM Action Items 완료 여부 체크
- 전일 🔴 지연 항목의 현재 상태 추적
- 전일 대비 신규 진입/완료 이슈 감지

---

## Phase 2: 역산 분석 & 분류

### 2-1. 각 이슈에 역산 데드라인 계산

```
For each open issue:
  1. Milestone due_date 확인
     → 없으면 Sprint end_date 사용
     → 둘 다 없으면 "⚪ 미정"
  2. Issue 유형 파악 (label, title 기반)
  3. 공수 추정 (Issue 본문 > Label > AI 기본 추정)
  4. 역산:
     deploy_date
       - deploy_buffer
       - qa_buffer
       - review_buffer
       - dev_buffer
       = dev_start_deadline
  5. 현재 상태(open/in-progress/review/closed)와 비교하여 일정 상태 판정
```

### 2-2. 섹션 분류

| 섹션 | 조건 |
|:---|:---|
| 1. 배포 데드라인 & QA 병목 | 🔴 지연 또는 QA 진입 지연 (개발 완료인데 QA 미착수) |
| 2. 개발 진행 중 + 핸드오프 | 🟠/🟡 + In Progress, 파트 간 핸드오프 필요 |
| 3. 신규 버그 & 기타 파트 이슈 | 새로 등록된 이슈, Design, 기타 |
| 4. PR 리뷰 병목 | CHANGESETS에서 Review 3일+ 적체 |

---

## Phase 3: Report Generation (Output Structure)

```markdown
# 👁️ PM 관제 뷰 — {YYYY-MM-DD} ({요일})

**Milestone:** {Milestone Name} (배포 예정일: {Date})
**Sprint:** {Sprint Name} ({Start} ~ {End})
**스캔 범위:** {project names}, 전체 assignee

> QA 병목을 고려한 역산 스케줄링 기반 보고서입니다.
> GitHub 상태를 직접 조회한 결과이며, 각 담당자가 이슈 상태를 관리합니다.

## 1. ⚠️ 배포 데드라인 & QA 병목 점검
**미팅 질문:** "QA 수동 검증에 시간이 얼마나 더 필요한가요? 오늘 반드시 QA로 넘겨야 하는 티켓은?"

| 티켓 | 파트 | 담당자 | 역산 상태 | Status | PM 체크 포인트 |
|:---|:---:|:---:|:---:|:---|:---|
| [#{ID}](url) {Title} | `[QA]` | @handle | 🔴 D+2일 지연 | In Progress | *개발 지연으로 QA 시간 부족* |

## 2. 🚧 개발 진행 중 — 팀 간 연계 점검
**미팅 질문:** "BE API 배포됐으니 FE에서 오늘 당장 붙일 수 있나요? 막히는 점 있나요?"

| 티켓 | 파트 | 담당자 | 역산 상태 | Status | PM 체크 포인트 |
|:---|:---:|:---:|:---:|:---|:---|
| [#{ID}](url) {Title} | `[FE/BE]` | @handle | 🟡 이번 주 내 | In Progress | *프론트 연동 대기 중* |

## 3. 🐞 신규 버그 & 기타 파트 이슈
**미팅 질문:** "새로 들어온 버그 중 이번 스프린트에 포함할 건 무엇인가요? 스프린트 조정이 필요한가요?"

| 티켓 | 파트 | 담당자 | 우선순위 | Status | 이슈 내용 |
|:---|:---:|:---:|:---:|:---|:---|
| [#{ID}](url) {Title} | `[Design]` | @handle | P1 | Open | {Note} |

## 4. 📋 PR 리뷰 병목 (3일+ 적체)
**미팅 질문:** "리뷰가 밀린 PR이 있습니다. 오늘 중 리뷰 가능한 분?"

| PR | 티켓 | 담당자 | 리뷰어 | 대기 일수 | 비고 |
|:---|:---|:---:|:---:|:---:|:---|
| PR #{N} | #{ID} | @author | @reviewer | 5일 | *머지 지연으로 QA 일정 영향* |

---

## 전일 대비 변화 (Delta)
- ✅ 완료: {전일 대비 새로 닫힌 이슈 N건}
- 🆕 신규: {전일 대비 새로 등록된 이슈 N건}
- ⚠️ 전일 Action Item 미완료: {미처리 항목}

## PM Action Items
- [ ] {구체적 액션}
- [ ] {구체적 액션}

*Generated: {timestamp} | Source: GitHub API (direct query)*
```

---

## Phase 4: PM_TASK_BOARD.md 스냅샷 갱신

보고서 생성 후, `tasks/PM_TASK_BOARD.md`를 GitHub 조회 결과로 갱신합니다.

### 스냅샷 구조

```markdown
# PM Task Board (GitHub Snapshot)

> Last Updated: {YYYY-MM-DD HH:MM}
> Source: {project names} — GitHub API direct query

## [{Project Name}]

### [BE] Backend
| Issue | Title | Assignee | Status | Milestone | Priority |
|:---|:---|:---|:---|:---|:---|
| [#{ID}](url) | {Title} | @handle | Open | {Milestone} | P1 |

### [FE] Frontend
| Issue | Title | Assignee | Status | Milestone | Priority |
|:---|:---|:---|:---|:---|:---|

### [QA] Quality Assurance
| Issue | Title | Assignee | Status | Milestone | Priority |
|:---|:---|:---|:---|:---|:---|

### [?] Part Unassigned
| Issue | Title | Assignee | Status | Milestone | Priority |
|:---|:---|:---|:---|:---|:---|
```

> 이 파일은 매 PM 스크럼 실행 시 덮어씌워집니다.
> Git 히스토리를 통해 시점별 상태를 추적할 수 있습니다.

---

## Execution

### 실행 방법
```
prompts/PM_SCRUM.md 기반으로 PM View 데일리 스크럼 보고서를 생성해줘.
```

### 사용하는 MCP Tools

| Tool | 용도 |
|:---|:---|
| `mcp__github__search_issues` | 프로젝트 전체 이슈 검색 |
| `mcp__github__get_issue` | 개별 이슈 상세 (milestone, labels) |
| `mcp__github__list_issues` | 레포별 이슈 목록 |
| `mcp__github__get_pull_request` | PR 상태 확인 |
| `Read` | tasks/SPRINT.md, tasks/CHANGESETS.md, 전일 PM 뷰 |
| `Write` / `Edit` | PM_TASK_BOARD.md 스냅샷 갱신, 보고서 생성 |

### 주의사항

1. **GitHub 쓰기 금지**: PM View는 읽기 전용. Issue를 닫거나, Label을 변경하지 않는다.
2. **공수 추정 투명성**: AI 추정값에는 반드시 `(AI 추정)` 표시를 붙인다.
3. **관리 프로젝트 미설정 시**: `tasks/SPRINT.md`에 프로젝트 등록을 안내하고 중단한다.
4. **Milestone 미설정 시**: 역산 스케줄링 없이 Priority Label 기반으로 fallback 정렬한다.
