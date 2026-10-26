# P4-1 후속 — 결과/성장 연출 소비 상태 복원

2026-10-23 KST. **페이즈 계획의 P4 재개**이며 디자인 추가 보정이 아니다. 이번 단위는 결과·성장 연출의 기기 내 중복 소비 방지다. P4 전체나 원격/오프라인 전체 복구를 완료한 것으로 취급하지 않는다.

## 사용자에게 달라진 동작

- 이미 처리한 리빌은 다시 ‘새 장면’으로 축하하지 않고 ‘저장된 장면/장면 읽기’로 조용히 연다. 본문과 출처·장면 조정·읽기 경로는 남는다. 새 결과를 받지 않았는데 완료 화면을 만들지 않는다.
- 성장 연출은 실제 양수 progress event ID마다 기기에서 한 번만 예약한다. 리빌에서 처리한 동일 성장 이벤트는 홈에서 다시 재생하지 않는다. 최신 전체 진척 값은 항상 실제 원고 값을 사용한다.
- 다른 화면에 가려진 결과, 선택하지 않은 홈 탭, 백그라운드 상태에서는 연출을 예약하지 않는다. 다시 표시되거나 foreground로 돌아오면 확인한다. 서버 작업/관찰 구독은 기존 P4 동작을 유지한다.
- 상태 기록 실패 시 연출은 생략하고 실제 원고를 열 수 있게 한다. 결과 화면의 ‘화면 상태 다시 저장’은 UI 상태만 재시도하며 생성/재시도 요청을 하지 않는다. 홈 장식의 기록 실패도 원고 진척을 숨기거나 자동 재시도 루프를 만들지 않는다.

## 저장 계약

`MumumongRepository.consumePresentation(volumeId, kind, sourceId)`는 **열람/완독이 아닌, 일회성 연출 예약**이다. 종류는 reveal/growth, 키는 권·종류·장면/성장 이벤트 ID이며 timestamp 외 원문/원고는 저장하지 않는다. Memory/Drift가 같은 계약을 구현한다. 원고/출처/U 잠금/진척 이벤트를 수정하거나 Outbox에 원격 처리를 추가하지 않는다.

Drift schema **2→3**: `presentation_receipts`만 추가하고 기존 양수 성장 이벤트는 조용한 과거 상태로 backfill한다. v1은 기존 읽기 위치 migration 이후 같은 확장을 수행한다. 미열람 리빌은 backfill로 읽었다고 가정하지 않는다. Reader의 실제 첫 문단 열람 마커가 있으면 새 리빌을 생략한다. 영수증만으로 firstReadAt을 만들지 않는다.

로컬 transaction + 복합 PK/insert-or-ignore-returning으로 중복 예약을 막는다. 잘못된 권/없는 장면/본문 없는 장면/없는 양수 성장 이벤트는 거절한다. 계정 소유자 변경·전체 데이터 삭제에서는 영수증도 삭제한다. 권 삭제에는 FK cascade가 적용된다.

기기별 **at-most-once** 예약이다. 예약 직후 앱이 종료되면 축하 연출을 못 볼 수 있지만 원고는 사라지지 않고 홈/보관함/Reader에서 계속 접근 가능하다. 실제 시선/완독/운영 알림 전달 증명이 아니며 여러 기기·새 브라우저까지 한 번을 보장하지 않는다. native push 영수증을 구현한 것도 아니다.

## 변경 코드

Repository 계약, Memory/Drift, database와 정식 build_runner 생성물, CaptureFlow, Home/Shell의 표시 여부, 계정 전환·전체 삭제 정리를 변경했다. 새 제공사·모델·프롬프트·서버 engine/SQL/RLS 변경은 없다.

## 실제 실행한 검증

