import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _inicializado = false;

  Future<void> inicializar() async {
    if (_inicializado) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);
    _inicializado = true;
  }

  Future<bool> solicitarPermissao() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<void> mostrarNotificacao({
    required int id,
    required String titulo,
    required String corpo,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'limite_gastos_channel',
      'Alertas de Limite de Gastos',
      channelDescription:
          'Notifica quando o limite de uma categoria é ultrapassado',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(id, titulo, corpo, details);
  }
}