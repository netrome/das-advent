FROM alpine:latest AS app-builder

# Install curl and other dependencies (if necessary)
RUN apk add --no-cache curl make

# Download the Elm binary
RUN curl -L -o elm.gz https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz \
    && gunzip elm.gz \
    && chmod +x elm \
    && mv elm /usr/local/bin/

WORKDIR /app
COPY app/ ./
RUN make

FROM python:3.10-alpine

RUN apk update \
    && apk upgrade \
    && apk add --no-cache gcc musl-dev python3-dev libffi-dev openssl-dev cargo

WORKDIR /app
COPY api/ ./api
COPY static/ ./static
COPY requirements.txt ./
COPY --from=app-builder /app/dist ./templates

RUN pip install -r requirements.txt

EXPOSE 8080
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8080"]
