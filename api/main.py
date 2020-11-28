import os

import fastapi

app = fastapi.FastAPI()

VIDEO_ROOT = os.environ["DAS_FILEPATH"] if "DAS_FILEPATH" in os.environ else "./video_uploads"


@app.get("/")
async def hello():
    return {"message": "Hello World"}


@app.post("/upload/")
async def upload(video: fastapi.UploadFile = fastapi.File(...)):
    await video.seek(0)
    content = await video.read()

    print(content)
    print(video.filename)
    print(video.content_type)
    open("/tmp/hello.mkv", "wb").write(content)

    return {"hello": "world"}


