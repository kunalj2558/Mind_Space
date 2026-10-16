import 'package:hearme/services/api_service.dart';
import 'package:hearme/core/constants/api_constants.dart';

class V2Service {
  /// Fetch all active clinical specialties (Psychiatrist, Psychologist, etc.)
  static Future<List<dynamic>> getSpecialties() async {
    try {
      final res = await ApiService.get(ApiConstants.v2Specialties);
      return res['specialties'] ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Browse marketplace of verified clinicians
  static Future<List<dynamic>> getProfessionals({
    String? specialty,
    String? language,
    String? mode,
    String? query,
    bool availableNow = false,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (specialty != null && specialty.isNotEmpty) {
        queryParams['specialty'] = specialty;
      }
      if (language != null && language.isNotEmpty) {
        queryParams['language'] = language;
      }
      if (mode != null && mode.isNotEmpty) {
        queryParams['mode'] = mode;
      }
      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
      }
      if (availableNow) {
        queryParams['availableNow'] = 'true';
      }

      String endpoint = ApiConstants.v2Professionals;
      if (queryParams.isNotEmpty) {
        final queryStr = Uri(queryParameters: queryParams).query;
        endpoint = '$endpoint?$queryStr';
      }

      final res = await ApiService.get(endpoint);
      return res['professionals'] ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Fetch full clinician profile details
  static Future<Map<String, dynamic>?> getProfessionalDetail(String id) async {
    try {
      final res = await ApiService.get(ApiConstants.v2ProfessionalDetail(id));
      return res['professional'];
    } catch (_) {
      return null;
    }
  }

  /// Fetch availability calendar slots for a clinician
  static Future<Map<String, dynamic>?> getAvailability(String id) async {
    try {
      final res =
          await ApiService.get(ApiConstants.v2ProfessionalAvailability(id));
      return res;
    } catch (_) {
      return null;
    }
  }

  /// Book an appointment with transparent rate snapshot & consent
  static Future<Map<String, dynamic>> bookAppointment({
    required String professionalProfileId,
    required String mode,
    required int durationMinutes,
    DateTime? scheduledAt,
    String? serviceType,
    bool shareSummaryConsent = false,
  }) async {
    final body = {
      'professionalProfileId': professionalProfileId,
      'mode': mode,
      'durationMinutes': durationMinutes,
      'scheduledAt': (scheduledAt ?? DateTime.now().add(const Duration(hours: 1)))
          .toIso8601String(),
      'serviceType': serviceType,
      'shareSummaryConsent': shareSummaryConsent,
    };
    return await ApiService.post(ApiConstants.v2Appointments, body: body);
  }

  /// List user's scheduled & past appointments
  static Future<List<dynamic>> getAppointments() async {
    try {
      final res = await ApiService.get(ApiConstants.v2Appointments);
      return res['appointments'] ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Single appointment details
  static Future<Map<String, dynamic>?> getAppointmentDetail(String id) async {
    try {
      final res = await ApiService.get(ApiConstants.v2AppointmentDetail(id));
      return res['appointment'];
    } catch (_) {
      return null;
    }
  }

  /// Cancel appointment with refund trigger
  static Future<Map<String, dynamic>> cancelAppointment(String id) async {
    return await ApiService.post(ApiConstants.v2AppointmentCancel(id));
  }

  /// Get secure session call credentials
  static Future<Map<String, dynamic>> getCallToken(String appointmentId) async {
    return await ApiService.post(ApiConstants.v2CallToken(appointmentId));
  }

  /// Start server-authoritative timer for consultation
  static Future<Map<String, dynamic>> startSession(String appointmentId) async {
    return await ApiService.post(ApiConstants.v2SessionStart(appointmentId));
  }

  /// End session and compute billable minutes
  static Future<Map<String, dynamic>> endSession(String appointmentId,
      {String? clinicalNotes}) async {
    return await ApiService.post(
      ApiConstants.v2SessionEnd(appointmentId),
      body: {'clinicalNotes': clinicalNotes ?? ''},
    );
  }

  /// Consultation chat messages
  static Future<List<dynamic>> getAppointmentMessages(
      String appointmentId) async {
    try {
      final res =
          await ApiService.get(ApiConstants.v2AppointmentMessages(appointmentId));
      return res['messages'] ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Send message in consultation chat
  static Future<Map<String, dynamic>> sendAppointmentMessage(
      String appointmentId, String message) async {
    return await ApiService.post(
      ApiConstants.v2AppointmentMessages(appointmentId),
      body: {'message': message},
    );
  }

  /// Emergency crisis resources & helplines (Tele-MANAS, KIRAN, 112)
  static Future<Map<String, dynamic>> getSafetyResources() async {
    try {
      return await ApiService.get(ApiConstants.v2SafetyResources);
    } catch (_) {
      return {};
    }
  }

  /// Submit user safety report
  static Future<Map<String, dynamic>> submitSafetyReport({
    required String category,
    required String description,
    String? reportedUserId,
    String? appointmentId,
    String priority = 'medium',
  }) async {
    return await ApiService.post(
      ApiConstants.v2SafetyReports,
      body: {
        'category': category,
        'description': description,
        'reportedUserId': reportedUserId,
        'appointmentId': appointmentId,
        'priority': priority,
      },
    );
  }

  /// Doctor earnings summary
  static Future<Map<String, dynamic>> getDoctorEarnings() async {
    try {
      return await ApiService.get(ApiConstants.v2DoctorEarnings);
    } catch (_) {
      return {};
    }
  }

  /// Patient billing orders
  static Future<List<dynamic>> getPatientBilling() async {
    try {
      final res = await ApiService.get(ApiConstants.v2PatientBilling);
      return res['orders'] ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Doctor accepts appointment request
  static Future<Map<String, dynamic>> acceptAppointment(String id) async {
    return await ApiService.post(ApiConstants.v2AppointmentAccept(id));
  }

  /// Doctor rejects appointment request
  static Future<Map<String, dynamic>> rejectAppointment(String id) async {
    return await ApiService.post(ApiConstants.v2AppointmentReject(id));
  }

  /// Get logged-in doctor profile and rates
  static Future<Map<String, dynamic>?> getDoctorProfile() async {
    try {
      final res = await ApiService.get(ApiConstants.v2DoctorProfile);
      return res['profile'];
    } catch (_) {
      return null;
    }
  }

  /// Update doctor rates and consultation modes
  static Future<Map<String, dynamic>> updateDoctorProfile({
    Map<String, dynamic>? rates,
    List<String>? consultationModes,
    bool? isAvailableNow,
    String? bio,
  }) async {
    final body = <String, dynamic>{};
    if (rates != null) body['rates'] = rates;
    if (consultationModes != null) body['consultationModes'] = consultationModes;
    if (isAvailableNow != null) body['isAvailableNow'] = isAvailableNow;
    if (bio != null) body['bio'] = bio;
    return await ApiService.put(ApiConstants.v2DoctorProfile, body: body);
  }

  /// Lightweight real-time appointment status polling
  static Future<Map<String, dynamic>?> getAppointmentStatus(String id) async {
    try {
      return await ApiService.get(ApiConstants.v2AppointmentStatus(id));
    } catch (_) {
      return null;
    }
  }

  /// In-App Wallet balance & transaction ledger
  static Future<Map<String, dynamic>> getWalletBalance() async {
    try {
      return await ApiService.get(ApiConstants.v2WalletBalance);
    } catch (_) {
      return {'balance': 0, 'currency': 'INR', 'transactions': []};
    }
  }

  /// Add money to in-app wallet from bank/UPI
  static Future<Map<String, dynamic>> topUpWallet(double amount, {String? paymentMethod}) async {
    return await ApiService.post(
      ApiConstants.v2WalletTopup,
      body: {
        'amount': amount,
        'paymentMethod': paymentMethod ?? 'UPI',
      },
    );
  }
}
