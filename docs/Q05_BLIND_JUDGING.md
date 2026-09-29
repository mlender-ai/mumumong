# Q-05 · 로컬 블라인드 판정 도구

Q-05 도구 구현을 완료했다. 실제 dev 품질 판정이나 G1/G2/G3 품질 통과를 뜻하지 않는다.
동결 프롬프트, 운영 모델, 앱 UI, DB 원고는 변경하지 않았다.

## 실행

레포 루트에서 실행한다. Deno가 PATH에 없으면 `npx --no-install deno`로 대체한다.

```bash
# API 키 없이 기능을 확인하는 가짜 데이터 데모
deno run -A tool/eval/judge_demo.ts

# A = 기준선, B = 후보. 화면에는 이 배치나 실행 이름이 표시되지 않는다.
deno run -A tool/eval/judge.ts --a eval/runs/<runA> --b eval/runs/<runB> --port 8787

# 판정 후 별도 터미널에서 리포트 확인
deno run -A tool/eval/report.ts eval/judgments/<runA>__<runB>.json
deno run -A tool/eval/report.ts eval/judgments/<runA>__<runB>.json --gate G1
```

화면: `http://127.0.0.1:8787/`. LAN 바인딩 옵션은 없다. 종료는 Ctrl+C다.
데모는 Q-03 실제 러너를 fixture로 두 번 실행해 비공개 `eval/runs/`에 결과를 만든다.
화면에 가짜 데이터임을 표시하며 품질 게이트 대상에서는 제외한다. 실제 공급자/API 키/DB를 사용하지 않는다.

## 판정·재개

- 두 실행의 공통 케이스만 비교한다. 코퍼스 세트와 SHA256이 같아야 한다.
  원본 꿈은 그 해시와 일치하는 로컬 코퍼스에서만 읽는다.
- 좌우는 암호학적 무작위 시드 + 케이스 ID의 해시로 결정한다.
  시드를 판정 파일에 저장해 재실행해도 좌우가 유지된다.
- sequence는 제목을 포함한 4개 장면 전체를 하나의 단위로 판정한다.
  원본 꿈은 접혀 있고 출처 표시는 기본 OFF다. 화면/API에서 모델·실행명·시드·좌우 매핑은 숨긴다.
- 1 / 2 / 3으로 왼쪽 / 오른쪽 / 비슷함을 선택하고 n으로 다음으로 이동한다.
  이유·문제 칩과 양쪽 출시 수준 체크도 저장한다. 비슷함에서 ‘이긴 쪽도 출시 수준 아님’을 체크하면 양쪽으로 기록한다.
- 선택마다 임시 파일 → rename으로 저장한다. 새 파일은 0600, 새 폴더는 0700이다.
  파일 writer lock, stale PID 복구, 직렬 저장과 revision 검사가 중복 창의 덮어쓰기를 막는다.
  저장 실패는 화면에 표시하고 메모리 판정을 확정하지 않는다.
- 같은 명령으로 재실행하면 첫 미판정 항목부터 이어진다. 이전 항목이나 완료 후 ‘처음부터 확인’에서 수정할 수 있다.
  생성 결과/설정/코퍼스가 바뀐 경우 기존 판정을 새 원고에 재사용하지 않는다.
- 한쪽 파이프라인 실패는 그쪽 자동 패배다. 성공 상태라도 완전한 장면이 없으면 사용자에게 읽을 결과가 없는 실패로 분류한다.
  양쪽 실패는 별도 `both_failed` 자동 비슷함으로 기록한다. 자동 항목은 사람이 읽는 큐에서 제외한다.
  자동 승리한 성공 쪽의 출시 수준은 **미판정**이지 자동 ‘출시 가능’이 아니다.

localhost 요청의 Host/Origin, 세션 토큰, JSON 제출을 검사한다.
CSP·no-store·no-referrer를 적용하고 외부 리소스를 사용하지 않는다.
본문은 DOM `textContent`로만 삽입한다. 파일 경로·Zod 상세·파서 원문·본문은 오류 출력에 넣지 않는다.

## 리포트·게이트

리포트는 본문·메모가 아닌 수치와 고정 분류 ID만 출력한다.
승/패/비슷함, 비슷함 제외 정확 단측 이항 부호검정, 자동 패배 수, 양쪽 출시 수준 비율,
이유/문제 집계와 single/sequence·clarity 분해를 제공한다. 혼합 sequence clarity는 `mixed`다.
B가 후보이므로 게이트는 B 승수 기준이다. 프로 모드에서는 A가 엔진, B가 작가다.

`--gate G1|G2|G3`는 지시서 §3.2를 적용한다.
측정 누락은 `unverified`이며 전체 **FAIL**이다. 판정 미완료, fixture/sentinel, 불완전 세트,
잘못된 비교 설정도 통과하지 않는다. dev는 18 singles(clarity 각 6) + 3 sequences,
holdout은 6 singles(각 2) + 1 sequence를 요구한다.
‘꿈당 비용 ≤ 200원’은 알려진 비용의 **최대값**으로 보수적으로 확인한다.
성공 호출 비용을 알 수 없거나 미등록 응답 모델이 있으면 비용 조건을 미검증으로 둔다.
V2와 출처 참조는 최종 장면과 실제 추출 element 집합으로 검사하며 과거 재시도의 오류 수를 사용하지 않는다.

