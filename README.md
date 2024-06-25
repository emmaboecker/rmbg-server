# Remove Background Server

Simple web app with simple frontend to easily remove background from images by dragging onto webpage.

## Running
Instructions on how to run this project



### Docker
#### batteries íncluded (recommended)
There is a docker image available on ghcr.io: `ghcr.io/emmaboecker/rmbg-server:main`

docker-compose.yml:
```yaml
version: '3.8'

services:
  rmbg-server:
    image: "ghcr.io/emmaboecker/rmbg-server:main"
    ports:
      - "3000:3000"
```

#### Dockerfile
There is a [Dockerfile](./Dockerfile) available, which can be used, for building it yourself you need the [model](https://huggingface.co/briaai/RMBG-1.4/blob/main/onnx/model.onnx) laying in the same directory when building

### NixOs (technically recommended)
Even though this is my personal recommendation and I would like to use it myself, the current version of libonnxruntime in nixpkgs is too old and will not work with this project without a big hastle, so currently you should use docker :(

---

## Credits 

Idea from [Fireship on YouTube](https://www.youtube.com/watch?v=cw34KMPSt4k), originally in python, recreated in rust.