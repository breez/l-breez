import 'dart:async';

import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/bloc/account/breez_liquid_sdk.dart';
import 'package:l_breez/bloc/currency/currency_state.dart';

class CurrencyBloc extends Cubit<CurrencyState> with HydratedMixin {
  final BreezLiquidSDK liquidSdk;

  CurrencyBloc(this.liquidSdk) : super(CurrencyState.initial()) {
    hydrate();
    _initializeCurrencyBloc();
  }

  void _initializeCurrencyBloc() {
    late final StreamSubscription streamSubscription;
    streamSubscription = liquidSdk.walletInfoStream.listen(
      (walletInfo) {
        listFiatCurrencies();
        fetchExchangeRates();
        streamSubscription.cancel();
      },
    );
  }

  void listFiatCurrencies() {
    liquidSdk.wallet!.listFiatCurrencies().then((fiatCurrencies) {
      emit(state.copyWith(
          fiatCurrenciesData: _sortedFiatCurrenciesList(
        fiatCurrencies,
        state.preferredCurrencies,
      )));
    });
  }

  List<FiatCurrency> _sortedFiatCurrenciesList(
    List<FiatCurrency> fiatCurrencies,
    List<String> preferredCurrencies,
  ) {
    var sorted = fiatCurrencies.toList();
    sorted.sort((f1, f2) {
      return f1.id.compareTo(f2.id);
    });

    // Then give precedence to the preferred items.
    for (var p in preferredCurrencies.reversed) {
      var preferredIndex = sorted.indexWhere((e) => e.id == p);
      if (preferredIndex >= 0) {
        var preferred = sorted[preferredIndex];
        sorted.removeAt(preferredIndex);
        sorted.insert(0, preferred);
      }
    }
    return sorted;
  }

  Future<Map<String, Rate>> fetchExchangeRates() async {
    final List<Rate> rates = await liquidSdk.wallet!.fetchFiatRates();
    final exchangeRates = rates.fold<Map<String, Rate>>({}, (map, rate) {
      map[rate.coin] = rate;
      return map;
    });
    emit(state.copyWith(exchangeRates: exchangeRates));
    return exchangeRates;
  }

  void setFiatId(String fiatId) {
    emit(state.copyWith(fiatId: fiatId));
  }

  void setPreferredCurrencies(List<String> preferredCurrencies) {
    emit(
      state.copyWith(
        fiatCurrenciesData: _sortedFiatCurrenciesList(state.fiatCurrenciesData, preferredCurrencies),
        preferredCurrencies: preferredCurrencies,
        fiatId: preferredCurrencies[0],
      ),
    );
  }

  void setBitcoinTicker(String bitcoinTicker) {
    emit(state.copyWith(bitcoinTicker: bitcoinTicker));
  }

  @override
  CurrencyState fromJson(Map<String, dynamic> json) {
    return CurrencyState.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(CurrencyState state) {
    return state.toJson();
  }
}
