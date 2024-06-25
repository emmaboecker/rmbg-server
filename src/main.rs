use std::env;
use std::io::{Cursor};
use std::sync::Arc;

use axum::extract::{DefaultBodyLimit, Multipart, State};
use axum::http::{header, StatusCode};
use axum::response::{Html, IntoResponse};
use axum::Router;
use axum::routing::{get, post};
use image::{ImageError, ImageFormat};
use rmbg::Rmbg;

#[tokio::main]
async fn main() -> eyre::Result<()> {
    tracing_subscriber::fmt::init();

    let rmbg = Rmbg::new(env::var("MODEL_PATH").unwrap_or("./model.onnx".to_string()))?;

    let app = Router::new()
        .route("/", get(root_get))
        .route("/", post(remove_background))
        .layer(DefaultBodyLimit::disable())
        .with_state(Arc::new(rmbg));

    let listener = tokio::net::TcpListener::bind(env::var("BIND_URL").unwrap_or("0.0.0.0:3000".to_string())).await.unwrap();

    tracing::info!("Listening on: {}", listener.local_addr().unwrap());

    axum::serve(listener, app).await.unwrap();

    Ok(())
}

async fn root_get() -> impl IntoResponse {
    Html(include_str!("./index.html"))
}

async fn remove_background(
    State(rmbg): State<Arc<Rmbg>>,
    mut multipart: Multipart,
) -> Result<impl IntoResponse, impl IntoResponse> {
    let field = match multipart.next_field().await.unwrap() {
        Some(field) => field,
        None => return Err((StatusCode::BAD_REQUEST, "No file found in request".to_string()))
    };

    let mut filename = match field.file_name() {
        Some(name) => name.to_string(),
        None => return Err((StatusCode::BAD_REQUEST, "File name couldn't be determined".to_string()))
    };

    let data = field.bytes().await.unwrap();


    let mut format = image::guess_format(&data).unwrap();

    let original_img = match image::load_from_memory_with_format(&data, format) {
        Ok(img) => img,
        Err(err) => return Err((StatusCode::BAD_REQUEST, format!("Failed to load image: {}", err)))
    };

    let img_without_bg = match rmbg.remove_background(&original_img) {
        Ok(img) => img,
        Err(err) => return Err((StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to remove background: {}", err)))
    };

    let mut bytes: Vec<u8> = Vec::new();
    if let Err(ImageError::Unsupported(_)) = img_without_bg.write_to(&mut Cursor::new(&mut bytes), format) {
        img_without_bg.write_to(&mut Cursor::new(&mut bytes), ImageFormat::Png).unwrap();
        tracing::debug!("Uploaded unsupported image format {}, converting to PNG", format.to_mime_type());
        format = ImageFormat::Png;
        filename.push_str(".png");
    }

    let headers = [
        (header::CONTENT_TYPE, format.to_mime_type()),
        (
            header::CONTENT_DISPOSITION,
            &format!("attachment; filename={:?}", filename),
        ),
    ];

    Ok((headers, axum::body::Bytes::from(bytes)).into_response())
}
