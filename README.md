# oinkvalley-protos

내부 API **IDL** + **도메인별** 언어 stub 패키지.

원격: https://github.com/timesmoker/oinkvalley-protos.git (HTTPS)

## 레이아웃

```
board/v1/…                 ← IDL
profile/v1/…
bubble_pal_api/v1/…
bubble_pal_engine/v1/…
content_fetcher/v1/…
java/<domain>/             ← 도메인별 Gradle 모듈
python/generate.sh <domain>
```

## 태그 (도메인 필수)

```
<artifact>/<semver>
```

예: **한 번에 3개 초과 태그 push 금지** (GitHub가 push 이벤트 안 만듦).

```bash
# workflow 고친 커밋이 main에 있는 뒤
git tag board-v1/1.0.0 && git push origin board-v1/1.0.0
# Actions 확인 후 다음
git tag profile-v1/1.0.0 && git push origin profile-v1/1.0.0
```

또는 Actions → publish → Run workflow (artifact + version).

| 태그 | Java 좌표 |
|------|-----------|
| `board-v1/1.0.0` | `com.oinkvalley.protos:board-v1:1.0.0` |
| `profile-v1/0.1.0` | `com.oinkvalley.protos:profile-v1:0.1.0` |
| `bubble-pal-api-v1/…` | `…:bubble-pal-api-v1:…` |
| `bubble-pal-engine-v1/…` | `…:bubble-pal-engine-v1:…` |
| `content-fetcher-v1/…` | `…:content-fetcher-v1:…` |

그 태그 → **그 도메인만** 컴파일·publish. 다른 모듈 안 건드림.

> Actions는 태그가 가리키는 커밋의 workflow를 씀. 필터/`publish.yml` 고치면
> 태그 다시 푸시(또는 새 커밋으로 태그 이동) 해야 재실행됨.

Python: 같은 태그의 GitHub Release에 wheel 첨부  
(`oinkvalley-protos-board-v1==1.0.0` 등).

## 소비 — Java

필요한 도메인만:

```gradle
dependencies {
	implementation 'com.oinkvalley.protos:board-v1:1.0.0'
	implementation 'com.oinkvalley.protos:profile-v1:1.0.0'
}
```

로컬:

```bash
cd java
VERSION=1.0.0 ./gradlew :board:publishToMavenLocal
VERSION=1.0.0 ./gradlew :profile:publishToMavenLocal
```

## 소비 — Python

Import root: `oinkvalley_<domain>.v1` (앱 패키지 `content_fetcher` 등과 충돌 방지).

```bash
# 태그 슬래시는 URL에서 %2F
pip install \
  "https://github.com/timesmoker/oinkvalley-protos/releases/download/board-v1%2F1.0.1/oinkvalley_protos_board_v1-1.0.1-py3-none-any.whl"
```

`from oinkvalley_board.v1 import board_pb2_grpc`

> **1.0.0 wheel 빈 패키지 버그**: hatchling이 gitignore된 stub을 제외함 → `ignore-vcs = true` 로 수정. **1.0.1+** 재태그 필요.

## 로컬 생성

```bash
cd java && ./gradlew :board:generateProto
./python/generate.sh board
```

## v1 / 메이저

IDL 경로 `v1` 유지. 깨는 변경 시 폴더 `v2` + artifact `board-v2` (나중에).
