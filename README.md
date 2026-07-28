# Simple Drive

Simple Drive is a Ruby on Rails API that stores and retrieves binary data using a unique identifier.

The application supports multiple storage backends through a single interface.

## Features

- JWT Bearer Authentication
- Store Base64 encoded binary data
- Retrieve blobs by ID
- Multiple storage backends
  - Local File System
  - Database
  - S3 Storage (MinIO)

---

# Requirements

- Ruby 3.4+
- Rails 8+
- Docker Desktop

---

# Installation

Clone the repository

```bash
git clone <repository_url>
cd simple_drive
```

Install dependencies

```bash
bundle install
```

Create the database

```bash
bin/rails db:create
bin/rails db:migrate
```

Start the server

```bash
bin/rails server
```

---

# Environment Variables

## Local Storage

```env
STORAGE_BACKEND=local
STORAGE_PATH=./storage/blobs
```

## Database Storage

```env
STORAGE_BACKEND=database
```

## S3 (MinIO)

```env
STORAGE_BACKEND=s3

S3_ENDPOINT=http://localhost:9000
S3_BUCKET=simple-drive
S3_ACCESS_KEY_ID=minioadmin
S3_SECRET_ACCESS_KEY=minioadmin
S3_REGION=us-east-1
```

---

# Running MinIO

Create a local directory for MinIO data

```bash
mkdir -p ~/minio/data
```

Pull the MinIO Docker image

```bash
docker pull quay.io/minio/minio
```

Run MinIO

```bash
docker run -d \
  --name minio \
  -p 9000:9000 \
  -p 9001:9001 \
  -v ~/minio/data:/data \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  quay.io/minio/minio server /data --console-address ":9001"
```

Verify the container

```bash
docker ps
```

Open MinIO Console

```
http://localhost:9001
```

Login

```
Username: minioadmin
Password: minioadmin
```

Create a bucket named

```
simple-drive
```

Useful Docker commands

Stop

```bash
docker stop minio
```

Start

```bash
docker start minio
```

Restart

```bash
docker restart minio
```

Logs

```bash
docker logs minio
```

Remove

```bash
docker rm -f minio
```

Uploaded objects are stored locally in

```
~/minio/data
```

---

# API

## Register

```
POST /api/register
```

Example

```json
{
  "user": {
    "email": "user@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }
}
```

---

## Login

```
POST /api/login
```

Example

```json
{
  "user": {
    "email": "user@example.com",
    "password": "password123"
  }
}
```

---

## Store Blob

```
POST /api/blobs
```

Headers

```
Authorization: Bearer <token>
Content-Type: application/json
```

Request

```json
{
  "id": "hello-world",
  "data": "SGVsbG8gV29ybGQh"
}
```

Response

```json
{
  "id": "hello-world",
  "size": "12",
  "created_at": "2026-07-26T11:57:01Z"
}
```

---

## Retrieve Blob

```
GET /api/blobs/{id}
```

Example

```
GET /api/blobs/hello-world
```

Response

```json
{
  "id": "hello-world",
  "data": "SGVsbG8gV29ybGQh",
  "size": "12",
  "created_at": "2026-07-26T11:57:01Z"
}
```

---

# Project Structure

```
app/
├── controllers/
├── models/
└── services/
    └── storage/
        ├── base_adapter.rb
        ├── resolver.rb
        ├── local_adapter.rb
        ├── database_adapter.rb
        ├── s3_adapter.rb
        └── s3_signer.rb
```

The controller interacts with a single storage interface while the resolver selects the configured backend.