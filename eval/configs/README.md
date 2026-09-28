# Evaluation configurations

`baseline_v10.json`은 동결된 v10 프롬프트와 기존 Groq 모델 조합이다.
각 역할은 `provider:model` 형식이다. Q-04는 Groq / Anthropic / OpenAI 어댑터를
연결한다. `_shared/llm/registry.ts`에 등록되지 않은 모델은 거부한다.
등록 자체는 실제 호출·문학 품질 검증의 증거가 아니다. `judge`는 아직 null이다.

`settings`의 style은 plain / lyrical / cinematic, adaptation은 faithful / balanced / free,
narrative_voice는 first_person_past / third_person_past다. 코퍼스의 settings는
이 세 필드만 부분 재정의할 수 있다. 실제 추출 clarity는 엔진이 결정하고,
expected_clarity는 사람 판단 비교용 메타데이터로만 저장한다.

설정은 알 수 없는 필드와 v10 이외 엔진 버전을 거부한다.
API 키, 꿈 원문, 생성 원고, 판정 데이터는 설정에 넣지 않는다.
키는 로컬 환경변수 `GROQ_API_KEY` / `ANTHROPIC_API_KEY` / `OPENAI_API_KEY`에만 둔다.
`MODEL_*` 환경변수는 평가 설정을
덮어쓰지 않는다. 설정을 바꾸면 별도 실행이며 기존 결과에 이어 붙이지 않는다.
