# Daily Scrum Report Generator

Sync가 완료된 상태에서 Daily Scrum 보고서를 생성합니다.
데이터 수집은 **로컬 문서 기반**으로, GitHub API 호출을 최소화합니다.

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

### 1-1. TASK_BOARD.md 읽기

`tasks/TASK_BOARD.md`에서 전체 티켓 상태를 수집한다.

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

### 1-4. Active Ticket Workspace Git Log

fleet.yaml의 프로젝트 디렉터리에서 활성 ticket workspace들의 git log를 확인한다.

```bash
# 각 프로젝트 디렉터리 스캔
# 예: my-project/T-BW-1702-*/
#   → git log --oneline --since="today 00:00" (오늘 커밋 목록)
#   → git status (uncommitted changes 유무)
```

---

## Phase 2: Priority Score 계산

각 Active 티켓에 대해 Priority Score를 산정한다.

### Priority Matrix

| Factor | Weight | Scoring |
|:---|:---|:---|
| **Urgency (Label)** | 40% | P0=100, P1=70, P2=40, P3=20, None=30 |
| **Due Date** | 30% | (아래 키워드 테이블 참조) |
| **Quick Win** | 20% | 1시간 이내=100, 반나절=70, 하루=50, 이틀+=30 |
| **Dependency** | 10% | 독립 실행=100, FE 대기=50, 외부 의존=30, Blocked=0 |
| **Category** | Bonus | QA/Bug=+10 |

### Final Score

```
Score = (Urgency * 0.4) + (DueDate * 0.3) + (QuickWin * 0.2) + (Dependency * 0.1) + Bonus
```

| Score Range | Tag | 의미 |
|:---|:---|:---|
| 80-100 | `[🔴 긴급]` | 오늘 반드시 처리 |
| 60-79 | `[🟠 높음]` | 오늘 중 착수 |
| 40-59 | `[🟡 보통]` | 이번 주 내 처리 |
| 0-39 | `[🟢 낮음]` | 여유 있을 때 처리 |

### Due Date Keywords (한/영 매핑)

| Keyword | DueDate Score |
|:---|:---|
| 오늘, today, ASAP | 100 |
| 내일, tomorrow | 80 |
| 이번 주, this week | 60 |
| 다음 주, next week | 40 |
| 미정, TBD | 20 |

### Quick Win 판단 기준

| 조건 | 점수 |
|:---|:---|
| 코드 변경 1-2 파일, 로직 단순 | 100 (1시간 이내) |
| 코드 변경 3-5 파일, 테스트 필요 | 70 (반나절) |
| 여러 서비스 연동, DB 마이그레이션 | 50 (하루) |
| 설계 검토 필요, 대규모 리팩토링 | 30 (이틀+) |

### Dependency 판단 기준

| 상태 | 점수 |
|:---|:---|
| 독립 실행 가능 | 100 |
| FE 배포 대기 | 50 |
| 외부 의존 (타팀/고객사) | 30 |
| Blocked (선행 작업 미완료) | 0 |

### Idle State Logic

- **Definition**: Status가 Active/In Progress이지만 `updated_at` < Today 00:00
- **판단**: TASK_BOARD.md 주석의 날짜, CHANGESETS.md 날짜, ticket workspace git log 기준
- **표시**: Note 컬럼에 `Idle {N}일` 추가

---

## Phase 3: Report Generation

### Output Structure

```markdown
# Daily Scrum: {YYYY-MM-DD} ({요일})

---

## 금일 수행 업무 (Work Done)

### {Project} — {Summary}
*   **{Description}** — {Detail}
    - CS/PR/commit 정보
*   ...

---

## 익일 계획 (Planned Work)

### 1. 🚨 장기 미결 및 지연 (Overdue & High Risk)

| Priority | Issue | Title | Status | Note |
|:---|:---|:---|:---|:---|
| [🔴 긴급] | [#{ID}](url) | {Title} | {Status} | {Note} |

### 2. {Project} — Main Track

| Priority | Issue | Title | Status | Note |
|:---|:---|:---|:---|:---|
| [🟠 높음] | [#{ID}](url) | {Title} | {Status} | {Note} |

### 3. QA 대응 및 기타

| Priority | Issue | Title | Status | Note |
|:---|:---|:---|:---|:---|
| [🟡 보통] | [#{ID}](url) | {Title} | {Status} | {Note} |

### 4. Idle (Low Priority)

| Issue | Title | Status | Note |
|:---|:---|:---|:---|
| [#{ID}](url) | {Title} | {Status} | Idle {N}일 |

---

## Sync Summary

- 마지막 Sync: {date}
- 동기화된 항목: {N}건
- 수동 확인 필요: {N}건 (있으면 항목 나열)

---

## 특이 사항 (Special Notes)
*   {Critical Issues, Blockers, 의존성, 일정 리스크}

*Data Source: TASK_BOARD.md, CHANGESETS.md, git log*
```

### Smart Merge Rules (기존 파일 업데이트 시)

1. **Preserve Manual Entries**: "특이 사항"이나 수동으로 추가한 항목은 절대 삭제하지 않는다.
2. **Move Completed**: 어제 "익일 계획"에 있던 항목 중 오늘 완료된 것은 "금일 수행 업무"로 이동한다.
3. **Append New**: 새로 동기화된 티켓은 적절한 섹션에 추가한다.
4. **Sort by Priority**: 각 섹션 내에서 Priority Score 내림차순 정렬한다.

### Section Assignment Rules

| 조건 | 배치 섹션 |
|:---|:---|
| Overdue (Target Date 경과) OR P0 | 🚨 장기 미결 및 지연 |
| Active + Priority Score 40+ | {Project} — Main Track |
| label: qa OR bug (최근 등록) | QA 대응 및 기타 |
| Active + Idle (금일 업데이트 없음) + 비긴급 | Idle (Low Priority) |
| Stage/Test 배포 대기 | 별도 섹션 (필요 시) |

---

## Execution

### 실행 방법
```
prompts/DAILY_SCRUM.md 기반으로 Daily Scrum 보고서를 생성해줘.
```

### Project Codes

| Project | Code | Ticket Prefix |
|:---|:---|:---|
| My Project | BW | `T-BW-{ID}` |
| Fourth Project | BD | `T-BD-{ID}` |
| Third Project | PR | `T-PR-{ID}` |
| Another Project | EH | `T-EH-{ID}` |
| Fifth Project | IM | `T-IM-{ID}` |
| Infrastructure | INFRA | `T-INFRA-{ID}` |

### Priority Labels (GitHub)

| Label | Urgency Score |
|:---|:---|
| `priority:P0`, `critical`, `urgent` | 100 |
| `priority:P1`, `high` | 70 |
| `priority:P2`, `medium` | 40 |
| `priority:P3`, `low` | 20 |
| (no label) | 30 |
