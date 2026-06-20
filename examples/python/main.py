"""
Python example - REST API with FastAPI
"""
from __future__ import annotations

import asyncio
import json
import re
from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from typing import List, Optional

import httpx
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel, Field

app = FastAPI(title="DevMedia Example API", version="1.0.0")


class StatusEnum(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    PENDING = "pending"


class UserCreate(BaseModel):
    name: str = Field(..., min_length=3, max_length=100)
    email: str = Field(..., pattern=r"^[\w\.-]+@[\w\.-]+\.\w+$")
    age: int = Field(ge=0, le=150, default=18)
    status: StatusEnum = StatusEnum.PENDING


class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    age: int
    status: StatusEnum
    created_at: datetime


@dataclass
class Config:
    database_url: str = "sqlite:///devmedia.db"
    debug: bool = False
    max_connections: int = 10


config = Config()


def validate_email(email: str) -> bool:
    pattern = r"^[\w\.-]+@[\w\.-]+\.\w+$"
    return bool(re.match(pattern, email))


users_db: List[UserResponse] = []
counter: int = 0


@app.get("/")
async def root():
    return {"message": "DevMedia Theme Example API", "version": "1.0.0"}


@app.get("/users", response_model=List[UserResponse])
async def list_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    status: Optional[StatusEnum] = None,
):
    filtered = [u for u in users_db if status is None or u.status == status]
    return filtered[skip : skip + limit]


@app.post("/users", response_model=UserResponse, status_code=201)
async def create_user(user: UserCreate):
    global counter
    counter += 1
    new_user = UserResponse(
        id=counter,
        name=user.name,
        email=user.email,
        age=user.age,
        status=user.status,
        created_at=datetime.now(),
    )
    users_db.append(new_user)
    return new_user


@app.get("/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: int):
    for user in users_db:
        if user.id == user_id:
            return user
    raise HTTPException(status_code=404, detail="User not found")


async def fetch_external_data(url: str) -> dict:
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(url, timeout=10.0)
            response.raise_for_status()
            return response.json()
    except httpx.HTTPError as e:
        raise HTTPException(status_code=502, detail=str(e))


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
