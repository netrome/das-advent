from typing import List, Set

import datetime
import hashlib
import json
import os
import pathlib
import random
import secrets

import fastapi
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.security import HTTPBasic, HTTPBasicCredentials
import pydantic


VIDEO_ROOT = os.environ["DAS_FILEPATH"] if "DAS_FILEPATH" in os.environ else "./video_uploads"
STATE_ROOT = os.environ["DAS_STATE_ROOT"] if "STATE_ROOT" in os.environ else "./app_state"
UPLOAD_CREDENTIALS = os.environ["DAS_AUTH"] if "DAS_AUTH" in os.environ else "anyone:melon"
STATIC_ROOT = "./static/"
DAY_ZERO = os.environ["DAS_DAY_ZERO"] if "DAS_DAY_ZERO" in os.environ else "2020-11-25"

print(f"Starting server with day zero: {DAY_ZERO}")

os.makedirs(VIDEO_ROOT, exist_ok=True)
os.makedirs(STATE_ROOT, exist_ok=True)

app = fastapi.FastAPI()
security = HTTPBasic()

app.mount("/video", StaticFiles(directory=VIDEO_ROOT), name="videos")
app.mount("/static", StaticFiles(directory=STATIC_ROOT), name="static")

templates = Jinja2Templates(directory="./templates")

class Greeting(pydantic.BaseModel):
    day: int
    video: str

    @classmethod
    def from_dict(cls, d):
        return cls(**d)


@app.get("/calendar_info/", response_model=List[Greeting])
async def calendar():
    return greetings_of_the_day(today())


@app.get("/videos/")
async def videos():
    return {"videos": os.listdir(VIDEO_ROOT)}


@app.get("/video/{name}")
async def video(name: str):
    return {"message": "Hello World"}


@app.post("/upload/")
async def upload(
        video: fastapi.UploadFile = fastapi.File(...),
        credentials: HTTPBasicCredentials = fastapi.Depends(security)
        ):
    [das_username, das_password] = UPLOAD_CREDENTIALS.split(":")

    correct_username = secrets.compare_digest(credentials.username, das_username)
    correct_password = secrets.compare_digest(credentials.password, das_password)

    if not (correct_username and correct_password):
        raise fastapi.HTTPException(
            status_code=fastapi.status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Basic"},
        )

    await video.seek(0)
    content = await video.read()

    given_name = baptise(video.filename, content)
    dump(given_name, content)

    return {"message": "Uploaded!"}


# Views ---

@app.get("/view_all/")
async def view_all(request: fastapi.Request):
    return templates.TemplateResponse("view_all.html", {"request": request})


@app.get("/upload/")
async def upload_page(request: fastapi.Request):
    return templates.TemplateResponse("upload.html", {"request": request})


@app.get("/")
async def calendar(request: fastapi.Request):
    return templates.TemplateResponse("calendar.html", {"request": request})


## Helpers ---


def baptise(filename, content):
    suffix = pathlib.Path(filename).suffix
    file_hash = hashlib.md5(content).hexdigest()
    return file_hash + suffix


def dump(given_name, content):
    full_path = pathlib.Path(VIDEO_ROOT).joinpath(given_name)
    open(full_path, "wb").write(content)


def initiate_greetings(path) -> List[Greeting]:
    dump_greetings(path, [Greeting(day=i+1, video="") for i in range(24)])


def dump_greetings(path, greetings: List[Greeting]):
    encodable = list(map(Greeting.dict, greetings))
    json.dump(encodable, path.open("w"), indent=2)


def greetings_of_the_day(day: int) -> List[Greeting]:
    path = pathlib.Path(STATE_ROOT).joinpath("greetings.json")

    if not path.exists():
        initiate_greetings(path)

    stored_greetings = list(map(Greeting.from_dict, json.load(path.open())))

    live_greetings = update_greetings(day, stored_greetings)

    if live_greetings != stored_greetings:
        dump_greetings(path, live_greetings)

    random.seed(2020)
    random.shuffle(live_greetings)

    return live_greetings


def update_greetings(day: int, stored_greetings: List[Greeting]) -> List[Greeting]:
    assigned_videos = {greeting.video for greeting in stored_greetings if greeting.video != ""}

    updated_greetings = list(map(update_greeting(assigned_videos), stored_greetings[:day]))

    return updated_greetings + stored_greetings[day:]


def update_greeting(already_assigned_videos):
    def inner(greeting):
        name = assign_new(already_assigned_videos) if greeting.video == "" else greeting.video
        return Greeting(video=name, day=greeting.day)
    return inner


def assign_new(already_assigned: Set[str]) -> str:
    choices = list(set(os.listdir(VIDEO_ROOT)) - already_assigned)
    if len(choices) > 0:
        chosen = random.choice(choices)
        already_assigned.add(chosen)
        return chosen
    return ""


def today() -> int:
    return (datetime.date.today() - datetime.date.fromisoformat(DAY_ZERO)).days
