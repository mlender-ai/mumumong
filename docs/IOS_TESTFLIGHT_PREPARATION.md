# iPhone 앱 / TestFlight 준비

2026-10-23. 사용자가 ‘기획서대로 iPhone 앱 준비’를 선택했다. 현재 공개 Vercel 주소는 웹 체험판이며 네이티브 앱 배포가 아니다.

> 2026-10-25: 입력/포커스·자동 저장·음성 경합 및 웹 지속성 보정은 [입력 QA 기록](ux-review/2026-10-25-input-qa/README.md)을 따른다. 아래 ARM64 아카이브는10/23 산출물이며 이번 수정의 설치 가능한 앱이 아니다. 최신 소스의 simulator 검사/빌드는 통과했지만 서명 identity0/개발팀 미설정은 그대로다. 계정·팀 준비 후 최신 소스로 다시 패키징/설치/실기기 녹음 검증해야 한다.

## 2026-10-26 계정 연결 / QA 범위 확인

- 후속 사용자 요청으로 **Apple 계정 연결·TestFlight 준비는 현재 작업에서 제외**했다. PWA의 가능한 로컬 QA/수정은 이 서명 단계와 독립적으로 진행한다. [10/26 PWA QA 기록](ux-review/2026-10-26-pwa-qa/README.md).
- 사용자는 Apple Developer 유료 계정을 보유하고 있으며 Xcode에 연결할 수 있다고 답했다. **계정 보유와 이 Mac의 연결·서명 준비는 별개다.** 실제 Xcode → Settings → Apple Accounts는 미연결 상태였고, 계정 추가 로그인 화면까지만 열었다. 이메일·비밀번호·2FA를 입력하거나 인증서·프로비저닝·앱 레코드를 생성하지 않았다.
- 같은 날 `security find-identity -v -p codesigning`은 **0 valid identities**, Runner 프로젝트는 **DEVELOPMENT_TEAM 미설정**임을 재확인했다. 사용자가 직접 계정을 연결하고 사용할 유료 개발팀을 확정하기 전에는 서명 빌드·TestFlight 업로드 완료로 보고하지 않는다.
- 사용자는 공개 QA 계정에 연령 확인·AI 처리 동의를 제출하지 않고 **로컬에서만 검사**하도록 지정했다. 공개 서비스의 동의 제출·QA 계정 생성·인증 후 저장/생성 검사는 진행하지 않는다. 새로 지어낸 로컬 fixture 검증과 공개 인증 후 전체 흐름의 검증 범위를 구분한다.
- 이번 확인은 계정·서명 상태 점검과 문서 갱신이다. 앱 코드를 바꾸거나 빌드·테스트·배포를 새로 실행하지 않았다. 기존 검증 결과는 아래의 날짜 및 연결된 입력 QA 기록을 따른다.

## 만들어 둔 것

- 실제 Flutter iPhone 앱의 ARM64 release 아카이브: `build/ios/archive/Runner.xcarchive`.
- 버전1.0.0,build2,bundle `com.mumumong.mumumong`,minimum iOS13,최종 빌드ID `ios-20261023T074903Z`.
- `ENV=staging ENGINE=remote AUTH=apple`로 빌드했다. mock 고정 결과나 웹뷰 포장 앱이 아니다. 기존 Supabase 프로젝트에 연결하며 browser-safe publishable key만 포함한다.
- **무서명 아카이브다. 설치 가능한 IPA가 없으며 TestFlight에 업로드하지 않았다.** 앱 본체는 로컬 약32MiB, 별도 dSYM은154MiB다. 아카이브 전체194.7MB는 사용자 다운로드 크기가 아니며, TestFlight 실제 다운로드/설치 크기는 아직 모른다.
- native 녹음은 `SFSpeechRecognizer`,ko-KR,`requiresOnDeviceRecognition=true`,최대5분. AVAudioEngine 버퍼만 사용하고 음성 파일을 만들거나 서버 STT로 폴백하지 않는다. **전사된 꿈 텍스트**의 AI 처리는 별도 동의 후 기존 서버 경로를 따른다.
- 사용하지 않는 RMS 계산/채널 전송을 제거했다. 전사는 계속 전달·자동저장한다. 실패 안내는 저장 버튼을 덮는 SnackBar 대신 입력 화면의 정적인 안내 슬롯에 표시한다.
- 녹음 버튼은 명확한 마이크/정지 아이콘으로 표시한다. 입력/STT 중 Orb/beam을 넣지 않는다.

## 지금 막힌 지점 — 서명과 계정

실제로 `security find-identity -v -p codesigning`은 **0 valid identities**, Runner는 **DEVELOPMENT_TEAM 미설정**이다. 서명 모드 스크립트도 이 지점에서 안전하게 종료했다. 인증서/프로비저닝/앱 등록을 임의 생성하거나 Apple 계정 비밀번호를 읽지 않았다.

사용자가 할 일:

