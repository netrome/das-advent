from typing import List

import hashlib
import json
import os
import pathlib

import fastapi
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
import pydantic


VIDEO_ROOT = os.environ["DAS_FILEPATH"] if "DAS_FILEPATH" in os.environ else "./video_uploads"
STATE_ROOT = "./app_state"
os.makedirs(VIDEO_ROOT, exist_ok=True)
os.makedirs(STATE_ROOT, exist_ok=True)

app = fastapi.FastAPI()

app.mount("/video", StaticFiles(directory=VIDEO_ROOT), name="static")

templates = Jinja2Templates(directory="./templates")

class Greeting(pydantic.BaseModel):
    day: int
    video: str


@app.get("/calendar_info/", response_model=List[Greeting])
async def calendar():
    return greetings_of_the_day(1)


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


# Views ---

@app.get("/view_all/")
async def upload_page(request: fastapi.Request):
    return templates.TemplateResponse("view_all.html", {"request": request})


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


def initiate_greetings(path):
    json.dump([Greeting(day=i+1, video="").dict() for i in range(24)],
                path.open("w"), indent=2)


def greetings_of_the_day(day: int) -> List[Greeting]:
    path = pathlib.Path(STATE_ROOT).joinpath("greetings.json")
    if not path.exists():
        initiate_greetings(path)
    greetings = json.load(path.open())
    return greetings



