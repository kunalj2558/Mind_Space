class ApiConstants {
  // Node.js backend
  static const String baseUrl = 'https://mind-space-3w8a.onrender.com/api';

  // Python FastAPI chatbot server
  static const String chatbotBaseUrl = 'https://hearme-chatbot.onrender.com';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';

  // Users
  static const String profile = '/users/profile';

  // Doctors
  static const String doctorPatients = '/doctors/patients';
  static String doctorPatientMindspace(String patientId) =>
      '/doctors/patients/$patientId/mindspace';
  static String doctorPatientChats(String patientId) =>
      '/doctors/patients/$patientId/chats';

  // Patients
  static const String patientLink = '/patients/link';
  static const String patientRecords = '/patients/records';
  static const String patientDoctor = '/patients/doctor';
  static const String patientMedicalSummary = '/patients/medical-summary';

  // Mental Health
  static const String mentalHealthAnalyze = '/mental-health/analyze';
  static const String mentalHealthNotifications = '/mental-health/notifications';

  // Rewards (chatbot)
  static const String rewardsRedeem = '/rewards/redeem';

  // Rewards (Node.js backend)
  static const String rewardsStats = '/rewards/stats';
  static const String rewardsRedeemed = '/rewards/redeemed';
  static const String rewardsMindSpace = '/rewards/mindspace';

  // History
  static const String historyChats = '/history/chats';
  static const String historyMindspace = '/history/mindspace';

  // ── MindSpace V2 Endpoints ───────────────────────────────────────────────
  static const String v2Specialties = '/v2/specialties';
  static const String v2Professionals = '/v2/professionals';
  static String v2ProfessionalDetail(String id) => '/v2/professionals/$id';
  static String v2ProfessionalAvailability(String id) =>
      '/v2/professionals/$id/availability';
  static const String v2Appointments = '/v2/appointments';
  static String v2AppointmentDetail(String id) => '/v2/appointments/$id';
  static String v2AppointmentConfirm(String id) => '/v2/appointments/$id/confirm';
  static String v2AppointmentAccept(String id) => '/v2/appointments/$id/accept';
  static String v2AppointmentReject(String id) => '/v2/appointments/$id/reject';
  static String v2AppointmentCancel(String id) => '/v2/appointments/$id/cancel';
  static const String v2DoctorProfile = '/v2/doctor/profile';
  static String v2CallToken(String id) => '/v2/appointments/$id/call-token';
  static String v2SessionStart(String id) => '/v2/sessions/$id/start';
  static String v2SessionEnd(String id) => '/v2/sessions/$id/end';
  static String v2AppointmentMessages(String id) =>
      '/v2/appointments/$id/messages';
  static const String v2PatientBilling = '/v2/patient/billing';
  static const String v2DoctorEarnings = '/v2/professional/earnings';
  static const String v2SafetyResources = '/v2/safety/resources';
  static const String v2SafetyReports = '/v2/safety/reports';
}
