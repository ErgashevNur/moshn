# ---- Build stage ----
FROM golang:1.21-alpine AS build
WORKDIR /src
RUN apk add --no-cache git
COPY go.mod go.sum ./
RUN go mod download
COPY . .
# Statik binary (CGO yo'q) — alpine'da ishlaydi
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /app/server .
# Yordamchi tool'lar (admin yaratish, seed) — runtime image'da kerak
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /app/createadmin ./tools/createadmin
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /app/seed ./tools/seed

# ---- Runtime stage ----
FROM alpine:3.19
RUN apk add --no-cache ca-certificates tzdata
ENV TZ=Asia/Tashkent
WORKDIR /app
COPY --from=build /app/server .
COPY --from=build /app/createadmin .
COPY --from=build /app/seed .
RUN mkdir -p /app/uploads
EXPOSE 8080
ENV GIN_MODE=release
CMD ["./server"]