1. Apple Developer Program 유료 회원 계정을 Xcode → Settings → Accounts에 직접 연결한다. 비밀번호/2FA/인증서는 채팅에 보내지 않는다.
2. `ios/Runner.xcworkspace`에서 Runner → Signing & Capabilities에 자신의 유료 개발팀을 선택한다. bundle ID의 소유권과 Sign in with Apple capability를 확인한다. 임의 팀/식별자로 바꾸지 않는다.
3. App Store Connect에 같은 bundle ID의 앱 레코드가 필요하다. Apple 로그인 공급자 설정/실계정 로그인도 확인해야 한다.

계정·팀 준비 후:

```sh
# 이미 업로드한 번호보다 큰 정수를 사용한다. 최초 준비 번호는2다.
MUMUMONG_IOS_BUILD_NUMBER=2 bash tool/prepare_ios_trial.sh --signed
```

스크립트는 서명 패키지만 만들고 자동 업로드/공개하지 않는다. Xcode Organizer에서 Validate→Distribute App→App Store Connect로 검토 후 전송한다. Apple의 처리 완료와 내부 TestFlight 설치를 확인해야 ‘배포됨’으로 보고할 수 있다. 외부 테스터는 별도 검토/테스터 설정이 필요할 수 있다. [Apple 업로드 안내](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds), [Flutter iOS 배포 안내](https://docs.flutter.dev/deployment/ios).

## 실제 검증 / 미검증

- Flutter299개, 신규 native simulator1개 통과. 신규는 마이크 아이콘→인식 불가 주입→텍스트 전환→초안 자동저장→키보드 위 저장 버튼 접근이다. 실패를 주입한 UI 검사이지 실제 마이크 정확도 검사가 아니다.
- 초기 CanvasKit font manifest는 등록된 모든 폰트를 다운로드한다는 설치된 Flutter 엔진 소스를 확인했다. 화면에서 쓰지 않는 PDF Bold3,351,940bytes를 일반 asset으로 옮겨 시작 시 font download/등록에서 제외했다. PDF를 내보낼 때만 rootBundle로 읽는다. 최종 native archive의 manifest에도 Bold가 없고 파일은 정상 포함돼 있으며, bundle 로드 회귀도 통과했다. 실제 압축 전송량/시작 시간은 미측정이다.
- ARM64 release archive 빌드 성공, App Settings validation 통과. 기본 launch image placeholder 경고는 남았으며 계정 연결 이후 출시 자산 검수에서 정리해야 한다.
- 폰트 분리 후 ARM64 archive와 simulator release를 다시 빌드했다. 웹 수정본은 build`20261023T075122Z`로 공개 반영했으며18파일 hash/HTTP200 및390×844 설치 안내를 확인했다. 이 웹 배포를 TestFlight 배포로 세지 않는다.
- 120Hz 모의 clock120 tick에 배경 repaint 알림이28–31회로 제한됨, background 정지/foreground 재개, 전체 루프 후 눈에 보이는 움직임, 동작 줄이기 및 day/night/키보드/큰 글자 검증 통과. 물리기기 FPS/터치 지연·메모리·시작 시간은 미측정이다.
- 초기 버튼 blur 제거 실험은 다수 시각 회귀를 일으켜 채택하지 않았다. 기존 유리 재질/버튼 눌림은 유지한다. 수정 후 전체 시각 비교가 통과했다.
- **미검증/남은 작업:** 서명 IPA·Apple 실계정 로그인·TestFlight 업로드/설치·물리 iPhone의 기상 직후 STT10회·한국어 품질/중단/권한/5분·공유/파일 저장·성능·출시용 launch 자산·배포 compliance/metadata 확인.
- 서버 모델/프롬프트/SQL은 이번 수정에서 바꾸지 않았다. 이전 실측의 V2/V5 생성 실패가 해결됐다는 뜻이 아니다. 웹 anonymous 기록을 Apple native 계정으로 자동 이전하는 기능도 없다. 기존 웹 기록은 지우지 말고 먼저 JSON 내보내기를 권한다.

## 브라우저 막대와의 차이

Vercel 도메인명은 브라우저 주소다. 뒤로/공유/새로고침은 브라우저 버튼이며 앱에서 강제로 제거할 수 없다. iPhone 앱에는 이 브라우저 영역이 없다. 시간/배터리/홈 표시줄 같은 iOS 시스템 영역은 남을 수 있다.

웹은 Safari → 공유 → 홈 화면에 추가 → ‘웹 앱으로 열기’로 브라우저 막대 없이 실행할 수 있다. 이는 네이티브 앱이 아니며 온디바이스 녹음이 생기지 않는다. Safari와 설치 웹 앱은 저장소가 분리될 수 있으므로 기존 기록을 자동 옮긴다고 안내하지 않는다. [Apple 공식 홈 화면 웹 앱 안내](https://support.apple.com/en-by/guide/iphone/iphea86e5236/ios).
