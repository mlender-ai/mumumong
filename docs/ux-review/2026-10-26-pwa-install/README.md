# 설치 PWA의 브라우저 막대 — 2026-10-26

## 조사

사용자 사진에서 포모클럽은 주소/뒤로가기/공유 막대가 없고 무무몽에는 있다. 시간·배터리·홈 표시줄은 두 사진 모두 남는다. 요구는 브라우저 크롬 없는 설치형 실행이며 native/TestFlight가 필수인 요구가 아니다. 앞선 설명은 일반 탭·설치 앱·scope 밖 이동을 충분히 구분하지 못했다.

요청한 `mlender-ai/fomo-club`의 `apps/web/app/layout.tsx`, `next.config.mjs`, `vercel.json`을 읽었다. 확인한 root layout에는 별도 PWA metadata 정의가 없으며 config의 legacy redirects는 같은 origin 내부 경로다. 확인 시 main SHA는 `b710ddb4d627fa05dc677be5c722d7b0bd7ec2a9`였다. 사용자의 설치 기기/실제 배포 commit 검증은 아니며 포모클럽은 수정하지 않았다.

### 확인된 문제 경로와 추정의 경계

| 주소/파일 | 수정 전 실제 확인 |
|---|---|
| live-trial root | HTTP200, 자동 redirect 없음, capable=yes, standalone manifest, scope/start/id=`/` |
| mobile-preview root | HTTP200이지만 meta refresh와 `location.replace`가 다른 origin인 live-trial로 이동 |
| 구주소 worker | 활성화 시 client를 `page.navigate('https://mumumong-live-trial.vercel.app/')`로 강제 이동 |

따라서 standalone 태그가 없어서만 생긴 문제가 아니다. 구주소 설치 아이콘이 이 경로를 밟으면 scope 밖 origin을 연다. 이는 사진의 Safari View Controller 형태와 일치하는 원인 경로다. **사용자 기기의 실제 설치 origin은 질문했지만 배포 시점까지 답이 없어 확정하지 않았다. 그 기기의 막대가 사라졌다고 판정하지 않는다.** 정식 origin 설치라면 Open as Web App 설정·실제 실행 URL/모드·외부 링크를 추가 확인해야 한다.

공식 근거:

