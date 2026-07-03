# 프로젝트 문서화 표준

> **작성일**: 2026-03-18
> **목적**: 모든 프로젝트에서 일관된 문서 구조를 유지하여, 개발·인수인계·온보딩·유지보수 전 과정에서 문서가 실질적으로 동작하게 한다.

---

## 1. 왜 문서를 표준화하는가

프로젝트마다 문서 구조가 다르면:
- 새 프로젝트에 투입될 때마다 "문서가 어디 있지?"부터 시작해야 함
- 인수인계 시 매번 다른 형태의 문서를 만들어야 함
- 유지보수 담당자가 바뀔 때마다 학습 비용이 반복됨

표준 구조가 있으면:
- 어떤 프로젝트든 `docs/entities/`를 열면 도메인 설계가 있다는 것을 알 수 있음
- 인수인계 문서가 `docs/handover/`에 있다는 것을 알 수 있음
- 한 프로젝트에서 익힌 탐색 경로가 다른 프로젝트에서도 동일하게 적용됨

---

## 2. 표준 문서 구조

### 디렉토리 레이아웃

```
{project}/docs/
├── README.md                    ← 이 프로젝트의 문서 안내 (진입점)
│
├── entities/                    ← 도메인별 설계 (Single Source of Truth)
│   └── {domain}/
│       ├── uc.md                ← 유즈케이스 (Use Case)
│       ├── br.md                ← 비즈니스 규칙 (Business Rules)
│       ├── model.md             ← 도메인 모델 (엔티티, 관계, 제약조건)
│       ├── data_dep.md          ← 데이터 의존성 맵
│       └── gherkin.md           ← 인수 테스트 시나리오 (선택)
│
├── api/                         ← API 스펙
│   └── {domain}/
│       ├── endpoints.md         ← 엔드포인트 목록 + 요청/응답
│       └── errors.md            ← 에러 코드 + 발생 조건
│
├── processes/                   ← 업무 프로세스 흐름
│   └── {process_name}.md        ← 예: payroll_calculation.md, approval_workflow.md
│
├── guides/                      ← 운영·환경·배포 가이드
│   ├── setup.md                 ← 로컬 개발 환경 구성
│   ├── deployment.md            ← 배포 절차
│   └── {기타 가이드}.md
│
├── histories/                   ← PR/변경 이력 (불변 기록)
│   └── {YYYY-MM-DD}_{설명}.md   ← 예: 2026-03-17_payroll-meal-fix.md
│
└── handover/                    ← 인수인계 문서 (전환 시점에 생성)
    ├── SERVICE_PROFILE.md
    ├── DATA_MODEL.md
    ├── API_CATALOG.md
    ├── BUSINESS_RULES.md
    ├── OPERATIONS.md
    └── KNOWN_ISSUES.md
```

### 각 디렉토리의 역할

| 디렉토리 | 역할 | 갱신 시점 | 비고 |
|:---------|:-----|:---------|:-----|
| `entities/` | 도메인 설계의 원본 | 도메인 변경 시 | **가장 중요. Docs-First 원칙의 핵심** |
| `api/` | API 계약 | API 추가/변경 시 | 클라이언트와의 계약 |
| `processes/` | 업무 흐름 정의 | 프로세스 변경 시 | 복잡한 업무 흐름이 있을 때만 |
| `guides/` | 실행 절차 | 환경/배포 변경 시 | 따라하면 동작해야 함 |
| `histories/` | 변경 기록 | PR 머지 시 | 불변. 왜 바꿨는지 기록 |
| `handover/` | 인수인계 스냅샷 | 담당자 전환 시 | entities/api에서 추출 |

---

## 3. 문서 작성 원칙

### Docs-First (문서 먼저)

> **코드를 작성하기 전에 설계 문서를 먼저 작성한다.**

- 기능 추가/변경 시: `entities/{domain}/`의 해당 문서를 먼저 갱신
- API 변경 시: `api/{domain}/endpoints.md`를 먼저 갱신
- 코드는 문서에 적힌 설계를 구현하는 것

**왜**: 문서가 먼저 있으면 코드 리뷰 시 "의도대로 구현했는가"를 판단할 수 있음. 코드만 있으면 "이게 맞는 건가"를 판단할 근거가 없음.

### 도메인 단위 관리

