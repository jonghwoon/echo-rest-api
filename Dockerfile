# 1단계: 빌드 환경 (OS: Alpine Linux - 가볍고 보안에 유리)
FROM golang:1.26.3-alpine AS builder

# 작업 디렉터리 설정
WORKDIR /app

# 의존성 파일 먼저 복사 및 다운로드 (캐시 활용을 위해)
COPY go.mod go.sum ./
RUN go mod download

# 소스 코드 전체 복사 및 빌드
COPY . .

# 💡 [변경] CGO 비활성화 및 리눅스 타겟으로 메인 앱과 마이그레이션 앱을 각각 빌드합니다.
# 1. 메인 서버 실행 파일 (main) 빌드
RUN CGO_ENABLED=0 GOOS=linux go build -tags netgo -ldflags '-s -w' -o main .

# 2. 마이그레이션 실행 파일 (migrate_app) 빌드
# ※ 만약 프로젝트 구조상 migrate.go 파일 위치가 다르다면 아래 경로('migrate/migrate.go')를 실제 위치에 맞게 수정해주세요.
RUN CGO_ENABLED=0 GOOS=linux go build -tags netgo -ldflags '-s -w' -o migrate_app migrate/migrate.go


# 2단계: 실행 환경 (초경량 빈 깡통 OS)
FROM alpine:latest

# 실행 환경 보안을 위해 ca-certificates 패키지 설치 (외부 API 호출이나 HTTPS 통신 대비)
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# 💡 [변경] 1단계에서 만들어진 2개의 실행 파일(main, migrate_app)을 모두 가져옵니다.
COPY --from=builder /app/main .
COPY --from=builder /app/migrate_app .

# 컨테이너 포트 노출 (이전 설정대로 8080 사용)
EXPOSE 8080

# 💡 [변경] 백엔드 컨테이너가 켜질 때 마이그레이션을 먼저 실행하고, 성공하면 메인 서버를 구동합니다.
CMD ["/bin/sh", "-c", "./migrate_app && ./main"]