# P4-3 / 비LLM P5 / P6 배포 검증

## 구현

- P4-2 SQL0017·plan/write 입력 래퍼를 배포했다. 설정 버전/CAS/멱등 영수증과 job별 과거 설정을 유지한다. 동결 프롬프트 네 파일은 edfc13c와 동일하다.
- SQL0018: pg_cron이 매분 due queue를 확인해 pg_net으로 worker만 깨운다. Vault의 전용 호출 토큰을 사용하며 service-role 키를 cron에 저장하지 않는다. 클라이언트는 net schema/큐 헤더와 전역 wake RPC에 접근하지 못한다. 앱 background 실행은 최적화이며 영속 복구의 전제가 아니다.
- SQL0019·Drift v5: 본문/순서/D·C·U/출처/잠금을 JSON v1로 고정한다. 원문 부록은 첫 줄120자 이내. 단편70%·본문 장면5개·서로 다른 두 꿈에 반복된 entity 조건 및 active job/미전송 저자 편집 차단. 제목/작가의 말 이외 문장은 고치지 않는다.
- 완성 요청은 Outbox에 같은 UUID로 보존하고 ACK 불명확 시 재사용한다. 충돌은 기존 active 상태를 복구하고 새 원고 확인 뒤 명시적 요청을 받는다. completed 책은 source 변경/다음 권/재실행과 분리해 보관한다.
- 완성본 읽기·실제 PDF 생성·공유/다운로드·다음 권 RPC를 연결했다. PDF는128×188mm·MaruBuri TTF,긴 제목/다페이지 차례를 처리한다. 공유 취소/실패에도 책은 남는다. OS가 파일 저장을 완료했는지는 앱이 확정하지 않는다.
- P6: BUILD_ID·source SHA-256·dirty HEAD·스키마 버전 release.json, 배포 전 정적 리소스 guard, 검증한 production deployment를 별도로 promote한다. 운영 SQL은 stage 비용/지연/실패/queue/cron 집계만 조회한다. 유료 추적 SDK·사용자 텍스트 수집·추가 공급자는 도입하지 않았다.

## 검증에서 발견해 수정한 문제

- 다권 SQLite에서 prototype seed의 단일-row 조회가 실패했다. 존재 확인을 limit1로 바꿨으며 재열기/다음 권 테스트를 통과했다.
- 큰 글자의 완료 확인 화면은 ListView 스크롤이 필요했다.375×667·1.6배·day/night에서 실제 탭과 확인 내용까지 검증했다.
- 실제 hosted 충돌 RPC는 처음에 시간 초과됐다. SQLSTATE40001이 PostgREST14에서 자동 무한 재시도를 유발하는 공식 알려진 문제다. 기존 migration을 다시 쓰지 않고 SQL0020으로 두 business-conflict RPC만 PT409로 교체했다. 클라이언트는 새 코드와 구버전40001을 모두 인식한다. [Supabase 공식 원인·대응](https://supabase.com/docs/guides/troubleshooting/high-cpu-and-infinite-transaction-retries-when-using-custom-error-codes-in-rpc-functions-77326b).
- hosted smoke 첫 실패의 finally에서 locked U cascade 삭제가 막혔다. 기존 delete_user_data RPC로 합성 데이터만 먼저 지운 뒤 Auth 계정을 삭제하도록 도구를 수정했고, 잔여 합성 계정2개도 정리했다. 실제 사용자 데이터는 삭제하지 않았다.

## 실제 실행한 증거

- Flutter 전체292개 통과(긴 PDF 제목/차례 회귀 포함).
- 별도 완성 UI/PDF5개: 제목→확인→완성본→PDF bytes→다음 권, 작은 화면 day/night×일반/1.6배. `book-title.png`, `book-confirm.png`, `book-completed.png`는 새로 지어낸 fixture다.
- Deno148개, 격리 PostgreSQL225개(업그레이드5 포함) 통과. 로컬 SQL 러너는 pg_cron을 설치하지 않으므로 hosted cron 검증과 구분한다.
- iPhone17Pro/iOS26.5 simulator 신규1개: 실제 SQLite 파일 완성/닫기/재열기→PDF bytes→책 UI→다음 권→이전 책 유지. OS 공유창·물리기기 테스트는 아니다.
- hosted Auth/PostgREST/RLS: 별도 합성 계정으로 stale409, 다른 소유자403/조회0건, 동시 완료2요청의 동일 스냅샷, 동시 다음 권2요청의 동일 VOL02, U/출처·부록 보존, 직접 책 위조403, 익명 worker403을 통과했다. 계정2개와 합성 데이터는 삭제했다.
- scheduler-only 실제 AI2건: 앱의 worker POST 없이 cron이 extract/link/plan/write/validate까지 실행했다. 두 건 모두 최종 원고 commit은 실패했다. 바퀴벌레 합성 꿈은V2/V5, 다른 합성 꿈은V2가 진단됐고 최종 attempts_exhausted로 끝났다. 성공 품질/E2E로 판정하지 않는다. frozen 규칙이나 DB 원고 교정을 하지 않았다.
- 실제 운영 집계에서 recovery cron2개 active/매분,cron 실패0,due queue0,stalled running0을 확인했다. 시험 데이터는 삭제되므로 위 수치가 소설 생성 성공률을 의미하지 않는다. 중앙 client funnel은 미수집, 물리 성능은 미측정이다.
- 정상 flutter analyze는 기존 한국어 경로 LSP JSON crash로 실패한다. 직접 Dart 분석/format/privacy/log/frozen 비교는 별도 실행하며 최종 결과는 배포 문서에 남긴다.

## 남은 것 / 완료로 세지 않는 것

Q 실측(비공개 꿈30·레퍼런스25·로컬 키), V2/V5 생성 안정성·첫 결과의 문학적 매력/사용자 검수, Q32 이후 LLM 완결 편집, OS push, 물리 iPhone STT·키보드·공유/파일 저장·터치/프레임 성능, Safari/PWA cold-start offline 인증/동의/bootstrap, 완전한 재시도 intent 복원, 실제 다기기 동시 편집 검수, 첫 작품의 독립/연속 선택 경험은 남아 있다. P4/P5/P6 전체를100%로 처리하지 않는다.
