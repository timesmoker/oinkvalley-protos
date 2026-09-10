# oinkvalley-protos

내부 API **IDL** (`.proto`) + **언어별 stub 패키지** 배포.

원격: https://github.com/timesmoker/oinkvalley-protos.git (HTTPS)

## 레이아웃

```
board/v1/…                 ← IDL (소스 오브 트루스)
profile/v1/…
bubble_pal_*/v1/…
content_fetcher/v1/…
java/                      ← stub 생성 → Maven (GitHub Packages)
python/                    ← stub 생성 → Release wheel
.github/workflows/publish.yml
```

서비스 레포에 `.proto` 복붙 금지. **패키지 의존.**

## 배포

```bash
git tag 0.0.1
git push origin 0.0.1
```

| 언어 | 어디에 | 좌표 |
|------|--------|------|
| **Java** | GitHub Packages (Maven) | `com.oinkvalley:oinkvalley-protos:0.0.1` |
| **Python** | GitHub **Release** asset | `oinkvalley-protos-0.0.1-*.whl` |

> GitHub Packages에 공식 PyPI 레지스트리 없음 → Python은 Release wheel.

## 소비 — Java

```gradle
repositories {
	mavenCentral()
	maven {
		url = uri('https://maven.pkg.github.com/timesmoker/oinkvalley-protos')
		credentials {
			username = System.getenv('GITHUB_ACTOR') ?: ''
			password = System.getenv('GITHUB_TOKEN') ?: ''
		}
	}
}

dependencies {
	implementation 'com.oinkvalley:oinkvalley-protos:0.0.1'
}
```

로컬 토큰: `GITHUB_TOKEN` (packages read).  
로컬 publish 테스트: `cd java && VERSION=0.0.1-SNAPSHOT ./gradlew publishToMavenLocal`

## 소비 — Python

Release에서 wheel 받아 설치:

```bash
# 예: 0.0.1 Release asset
pip install \
  "https://github.com/timesmoker/oinkvalley-protos/releases/download/0.0.1/oinkvalley_protos-0.0.1-py3-none-any.whl"
```

또는 CI에서 `gh release download`.

## 로컬 생성

```bash
cd java && ./gradlew build

pip install 'grpcio-tools>=1.68'
./python/generate.sh
```
