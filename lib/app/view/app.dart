import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/app/app_theme_manager/app_theme_manager.dart';
import 'package:l_breez/app/routes/routes.dart';
import 'package:l_breez/cubit/account/account_cubit.dart';
import 'package:l_breez/cubit/account/account_state.dart';
import 'package:l_breez/cubit/account/credentials_manager.dart';
import 'package:l_breez/cubit/backup/backup_cubit.dart';
import 'package:l_breez/cubit/chainswap/chainswap_cubit.dart';
import 'package:l_breez/cubit/currency/currency_cubit.dart';
import 'package:l_breez/cubit/ext/block_builder_extensions.dart';
import 'package:l_breez/cubit/input/input_cubit.dart';
import 'package:l_breez/cubit/lnurl/lnurl_cubit.dart';
import 'package:l_breez/cubit/security/security_cubit.dart';
import 'package:l_breez/cubit/security/security_state.dart';
import 'package:l_breez/cubit/user_profile/user_profile_cubit.dart';
import 'package:l_breez/services/injector.dart';
import 'package:theme_provider/theme_provider.dart';

class App extends StatelessWidget {
  final ServiceInjector injector;
  const App({super.key, required this.injector});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AccountCubit>(
          create: (BuildContext context) => AccountCubit(
            injector.liquidSDK,
            CredentialsManager(keyChain: injector.keychain),
          ),
        ),
        BlocProvider<InputCubit>(
          create: (BuildContext context) => InputCubit(
            injector.lightningLinks,
            injector.device,
          ),
        ),
        BlocProvider<UserProfileCubit>(
          create: (BuildContext context) => UserProfileCubit(),
        ),
        BlocProvider<CurrencyCubit>(
          create: (BuildContext context) => CurrencyCubit(injector.liquidSDK),
        ),
        BlocProvider<SecurityCubit>(
          create: (BuildContext context) => SecurityCubit(),
        ),
        BlocProvider<BackupCubit>(
          create: (BuildContext context) => BackupCubit(injector.liquidSDK),
        ),
        BlocProvider<LnUrlCubit>(
          create: (BuildContext context) => LnUrlCubit(injector.liquidSDK),
        ),
        BlocProvider<ChainSwapCubit>(
          create: (BuildContext context) => ChainSwapCubit(injector.liquidSDK),
        ),
      ],
      child: const AppView(),
    );
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  final GlobalKey _appKey = GlobalKey();
  final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return AppThemeManager(
      child: BlocBuilder2<AccountCubit, AccountState, SecurityCubit, SecurityState>(
        builder: (context, accountState, securityState) {
          return MaterialApp(
            key: _appKey,
            title: "Misty ${getSystemAppLocalizations().app_name}",
            theme: ThemeProvider.themeOf(context).data,
            localizationsDelegates: localizationsDelegates(),
            supportedLocales: supportedLocales(),
            builder: (BuildContext context, Widget? child) {
              const kMaxTitleTextScaleFactor = 1.3;

              return MediaQuery.withClampedTextScaling(
                maxScaleFactor: kMaxTitleTextScaleFactor,
                child: child!,
              );
            },
            initialRoute: securityState.pinStatus == PinStatus.enabled ? "lockscreen" : "splash",
            onGenerateRoute: (RouteSettings settings) => onGenerateRoute(
              settings: settings,
              homeNavigatorKey: _homeNavigatorKey,
              accountState: accountState,
              securityState: securityState,
            ),
          );
        },
      ),
    );
  }
}
