# Q-06–Q-09 · 측정 기반 묶음 구현 보고

2026-09-29. 도구 구현과 실제 문장 품질 통과는 다르다. 운영 문장·모델·DB·Flutter 화면은 바꾸지 않았다.

| 작업 | 개발 상태 | 아직 필요한 완료 조건 |
|---|---|---|
| Q-06 산문 린터 | 완료 · 순수 함수 20개 지표, 러너 `--lint`, 중앙값/p90 | 임계값/V9는 Q-30 이후 |
| Q-07 충실도 판정기 | 코드·러너·검수/승인 연동 구현 | 실제 장면 15건 사용자 직접 검수, 일치율 ≥80% |
| Q-08 기준선 | 숫자 전용 보고서 생성 도구 구현 | dev 30개 꿈, 실제 API 실행, Q-07 검수, 실제 기준선 커밋 |
| Q-09 레퍼런스 | 직접 라벨링·로컬 분석·근접도 도구 구현 | 양성 25편 실제 수집/라벨, 프로파일 확정·기준선 근접도 |

`write.v10`, `plan.v6`, `opening_expansion`, `opening_polish`는 `edfc13c`와 동일하다.
기존 기준선 설정 파일도 그대로다. 새 `baseline_v10_measured.json`은 같은 집필 설정에 **평가 전용** judge 모델만 더한다.
이 judge 모델은 품질 승자가 아니라 등록된 연결 후보이며 작가·expansion·polish 모델과 달라야 한다.
운영 플래그/프로바이더 전환, Supabase 배포, 원고 직접 교정은 하지 않았다.

## Q-06 측정 규약

`_shared/prose_lint.ts`의 `lintProse`가 기본 13개 + 웹소설 호흡 7개 지표를 산출한다.
근접도 핵심 10개는 별도 고정하며 V7은 기존 `BANNED_EXPRESSIONS`를 재사용한다. 문학적 판정이나 형태소 분석이 아니다.

- NFC·Unicode 코드포인트 길이, 빈 문단 제외. 문단 내부 공백/기호는 길이에 포함하고 연결용 개행은 1,000자 분모에서 제외한다.
- 문장 길이는 종결 기호/따옴표 포함 trim 길이, 종결은 마지막 어절의 마지막 두 코드포인트다.
- 종결 기호 뒤 공백/끝에서 분리하되 대사 내부 종결은 닫는 따옴표까지 유지한다. 미닫힌 대사는 남은 부분을 하나로 처리한다.
- 현재형은 지시서의 끝 3음절 규칙, 직유는 `마치/듯이`만 사용한다. `처럼`은 제외한다.
- 분위수는 기존 러너와 같은 nearest-rank다. 빈 표본은 지표 0 / 분포 null이며 통과 근거가 아니다.
- 각 꿈 최종 장면 및 합친 케이스에 `metrics`를 저장한다. summary 분포는 장면 단위다.

## Q-07 판정·승인

`_shared/fidelity_judge.ts`는 role `judge` 구조화 호출이다. 원문/회상·요소·문단 출처·시점을 받아 D 사실 변경/구체적 발명, C 모순, 주인공 역전, high 요소 누락을 본다.
질감·시선·망설임은 구체적 발명과 구분한다. 문단 index/origin은 빠짐없이 정확히 한 번, 누락 id는 실제 high 집합이어야 한다.
작가와 판정기가 같은 모델(별칭 포함)이면 호출 전 거부한다.

판정 실패는 생성 성공과 분리한다. 성공한 장면을 지우지 않으며 실패/미측정을 통과로 세지 않는다.
평가 호출 토큰·비용·지연은 엔진 비용/지연과 분리한다. 알려지지 않은 실패 호출 비용은 무료로 표시하지 않는다.
detail/본문은 비공개 결과·검수 파일에만 남고 콘솔/문서에는 숫자·고정 분류만 출력한다.

검수 파일은 ID 정렬 후 장면 15건을 고정 선택한다. 사용자 동의/비동의 15건 중 12건 이상 동의해야 승인된다.
fixture/sentinel 승인은 실제 게이트용이 아니다. 승인서는 모델·판정 프롬프트·결과·검수 입력·사람 판정 해시에 묶인다.
변경 시 승인은 무효다. Q-05 충실도 수치에는 승인서 모델/해시 증거가 필요하며 증거 없는 임의 수치는 미검증이다.
메트릭 갱신 후 judge를 재실행해야 저장된 게이트 스냅샷도 갱신된다.

## 실행 순서

레포 루트에서 실행한다. Deno가 PATH에 없으면 `deno`를 `npx --no-install deno`로 대체한다.
실제 dev/API 키는 로컬에서만 준비하고 값을 채팅/Git에 올리지 않는다.

```bash
# 읽기 전용 counts + 자격증명 존재 여부. holdout은 읽지 않음.
deno run --allow-read --allow-env tool/eval/preflight.ts
# API 키 없는 기능 검증. 품질 게이트 대상 아님.
deno run -A tool/eval/run.ts --config eval/configs/baseline_v10_measured.json --set fixtures --lint --fidelity
# 실제 기준선. config 공급자 키가 로컬에 있어야 함.
deno run -A tool/eval/run.ts --config eval/configs/baseline_v10_measured.json --set dev --lint --fidelity
deno run -A tool/eval/judge.ts --mode fidelity-audit --run eval/runs/<run>
# 사용자가 15건을 직접 검수한 뒤
deno run -A tool/eval/measurements.ts calibrate eval/runs/<run> eval/judgments/<audit>.json
deno run -A tool/eval/measurements.ts refresh eval/runs/<run>
deno run -A tool/eval/baseline_report.ts eval/runs/<run>
```

