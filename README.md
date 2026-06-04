# Mini Daily Call Module

## Project Overview

Mini Daily Call Module is a Flutter + Flask application developed as a technical assessment/project submission.

The project consists of:

* Flutter Frontend
* Flask Backend API
* Database files
* Deployment and release assets

---

## Project Structure

```text
mini-call-module/

├── backend/              # Flask API source code
├── frontend/             # Flutter application source code
├── deployment/
│   ├── API/
│   ├── Database/
│   └── Call Module App Release/
│
├── setup_backend.bat     # First-time backend setup
├── start_backend.bat     # Start Flask backend
└── README.md
```

---

## Prerequisites

Please install the following before running the project:

### Backend

* Python 3.11 or newer

Download:

https://www.python.org/downloads/

During installation:

✓ Add Python to PATH

### Frontend

Install Flutter SDK:

https://flutter.dev/docs/get-started/install

---

## Backend Setup

Run once:

```bash
setup_backend.bat
```

This script will:

* Create a Python virtual environment
* Install all required Python packages

Wait until the setup completes.

---

## Start Backend

Run:

```bash
start_backend.bat
```

The Flask backend should start successfully.

Default API URL:

```text
http://localhost:5000
```

Keep this terminal window open while using the application.

---

## Frontend Setup

Navigate to:

```text
frontend/
```

Run:

```bash
flutter pub get
```

Then:

```bash
flutter run
```

---

## Database

Database-related files can be found in:

```text
deployment/Database/
```

---

## Release Builds

Application release files can be found in:

```text
deployment/Call Module App Release/
```

---

## Demo Video

Demo video will be added here.

(TODO)

---

## Screenshots

Application screenshots will be added here.

(TODO)

---

## Notes

* Backend must be started before launching the frontend.
* If the backend is not running, API requests from the frontend will fail.
* This repository contains both source code and deployment assets for easier review.

```
```
