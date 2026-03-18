# Process: Git Conventions

> **Authoritative source**: `.houston/PROCESSES.md` §3. This file is the detailed reference.

## Git 전략은 Repo에서 정의한다

Houston은 업무 거버넌스(티켓, 증거, 프로세스)를 소유하며,
Git 브랜칭 전략, 커밋 포맷, PR 규칙 등 구현 컨벤션은 **각 repo의 CLAUDE.md**에 위임한다.

### 왜?

- 각 repo는 서로 다른 CI/CD 파이프라인, 배포 환경, 팀 구성을 가진다.
- Houston이 하나의 Git 전략을 강제하면 repo의 실제 운영과 충돌한다.
- AI agent가 Houston의 전략과 repo의 전략 사이에서 혼동할 수 있다.

### Houston이 소유하는 것

| 항목 | 설명 |
|:---|:---|
| Ticket 시스템 | `T-{Project}-{ID}` 체계 |
| CHANGESETS / TASK_BOARD | 작업 상태 추적 |
| Evidence-based completion | 증거 없이 Done 불가 |
| Hotfix Fast Track 프로세스 | 긴급 대응 시 무엇을 생략하고 무엇을 유지하는가 |

### Repo가 소유하는 것

| 항목 | 설명 |
|:---|:---|
| Base branch | `fleet.yaml`의 `branch` 필드로 결정 |
| Branch naming | Repo CLAUDE.md에서 정의 |
| Commit message format | Repo CLAUDE.md에서 정의 |
| PR rules | Repo CLAUDE.md에서 정의 |
| 브랜칭 전략 (flow) | Repo CLAUDE.md 또는 repo `docs/processes/`에서 정의 |
| Stage/배포 관리 | Repo 자체 스크립트 및 CI/CD |

### Repo에 CLAUDE.md가 없는 경우

`fleet.yaml`의 `branch` 필드에서 base branch를 확인하고,
해당 branch에서 분기 → 같은 branch로 PR하는 기본 흐름을 따른다.
커밋 메시지는 Houston 기본값(`.houston/RULES.md` Commit Rules)을 적용한다.

### 각 Repo의 Git 전략 문서 위치

| Repo | 전략 문서 |
|:---|:---|
| BW (My Project) | `CLAUDE.md` + `docs/processes/GIT_STRATEGY.md` |
| 기타 | 각 repo의 `CLAUDE.md` 참조 |
