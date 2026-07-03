# GitHub Issue 생성 프롬프트

GitHub Issue를 PRD(Product Requirements Document) 형식으로 생성할 때 사용합니다.
GitHub Issue는 **무엇을(WHAT), 왜(WHY)** 에 집중하며, 비개발자도 이해할 수 있는 언어로 작성합니다.
구현 세부사항(HOW)은 Houston Ticket(`CREATE_TICKET.md`)에서 다룹니다.

---

## 사용법

```
이슈 생성해줘: {요청 내용}
```

또는

```
{요청 내용} 이슈로 만들어줘.
```

---

## 이슈 유형별 템플릿

요청 내용을 분석하여 아래 유형 중 적합한 템플릿을 선택합니다.

| 유형 | 템플릿 | 판단 기준 |
|:---|:---|:---|
| 신규 기능 | `prompts/issue-templates/feature.md` | 새로운 기능 추가, 기존 기능 확장 |
| 버그 | `prompts/issue-templates/bug.md` | 기대와 다른 동작, 오류 |
| 개선 | `prompts/issue-templates/improvement.md` | 성능, 사용성, 코드 품질 개선 |
| QA | `prompts/issue-templates/qa.md` | QA 담당자가 테스트 중 발견한 이슈 (버그 템플릿의 간소화 버전) |
| 인프라 | `prompts/issue-templates/infra.md` | 서버, CI/CD, 환경 구성 |

---

## 생성 절차

### 1. 유형 판단
요청 내용에서 이슈 유형을 판단합니다. 불명확하면 사용자에게 확인합니다.

### 2. 템플릿 읽기
해당 유형의 템플릿 파일(`prompts/issue-templates/{type}.md`)을 읽습니다.

### 3. 내용 작성
- 템플릿의 각 섹션을 요청 내용 기반으로 채웁니다.
- 정보가 부족하면 코드 탐색으로 보충하거나, 사용자에게 질문합니다.
- 추론한 내용은 `[추론]` 태그로 표시합니다.

### 4. 작성 원칙

**DO:**
- 비개발자도 이해할 수 있는 업무 용어 사용
- Scenario는 Given/When/Then 포맷 (업무 언어로)
- Acceptance Criteria는 검증 가능한 조건으로
- 문제의 배경과 근거를 구체적으로

**DON'T:**
- 코드 경로, 함수명, 기술 스택 등 구현 디테일 작성
- CS/IP 구조, 브랜치명 등 Houston Ticket 내용 혼입
- FE/BE 구분 — 이슈는 기능 단위로 작성

### 5. GitHub에 생성
아래 형식으로 `gh api`를 사용하여 생성합니다.

```bash
gh api repos/org/all_issue/issues -X POST \
  -f title="{이모지} {제목}" \
  -f body="$(cat <<'EOF'
{템플릿 기반으로 작성된 본문}
EOF
)" \
  -f "assignees[]={담당자}" \
  -f "labels[]={라벨}" \
  -F milestone={마일스톤번호}
```

- **라벨**: 유형에 맞는 라벨 사용 (예: `✨ feature`, `🐞 bug`, `🔥 enhancement`, `🕵️ qa`, `🛣️ infra`)
- **담당자**: 사용자가 지정한 경우에만 설정. 미지정 시 확인.
- **마일스톤**: `-F milestone={마일스톤ID}` — ID는 `gh api repos/org/all_issue/milestones` 으로 조회
- **프로젝트 필드 설정**: 사용자가 요청한 경우, 이슈를 프로젝트에 추가한 후 GraphQL mutation으로 설정:
  1. `addProjectV2ItemById` — 이슈를 프로젝트에 추가 (Item ID 획득)
  2. `updateProjectV2ItemFieldValue` — Sprint, Status, Part 등 필드 설정

### 6. 결과 보고
생성된 이슈 URL을 사용자에게 전달합니다.

---

## GitHub Issue → Houston Ticket 연결

GitHub Issue(PRD) 생성 후, 구현 착수 시:
1. 사용자가 "T-{Project}-{IssueID} 처리해줘" 요청
2. Agent가 `CREATE_TICKET.md` 프롬프트에 따라 Houston Ticket 생성
3. PRD의 각 섹션이 구현계획의 입력값이 됨:

| GitHub Issue (PRD) | Houston Ticket (구현계획) |
|:---|:---|
| Summary | Ticket Summary |
| Background | 컨텍스트 분석, 관련 코드 탐색 방향 |
| Goal | 완료 기준 |
| Scope In/Out | CS 분할 범위 결정 |
| Scenarios (GWT) | BDD Scenarios → 인수 테스트 1:1 변환 |
| Acceptance Criteria | [Post] 체크리스트 |

---

## 예시

**입력**: "stg_admin 업체에서 스케줄 대시보드 카드형 데이터가 안 보이는 버그 이슈 만들어줘"

**유형 판단**: 버그 → `prompts/issue-templates/bug.md` 사용

**출력**: GitHub Issue 생성 (비개발자도 이해 가능한 PRD 형태)
