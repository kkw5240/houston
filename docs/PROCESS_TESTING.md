# Process: Testing Strategy (TDD + BDD Hybrid)

> **Authoritative source**: `.houston/PROCESSES.md` §2. This file is the detailed reference.
> Inline agent instructions (CLAUDE.md etc.) are auto-generated from `.houston/` — keep them in sync.

> **Source**: Extracted from `workspace/README.md` (Legacy) and `docs/guides/AI_AGENT_GUIDE.md`.

## 1. Core Philosophy

This workspace adopts a **TDD + BDD Hybrid** approach:

> **Core Principle**: Ticket의 Scenario가 곧 테스트 명세이다.
>
> - BDD로 요구사항을 시나리오로 정의하고, 인수 테스트를 **먼저** 작성
> - TDD로 세부 기능을 구현하여 인수 테스트를 통과시킴
> - 커밋 시 인수 테스트만 포함, Unit Test는 로컬 개발용

## 2. Development Workflow (Red-Green-Refactor)

```
┌─────────────────────────────────────────────────────────────┐
│  1. Ticket 작성: BDD 시나리오 정의 (Given-When-Then)          │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  2. 개발 시작 전: 인수 테스트 먼저 작성 (Red 상태)            │
│     └── Scenario 1개 = 인수 테스트 1개 (1:1 매핑)            │
│     └── 이 시점에서 테스트는 실패함 (아직 구현 안됨)          │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  3. 개발 중: 인수 테스트를 Green으로 만들기 위해 TDD 진행     │
│     ├── 세부 기능 A: Unit Test 작성 → 구현 → 통과            │
│     ├── 세부 기능 B: Unit Test 작성 → 구현 → 통과            │
│     └── (반복)                                              │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  4. 개발 완료: 모든 인수 테스트 자동으로 Green               │
│     └── 세부 기능들이 완성되면서 인수 테스트도 통과됨         │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  5. 커밋: 인수 테스트만 포함, Unit Test 제외                 │
└─────────────────────────────────────────────────────────────┘
```

## 3. Test Types & Roles

| 테스트 종류 | 목적 | 작성 시점 | 커밋 여부 |
| :--- | :--- | :--- | :--- |
| **인수 테스트** | 요구사항 충족 증명, 회귀 방지 | 개발 시작 전 (Red) | ✅ 커밋 |
| **Unit Test** | 빠른 피드백, 설계 검증, 디버깅 | 개발 중 | ❌ 로컬만 |

## 4. BDD Scenario Rules

모든 Ticket의 `## Scenarios (BDD)` 섹션에 다음 형식으로 작성합니다.

### 4.1 Scenario Format (Given-When-Then)

```gherkin
### Scenario: {시나리오 제목}
Given {사전 조건}
When {행동/API 호출}
Then {기대 결과}
And {추가 검증} (선택)
```

### 4.2 Guidelines

| 원칙 | 설명 |
| :--- | :--- |
| **Happy Path 우선** | 정상 동작 시나리오 1개 필수 |
| **핵심 실패 케이스만** | 비즈니스적으로 중요한 실패만 (모든 에러 커버 X) |
| **API 레벨로 작성** | 내부 구현이 아닌 입력/출력 관점 |
| **최소 개수** | 일반적으로 1-3개, 최대 5개 |

## 5. Implementation Guide (For Agents)

### 5.1 Scenario → Acceptance Test Mapping

```
Scenario 1개 = 인수 테스트 함수 1개 (1:1 매핑)
```

### 5.2 Acceptance Test Template (Representative)

```python
"""
티켓: T-{ID}
시나리오: {시나리오 제목}
"""
class Test_{기능명}:

    def test_{시나리오_제목}(self, client, 기본_환경):
        # Given: {사전 조건}
        company_no = 기본_환경["company"].company_no

        # When: {행동/API 호출}
        response = client.patch(
            f"/companies/{company_no}",
            json={"is_tutorial": True}
        )

        # Then: {기대 결과}
        assert response.status_code == 200

        # And: {추가 검증}
        assert response.json()["is_tutorial"] == True
```

### 5.3 Agency Rules

1. **Ticket의 Scenarios (BDD) 섹션 확인** - 여기에 정의된 것만 테스트
2. **1 Scenario = 1 Test** - 엄격히 준수
3. **Mock 최소화** - 실제 DB/API 사용 권장
4. **입력/출력만 검증** - 구현 세부사항 검증 금지

## 6. Pre-Merge Verification Checklist

Before creating a PR, verify:

1. **Acceptance Test First**: 인수 테스트가 개발 전에 작성되었는지
2. **All Green**: 모든 인수 테스트 통과 (`pytest`)
3. **No Regression**: 기존 테스트가 깨지지 않음
4. **Unit Test 제외**: 로컬 Unit Test가 커밋에 포함되지 않음
5. **Linting**: No critical lint errors (if configured)

## 7. Test File Organization

```
tests/
├── acceptance/            # 인수 테스트 (커밋 대상)
│   ├── test_{domain}_scenarios.py
│   └── conftest.py
├── regression/            # 버그 재현 테스트
│   └── test_T_{ticket_id}.py
├── fixtures/              # 테스트 데이터 팩토리
│   └── factories.py
└── unit/                  # Unit Test (커밋 안함)
    └── ...
```

> **Note**: `tests/unit/` 디렉토리는 `.gitignore`에 추가하여 로컬 개발용 Unit Test가 실수로 커밋되지 않도록 권장.

## 8. Common Commands

```bash
# Python (pytest)
pytest tests/acceptance/   # 인수 테스트만 실행
pytest                     # 전체 테스트 실행

# Flutter
flutter test

# JavaScript/TypeScript
npm test
```