- 문서는 기능(티켓)별이 아니라 **도메인별**로 관리
- 티켓 작업 시 해당 도메인 문서를 **갱신**하는 방식
- ❌ `docs/designs/T-1234-feature-x.md` (티켓별 — 시간이 지나면 파편화)
- ✅ `docs/entities/payroll/br.md` (도메인별 — 항상 최신 상태 유지)

### 변경 이력은 histories/에

- `docs/histories/`에 PR 단위로 이력을 기록
- 코드 PR에 포함시켜 같은 PR에서 머지 (별도 PR 금지)
- 형식: `{YYYY-MM-DD}_{설명}.md`

---

## 4. 프로젝트 라이프사이클별 문서 가이드

### 4.1 개발 착수 — 최소 필수 문서

프로젝트 시작 시 아래 구조를 생성하고, 핵심 도메인부터 채워나갑니다.

```
docs/
├── README.md                     ← 프로젝트 소개, 문서 구조 안내
├── entities/
│   └── {핵심도메인}/
│       ├── uc.md                  ← 주요 유즈케이스 (기획서 기반)
│       └── br.md                  ← 핵심 비즈니스 규칙
├── guides/
│   └── setup.md                   ← 로컬 환경 구성 방법
└── histories/                     ← 빈 디렉토리 (PR부터 누적)
```

**이 단계의 핵심**: UC와 BR을 먼저 쓰면 "뭘 만들어야 하는지"가 명확해짐. 이것이 곧 설계.

### 4.2 개발 진행 — 스프린트 중 갱신

| 작업 | 문서 갱신 |
|:-----|:---------|
| 새 도메인 추가 | `entities/{domain}/` 디렉토리 생성, uc.md + br.md 작성 |
| API 추가/변경 | `api/{domain}/endpoints.md` 갱신 |
| 버그 수정 | `histories/` 이력 추가. 비즈니스 규칙 발견 시 br.md 보강 |
| 프로세스 정의 | `processes/{name}.md` 작성 |
| 환경/배포 변경 | `guides/` 갱신 |

### 4.3 인수인계 — handover/ 생성

담당자가 바뀔 때, 개발 중 쌓인 문서에서 인수인계 스냅샷을 생성합니다.

```
추출 관계:

entities/{domain}/br.md (여러 도메인)  ──→  handover/BUSINESS_RULES.md (통합)
entities/{domain}/model.md            ──→  handover/DATA_MODEL.md (통합)
api/{domain}/endpoints.md             ──→  handover/API_CATALOG.md (통합)
guides/setup.md + deployment.md       ──→  handover/OPERATIONS.md (통합)
(코드 분석)                            ──→  handover/SERVICE_PROFILE.md
(경험 기반)                            ──→  handover/KNOWN_ISSUES.md
```

> 인수인계 템플릿은 `docs/templates/handover/`에 있습니다.
> 개발 중 entities/api/guides를 잘 유지했다면, handover/ 생성은 대부분 추출+통합 작업입니다.

### 4.4 신규 인원 온보딩 — 읽는 순서

새 담당자가 프로젝트에 투입될 때 권장하는 독서 순서:

| 순서 | 문서 | 목적 | 소요 |
|:-----|:-----|:-----|:-----|
| 1 | `docs/README.md` | 프로젝트 개요 파악 | 5분 |
| 2 | `handover/SERVICE_PROFILE.md` | 기술 스택, 구조 파악 | 10분 |
| 3 | `handover/KNOWN_ISSUES.md` | 위험 영역 사전 인지 | 10분 |
| 4 | `handover/BUSINESS_RULES.md` | 비즈니스 규칙 파악 | 15분 |
| 5 | `guides/setup.md` | 로컬 환경 구성 | 30분 |
| 6 | `handover/OPERATIONS.md` | 배포, 장애 대응 숙지 | 10분 |

> handover/가 없는 프로젝트는 `entities/`와 `guides/`를 직접 읽습니다.

### 4.5 유지보수 — 지속 갱신

| 상황 | 갱신 대상 |
|:-----|:---------|
| 버그 수정 시 | `histories/` 이력 추가 |
| 새 규칙 발견 시 | `entities/{domain}/br.md` 추가 |
| 지뢰밭 발견 시 | `handover/KNOWN_ISSUES.md` 추가 |
| API 변경 시 | `api/{domain}/endpoints.md` + `handover/API_CATALOG.md` 갱신 |
| 환경 변경 시 | `guides/` + `handover/OPERATIONS.md` 갱신 |