- 전체 Flutter **260개 통과**(이전250 + 신규10). 기존 화면 비교와 별도14화면 캡처 도구의 재비교도 통과했다. 이번에는 이전 이미지 기준선을 덮어쓰지 않았다.
- Memory/Drift 공통 계약: 동시에8번 예약해 fresh는1번, 종류별 독립 키, 잘못된 source 거절, 이미 읽은 장면의 연출 생략, 예약 전후 본문·D/C/U·U 잠금·읽음 마커 불변.
- 실제 임시 SQLite 파일의 v2→v3 migration과 재열기: 과거 성장 조용히 유지, 미열람 결과 최초 예약, 재열기 후 중복 예약 false. 초안·U 본문/잠금·Outbox·읽기 위치 보존. 기존 v1→v3와 전체 삭제/계정 전환 정리 검사도 포함한다. 사용자의 DB를 열거나 reset하지 않았다.
- Widget: 완료 결과 재진입 시 새 리빌/로그/읽음/생성 중복 없음, 저장 실패→원고 접근/상태만 재시도, 덮인 route에서 미소비→복귀, 홈 비선택 탭→표시→재마운트, background 완료→foreground에서 최초 소비.
- format 및 직접 Dart 분석 통과. root `flutter analyze --no-pub`는 기존 한국어 경로 LSP JSON FormatException(exit255)로 실패했다. 직접 분석을 기본 명령 통과로 보고하지 않는다.
- privacy/log guards·diff 공백 검사 통과, edfc13c 대비 frozen write/plan/opening_expansion/opening_polish 네 파일 diff 없음. private eval 데이터를 열거나 출력하지 않았다.

- iPhone17 Pro / iOS26.5 **시뮬레이터2개 통과**: 기존21초 대기→화면 이탈→mock 완료→SQLite 재열기→정확한 장면 Reader 및 신규 첫 리빌→SQLite 종료/재열기→저장된 장면으로 정적 재진입/읽음null/중복 장면 없음. 최종 전체 실행은35초(별도 Xcode22.5초)다. 물리기기 강제 종료나 hosted 생성 검증이 아니다.
- 최종 순차 iOS simulator 무서명 build16.9초, 일반 web release26.8초, 로컬 mock preview release25.3초 통과. 두 web 출력의 폰트/아이콘/SQLite 등 필수14리소스 guard 통과. 검토 도구는 기존4206 정적 서버 출력 경로에 갱신했으며 열린 탭의 입력을 지우지 않도록 강제 새로고침하지 않았다. 이번 단위의 browser/웹 영속 DB 동작은 미검증이다.

### 발견해서 고친 검증 문제

- 최초 widget fixture가 fake-async 안에서 저장소 Stream.first를 기다려 정지했다. 해당 실행을 중단하고 fixture 준비를 tester.runAsync로 옮긴 후 재실행했다.
- 최초 native 새 시나리오는 commit 후 `recordJobProgress`로 terminal cache를 만들려 했다. 이 메서드는 완료된 꿈을 되살리지 않도록 의도적으로 무시하므로 캐시가 생기지 않아 실패했다. 실제 mock engine과 같은 fixture용 `writeEngineProgress` 경로로 고쳤다. 보호 동작을 풀거나 제품에서 완료를 날조하지 않았다.
- 첫 부분 테스트 명령에 없는 두 파일 경로를 포함해 실패했다. 실제 경로 `test/contract/`를 확인하고 재실행했으며 전체260개 통과가 최종 근거다.

## 미검증·남은 작업

실제 hosted/계정/AI/RLS, 실제 iPhone/PWA·웹 SQLite 재시작·다중 탭/기기·프로세스 강제 종료의 crash window·터치 성능은 미검증이다. 원문 입력에 대한 소설 충실도/재미도 검증하지 않았다. 계정/원격 API 키나 실측 코퍼스는 사용하지 않았다.

P4-1의 재시도 접수 대기 Outbox 복원·오프라인 콜드스타트 인증/동의 경계는 별도 잔여다. **다음 계획 항목은 P4-2 각색·문체·시점의 이후 생성분 변경 및 버전/Outbox/RPC 충돌 계약**, 그다음 P4-3 운영 복구·지원 플랫폼 알림이다. P5 완결/PDF와 P6 관측/전체 검수는 아직 넘어가지 않는다. LLM 완결 편집은 Q-32 이후다.

## 데이터/배포 영향

앱 실행 시 로컬 DB는 비파괴 v3 migration을 적용한다. 서버 migration·실제 원고 DB 수정·공개 배포·commit·push는 없다. 이전 v2 앱의 v3 DB downgrade는 지원하지 않으며 destructive down migration을 만들지 않았다. 공개 배포 전에는 v3 호환 코드를 유지하는 rollback 계획이 필요하다. 로컬 mock 미리보기는 실제 AI 결과/영속 DB 검증을 대신하지 않는다.
