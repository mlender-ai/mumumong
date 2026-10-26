# 시작 화면 단순화 · 하나의 Thinking Orb

2026-10-26 KST. 사용자5개 화면 지적에 대한 후속이다. 제품/계정/소설 엔진 변경이 아니라 설치 안내 제거·정보 위계·처리 모션 정리다. 사용자는 설치 origin을 기억하지 못한다고 답했다. 기존 아이콘/기록을 삭제하거나 계정을 이전하지 않는다.

## 원인과 변경

| 지적 | 원인 | 적용 |
|---|---|---|
| 설치가 끝나도 긴 안내가 다시 나옴 | `/install.html`이 설치 모드에서도 설명 화면에 머물고 소개/설정에서 다시 진입 | 앱 내 설치 안내 제거. 기존 링크는 같은 origin의 `/`로만 연결. no-JS에서는 짧은 ‘무무몽 열기’ 링크 |
| 동의 화면 내용이 너무 많음 | 전체 고지·제공사·약관·버전·출처 설명·반복 경고를 한 번에 표시 | 목적/제공사 한 문장 + 선택 상세 + 필수 확인2개 + 주 행동. 상세에는 원래 서버 정책/약관/데이터 안내/버전 유지 |
| ‘동의 기록’이 무엇인지 불명확 | 내부 검증 단계를 그대로 표시 | 대기 문구를 ‘시작할 준비를 하고 있어요’로 변경. 서버 동의 확인/거절/버전 재동의는 그대로 |
| 설정 시작 화면 복잡/CTA가 너무 멂 | 영문 메타·기본값 요약·설명과 별도 하단 고정 CTA | 제목+한 문장+시작. 선택 설정은 보조 ‘이야기 설정’. 관련 내용과 행동32px 묶음/24px gutter/280px primary |
| Orb가 잠깐 보인 후 다른 형태로 변함 | `DreamOrbState`마다 라이브러리의 working/web/ribbon/rubik을 교체 | 생산 wrapper는 레퍼런스의 `composing` 모양 하나로 고정. 실제 처리 단계와 접근성 설명은 별개. 입력/STT는 정적 유지 |

