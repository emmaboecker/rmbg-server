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
RUN cargo build --release --features impure

FROM scratch AS runtime
COPY --from=builder /usr/src/target/release/railboard-api /railboard-api
COPY --from=chef /usr/src/model.onnx /model.onnx
ENV MODEL_PATH=/model.onnx
ENTRYPOINT ["/rmbg-server"]