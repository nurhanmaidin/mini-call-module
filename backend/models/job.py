from extensions import db
from datetime import datetime

class Job(db.Model):
    __tablename__ = 'jobs'

    id             = db.Column(db.Integer, primary_key=True)
    title          = db.Column(db.String(200), nullable=False)
    description    = db.Column(db.Text, nullable=False)
    location       = db.Column(db.String(300))
    latitude       = db.Column(db.Float)
    longitude      = db.Column(db.Float)
    status         = db.Column(db.String(30), default='pending')
    photo_path     = db.Column(db.String(300))

    created_by_id  = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    assigned_to_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)

    created_at     = db.Column(db.DateTime, default=datetime.utcnow)
    assigned_at    = db.Column(db.DateTime, nullable=True)
    completed_at   = db.Column(db.DateTime, nullable=True)

    created_by  = db.relationship('User', foreign_keys=[created_by_id])
    assigned_to = db.relationship('User', foreign_keys=[assigned_to_id])

    def to_dict(self):
        return {
            'id':           self.id,
            'title':        self.title,
            'description':  self.description,
            'location':     self.location,
            'latitude':     self.latitude,
            'longitude':    self.longitude,
            'status':       self.status,
            'photo_path':   self.photo_path,
            'created_by':   self.created_by.to_dict() if self.created_by else None,
            'assigned_to':  self.assigned_to.to_dict() if self.assigned_to else None,
            'created_at':   self.created_at.isoformat() if self.created_at else None,
            'assigned_at':  self.assigned_at.isoformat() if self.assigned_at else None,
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
        }