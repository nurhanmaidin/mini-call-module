from flask import Flask
from flask_cors import CORS
from extensions import db, jwt
from config import Config
import os

# Create the Flask app
app = Flask(__name__)
app.config.from_object(Config)

# Make sure uploads folder exists
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

# Attach db and jwt to the app (this is the correct pattern)
db.init_app(app)
jwt.init_app(app)
CORS(app)

# Import models AFTER init_app (order still matters)
from models.user import User
from models.job  import Job

# Import and register route blueprints
from routes.auth      import auth_bp
from routes.jobs      import jobs_bp
from routes.dashboard import dashboard_bp

app.register_blueprint(auth_bp)
app.register_blueprint(jobs_bp)
app.register_blueprint(dashboard_bp)

# Create tables and seed users
with app.app_context():
    db.create_all()

    if User.query.count() == 0:
        from werkzeug.security import generate_password_hash
        seed_users = [
            User(name='CS User',   email='cs@demo.com',      password=generate_password_hash('password123'), role='cs'),
            User(name='Manager',   email='manager@demo.com',  password=generate_password_hash('password123'), role='manager'),
            User(name='Tech Ali',  email='ali@demo.com',      password=generate_password_hash('password123'), role='technician'),
            User(name='Tech Reza', email='reza@demo.com',     password=generate_password_hash('password123'), role='technician'),
        ]
        db.session.add_all(seed_users)
        db.session.commit()
        print('✅ Test users seeded!')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)