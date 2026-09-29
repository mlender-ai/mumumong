# Q-10 · 모델 비교 준비 (실제 베이크오프 미실행)

## 완료한 범위

후보 설정 생성, 실행 전 점검, 자동 1차 선별, G1 비교 계약을 구현했다.
Q-10의 완료 조건인 **실제 G1 승자 선정은 미완료**다. 운영 모델·프롬프트·DB 원고는 바꾸지 않았다.

- `write`·`write_aux`·`polish`를 동일 후보로 교체한다. `extract`·`link`·`plan`·`remember`·`judge`는 고정한다.
- 등록 모델의 별칭도 실제 ID로 비교한다. 중복 후보, 자기 판정, 기준선 자체, 세 역할 중 일부만 바꾸는 설정은 거부한다.
- 설정은 1~3개 후보만 만들며 기존 파일을 덮어쓰지 않는다. 기본 설정과 동결 파일은 보존한다.
- 실제 dev 전체 21단위, 동일 코퍼스/코드 지문, 고정 v10 프롬프트/설정, 린트 결과를 검사한다.
- 자동 선별은 실패율 ≤5%, 충실도 하락 ≤5%p, 꿈당 최대 엔진 비용 ≤200원이다. 판정기 비용은 엔진 비용과 별도다.
- 충실도는 Q-07의 유효한 사람 검수 증명과 결과 해시가 있어야 한다. 없거나 만료되면 `INCOMPLETE`다.
- 자동 생존은 승자 선정이 아니다. 사람 판정 21단위와 **G1의 더 엄격한 −3%p** 조건을 별도로 통과해야 한다.
- G1은 세 문장 역할 교체를 허용하고 코드 지문 변경·누락을 거부한다. 기존 지문 없는 판정은 재준비해야 한다.
- fixtures/sentinel은 실제 자동 선별을 할 수 없다. holdout은 결과를 읽기 전에 Q-32 잠금으로 차단한다.

## 초기 설정과 판정 모델

`bakeoff_sonnet5.json`, `bakeoff_sonnet46.json`은 **기존 어댑터에 등록된 호환성 후보**다.
한국어 산문 승자나 최종 후보 목록을 뜻하지 않는다. 실제 API 호출/계정 접근 권한은 미검증이다.
공식 문서에서 두 ID는 여전히 사용 가능한 legacy 모델로 확인했다.
[Sonnet 5](https://platform.claude.com/docs/en/models/sonnet-5/overview),
[Sonnet 4.6](https://platform.claude.com/docs/en/models/sonnet-4-6/overview) (2026-09-29 확인).
더 최신 모델을 후보로 추가하려면 별도로 ID·가격·파라미터·어댑터를 확인하고 **측정 전** 등록한다.

현재 공통 판정 모델은 `baseline_v10_measured.json`의 OpenAI GPT-4.1이다.
따라서 GPT-4.1을 작가 후보로 쓰면 자기 판정이 되어 거부한다.
다른 공통 판정 모델을 선택할 경우 **Q-08 측정 전**에 모든 설정에 동일하게 반영하고 검수한다.
Q-08 이후 판정 모델/코드가 바뀌면 기존 기준선과 섞지 말고 기준선부터 다시 측정한다.
키를 채팅·설정·Git에 넣지 않는다.

## 실행 순서

레포 루트에서 실행한다. `deno`가 없다면 `npx --no-install deno`를 사용한다.
아래 `BASELINE_RUN`, `CANDIDATE_RUN`, `VOTES`는 실제 비공개 파일 경로로 대체한다.

1. dev 꿈 30개(single 18 + sequence 3×4)를 수집하고 Q-08 실제 측정을 완료한다.
   Q-07 실제 판정 15건을 직접 검수해 12건 이상 동의하고 기준선 지표를 확정한다.
2. 후보/공통 판정 모델과 실행 환경을 먼저 고정한다. 설정 생성 예:

```bash
deno run --allow-read --allow-write tool/eval/bakeoff.ts prepare \
  --baseline eval/configs/baseline_v10_measured.json \
  --candidate example=anthropic:claude-sonnet-5
```

3. 전송 없는 사전 점검 후 후보를 실제 실행한다. `check`는 키의 존재 여부만 출력한다.
   `ready_for_measured_run`은 실행 재료 준비 여부이며 품질 통과가 아니다.

```bash
deno run --allow-read --allow-env tool/eval/bakeoff.ts check eval/configs/bakeoff_sonnet5.json
deno run -A tool/eval/run.ts --config eval/configs/bakeoff_sonnet5.json --set dev --lint --fidelity
deno run -A tool/eval/bakeoff.ts screen BASELINE_RUN CANDIDATE_RUN
```

4. `SURVIVES_AUTOMATIC_SCREEN` 후보만 기준선 대비 블라인드 판정한다.

```bash
deno run -A tool/eval/judge.ts --a BASELINE_RUN --b CANDIDATE_RUN --mode ab
deno run -A tool/eval/report.ts VOTES --gate G1
```

자동 보고서는 후보 run 안의 비공개 `q10_screening.json`에 수치·ID·지문만 저장한다.
CLI 종료값은 0=생성/준비/자동 생존, 1=입력 오류, 2=미준비/탈락/측정 미완료다.
`REJECT`는 알려진 탈락 조건이 있을 때, `INCOMPLETE`는 확인된 탈락 없이 증거가 부족할 때다.
G1 승자가 여러 명이면 추가 상호 판정 후 한 명을 결정한다.
실제 결과가 없으므로 `Q-10_model_decision.md`를 꾸며 만들지 않았다.

## 검증 / 미검증

- 실행: 평가 도구 86개(신규 Q-10 13개), 엔진 132개, Flutter 120개 테스트 통과.
- 실행: Deno format/lint/check, Dart format, 원본과 lib/test/pubspec 파일이 동일함을 확인한 ASCII 경로 Flutter analyze 통과.
- 실행: 실제 루트 CLI에서 초기 후보 설정 2개 생성. 기준선·후보 사전 점검은 dev/로컬 키 부재로 종료 2, API 호출 0.
- 실행: 루트 CLI의 기준선·후보 합성 실행은 각각 3단위/6꿈을 완주했다. 실제 선별 CLI는 fixtures를 거부했다. API/DB 호출이나 실제 품질 비교가 아니다.
- 실행: 웹 release 빌드(`/tmp/mumumong-q10-web.hCcxRc`), 로그·평가 유출 가드, 동결 4파일의 `edfc13c` 대비 바이트 동일성 검사 통과. 기존 `build/web`는 덮어쓰지 않았다.
- 실행: 합성 데이터 단위 테스트에서 설정→실제 동결 코어→검수 증명→자동 선별 파일 저장·검수 변경 시 승인 철회를 확인했다. 실제 사람 판정이나 문장 품질 증거가 아니다.
- 미검증: 실제 Q-08 기준선, 실제 후보 API 실행/문장 품질/비용/지연, 사용자 블라인드 판정, G1 승자·상호 판정, Q-11 동의/운영 교체/24시간 관측, iOS 런타임·클라우드 E2E.

앱 화면과 기존 데모 서버는 변경하지 않았다. 실제 데이터 없이 v11 프롬프트를 새로 만들거나 운영 문장을 교정하지 않는다.