- [Apple WWDC23](https://developer.apple.com/videos/play/wwdc2023/10120/?time=521): standalone은 브라우저 toolbar 없이 실행하며 iOS Home Screen 앱의 scope 밖 링크는 Safari View Controller를 연다.
- [WebKit Safari26.0](https://webkit.org/blog/17333/webkit-features-in-safari-26-0/): iOS26은 홈 화면 추가 시 Open as Web App이 기본이며 사용자가 끌 수 있다. iOS Home Screen 웹 앱에 service worker는 필수가 아니다.
- [W3C scope](https://www.w3.org/TR/appmanifest/#navigation-scope): scope 밖에서는 origin 표시 UI를 권고한다. CSS/fullscreen으로 origin 보안 경계를 숨기는 문제가 아니다.
- [Apple Safari 설정](https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/ConfiguringWebApplications/ConfiguringWebApplications.html): standalone 브라우저 UI와 시스템 status bar를 구분한다.

## 수정

1. 구주소 HTML 자동 이동과 worker client 강제 이동을 모두 제거했다. worker는 등록만 해제하며 기존 탭을 reload하거나 캐시/IndexedDB/세션을 삭제하지 않는다. 구주소는 같은 origin에 남는 안내와 명시적 설치 링크만 제공한다. [로컬 확인](retired-origin-no-redirect.png).
2. 정식 `web/install.html`은 같은 origin의 manifest/아이콘을 사용한다. 실제 `navigator.standalone`/display-mode로 browser/standalone을 구분하고 Safari→홈 화면 추가→Open as Web App→새 아이콘 실행을 안내한다. 복사는 정식 public root만 사용하며 실패 안내가 있다. 설치를 강제하지 않는다. [공개 안내](public-install-guide.png).
3. manifest id/start_url/scope=`/`, display=standalone을 유지했다. fullscreen/CSS로 크롬을 숨기거나 시스템 영역을 덮지 않았다. 계정·원고·초안·DB/스키마·동의와 엔진/Q는 그대로다. origin 간 세션 전달/자동 이전을 추가하지 않았다.
4. Flutter 설치 안내도 구주소 이동 문제와 정확한 설치 페이지를 설명한다. 사용자 홈/입력/리더 디자인은 바꾸지 않았다.
5. 설치 JS6개·필수 artifact/해시 검사를 추가했다. 구주소 deploy도 기존 project 확인→stage→두 파일 검증→동일 deployment promote로 바꿨다. 과거 ‘아이콘을 삭제하라’ 문구를 제거했다. 기존 아이콘/데이터를 유지하고 원래 화면에서 기록을 먼저 내보내도록 안내한다.

## 실제 검증

- Flutter format124파일 변경0, VM **309개 통과**, 직접 Dart 분석 No issues.
- `flutter analyze --no-pub`: 기존 한국어 경로 LSP JSON **exit255**, 통과 아님.
- 신규 설치 JS **6개**: stable id/start/scope, same-origin manifest, navigator/media/browser3조건, copy 성공/실패, HTML/worker 강제 이동·데이터 삭제 부재.
- 기존 startup JS **5개**, Chrome 입력 **6개**, 실제 WASM/IndexedDB commit **1개** 통과. 배포 스크립트가 재실행했다.
- 실제 main.dart remote web release 및 compiled bootstrap 문법 검사 통과. iOS source/녹음은 바꾸지 않았으며 native build·STT는 이번에 미실행이다.
- 실제 브라우저390×844에서 로컬/공개 설치 페이지의 browser 판별·안내·copy 피드백을 확인했다. 모의 standalone=true는 Node 단위 검사이며 실제 iPhone 설치 성공이 아니다.
- 로컬 구주소의 자동 이동 부재, 공개 HTTP redirect header 부재 및 HTML/worker bytes 일치를 확인했다. 공개 브라우저에서도 구주소가 자기 origin에 남고 warn/error0개임을 확인했다. [공개 구주소 안내](public-retired-guide.png).
- shell 문법·diff whitespace·로그/평가 데이터 guard·동결4파일 edfc13c 비교 통과. 공개 계정·동의·꿈·원고·AI는 제출하지 않았다.
- 현재 iOS Simulator I/O 키 제어가 비활성이고 앱 활성화 API도 없어 실제 Safari 설치 조작을 완료하지 못했다. 실제 iPhone 설치 origin/새 아이콘/막대 제거는 **미검증**이다. 안내 페이지를 실기기 성공으로 세지 않는다.

## 배포

| 대상 | 실제 배포 |
|---|---|
| 정식 앱/설치 안내 | `dpl_4by67PjgtyrgekGGuQg3euKQyuNc`, READY/promoted |
| 정식 build ID | `20261026T075104Z` |
| source SHA256 | `5d2099b296fcdb313d1396058ac0c478514739c3382de8d50dc1be3f45ac61d0` |
| 구주소 안내/worker | `dpl_8ryKj4EfwtqZK3P3EwSrgLLPfCNq`, READY/promoted |

같은 team `mlender-ais-projects`의 정식 project `prj_VtS5dNxLxW12SsJMykVDhnXPtiUe`와 구주소 `prj_ThQsdQXTDctXFoEn89UDy5LtvPjZ`를 확인했다. 정식 stage/public24파일과 구주소 stage/public2파일 해시 일치. protection은 유지했다. HEAD6c4e296+기존 dirty tree이며 commit/push하지 않았다.

설치 페이지: https://mumumong-live-trial.vercel.app/install.html

Vercel10분 bounded error scan은 exit0/항목0개였다. client/Supabase/실제 생성이나 지속 모니터링의 정상 보증이 아니다. 정식 rollback 후보는 이전 `dpl_HYPcxk6Vx38tM7NLHbqhM5tWoUm5`이며 설치 안내는 없다. 구주소를 이전 자동 이동 배포로 되돌리면 문제 경로를 복원하므로 맹목적으로 rollback하지 않는다.

## 남은 사용자 조작

이미 설치된 아이콘의 원래 origin은 서버로 재바인딩할 수 없다. 구주소 아이콘이었다면 **기존 아이콘을 보존**한 채 정식 설치 페이지를 Safari에서 열어 Open as Web App으로 새 아이콘을 추가하고 그 아이콘으로 실행해야 한다. 기존 기록을 먼저 내보내며 자동 이전/익명 계정 복구를 약속하지 않는다. 정식 origin 아이콘이었다면 실제 설치/실행 모드부터 확인하고 임의 삭제·재설치를 요구하지 않는다.
