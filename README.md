Das advent calendar by Mårten and Ruth

# Uploading a file to the API using the Python console example
```
files = {"video": ("upload.mkv", open("Downloads/Obstacle Challenge CAT vs DOG-e8QtsyNXvFg.mkv"
, "rb").read(), "video/x-matroska")}

resp = requests.post("http://localhost:8000/upload/", files=files)

```
