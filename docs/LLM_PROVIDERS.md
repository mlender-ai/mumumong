# Q-04 LLM provider layer

현재 상태: 구현·스텁 검증 완료, **Anthropic 실제 E4 호출은 미검증**이다.
로컬과 무무몽 프로젝트에 `ANTHROPIC_API_KEY`가 없어 완료 조건 전체를 충족하지 못했다.
새 어댑터는 아직 원격 배포하지 않았으며 운영 모델은 기존 Groq다.

## 구조와 경계

`_shared/llm/port.ts`가 역할 → `MODEL_<ROLE>` → 레지스트리 → 공급자 어댑터를 연결한다.
`LlmPort`는 `structured()`와 문자열 입력/출력의 `text()`를 제공한다.
기존 단계 코어는 필요한 `StructuredLlmPort`만 받는다. 프롬프트·계약·정규화 로직은 그대로다.
기존 `llm.ts` / `llm_adapter.ts` / `llm_port.ts` import는 호환 경로로 유지한다.

- Groq: strict `json_schema`, 구조화 요청의 400만 `json_object`로 한 번 전환.
- Anthropic: 입력 스키마를 도구에 전달하고 해당 도구 호출을 강제한다.
- OpenAI: strict `json_schema`, `store: false`. 별도 보존 정책 동의의 대체는 아니다.
- 최종 생성 계약은 기존 단계별 Zod 검증이 책임진다. JSON 디코딩 성공 ≠ 유효한 장면.
- `reasoning_effort: low`는 Groq의 gpt-oss에만 전송한다.
- HTTP 429·5xx만 최대 두 번, 500ms / 1,000ms 백오프로 재시도한다.
  Groq 형식 폴백도 같은 재시도 예산을 공유한다. 다른 4xx 및 네트워크 예외는 즉시 실패한다.
- 응답 본문, JSON 파서 원문, 네트워크 예외의 임의 이름/원인은 오류·로그에 노출하지 않는다.
  실패 본문을 폐기하는 스트림 자체의 오류도 노출하지 않는다.
- 다른 공급자로 자동 폴백하지 않는다. 비공개 생성 결과 캐시와 게이트웨이 서비스는 도입하지 않았다.

## 등록 모델과 단가

2026-09-29 공식 공급자 문서에서 확인한 일반 텍스트, 비캐시 입력/출력 USD / 1M 토큰이다.
정본은 `_shared/llm/registry.ts`다. 등록은 어댑터 호환 정보이며 품질 우승·계정 접근 권한의 증거가 아니다.

| 설정 ID | 입력 | 출력 | 확인 출처 |
|---|---:|---:|---|
| `groq:openai/gpt-oss-20b` | 0.075 | 0.30 | [Groq models](https://console.groq.com/docs/models) |
| `groq:openai/gpt-oss-120b` | 0.15 | 0.60 | [Groq models](https://console.groq.com/docs/models) |
| `anthropic:claude-sonnet-5` | 2 | 10 | [Sonnet 5](https://platform.claude.com/docs/en/models/sonnet-5/overview) |
| `anthropic:claude-sonnet-4-6` | 3 | 15 | [Sonnet 4.6](https://platform.claude.com/docs/en/models/sonnet-4-6/overview) |
| `openai:gpt-4.1-2025-04-14` | 2 | 8 | [GPT-4.1](https://developers.openai.com/api/docs/models/gpt-4.1) |

OpenAI `gpt-4.1` 별칭도 인식하지만 비교 실행에는 고정 스냅샷을 권장한다.
단가 추정은 레지스트리와 기존 환율 상수 1 USD = 1,400 KRW를 사용하며 실제 청구액이 아니다.
재시도 중 실패한 호출의 사용량은 알 수 없다. 평가 러너는 확인된 성공 사용량만 합산하며,
실패한 단계 호출이나 미등록 응답 모델이 있으면 비용을 불완전으로 표시한다.

등록한 Anthropic 모델은 가변 `temperature`를 전송하지 않고 thinking을 비활성화한다.
기존 요청 객체의 temperature 값이 그 공급자에서도 적용된다는 뜻이 아니다.
이는 [Messages API](https://platform.claude.com/docs/en/api/messages/create)의 모델별 파라미터 제한을 따른다.
강제 도구 사용은 [tool definition](https://platform.claude.com/docs/en/agents-and-tools/tool-use/define-tools)을 따른다.
OpenAI 요청 형식은 [Chat Completions](https://developers.openai.com/api/reference/resources/chat/subresources/completions/methods/create)와
[structured outputs](https://developers.openai.com/api/docs/guides/structured-outputs)를 따른다.

## 키·실제 E4 스모크

운영 키는 Edge Function secret `GROQ_API_KEY`, `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`에서만 읽는다.
앱/평가 설정/레포에는 키를 넣지 않는다. 로컬 검증은 해당 프로세스 환경변수를 사용한다.
`apiKey` 인자와 `readSecret` 주입은 스텁 테스트 경로이며 HTTP 요청으로 받지 않는다.

로컬 환경에 키를 안전하게 설정한 뒤 레포 루트에서:

```bash
MODEL_WRITE=anthropic:claude-sonnet-5 deno run --allow-env --allow-net=api.anthropic.com tool/eval/smoke_write.ts
```

`deno`가 PATH에 없으면 `npx --no-install deno`로 대체한다.
이 도구는 새로 지어낸 가짜 꿈의 **단일 E4 기본 호출**을 검증한다.
E1/E3 입력은 가짜 고정 컨텍스트다. 첫 장면 expansion/polish를 호출하지 않도록 continuation을 사용한다.
코퍼스·holdout·DB를 읽거나 생성 원고를 저장/교정하지 않는다. 출력은 호출 수·모델·프롬프트 버전·토큰·문단 수뿐이다.
전체 파이프라인, 문학 품질, 첫 장면 품질 및 블라인드 판정의 검증은 아니다.
키 없이 실행한 결과는 `provider_not_configured`이며 **실제 호출 성공으로 간주하지 않는다**.

## 실행한 검증 / 미검증

실행: 120 엔진 테스트(새 어댑터 32 + 기존 88), 평가 도구 31 테스트,
120 Flutter 테스트, Dart 포맷, 웹 release 빌드(임시 디렉터리), 로그·평가 유출 가드.
한글 경로의 `flutter analyze`는 기존 분석 서버 오류로 실패했다.
`lib/`, `test/`, pubspec 두 파일이 일치하는 ASCII 경로 복사본에서는 analyze가 통과했다.
동결 프롬프트/두 opening helper는 `edfc13c`와 바이트 단위 동일하다.

미검증: Anthropic 실제 E4 호출(API 키 없음), OpenAI 실제 호출, 새 코드의 원격 배포/클라우드 E2E,
iOS 런타임, 실제 dev/sentinel 품질·블라인드 판정. holdout은 의도적으로 열지 않았다.
