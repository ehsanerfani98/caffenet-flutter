

/// مدل کامل سفارش — Formatter::order بک‌اند (camelCase flat).
class OrderModel {
  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.serviceId,
    required this.serviceTitle,
    required this.status,
    required this.urgency,
    required this.deliveryMethod,
    this.deliveryAddress,
    this.deliveryPostalCode,
    this.formData = const {},
    this.customerFiles = const [],
    this.resultFiles = const [],
    required this.totalPrice,
    this.discountAmount = 0,
    this.paidAmount = 0,
    this.refundAmount = 0,
    this.paymentMethod = 'wallet',
    this.paymentTrackingCode = '',
    this.customerNote,
    this.contactMethods = const [],
    this.rating,
    this.reviewComment,
    this.createdAt,
    this.updatedAt,
    this.queueType = QueueType.normal,
    this.queuePosition,
    this.estimatedWaitMinutes,
    this.estimatedDurationMinutes,
    this.estimatedStartAt,
    this.estimatedEndAt,
    this.noResponseDeadline,
    this.trackToken,
    this.reservedSlotId,
    this.logs = const [],
    this.ticketMessages = const [],
  });

  final String id;
  final String orderNumber;
  final String serviceId;
  final String serviceTitle;
  final String status;
  final String urgency;
  final String deliveryMethod;
  final String? deliveryAddress;
  final String? deliveryPostalCode;
  final Map<String, dynamic> formData;
  final List<UploadedFile> customerFiles;
  final List<UploadedFile> resultFiles;
  final int totalPrice;
  final int discountAmount;
  final int paidAmount;
  final int refundAmount;
  final String paymentMethod;
  final String paymentTrackingCode;
  final String? customerNote;
  final List<String> contactMethods;
  final int? rating;
  final String? reviewComment;
  final String? createdAt;
  final String? updatedAt;

  // ── Smart queue ──
  final String queueType;
  final int? queuePosition;
  final int? estimatedWaitMinutes;
  final int? estimatedDurationMinutes;
  final String? estimatedStartAt;
  final String? estimatedEndAt;
  final String? noResponseDeadline;
  final String? trackToken;
  final String? reservedSlotId;

  final List<OrderLog> logs;
  final List<TicketMessage> ticketMessages;

  bool get isActive => OrderStatus.isActive(status);
  bool get isPaid => paidAmount > 0 || status == OrderStatus.delivered;
  int get payable => totalPrice - discountAmount < 0 ? 0 : totalPrice - discountAmount;

  factory OrderModel.fromJson(dynamic raw) {
    final m = (raw as Map).cast<String, dynamic>();
    return OrderModel(
      id: '${m['id'] ?? ''}',
      orderNumber: '${m['orderNumber'] ?? ''}',
      serviceId: '${m['serviceId'] ?? ''}',
      serviceTitle: '${m['serviceTitle'] ?? ''}',
      status: '${m['status'] ?? OrderStatus.pendingPayment}',
      urgency: '${m['urgency'] ?? 'normal'}',
      deliveryMethod: '${m['deliveryMethod'] ?? 'download'}',
      deliveryAddress: m['deliveryAddress']?.toString(),
      deliveryPostalCode: m['deliveryPostalCode']?.toString(),
      formData: (m['formData'] as Map?)?.cast<String, dynamic>() ?? const {},
      customerFiles:
          (m['customerFiles'] as List?)?.map(UploadedFile.fromJson).toList() ?? const [],
      resultFiles:
          (m['resultFiles'] as List?)?.map(UploadedFile.fromJson).toList() ?? const [],
      totalPrice: (m['totalPrice'] as num?)?.toInt() ?? 0,
      discountAmount: (m['discountAmount'] as num?)?.toInt() ?? 0,
      paidAmount: (m['paidAmount'] as num?)?.toInt() ?? 0,
      refundAmount: (m['refundAmount'] as num?)?.toInt() ?? 0,
      paymentMethod: '${m['paymentMethod'] ?? 'wallet'}',
      paymentTrackingCode: '${m['paymentTrackingCode'] ?? ''}',
      customerNote: m['customerNote']?.toString(),
      contactMethods:
          (m['contactMethods'] as List?)?.map((e) => '$e').toList() ?? const [],
      rating: m['rating'] == null ? null : (m['rating'] as num?)?.toInt(),
      reviewComment: m['reviewComment']?.toString(),
      createdAt: m['createdAt']?.toString(),
      updatedAt: m['updatedAt']?.toString(),
      queueType: '${m['queueType'] ?? QueueType.normal}',
      queuePosition: m['queuePosition'] == null
          ? null
          : (m['queuePosition'] as num?)?.toInt(),
      estimatedWaitMinutes: m['estimatedWaitMinutes'] == null
          ? null
          : (m['estimatedWaitMinutes'] as num?)?.toInt(),
      estimatedDurationMinutes: m['estimatedDurationMinutes'] == null
          ? null
          : (m['estimatedDurationMinutes'] as num?)?.toInt(),
      estimatedStartAt: m['estimatedStartAt']?.toString(),
      estimatedEndAt: m['estimatedEndAt']?.toString(),
      noResponseDeadline: m['noResponseDeadline']?.toString(),
      trackToken: m['trackToken']?.toString(),
      reservedSlotId: m['reservedSlotId']?.toString(),
      logs: (m['logs'] as List?)?.map(OrderLog.fromJson).toList() ?? const [],
      ticketMessages:
          (m['ticketMessages'] as List?)?.map(TicketMessage.fromJson).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderNumber': orderNumber,
        'serviceId': serviceId,
        'serviceTitle': serviceTitle,
        'status': status,
        'urgency': urgency,
        'deliveryMethod': deliveryMethod,
        'deliveryAddress': deliveryAddress,
        'deliveryPostalCode': deliveryPostalCode,
        'formData': formData,
        'customerFiles': customerFiles.map((f) => f.toJson()).toList(),
        'resultFiles': resultFiles.map((f) => f.toJson()).toList(),
        'totalPrice': totalPrice,
        'discountAmount': discountAmount,
        'paidAmount': paidAmount,
        'refundAmount': refundAmount,
        'paymentMethod': paymentMethod,
        'paymentTrackingCode': paymentTrackingCode,
        'customerNote': customerNote,
        'contactMethods': contactMethods,
        'rating': rating,
        'reviewComment': reviewComment,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'queueType': queueType,
        'queuePosition': queuePosition,
        'estimatedWaitMinutes': estimatedWaitMinutes,
        'estimatedDurationMinutes': estimatedDurationMinutes,
        'estimatedStartAt': estimatedStartAt,
        'estimatedEndAt': estimatedEndAt,
        'noResponseDeadline': noResponseDeadline,
        'trackToken': trackToken,
        'reservedSlotId': reservedSlotId,
        'logs': logs.map((l) => l.toJson()).toList(),
        'ticketMessages': ticketMessages.map((t) => t.toJson()).toList(),
      };

  /// اعمال payload سبک polling (OrderUpdateResource — snake_case سرور).
  OrderModel applyUpdate(Map<String, dynamic> u) {
    return copyWith(
      status: '${u['status'] ?? status}',
      queuePosition: u['queue_position'] == null
          ? queuePosition
          : (u['queue_position'] as num?)?.toInt(),
      estimatedWaitMinutes: u['estimated_wait_minutes'] == null
          ? estimatedWaitMinutes
          : (u['estimated_wait_minutes'] as num?)?.toInt(),
      estimatedDurationMinutes: u['estimated_duration_minutes'] == null
          ? estimatedDurationMinutes
          : (u['estimated_duration_minutes'] as num?)?.toInt(),
      estimatedStartAt: u['estimated_start_at']?.toString() ?? estimatedStartAt,
      estimatedEndAt: u['estimated_end_at']?.toString() ?? estimatedEndAt,
      noResponseDeadline:
          u['no_response_deadline']?.toString() ?? noResponseDeadline,
      updatedAt: u['updated_at']?.toString() ?? updatedAt,
    );
  }

  OrderModel copyWith({
    String? status,
    int? queuePosition,
    int? estimatedWaitMinutes,
    int? estimatedDurationMinutes,
    String? estimatedStartAt,
    String? estimatedEndAt,
    String? noResponseDeadline,
    String? updatedAt,
    int? rating,
    String? reviewComment,
    List<UploadedFile>? customerFiles,
    List<UploadedFile>? resultFiles,
    List<TicketMessage>? ticketMessages,
    List<OrderLog>? logs,
  }) {
    return OrderModel(
      id: id,
      orderNumber: orderNumber,
      serviceId: serviceId,
      serviceTitle: serviceTitle,
      status: status ?? this.status,
      urgency: urgency,
      deliveryMethod: deliveryMethod,
      deliveryAddress: deliveryAddress,
      deliveryPostalCode: deliveryPostalCode,
      formData: formData,
      customerFiles: customerFiles ?? this.customerFiles,
      resultFiles: resultFiles ?? this.resultFiles,
      totalPrice: totalPrice,
      discountAmount: discountAmount,
      paidAmount: paidAmount,
      refundAmount: refundAmount,
      paymentMethod: paymentMethod,
      paymentTrackingCode: paymentTrackingCode,
      customerNote: customerNote,
      contactMethods: contactMethods,
      rating: rating ?? this.rating,
      reviewComment: reviewComment ?? this.reviewComment,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      queueType: queueType,
      queuePosition: queuePosition ?? this.queuePosition,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      estimatedStartAt: estimatedStartAt ?? this.estimatedStartAt,
      estimatedEndAt: estimatedEndAt ?? this.estimatedEndAt,
      noResponseDeadline: noResponseDeadline ?? this.noResponseDeadline,
      trackToken: trackToken,
      reservedSlotId: reservedSlotId,
      logs: logs ?? this.logs,
      ticketMessages: ticketMessages ?? this.ticketMessages,
    );
  }
}

