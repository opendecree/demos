# Build stage
FROM golang:1.24-bookworm AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /bin/payroll-service .

# Runtime stage
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /bin/payroll-service /bin/payroll-service
COPY static/ /static/
USER nonroot:nonroot
ENTRYPOINT ["/bin/payroll-service"]
