import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WhatsAppService {
  static final WhatsAppService instance = WhatsAppService._init();

  // Settings keys
  static const String _keyEnabled = 'whatsapp_enabled';
  static const String _keyPhoneNumber = 'whatsapp_phone_number';
  static const String _keyShareSnapshots = 'whatsapp_share_snapshots';
  static const String _keyShareVideos = 'whatsapp_share_videos';
  static const String _keyMessageTemplate = 'whatsapp_message_template';

  // Settings
  bool _isEnabled = false;
  String _phoneNumber = '';
  bool _shareSnapshots = true;
  bool _shareVideos = true;
  String _messageTemplate = '🔴 Security Alert\n\n📅 Date: {date}\n⏰ Time: {time}\n📝 Description: {description}\n📊 Confidence: {confidence}%\n\n📷 Snapshot attached';

  bool get isEnabled => _isEnabled;
  String get phoneNumber => _phoneNumber;
  bool get shareSnapshots => _shareSnapshots;
  bool get shareVideos => _shareVideos;
  String get messageTemplate => _messageTemplate;
  bool get isConfigured => _isEnabled && _phoneNumber.isNotEmpty;

  WhatsAppService._init();

  /// Initialize WhatsApp service
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_keyEnabled) ?? false;
      _phoneNumber = prefs.getString(_keyPhoneNumber) ?? '';
      _shareSnapshots = prefs.getBool(_keyShareSnapshots) ?? true;
      _shareVideos = prefs.getBool(_keyShareVideos) ?? true;
      _messageTemplate = prefs.getString(_keyMessageTemplate) ??
          '🔴 Security Alert\n\n📅 Date: {date}\n⏰ Time: {time}\n📝 Description: {description}\n📊 Confidence: {confidence}%\n\n📷 Snapshot attached';
    } catch (e) {
      debugPrint('Error initializing WhatsApp service: $e');
    }
  }

  /// Format phone number by removing any non-digit characters
  String _formatPhoneNumber(String phone) {
    // Remove all non-digit characters except +
    String formatted = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Ensure it starts with country code
    if (!formatted.startsWith('+')) {
      // If no country code, assume it needs to be added
      if (formatted.length == 10) {
        // Assuming Indian number +91 for 10 digit numbers
        formatted = '+91$formatted';
      }
    }
    
    return formatted;
  }

  /// Build message from template
  String _buildMessage({
    required String description,
    required DateTime timestamp,
    required double confidence,
  }) {
    String message = _messageTemplate;
    
    message = message.replaceAll('{date}', '${timestamp.day}/${timestamp.month}/${timestamp.year}');
    message = message.replaceAll('{time}', '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}');
    message = message.replaceAll('{description}', description);
    message = message.replaceAll('{confidence}', (confidence * 100).toStringAsFixed(1));
    
    return message;
  }

  /// Share snapshot via WhatsApp
  Future<bool> shareSnapshot({
    required String snapshotPath,
    required String description,
    required DateTime timestamp,
    required double confidence,
  }) async {
    if (!isConfigured) {
      debugPrint('WhatsApp not configured or disabled');
      return false;
    }

    try {
      final formattedPhone = _formatPhoneNumber(_phoneNumber);
      final message = _buildMessage(
        description: description,
        timestamp: timestamp,
        confidence: confidence,
      );

      // First, try to share with attachment using share_plus
      if (_shareSnapshots) {
        final file = File(snapshotPath);
        if (await file.exists()) {
          // Use WhatsApp URL scheme with text
          final encodedMessage = Uri.encodeComponent(message);
          final whatsappUrl = 'https://wa.me/$formattedPhone?text=$encodedMessage';
          
          final uri = Uri.parse(whatsappUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return true;
          }
        }
      }

      // If no snapshot sharing, just send text
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/$formattedPhone?text=$encodedMessage';
      
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }

      debugPrint('Cannot launch WhatsApp');
      return false;
    } catch (e) {
      debugPrint('Error sharing via WhatsApp: $e');
      return false;
    }
  }

  /// Share video via WhatsApp
  Future<bool> shareVideo({
    required String videoPath,
    required String description,
    required DateTime timestamp,
    required double confidence,
  }) async {
    if (!isConfigured || !_shareVideos) {
      debugPrint('WhatsApp video sharing not configured or disabled');
      return false;
    }

    try {
      final formattedPhone = _formatPhoneNumber(_phoneNumber);
      final message = _buildMessage(
        description: description,
        timestamp: timestamp,
        confidence: confidence,
      );

      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/$formattedPhone?text=$encodedMessage';
      
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }

      debugPrint('Cannot launch WhatsApp');
      return false;
    } catch (e) {
      debugPrint('Error sharing video via WhatsApp: $e');
      return false;
    }
  }

  /// Update settings
  Future<void> updateSettings({
    bool? enabled,
    String? phoneNumber,
    bool? shareSnapshots,
    bool? shareVideos,
    String? messageTemplate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (enabled != null) {
        _isEnabled = enabled;
        await prefs.setBool(_keyEnabled, enabled);
      }

      if (phoneNumber != null) {
        _phoneNumber = phoneNumber.trim();
        await prefs.setString(_keyPhoneNumber, _phoneNumber);
      }

      if (shareSnapshots != null) {
        _shareSnapshots = shareSnapshots;
        await prefs.setBool(_keyShareSnapshots, shareSnapshots);
      }

      if (shareVideos != null) {
        _shareVideos = shareVideos;
        await prefs.setBool(_keyShareVideos, shareVideos);
      }

      if (messageTemplate != null) {
        _messageTemplate = messageTemplate;
        await prefs.setString(_keyMessageTemplate, messageTemplate);
      }
    } catch (e) {
      debugPrint('Error updating WhatsApp settings: $e');
    }
  }

  /// Get settings as map
  Map<String, dynamic> getSettings() {
    return {
      'enabled': _isEnabled,
      'phoneNumber': _phoneNumber,
      'shareSnapshots': _shareSnapshots,
      'shareVideos': _shareVideos,
      'messageTemplate': _messageTemplate,
      'isConfigured': isConfigured,
    };
  }

  /// Check if WhatsApp is installed on device
  Future<bool> isWhatsAppInstalled() async {
    try {
      if (Platform.isAndroid) {
        final whatsappUri = Uri.parse('whatsapp://');
        return await canLaunchUrl(whatsappUri);
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
