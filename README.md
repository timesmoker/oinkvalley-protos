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

예:

```bash
git tag board-v1/0.0.1 && git push origin board-v1/0.0.1
git tag profile-v1/0.1.0 && git push origin profile-v1/0.1.0
git tag bubble-pal-engine-v1/0.0.2 && git push origin bubble-pal-engine-v1/0.0.2
```

| 태그 | Java 좌표 |
|------|-----------|
| `board-v1/0.0.1` | `com.oinkvalley.protos:board-v1:0.0.1` |
| `profile-v1/0.1.0` | `com.oinkvalley.protos:profile-v1:0.1.0` |
| `bubble-pal-api-v1/…` | `…:bubble-pal-api-v1:…` |
| `bubble-pal-engine-v1/…` | `…:bubble-pal-engine-v1:…` |
| `content-fetcher-v1/…` | `…:content-fetcher-v1:…` |

그 태그 → **그 도메인만** 컴파일·publish. 다른 모듈 안 건드림.

> Actions는 태그가 가리키는 커밋의 workflow를 씀. 필터/`publish.yml` 고치면
> 태그 다시 푸시(또는 새 커밋으로 태그 이동) 해야 재실행됨.

Python: 같은 태그의 GitHub Release에 wheel 첨부  
(`oinkvalley-protos-board-v1==0.0.1` 등).

## 소비 — Java

필요한 도메인만:

```gradle
dependencies {
	implementation 'com.oinkvalley.protos:board-v1:0.0.1'
	implementation 'com.oinkvalley.protos:profile-v1:0.0.1'
}
```

로컬:

```bash
cd java
VERSION=0.0.1 ./gradlew :board:publishToMavenLocal
VERSION=0.0.1 ./gradlew :profile:publishToMavenLocal
```

## 소비 — Python

```bash
pip install \
  "https://github.com/timesmoker/oinkvalley-protos/releases/download/board-v1/0.0.1/oinkvalley_protos_board_v1-0.0.1-py3-none-any.whl"
```

## 로컬 생성

```bash
cd java && ./gradlew :board:generateProto
./python/generate.sh board
```

## v1 / 메이저

IDL 경로 `v1` 유지. 깨는 변경 시 폴더 `v2` + artifact `board-v2` (나중에).
