# Workflow: Repo-per-Ticket (Disposable Workspace)

> **Authoritative source**: `.houston/PROCESSES.md` §1. This file is the detailed reference.
> Inline agent instructions (CLAUDE.md etc.) are auto-generated from `.houston/` — keep them in sync.

> **Source**: Extracted from `workspace/README.md` (Legacy) and `docs/guides/AI_AGENT_GUIDE.md`.

## 1. Concept: Disposable Workspace

동시에 여러 티켓을 처리할 때 발생하는 **환경 오염**과 **컨텍스트 스위칭** 문제를 해결하기 위해 **티켓 단위 격리(Repo-per-Ticket)** 워크플로우를 사용합니다.

### 1.1 Problem: Single Workspace 방식의 한계

| 문제 | 설명 |
|------|------|
| **물리적 병렬 처리 불가** | 티켓 A 작업 중 티켓 B 긴급 수정 시 git stash 필요. 서버 포트도 하나뿐. |
| **환경 오염 위험** | .env, DB 설정이 섞여 있어 티켓 간 설정 충돌 발생 가능 |
| **Human Error** | 잘못된 브랜치에서 작업 시작, develop에 직접 커밋 등 실수 |

### 1.2 Solution: Disposable Workspace

```
workspace/
├── my-project/
│   ├── source/                       # [Source] Read-Only 원본 (항상 최신 remote)
│   ├── T-XX-100-feature-a/     # [Ticket A] 격리된 작업 공간
│   └── T-XX-200-urgent-fix/         # [Ticket B] 격리된 작업 공간
└── scripts/                          # Workspace 자동화 스크립트
```

### 1.3 Workflow: Copy & Spawn → Use & Destroy

1.  **Source Repo = Template**
    *   `source/` (구 master)는 항상 최신 remote 상태 유지
    *   여기서 직접 코딩하지 않음 (Read-Only 권장)

2.  **Copy & Spawn** (티켓 시작)
    ```bash
    ./scripts/new_ticket.sh ../my-project/source T-XX-100 feature-a
    # Creates: my-project/T-XX-100-feature-a/
    ```
    - Source를 통째로 복사하여 격리된 환경 생성
    - 서버 포트, DB 설정을 자유롭게 변경 가능

3.  **Use & Destroy** (티켓 완료)
    ```bash
    ./scripts/close_ticket.sh ./my-project/T-XX-100-feature-a
    ```
    - PR 머지 후 티켓 폴더 삭제
    - 디스크 공간 회수

### 1.4 Benefits

| 장점 | 설명 |
|------|------|
| **완전한 격리** | 티켓 A의 변경이 티켓 B에 영향 없음 |
| **병렬 처리** | 여러 서버를 동시에 띄워 비교 가능 |
| **롤백 용이** | 문제 발생 시 폴더만 삭제하면 원복 |
| **인지 부하 감소** | 브랜치 전환 없이 폴더만 이동 |

---

## 2. Execution Guide (How-to)

**Repo-per-Ticket** 모델에서 AI Agent가 티켓을 실행하는 방법입니다.

### 2.1 When to Use

- 프로젝트 그룹 폴더 구조가 설정된 경우 (e.g., `../my-project/source/`)
- 동시에 여러 티켓을 처리해야 하는 경우
- 환경 격리가 필요한 경우

### 2.2 Execution Flow

```
1. 티켓 폴더 확인/생성
   └── scripts/new_ticket.sh 사용 또는 수동 복사

2. 티켓 폴더로 이동
   └── cd lines-{project}/{ticket-folder}/

3. 일반 티켓 실행 프로세스 진행
   └── [Pre] → [Tasks] → [Post]

4. 완료 후 정리
   └── scripts/close_ticket.sh 사용 또는 수동 삭제
```

### 2.3 Script Usage

**티켓 시작:**
```bash
./scripts/new_ticket.sh <MASTER_PATH> <TICKET_ID> [DESCRIPTION]
# Example:
./scripts/new_ticket.sh ../my-project/source T-XX-100 "login-fix"
# Creates: my-project/T-XX-100-feature-a/
# Branch: feat/T-XX-100-feature-a
```

**티켓 종료:**
```bash
./scripts/close_ticket.sh <TICKET_PATH>
# Example:
./scripts/close_ticket.sh ./my-project/T-XX-100-feature-a
# Checks unpushed commits, then deletes folder
```

### 2.4 Important Rules

1. **Source Repo 보호**: `source/` 폴더에서 직접 작업하지 않음
2. **폴더 명명**: `T-{ProjectCode}-{IssueID}-{description}` 형식 준수
3. **브랜치 생성**: 티켓 폴더 내에서 `feat/T-{ID}--CS-01` 브랜치 생성
4. **정리 필수**: PR 머지 후 티켓 폴더 삭제 (디스크 관리)

### 2.5 Without Scripts (Manual Process)

스크립트가 없는 경우 수동으로 진행:

```bash
# 1. Source 업데이트
cd ../my-project/source
git pull origin stage

# 2. 티켓 폴더 생성 (복사)
cp -R . ../T-XX-100-feature-a
cd ../T-XX-100-feature-a

# 3. 브랜치 생성
git checkout -b feat/T-XX-100-feature-a

# 4. 작업 진행...

# 5. 완료 후 삭제 (unpushed commits 확인 후)
cd ..
rm -rf T-XX-100-feature-a
```

---

## 3. Parallel Work (Sub-Issues / Independent Tasks)

When the user requests multiple tasks at once (e.g., sub-issues within one parent issue, or independent tickets):

1. **Each task gets its own workspace** — Repo-per-Ticket applies per task, not per session
   - Task A → `T-{ID-A}-{desc}/` + branch `feat/T-{Project}-{ID-A}--CS-{Seq}`
   - Task B → `T-{ID-B}-{desc}/` + branch `feat/T-{Project}-{ID-B}--CS-{Seq}`
2. **Same repo is OK** — multiple ticket workspaces can copy from the same `source/`
3. **No cross-contamination** — never mix changes from different tasks in one workspace
4. **Track separately** — each task gets its own CS row in `tasks/CHANGESETS.md`
5. **Evidence per task** — each task must have its own commit hash / PR link
6. **TASK_BOARD.md** shows parallel status — multiple items in "In Progress" is normal

> Parallel work is safe because Repo-per-Ticket guarantees physical isolation.
> If two tasks modify the same file, conflicts are resolved at PR merge time — not in the workspace.

**Priority decision criteria** (highest first):

1. **Hotfix / Production incident** — always top priority
2. **User-specified priority** — "A 먼저 해줘" etc.
3. **Blocker resolution** — unblocks another task's dependency
4. **Quick Win** — shortest time to completion
5. **FIFO** — when none of the above apply

When uncertain, ask the user.