Q-07/Q-09 측정 도구는 이후 묶음에서 구현됐지만 실제 판정기 검수·레퍼런스 확정은 미완료다.
이 단계에서 점수를 만들어 넣거나 미측정을 0/통과로 간주하지 않는다.
향후 각 실행 폴더의 `quality_metrics.json`으로 다음 메타데이터를 전달할 수 있다.

| 필드 | 의미 |
|---|---|
| `results_sha256` | 해당 `results.jsonl` 파일 전체 SHA256 |
| `case_ids` | 측정에 포함된 정확한 공통 케이스 ID 목록 |
| `fidelity.passed`, `fidelity.total` | 실제 충실도 통과/전체 개수. 선택 필드 |
| `fidelity_calibration` | Q-07 직접 검수 승인서의 모델/해시 증거. 없거나 무효이면 충실도는 미검증 |
| `reference_proximity` | 실제 Q-09 근접도 0~10 정수. 선택 필드 |

해시가 틀리면 거부한다. ID 범위가 다르면 해당 측정은 적용하지 않는다.
측정 추가 후 **judge를 같은 명령으로 재실행**하면 판정·시드는 유지하고 메트릭만 갱신한다.
그 다음 report를 실행한다. report 단독 실행은 저장된 판정 시점의 메트릭 스냅샷을 사용한다.
holdout 입력 읽기는 Q-32까지 judge와 fidelity-audit에서 계속 차단한다.
G3 계산은 가짜 메타데이터 유닛 테스트로만 확인했다.

종료 코드: report 정상 0 / 입력 오류 1 / 게이트 FAIL 2.
비공개 디렉터리 5종(corpus, runs, judgments, reference, pro)은 .gitignore + CI index 가드로 차단한다.

## 추가 모드와 입력 계약

모든 예시·레퍼런스·판정 파일은 로컬 비공개 경로만 사용한다.
아래 계약은 후속 Q 작업이 읽고 쓸 도구 인터페이스이며, 충실도 판정기·작가 외주·레퍼런스 분석 자체를 구현했다는 뜻은 아니다.

| 모드 | 명령 인자 | 입력 형식 |
|---|---|---|
| 충실도 감사 | `--mode fidelity-audit --run eval/runs/<run>` | 실행의 `fidelity_audit.json`: `{items:[{id,raw_text,text,finding},...]}`. 15개 이상, 첫 15개 동의/비동의 |
| 예시 선택 | `--mode pick --candidates eval/runs/<file>.json` | `[{id,text},...]`. 각 예시 선택/제외 |
| 문단 라벨링 | `--mode annotate --reference eval/reference/works.jsonl` | 줄마다 `{id,title?,paragraphs:[string,...],labels?:[string,...]}`. 문단 번호 탭·라벨 칩·240자 메모 |
| 프로 비교 | `--mode pro --a eval/runs/<fixture-run> --pro eval/pro/rewrites.jsonl` | 줄마다 `{id,kind,scenes:[{title,passages:[{text},...]},...]}`. 공통 ID, single 1 / sequence 4개 장면 |

프로 비교는 새로 지어낸 fixture 꿈만 허용한다. 작가 본문 출처는 모두 C로 표시한다.
추가 모드 판정은 `eval/judgments/<mode>-<입력해시 앞16자리>.json`에 저장한다.
라벨링 메모는 비공개 파일에만 보존하며 report에는 문단 라벨 집계만 나온다.

## 검증 기록 (2026-09-29)

- 평가 도구 테스트 56개(새 Q-05 25 + 기존 31), 엔진 120개, Flutter 120개 통과.
- Dart 포맷, 동일 Flutter 소스 ASCII 경로의 analyze, 웹 release 임시 출력 빌드,
  로그/유출 가드, 네 개 동결 파일과 `edfc13c`의 동일성 확인.
- 실제 Q-03 fixture 두 실행 → 브라우저 3건 판정 저장 → 중단/재개 → CLI report → G1 FAIL까지 실행.
  가짜 판정 결과는 A 1 / B 1 / 비슷함 1이며 p=0.75다. 문장 품질 증거가 아니다.
- 브라우저 스킬로 desktop / 390px 모바일, 기본 접힘·출처 OFF, 외부 리소스 0,
  콘솔/페이지 오류 없음, 4개 연속 장면, 단축키 저장·이동·완료를 확인했다.
  검증에서 발견한 본문 겹침을 수정했다.
- 미검증: 실제 dev 인간 블라인드 판정, 실제 G1/G2/G3 품질 판정, Q-07/Q-09/Q-22 실데이터 연동,
  iOS 런타임 및 클라우드 E2E. Q-04 실제 Anthropic E4 호출도 여전히 미검증이다.
