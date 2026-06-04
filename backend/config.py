import os

BASE_DIR = os.path.abspath(os.path.dirname(__file__))

class Config:
    # Database
    SQLALCHEMY_DATABASE_URI = 'sqlite:///' + os.path.join(BASE_DIR, 'callmodule.db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # JWT settings
    JWT_SECRET_KEY = 'super-secret-jwt-key-change-this'

    # THIS is what fixes the 422 error
    # It tells Flask-JWT to look for the token in the Authorization header
    JWT_TOKEN_LOCATION = ['headers']
    JWT_HEADER_NAME = 'Authorization'
    JWT_HEADER_TYPE = 'Bearer'

    # Upload folder
    UPLOAD_FOLDER = os.path.join(BASE_DIR, 'uploads')