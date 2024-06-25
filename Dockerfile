FROM lukemathwalker/cargo-chef:latest-rust-bullseye AS chef
WORKDIR /usr/src

COPY model.onnx .

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /usr/src/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
COPY . .
RUN curl -fSL https://github.com/microsoft/onnxruntime/releases/download/v1.17.3/onnxruntime-linux-x64-1.17.3.tgz -o onnxruntime-linux-x64-1.17.3.tgz
RUN tar -xzf onnxruntime-linux-x64-1.17.3.tgz
RUN cargo build --release --features impure

FROM debian:bullseye-slim AS runtime
COPY --from=builder /usr/src/target/release/rmbg-server /rmbg-server
COPY --from=chef /usr/src/model.onnx /model.onnx
COPY --from=builder /usr/src/onnxruntime-linux-x64-1.17.3/lib/libonnxruntime.so /libonnxruntime.so
COPY --from=builder /usr/src/onnxruntime-linux-x64-1.17.3/lib/libonnxruntime.so.1.17.3 /libonnxruntime.so.1.17.3
ENV MODEL_PATH=/model.onnx
ENTRYPOINT ["/rmbg-server"]