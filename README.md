# Mini Daily Call Module

## Project Overview

Mini Daily Call Module is a Flutter + Flask application developed as a technical assessment/project submission.

The project consists of:

* Flutter Frontend
* Flask Backend API
* Database files
* Deployment and release assets
* Demo video and application screenshots

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
├── demo-video/           # Project demonstration video
├── screenshots/          # Application screenshots
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

No Flutter installation is required for evaluation purposes if you use the provided release build.

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

### If `start_backend.bat` Does Not Work

You can start the backend manually using Command Prompt:

1. Open Command Prompt.
2. Navigate to the backend folder:

```bash
cd backend
```

3. Activate the virtual environment:

```bash
venv\Scripts\activate
```

4. Start the Flask application:

```bash
python app.py
```

If the application starts successfully, you should see Flask running on:

```text
http://localhost:5000
```

Keep the terminal window open while using the application.

---

## Frontend Setup

A pre-built Windows release of the application is already provided.

Navigate to:

```text
deployment/Call Module App Release/
```

Open the provided `.exe` file to launch the application.

### Recommended Steps for Reviewers

1. Run:

```bash
start_backend.bat
```

2. If the batch file does not work, follow the manual backend startup instructions above.

3. Wait for the backend to start successfully.

4. Navigate to:

```text
deployment/Call Module App Release/
```

5. Launch the provided `.exe` file.

No Flutter SDK installation is required to run the application using the provided release build.

### For Developers (Optional)

If you would like to run the Flutter source code instead of the release build:

Install Flutter SDK:

https://flutter.dev/docs/get-started/install

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

This folder contains the pre-built Windows executable (`.exe`) that can be used to run the application without installing Flutter.

---

## Demo Video

A demonstration video of the application is available in:

```text
demo-video/
```

The video showcases the application's main features, workflow, and functionality.

---

## Screenshots

Application screenshots are available in:

```text
screenshots/
```

These screenshots provide a visual overview of the application's user interface and key features.

---

## Notes

* Backend must be started before launching the application.
* The provided Windows executable can be found in `deployment/Call Module App Release/`.
* If the backend is not running, API requests from the application will fail.
* If `start_backend.bat` does not work on your machine, start the backend manually using the commands provided in the **Start Backend** section.
* Flutter source code is included for review and development purposes.
* Demo materials are included in the `demo-video/` and `screenshots/` folders.
* This repository contains both source code and deployment assets for easier evaluation and testing.
