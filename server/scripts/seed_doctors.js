const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const dotenv = require('dotenv');
dotenv.config();

async function run() {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('Connected to MongoDB');

  const salt = await bcrypt.genSalt(10);
  const hash = await bcrypt.hash('password123', salt);

  const usersCol = mongoose.connection.collection('users');
  const doctorsCol = mongoose.connection.collection('doctors');

  const updateResult = await usersCol.updateMany(
    { role: 'doctor' },
    { $set: { password: hash } }
  );
  console.log('Updated user passwords count:', updateResult.modifiedCount);

  // Ensure Doctor documents exist for all doctor users
  const doctorUsers = await usersCol.find({ role: 'doctor' }).toArray();
  for (const d of doctorUsers) {
    const existing = await doctorsCol.findOne({ userId: d._id });
    if (!existing) {
      await doctorsCol.insertOne({
        userId: d._id,
        specialization: 'Psychiatrist',
        licenseNumber: 'MCI-2015-44910',
        hospital: 'MindSpace Clinic',
        patients: [],
        createdAt: new Date(),
      });
      console.log('Created doctor profile for:', d.name);
    }
  }

  // Verify Dr. Rajesh Deshmukh
  const drRajesh = await usersCol.findOne({ email: 'demo.drrajeshdeshmukh@mindspace.health' });
  const isMatch = await bcrypt.compare('password123', drRajesh.password);
  console.log('--- VERIFICATION ---');
  console.log('Name:', drRajesh.name);
  console.log('Email:', drRajesh.email);
  console.log('Password is password123?:', isMatch);
  console.log('Unique Linking Code:', drRajesh.uniqueCode);

  process.exit(0);
}

run().catch(e => {
  console.error(e);
  process.exit(1);
});
