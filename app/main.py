from fastapi import FastAPI


app = FastAPI(title="Secure CI/CD Lesson App")


@app.get("/")
def read_root() -> dict[str, str]:
    return {"hello": "world"}


@app.get("/health")
def healthcheck() -> dict[str, str]:
    return {"status": "ok"}