---

## 5. entities/ 상세 — 도메인 문서 작성 가이드

### 5.1 UC (유즈케이스) — `{domain}/uc.md`

**목적**: 이 도메인에서 사용자가 할 수 있는 행위를 정의

```markdown
## UC-001: {{유즈케이스명}}

- **액터**: {{누가 이 기능을 사용하는가}}
- **전제조건**: {{이 기능을 사용하기 위한 사전 조건}}
- **기본 흐름**:
  1. {{단계 1}}
  2. {{단계 2}}
  3. ...
- **대안 흐름**: {{예외 상황 처리}}
- **관련 API**: {{엔드포인트}}
```

### 5.2 BR (비즈니스 규칙) — `{domain}/br.md`

**목적**: 코드만 봐서는 알 수 없는 업무 규칙

```markdown
## BR-001: {{규칙명}}

- **위험도**: {{Critical / High / Medium / Low}}
- **조건**: {{적용 조건}}
- **동작**: {{시스템 동작}}
- **근거**: {{법률/계약/고객 요구}}
- **위반 시 영향**: {{무엇이 잘못되는가}}
```

### 5.3 Model (도메인 모델) — `{domain}/model.md`

**목적**: 엔티티 구조, 필드, 관계, 제약조건

### 5.4 Data Dep (데이터 의존성) — `{domain}/data_dep.md`

**목적**: 이 도메인의 데이터가 다른 도메인에 미치는 영향

---

## 6. 프로젝트 규모별 최소 요구

모든 프로젝트가 동일한 양의 문서를 가질 필요는 없습니다.
규모에 따라 최소 요구 수준을 다르게 합니다.

### 소규모 (엔드포인트 20개 미만, 도메인 1-2개)

```
docs/
├── README.md
├── entities/{domain}/br.md      ← 핵심 규칙만
├── guides/setup.md
└── handover/                    ← 인수인계 시에만
```

### 중규모 (엔드포인트 20-100개, 도메인 3-5개)

```
docs/
├── README.md
├── entities/{domain}/           ← uc.md + br.md 필수
│   └── (model.md 권장)
├── api/{domain}/endpoints.md
├── guides/setup.md + deployment.md
├── histories/
└── handover/
```

### 대규모 (엔드포인트 100개 이상, 도메인 6개 이상)

```
docs/
├── README.md
├── entities/{domain}/           ← 전 문서 (uc, br, model, data_dep, gherkin)
├── api/{domain}/                ← endpoints + errors
├── processes/                   ← 업무 프로세스 필수
├── guides/
├── histories/
└── handover/
```

---

## 7. entities/와 handover/의 관계

| entities/ (개발 중 유지) | handover/ (전환 시 생성) | 관계 |
|:------------------------|:----------------------|:-----|
| 도메인별로 분리 | 전체 통합 | 여러 도메인 → 1파일 |
| 개발자 관점 (설계) | 유지보수 관점 (운영) | 관점 전환 |
| 상시 갱신 | 전환 시점 스냅샷 | 원본 → 파생 |
| 상세 (엔티티 필드 수준) | 요약 (핵심만) | 상세도 차이 |

**원칙**: entities/가 원본, handover/는 파생. 둘 다 갱신하려면 entities/를 먼저 갱신하고 handover/에 반영.

---

## 8. 기존 프로젝트 적용 가이드

이미 운영 중인 프로젝트에 이 표준을 적용하는 방법:

### 즉시 적용 (구조만)

```bash
# 1. 디렉토리 생성
mkdir -p docs/{entities,api,processes,guides,histories,handover}

# 2. README.md 작성 (프로젝트 소개 + 문서 구조 안내)

# 3. 기존 문서가 있으면 해당 디렉토리로 이동
```

### 점진적 채움

- 새 기능/버그 수정할 때마다 해당 도메인의 `entities/{domain}/br.md`에 발견한 규칙 추가
- PR마다 `histories/` 이력 추가
- 몇 달 지나면 자연스럽게 문서가 채워짐

### 인수인계 시점

- 그때까지 쌓인 entities/api/guides에서 handover/ 6개 파일 생성
- 부족한 부분은 handover 템플릿의 검수 체크리스트로 확인

---

## 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|:-----|:---------|:------|
| 2026-03-18 | 초판 작성 | Thomas Kim |
