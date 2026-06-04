from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from extensions import db
from models.job import Job
from models.user import User
from datetime import datetime
import os

jobs_bp = Blueprint('jobs', __name__, url_prefix='/jobs')

# ── Helper: check role ─────────────────────────────────────────────────────────
def current_user():
    claims = get_jwt()  # gets the additional_claims we stored
    return {
        'id':   claims.get('id'),
        'role': claims.get('role'),
        'name': claims.get('name')
    }

# ── CS: Create a new job ───────────────────────────────────────────────────────
@jobs_bp.route('', methods=['POST'])
@jwt_required()
def create_job():
    user = current_user()
    if user['role'] != 'cs':
        return jsonify({'error': 'Only CS can create jobs'}), 403

    data = request.get_json()
    if not data.get('title') or not data.get('description'):
        return jsonify({'error': 'Title and description required'}), 400

    job = Job(
        title          = data['title'],
        description    = data['description'],
        location       = data.get('location', ''),
        latitude       = data.get('latitude'),
        longitude      = data.get('longitude'),
        created_by_id  = user['id'],
        status         = 'pending'
    )
    db.session.add(job)
    db.session.commit()

    return jsonify(job.to_dict()), 201

# ── All roles: List jobs (filtered by role) ────────────────────────────────────
@jobs_bp.route('', methods=['GET'])
@jwt_required()
def list_jobs():
    user = current_user()

    if user['role'] == 'technician':
        # Technicians only see their own assigned jobs
        jobs = Job.query.filter_by(assigned_to_id=user['id']).all()
    else:
        # CS and Manager see all jobs
        jobs = Job.query.all()

    return jsonify([j.to_dict() for j in jobs]), 200

# ── Get single job detail ──────────────────────────────────────────────────────
@jobs_bp.route('/<int:job_id>', methods=['GET'])
@jwt_required()
def get_job(job_id):
    job = Job.query.get_or_404(job_id)
    return jsonify(job.to_dict()), 200

# ── Manager: Assign or reassign job to a technician ───────────────────────────
@jobs_bp.route('/<int:job_id>/assign', methods=['PUT'])
@jwt_required()
def assign_job(job_id):
    user = current_user()
    if user['role'] != 'manager':
        return jsonify({'error': 'Only managers can assign jobs'}), 403

    data = request.get_json()
    tech_id = data.get('technician_id')
    if not tech_id:
        return jsonify({'error': 'technician_id required'}), 400

    # Make sure the technician exists and has the right role
    tech = User.query.filter_by(id=tech_id, role='technician').first()
    if not tech:
        return jsonify({'error': 'Technician not found'}), 404

    job = Job.query.get_or_404(job_id)
    job.assigned_to_id = tech_id
    job.status         = 'assigned'
    job.assigned_at    = datetime.utcnow()
    db.session.commit()

    return jsonify(job.to_dict()), 200

# ── Technician: Update job status ──────────────────────────────────────────────
@jobs_bp.route('/<int:job_id>/status', methods=['PUT'])
@jwt_required()
def update_status(job_id):
    user = current_user()
    if user['role'] != 'technician':
        return jsonify({'error': 'Only technicians can update status'}), 403

    data   = request.get_json()
    new_st = data.get('status')

    # Define which transitions are allowed
    allowed = {
        'assigned':   'on_the_way',
        'on_the_way': 'on_site',
        'on_site':    'completed'
    }

    job = Job.query.get_or_404(job_id)

    # Make sure THIS technician owns this job
    if job.assigned_to_id != user['id']:
        return jsonify({'error': 'This job is not assigned to you'}), 403

    if allowed.get(job.status) != new_st:
        return jsonify({
            'error': f'Cannot go from "{job.status}" to "{new_st}"',
            'next_allowed': allowed.get(job.status)
        }), 400

    job.status = new_st
    if new_st == 'completed':
        job.completed_at = datetime.utcnow()

    db.session.commit()
    return jsonify(job.to_dict()), 200

# ── CS or Manager: Upload photo for a job ─────────────────────────────────────
@jobs_bp.route('/<int:job_id>/upload', methods=['POST'])
@jwt_required()
def upload_photo(job_id):
    user = current_user()
    if user['role'] not in ['cs', 'manager']:
        return jsonify({'error': 'Access denied'}), 403

    if 'photo' not in request.files:
        return jsonify({'error': 'No file uploaded. Use key "photo"'}), 400

    file    = request.files['photo']
    if file.filename == '':
        return jsonify({'error': 'Empty filename'}), 400

    # Save file with job_id prefix to avoid name collisions
    filename = f"job_{job_id}_{file.filename}"
    filepath = os.path.join(current_app.config['UPLOAD_FOLDER'], filename)
    file.save(filepath)

    # Save filename to job record
    job = Job.query.get_or_404(job_id)
    job.photo_path = filename
    db.session.commit()

    return jsonify({'photo_path': filename}), 200

# ── Manager: Get all technicians (for assign dropdown) ────────────────────────
@jobs_bp.route('/technicians', methods=['GET'])
@jwt_required()
def list_technicians():
    user = current_user()
    if user['role'] != 'manager':
        return jsonify({'error': 'Access denied'}), 403

    techs = User.query.filter_by(role='technician').all()
    return jsonify([t.to_dict() for t in techs]), 200