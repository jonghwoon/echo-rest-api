# 1단계: 빌드 환경 (OS: Alpine Linux - 가볍고 보안에 유리)
FROM golang:1.26.3-alpine AS builder

# 작업 디렉터리 설정
WORKDIR /app

# 의존성 파일 먼저 복사 및 다운로드 (캐시 활용을 위해)
COPY go.mod go.sum ./
RUN go mod download

# 소스 코드 전체 복사 및 빌드
COPY . .
# CGO 비활성화 및 리눅스 타겟으로 빌드하여 실행 파일(main) 생성
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

# 2단계: 실행 환경 (초경량 빈 깡통 OS)
FROM alpine:latest

WORKDIR /root/

# 1단계에서 만들어진 실행 파일(main)만 가져옴 (소스 코드는 버림)
COPY --from=builder /app/main .

# (선택) 필요한 설정 파일이나 .env가 있다면 여기에 추가 복사
# COPY --from=builder /app/.env .

# 컨테이너 포트 노출 (이전 설정대로 8080 사용)
EXPOSE 8080

# 백엔드 서버 실행
CMD ["./main"]