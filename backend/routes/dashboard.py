from flask import Blueprint, request, jsonify, Response
from flask_jwt_extended import jwt_required, get_jwt
from models.job import Job
from models.user import User
import csv, io

dashboard_bp = Blueprint('dashboard', __name__, url_prefix='/dashboard')

@dashboard_bp.route('', methods=['GET'])
@jwt_required()
def get_dashboard():
    claims = get_jwt()
    user = {
        'id':   claims.get('id'),
        'role': claims.get('role'),
        'name': claims.get('name')
    }
    if user['role'] != 'manager':
        return jsonify({'error': 'Access denied'}), 403

    # Count jobs by status
    total     = Job.query.count()
    pending   = Job.query.filter_by(status='pending').count()
    assigned  = Job.query.filter_by(status='assigned').count()
    on_way    = Job.query.filter_by(status='on_the_way').count()
    on_site   = Job.query.filter_by(status='on_site').count()
    completed = Job.query.filter_by(status='completed').count()

    # Jobs per technician
    techs = User.query.filter_by(role='technician').all()
    by_tech = []
    for t in techs:
        count = Job.query.filter_by(assigned_to_id=t.id).count()
        by_tech.append({'technician': t.name, 'job_count': count})

    return jsonify({
        'total':      total,
        'pending':    pending,
        'assigned':   assigned,
        'on_the_way': on_way,
        'on_site':    on_site,
        'completed':  completed,
        'by_technician': by_tech
    }), 200

@dashboard_bp.route('/export/csv', methods=['GET'])
@jwt_required()
def export_csv():
    claims = get_jwt()
    user = {
        'role': claims.get('role')
    }
    if user['role'] != 'manager':
        return jsonify({'error': 'Access denied'}), 403

    jobs = Job.query.all()

    # Build CSV in memory
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(['ID','Title','Status','Location','Created By','Assigned To','Created At','Completed At'])

    for j in jobs:
        writer.writerow([
            j.id,
            j.title,
            j.status,
            j.location or '',
            j.created_by.name if j.created_by else '',
            j.assigned_to.name if j.assigned_to else 'Unassigned',
            j.created_at.strftime('%Y-%m-%d %H:%M') if j.created_at else '',
            j.completed_at.strftime('%Y-%m-%d %H:%M') if j.completed_at else '',
        ])

    output.seek(0)
    return Response(
        output.getvalue(),
        mimetype='text/csv',
        headers={'Content-Disposition': 'attachment; filename=jobs_export.csv'}
    )