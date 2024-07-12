import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/models/payment_minutiae.dart';
import 'package:l_breez/routes/home/widgets/bubble_painter.dart';
import 'package:l_breez/routes/home/widgets/dashboard/wallet_dashboard_header_delegate.dart';
import 'package:l_breez/routes/home/widgets/payments_filter/fixed_sliver_delegate.dart';
import 'package:l_breez/routes/home/widgets/payments_filter/header_filter_chip.dart';
import 'package:l_breez/routes/home/widgets/payments_filter/payments_filter_sliver.dart';
import 'package:l_breez/routes/home/widgets/payments_list/payments_list.dart';
import 'package:l_breez/routes/home/widgets/status_text.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;
import 'package:logging/logging.dart';

const _kFilterMaxSize = 64.0;
const _kPaymentListItemHeight = 72.0;

final _log = Logger("AccountPage");

class AccountPage extends StatelessWidget {
  final GlobalKey firstPaymentItemKey;
  final ScrollController scrollController;

  const AccountPage(
    this.firstPaymentItemKey,
    this.scrollController, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountCubit, AccountState>(
      builder: (context, accountState) {
        return BlocBuilder<UserProfileCubit, UserProfileState>(
          builder: (context, userModel) {
            _log.info("AccountPage build with ${accountState.payments.length} payments");
            return Container(
              color: Theme.of(context).customData.dashboardBgColor,
              child: _build(
                context,
                accountState,
                userModel,
              ),
            );
          },
        );
      },
    );
  }

  Widget _build(
    BuildContext context,
    AccountState accountState,
    UserProfileState userModel,
  ) {
    final nonFilteredPayments = accountState.payments;
    final paymentFilters = accountState.paymentFilters;
    var accountCubit = context.read<AccountCubit>();
    final filteredPayments = accountCubit.filterPaymentList();

    List<Widget> slivers = [];

    slivers.add(
      const SliverPersistentHeader(
        floating: false,
        delegate: WalletDashboardHeaderDelegate(),
        pinned: true,
      ),
    );

    final bool showSliver = nonFilteredPayments.isNotEmpty || paymentFilters.filters != PaymentType.values;
    int? startDate = paymentFilters.fromTimestamp;
    int? endDate = paymentFilters.toTimestamp;
    bool hasDateFilter = startDate != null && endDate != null;
    if (showSliver) {
      slivers.add(
        PaymentsFilterSliver(
          maxSize: _kFilterMaxSize,
          scrollController: scrollController,
          hasFilter: paymentFilters.filters != PaymentType.values || hasDateFilter,
        ),
      );
    }

    if (hasDateFilter) {
      slivers.add(
        HeaderFilterChip(
          _kFilterMaxSize,
          DateTime.fromMillisecondsSinceEpoch(startDate),
          DateTime.fromMillisecondsSinceEpoch(endDate),
        ),
      );
    }

    if (showSliver) {
      slivers.add(
        PaymentsList(
          filteredPayments,
          _kPaymentListItemHeight,
          firstPaymentItemKey,
        ),
      );
      slivers.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: FixedSliverDelegate(
            _bottomPlaceholderSpace(context, filteredPayments),
            child: Container(),
          ),
        ),
      );
    } else if (!accountState.initial && nonFilteredPayments.isEmpty) {
      slivers.add(
        SliverPersistentHeader(
          delegate: FixedSliverDelegate(
            250.0,
            builder: (context, shrinkedHeight, overlapContent) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(40.0, 120.0, 40.0, 0.0),
                child: StatusText(accountState: accountState),
              );
            },
          ),
        ),
      );
    }

    return Stack(
      key: const Key("account_sliver"),
      fit: StackFit.expand,
      children: [
        if (!showSliver) ...[
          CustomPaint(painter: BubblePainter(context)),
        ],
        CustomScrollView(
          controller: scrollController,
          slivers: slivers,
        ),
      ],
    );
  }

  double _bottomPlaceholderSpace(
    BuildContext context,
    List<PaymentMinutiae> payments,
  ) {
    if (payments.isEmpty) return 0.0;
    double listHeightSpace =
        MediaQuery.of(context).size.height - kMinExtent - kToolbarHeight - _kFilterMaxSize - 25.0;
    const endDate = null;
    double dateFilterSpace = endDate != null ? 0.65 : 0.0;
    double bottomPlaceholderSpace =
        (listHeightSpace - (_kPaymentListItemHeight + 8) * (payments.length + 1 + dateFilterSpace))
            .clamp(0.0, listHeightSpace);
    return bottomPlaceholderSpace;
  }
}
