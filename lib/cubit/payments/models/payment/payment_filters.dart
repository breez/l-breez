import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

class PaymentFilters implements Exception {
  final List<PaymentType>? filters;
  final int? fromTimestamp;
  final int? toTimestamp;

  PaymentFilters({
    this.filters = PaymentType.values,
    this.fromTimestamp,
    this.toTimestamp,
  });

  PaymentFilters.initial() : this();

  PaymentFilters copyWith({
    List<PaymentType>? filters,
    int? fromTimestamp,
    int? toTimestamp,
  }) {
    return PaymentFilters(
      filters: filters ?? this.filters,
      fromTimestamp: fromTimestamp,
      toTimestamp: toTimestamp,
    );
  }

  factory PaymentFilters.fromJson(Map<String, dynamic> json) {
    return PaymentFilters(
      filters: PaymentType.values,
      fromTimestamp: json["fromTimestamp"],
      toTimestamp: json["toTimestamp"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "filters": filters.toString(),
      "fromTimestamp": fromTimestamp,
      "toTimestamp": toTimestamp,
    };
  }

  @override
  String toString() => jsonEncode(toJson());

  @override
  int get hashCode => Object.hash(
        filters?.map((type) => type.hashCode).toList() ?? [],
        fromTimestamp,
        toTimestamp,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PaymentFilters &&
            listEquals(filters, other.filters) &&
            fromTimestamp == other.fromTimestamp &&
            toTimestamp == other.toTimestamp;
  }
}