보고서는 full real dev(18 singles, clarity 각 6 + sequences 3 = 30 dreams), 동결 모델/설정/프롬프트,
승인된 충실도와 모든 생성 장면 측정이 있을 때만 비공개 `eval/runs/<run>/baseline_report.md`로 생성된다.
실제 값이 준비되면 숫자만 검토해 `docs/quality/Q-08_baseline.md`에 반영한다. 이번에는 실제 값이 없으므로 정본을 꾸며 만들지 않았다.
권장 A/A 10건은 `--aa eval/judgments/<aa>.json`으로 추가한다. 미실행은 미검증, 한쪽 7승 이상은 노이즈 표시다.

## Q-09 직접 수집 → 라벨링 → 분석

크롤러/스크래퍼/앱 추출/DRM 우회는 만들지 않았다. 원문은 LLM에 보내지 않는다.
정당하게 열람 가능한 국내 원작 회차를 사용자가 직접 준비한다. 작품명은 로컬 manifest에만 둔다.
`works.jsonl`은 지시서의 `id/group/genre/voice/opening/ending/next_opening?`을 받는다.
group=`positive/control`, voice=`first/third`, genre=현판/로판/판타지/로맨스/미스터리/호러/기타 중 하나다.
`미스터리/호러`는 하나의 값이다. 문단은 줄바꿈으로 구분하고 편집기의 자동 줄바꿈은 넣지 않는다.

```bash
deno run -A tool/eval/judge.ts --mode annotate --reference eval/reference/works.jsonl
deno run --allow-read --allow-write tool/eval/reference_profile.ts analyze eval/reference/works.jsonl --annotations eval/judgments/<annotate>.json
deno run --allow-read --allow-write tool/eval/reference_profile.ts score eval/runs/<baseline> eval/reference/profile.json
# 화면 체험용 가짜 데이터 (8788), API/DB 없음
deno run -A tool/eval/reference_demo.ts
```

첫 문장 유형·첫 사건 문단·공개 정보·끝맺음 유형·자기 말 메모를 직접 저장한다. 일반 문단 라벨 모드도 유지했다.
분석은 원문/라벨 해시가 일치해야 한다. 원문 파일의 `labels`에 동일 typed 스키마로 직접 라벨을 넣어도 된다. LLM 사전 라벨은 만들지 않는다.
양성/대조 opening·ending 분위수, 라벨 분포, 시점 분해, 방향성 중앙값 차이를 계산한다. 작은 표본에 유의성을 주장하지 않는다.
양성 25편·1인칭 절반 이상·한 장르 ≤40%·라벨 완료를 충족하지 않거나 합성 자료면 미확정이다.
근접도는 핵심 10개 장면 지표 중앙값이 양성 도입 p25–p75에 드는 개수(경계 포함)다. 미확정은 null이지 0점이 아니다.

생성물은 입력 옆 비공개 `profile.json`, `profile_report.md`, `profile_module.ts`이며 숫자/고정 라벨만 포함한다.
미확정 module은 null이므로 이전 정상 module을 잘못 재사용하지 않는다. shared 기본 프로파일도 아직 null이다.
실제 수집 후 숫자 module/문서를 검토해 `_shared/reference_profile.ts`, `docs/quality/Q-09_reference_profile.md`에 반영한다.
몰입 원칙에는 근거 숫자를 붙인다. 회귀·빙의·환생, 상태창·시스템창, 사이다 구조, 회차 분량은 목표에서 제외한다.
그 다음 실제 기준선 근접도도 Q-08에 기록한다. 아직 실제 프로파일을 발행하지 않았다.

## 실제 실행한 검증

- 평가 73개(기존 56 + 새 17), 엔진 132개(기존 120 + 산문 8 + 충실도 4), Flutter 120개 테스트 통과.
- Deno format/lint/check, Dart format, 동일 소스 검증 후 ASCII 경로 Flutter analyze, 웹 release(`/tmp/mumumong-q06-q09-web.ubDZPZ`) 통과. 기존 앱 프리뷰 출력은 덮어쓰지 않았다.
- root CLI의 실제 fixture runner `--lint --fidelity`: 3 cases/6 dreams, 지표 20개, 가짜 판정 6건, calibrated=false, 게이트 충실도 미제공. 문장 품질 증거가 아니다.
- 브라우저 desktop/390px: 필수 누락 차단, 선택/저장/새로고침/이전/완료, 로컬 파일 재개. 외부 리소스 0, 페이지 오류 없음, 가로 넘침 없음. 브라우저 스킬 UI→API→파일→분석 검증에서 빈 원본/항목 표기를 정리했다.
- 두 직접 지어낸 예시의 실제 라벨 파일을 분석 CLI에 전달: positive 1/control 1, eligible=false. 표본 부족/편중/합성 표시가 실제 프로파일 확정을 차단했다.
- 로그/유출 가드, 네 개 동결 파일 동일성. 원문/결과/판정/레퍼런스는 모두 Git 제외.
- preflight: 실제 dev/reference 정본 파일 없음, 현재 CLI의 Groq/OpenAI/Anthropic 키 미설정. 키 값/본문 출력 없음. holdout 미열람.

## 미검증·남은 것

Q-07 실제 공급자 호출·사용자 15건 일치율, Q-08 실제 기준선/A/A, Q-09 실제 25편 수집/라벨/프로파일/기준선 근접도,
G1/G2/G3 문장 품질, Q-04 Anthropic 실제 E4, iOS 런타임, 이번 변경의 클라우드 E2E는 미검증이다.
합성 단위 테스트의 승인은 연결/계산 검증일 뿐 실제 인간 품질 판정이 아니다.
holdout은 Q-32까지 미개봉. Q-10 모델 베이크오프/v11 문장 변경은 실제 기준선 전에 실행하지 않았다.
