import os

import fastapi
import pathlib
import hashlib

app = fastapi.FastAPI()

VIDEO_ROOT = os.environ["DAS_FILEPATH"] if "DAS_FILEPATH" in os.environ else "./video_uploads"
os.makedirs(VIDEO_ROOT, exist_ok=True)

@app.get("/")
async def hello():
    return {"message": "Hello World"}


@app.post("/upload/")
async def upload(video: fastapi.UploadFile = fastapi.File(...)):
    await video.seek(0)
    content = await video.read()

    print(video.filename)
    print(video.content_type)

    # save video
    suffix = pathlib.Path(video.filename).suffix
    file_hash = hashlib.md5(content).hexdigest()
    filename = file_hash + suffix
    path = os.path.join(VIDEO_ROOT, filename)
    open(path, "wb").write(content)

    return {"hello": "world"}


