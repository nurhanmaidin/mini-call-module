from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token
from werkzeug.security import check_password_hash
from models.user import User

auth_bp = Blueprint('auth', __name__, url_prefix='/auth')

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()

    # Basic validation
    if not data or not data.get('email') or not data.get('password'):
        return jsonify({'error': 'Email and password required'}), 400

    # Find user by email
    user = User.query.filter_by(email=data['email']).first()

    # Check if user exists AND password is correct
    if not user or not check_password_hash(user.password, data['password']):
        return jsonify({'error': 'Invalid email or password'}), 401

    # Create a JWT token that contains the user's id and role
    token = create_access_token(
      identity=str(user.id),
        additional_claims={
            'role': user.role,
            'name': user.name,
            'id':   user.id
        }
    )

    return jsonify({
        'token': token,
        'user': user.to_dict()
    }), 200