[Libraries.dev 원본](https://libraries.dev/orbs)을 브라우저에서 직접 대조했다. 첨부된 ‘Thinking…’ 예시는 `composing` 이미지이며 촘촘한 띠가 있는 구형이다. `connecting`은 사용자가 지적한 node-web이고, `working`은 희박한 궤도 입자다. 첫 검토 후보의 working은 최종 대조 후 제외했으며 공개 별칭으로 승격하지 않았다. 최종 Dart wrapper는 Flutter 포트 thinking_orbs0.2.0의64px composing을 사용한다. 원본 React 코드를 실행한 것은 아니다.

## 검증 범위

시작 링크 → 소개 → 서버 고지 UI → 필수 확인 → 첫 원고 설정 → 처리 대기까지의 표시/조작 계약을 검사했다. 동의·첫 원고 생성은 로컬 fake/adapter만 사용했다. 공개 연령/AI 동의·계정 생성·꿈/원고 저장·AI 생성은 제출하지 않았다.

- 전체 Flutter VM314개 통과. 필수 확인/서버 거절·정책 버전 차단을 포함한다.
- 새 회귀6개: 상세 접기와 체크 보존,375×667/160% 밝게·밤 스크롤/터치, 원고 생성 실패 후 선택 보존/중복 요청 방지,5처리 단계의 동일 mounted Orb/형태, 실제 raster 움직임과 동작 줄이기의 정지.
- 첫 큰 글자 검사에서 로고/단계 표시가17px 넘치는 것을 발견해 Wrap으로 수정했다. 이후 예외/놓친 탭 경고 없이 통과했다.
- 변경된 consent1/setup10/processing10 golden을 이 폴더에 분리했다. 과거 화면 증거를 덮어쓰지 않았다. 나머지 기존 화면 비교도 전체 테스트에서 유지한다.
- 직접 Dart 분석/format 통과. `flutter analyze --no-pub`는 기존 한글 경로 LSP JSON crash(exit255)로 실패하며 통과로 세지 않는다.
- 로컬 release 브라우저390×844에서 상세 펼침/접기·필수 확인 전후 버튼·선택 설정·5단계 모션을 직접 확인했다. `tool/start_flow_review.dart`는 로컬 전용이며 계정/저장소/AI를 연결하지 않는다. 실제 모델 처리 시간이 아니다.

브라우저와 생산형 로컬 테스트는 실제 iPhone 설치 아이콘·키보드·음성 인식/터치 지연·AI 품질 검증이 아니다. 기존 초기화/초안 복구/스키마5/manifest identity 및 Q 동결을 유지했다.

## 변경 화면

로컬 UI 어댑터, 공개 동의 제출 아님:

![간결한 동의](browser-consent-ready.png)
![첫 이야기 시작](browser-setup.png)

최종 Orb는 아래처럼 띠 형태를 유지한다. 로컬 review는2초마다5가지 실제 상태 enum을 순환하지만 모양은 composing으로 고정된다. 두 브라우저 프레임은 같은 기하의 움직임이며 warning/error 항목0개였다. 이전 `browser-orb-a.png`는 제외한 working 후보이며 최종 증거가 아니다.

![고정한 Thinking Orb 프레임A](browser-thinking-a.png)
![같은 Thinking Orb 프레임B](browser-thinking-b.png)

## 최종 배포 기록

- 공개 주소: https://mumumong-live-trial.vercel.app/
- 프로젝트/팀: `prj_VtS5dNxLxW12SsJMykVDhnXPtiUe` / `mlender-ais-projects`. CLI의 기존 연결을 확인했고 보호 설정은 변경하지 않았다. MCP는 이 팀403으로 접근할 수 없어 같은 팀의 기존 CLI 인증을 사용했다.
- 빌드 `20261026T111252Z`, production 배포 `dpl_FMV2esbwj6wUu8ohtgv5KnhKyvBP`, **READY/promoted**. staging URL은 `https://mumumong-live-trial-45mje4aik-mlender-ais-projects.vercel.app`.
- source SHA256 `7362c0890fdf76ea5899dbabccfbb9b464f6d1683e409e66c86596e77d86a4af`; HEAD`6c4e296f9b3d5f06d6a50e9c1aac74b7d9f1d234`, dirty tree 명시. 새 commit/push 없음.
- 보호된 stage와 공개 별칭에서 각각24리소스 해시 일치. 다른 빌드로 재컴파일하지 않고 같은 deployment를 promote했다. public promotion 직전에는 기존075104Z임을 확인했다.
- 최종 deploy script에서 worker lock-match 재빌드,Chrome 입력6개,실제 WASM/IndexedDB commit1개,설치JS6개·초기화JS5개,실제 `lib/main.dart` remote/auth staging web release 및 compiled bootstrap 문법 검사 통과. 최종 무서명 iOS simulator build 통과. Worker SHA256`af7417de6a9acf7417dac63d1ba166d0512fbe9c63080544f94c56afa83d1c76` 유지.
- 실제 production 번들을 로컬 기본 데스크톱 크기에서, 공개 주소의 동의 레이아웃을390×844에서도 검수했다. install 링크가 `/`로 바로 연결하고 큰 소개 화면은 남아 있다. 공개 동의 페이지는 짧은 설명/체크2개/접힌 고지/비활성 시작을 보여준다. 펼치면 실제 서버 정책/링크/버전이 보이고 다시 접힌다. 체크·제출·계정/AI 생성 없음. 브라우저 warning/error 항목0개.
- 배포 후 Vercel error 로그10분/최대20건 한정 조회0개. 이 정적 웹 조회는 클라이언트·Supabase·AI 정상 보증이 아니다. 장기 모니터/새 drain은 설정하지 않았다.
- format/diff검사 통과, 동결4파일은 edfc13c와 동일, 보호된 eval 경로 추적 파일0. 서버 엔진/스키마·원고 본문·원음 처리 변경 없음.
- 되돌릴 이전 공개 배포: `dpl_4by67PjgtyrgekGGuQg3euKQyuNc` / build`20261026T075104Z`. 실제 iPhone PWA 아이콘 실행/IME/음성/프레임·터치 지연과 동의 후 hosted 소설 품질은 미검증이다.

실제 공개 동의 화면(동의 제출 없음):

![공개 반영](public-consent.png)
