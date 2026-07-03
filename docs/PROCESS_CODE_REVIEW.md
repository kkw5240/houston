# PR Review Workflow (2-Stage: OMC + Gemini CLI)

> **Last Updated**: 2026-04-01

## Overview

2단계 병행 리뷰 + Approved까지 반복 루프.

- **Step 1**: OMC `/oh-my-claudecode:code-review` (로컬, 즉시 피드백) → Approved 시 Step 2로
- **Step 2**: gemini-cli (GitHub에 리뷰 등록) → Approved 시 루프 종료
- **종료 조건**: Step 1 + Step 2 양쪽 모두 Approved
- **Request Changes 시**: 피드백 반영 → 수정 → 재커밋 → Step 1부터 재실행 (양쪽 재검증)

## Gemini CLI Setup (one-time)
```bash
GH_TOKEN=$(gh auth token) && gemini mcp add github npx -s user -e "GITHUB_PERSONAL_ACCESS_TOKEN=$GH_TOKEN" -- -y @modelcontextprotocol/server-github
```

## Gemini Review Command

> **주의**: 같은 GitHub 토큰으로 PR 생성/리뷰하면 "Cannot approve own PR" 에러 발생. 반드시 **COMMENT 이벤트**로 리뷰 등록해야 함.

```bash
gemini -y -o text "PR_FULL_URL 이 PR의 변경된 코드 파일들을 GitHub MCP 도구로 읽어서 코드 리뷰해줘. Critical, Major, Minor로 분류해서 한국어로 작성해줘. 리뷰 완료 후 Approve 또는 Request Changes 판정도 해줘. GitHub에 리뷰를 등록할 때는 COMMENT 이벤트로 해줘."
```

## Workflow Detail
```
1. PR 생성 (gh pr create)
2. Step 1: OMC code-review (로컬)
3. Step 2: gemini로 코드리뷰 요청
4. 리뷰 반영 검토 (표 형태로 정리):
   - 반영: 코드 수정 + 커밋 + push
   - 현행 유지: 프로젝트 패턴 일관성 등 사유 명시
   - 스킵: black 자동 포매팅 등 도구 결과, 범위 밖
5. 반영 결과를 gh pr comment로 등록
6. 별도 이슈 필요한 건 → gh issue create
7. 양쪽 Approved → 머지
```

## Notes
- gemini의 web_fetch는 private repo 접근 불가 → GitHub MCP 필수
- `-y` 플래그: 도구 사용 자동 승인 (yolo mode)
- `-o text`: 텍스트 출력 (JSON 아닌)
- timeout 넉넉히 설정 (300s)
- **COMMENT 이벤트 사용**: 같은 GitHub 토큰으로 PR 생성/리뷰하면 "Cannot approve own PR" 에러 발생. APPROVE 대신 COMMENT 이벤트로 리뷰 등록
