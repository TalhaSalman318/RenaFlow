const Bed = require('../models/Bed');

const seedBeds = async () => {
  const existingCount = await Bed.countDocuments();

  if (existingCount === 50) {
    return { seeded: false, count: existingCount };
  }

  const operations = Array.from({ length: 50 }, (_, index) => {
    const bedNumber = index + 1;
    return {
      updateOne: {
        filter: { bedNumber },
        update: {
          $setOnInsert: {
            bedNumber,
            bedCode: `BED-${String(bedNumber).padStart(2, '0')}`,
            status: 'vacant',
            currentPatientId: null,
            assignedNurseId: null,
            alertReason: null
          }
        },
        upsert: true
      }
    };
  });

  await Bed.bulkWrite(operations, { ordered: false });
  return { seeded: true, count: await Bed.countDocuments() };
};

module.exports = seedBeds;