/// رویداد سفارش — Formatter::orderLog بک‌اند.
class OrderLog {
  const OrderLog({
    required this.id,
    this.timestamp,
    this.action = '',
    this.performedBy = '',
    this.note = '',
  });

  final String id;
  final String? timestamp;
  final String action;
  final String performedBy;
  final String note;

  factory OrderLog.fromJson(dynamic raw) {
    final m = (raw as Map).cast<String, dynamic>();
    return OrderLog(
      id: '${m['id'] ?? ''}',
      timestamp: m['timestamp']?.toString(),
      action: '${m['action'] ?? ''}',
      performedBy: '${m['performedBy'] ?? ''}',
      note: '${m['note'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id, 'timestamp': timestamp, 'action': action,
        'performedBy': performedBy, 'note': note,
      };
}

/// پیام تیکت — Formatter::ticketMessage بک‌اند.
class TicketMessage {
  const TicketMessage({
    required this.id,
    this.senderRole = 'customer',
    this.senderName = '',
    this.message = '',
    this.timestamp,
    this.isOperatorResponse = false,
  });

  final String id;
  final String senderRole;
  final String senderName;
  final String message;
  final String? timestamp;
  final bool isOperatorResponse;

  bool get isMine => senderRole == 'customer';

  factory TicketMessage.fromJson(dynamic raw) {
    final m = (raw as Map).cast<String, dynamic>();
    return TicketMessage(
      id: '${m['id'] ?? ''}',
      senderRole: '${m['senderRole'] ?? 'customer'}',
      senderName: '${m['senderName'] ?? ''}',
      message: '${m['message'] ?? ''}',
      timestamp: m['timestamp']?.toString(),
      isOperatorResponse: m['isOperatorResponse'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id, 'senderRole': senderRole, 'senderName': senderName,
        'message': message, 'timestamp': timestamp,
        'isOperatorResponse': isOperatorResponse,
      };
}
