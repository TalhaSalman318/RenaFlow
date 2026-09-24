const User = require('../models/User');

const seedAdmin = async () => {
  const existing = await User.findOne({
    $or: [{ email: 'admin@renalflow.com' }, { medicalId: 'ADMIN01' }]
  }).select('+passwordHash');

  if (existing) {
    let changed = false;
    existing.passwordHash = 'password123';
    changed = true;
    if (existing.email !== 'admin@renalflow.com') {
      existing.email = 'admin@renalflow.com';
      changed = true;
    }
    if (existing.medicalId !== 'ADMIN01') {
      existing.medicalId = 'ADMIN01';
      changed = true;
    }
    if (existing.role !== 'admin') {
      existing.role = 'admin';
      changed = true;
    }
    if (!existing.isActive) {
      existing.isActive = true;
      changed = true;
    }
    if (changed) await existing.save();
    return { seeded: false, userId: existing._id };
  }

  const admin = await User.create({
    email: 'admin@renalflow.com',
    medicalId: 'ADMIN01',
    passwordHash: 'password123',
    role: 'admin',
    displayName: 'RenalFlow Administrator',
    isActive: true
  });
  return { seeded: true, userId: admin._id };
};

module.exports = seedAdmin;