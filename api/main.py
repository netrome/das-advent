import os
import pathlib
import hashlib

import fastapi
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles

VIDEO_ROOT = os.environ["DAS_FILEPATH"] if "DAS_FILEPATH" in os.environ else "./video_uploads"
os.makedirs(VIDEO_ROOT, exist_ok=True)

app = fastapi.FastAPI()

app.mount("/video", StaticFiles(directory=VIDEO_ROOT), name="static")

templates = Jinja2Templates(directory="./templates")

@app.get("/")
async def hello():
    return {"message": "Hello World"}


@app.get("/videos/")
async def videos():
    return {"videos": os.listdir(VIDEO_ROOT)}


@app.get("/video/{name}")
async def video(name: str):
    return {"message": "Hello World"}


@app.post("/upload/")
async def upload(video: fastapi.UploadFile = fastapi.File(...)):
    await video.seek(0)
    content = await video.read()

    given_name = baptise(video.filename, content)
    dump(given_name, content)

    return {"hello": "world"}


@app.get("/upload/")
async def upload_page(request: fastapi.Request):
    return templates.TemplateResponse("upload.html", {"request": request})


## Helpers ---


def baptise(filename, content):
    suffix = pathlib.Path(filename).suffix
    file_hash = hashlib.md5(content).hexdigest()
    return file_hash + suffix


def dump(given_name, content):
    full_path = pathlib.Path(VIDEO_ROOT).joinpath(given_name)
    open(full_path, "wb").write(content)

