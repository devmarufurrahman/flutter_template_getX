import 'dart:io';

void main(List<String> arguments) async {
  stdout.write('🚀 Enter your Project Name (snake_case): ');
  final projectName = stdin.readLineSync()?.trim();

  if (projectName == null || projectName.isEmpty) {
    print('❌ Project name cannot be empty!');
    return;
  }

  print('\n--- 🏗️  STARTING PROJECT CREATION: $projectName ---');

  // ১. ফ্লাটার প্রজেক্ট ক্রিয়েট করা
  print('Step 1: Running "flutter create"...');
  var createResult = await Process.run('flutter', [
    'create',
    projectName,
  ], runInShell: true);
  if (createResult.exitCode != 0) {
    print('❌ Error: ${createResult.stderr}');
    return;
  }
  Directory.current = Directory('${Directory.current.path}/$projectName');

  // ২. এসেটস ফোল্ডার তৈরি
  print('Step 2: Creating Assets folders...');
  final assetFolders = [
    'animations',
    'fonts',
    'icons',
    'images',
    'vectors',
    'videos',
  ];
  for (var folder in assetFolders) {
    await Directory('assets/$folder').create(recursive: true);
  }

  // ৩. রুট ফাইলগুলো তৈরি (.env, l10n.yaml)
  print(
    'Step 3: Creating Config files (.env, l10n.yaml, create_feature.dart)...',
  );
  File('.env').writeAsStringSync(
    'API_BASE_URL=https://api.example.com\nAPP_NAME=$projectName',
  );

  File('l10n.yaml').writeAsStringSync('''
  arb-dir: lib/l10n
  template-arb-file: app_en.arb
  output-localization-file: app_localizations.dart
  output-dir: lib/generated/l10n  
  untranslated-messages-file: lib/l10n/untranslated.json  
  ''');

  // --- Create Feature Script জেনারেট করা (Project Root-এ) ---
  print('📝 Generating "create_feature.dart" in project root...');

  File('create_feature.dart').writeAsStringSync('''
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('❌ Error: Please provide a feature name.');
    print('Usage: dart create_feature.dart <feature_name> [optional_path]');
    return;
  }

  String projectName = _getProjectName();
  if (projectName.isEmpty) {
    print('❌ Error: Could not find "name" in pubspec.yaml');
    return;
  }

  String featureName = _toSnakeCase(args[0]);
  String className = _toCamelCase(featureName);
  String targetDir = args.length > 1 ? args[1] : 'lib/feature';
  if (targetDir.endsWith('/')) targetDir = targetDir.substring(0, targetDir.length - 1);
  String basePath = '\$targetDir/\$featureName';

  print('🚀 Creating feature: \$featureName');

  _createDirectory('\$basePath/view');
  _createDirectory('\$basePath/controller');
  _createDirectory('\$basePath/binding');
  _createDirectory('\$basePath/repository');
  _createDirectory('\$basePath/widgets');

  _createFile('\$basePath/view/\${featureName}_view.dart', _viewTemplate(className, projectName));
  _createFile('\$basePath/controller/\${featureName}_controller.dart', _controllerTemplate(className, projectName));
  _createFile('\$basePath/binding/\${featureName}_binding.dart', _bindingTemplate(className, projectName));
  _createFile('\$basePath/repository/\${featureName}_repository.dart', _repositoryTemplate(className, projectName));

  _addToImportsFile('lib/core/utils/constants/imports.dart', projectName, featureName, [
    '\$basePath/view/\${featureName}_view.dart',
    '\$basePath/controller/\${featureName}_controller.dart',
    '\$basePath/binding/\${featureName}_binding.dart',
    '\$basePath/repository/\${featureName}_repository.dart',
  ]);

  _addRoute(className);
  _addPage(className);

  print('\\n✅ Success! Feature "\$featureName" created and integrated.');
}

String _getProjectName() {
  final file = File('pubspec.yaml');
  if (!file.existsSync()) return '';
  final lines = file.readAsLinesSync();
  for (var line in lines) {
    if (line.trim().startsWith('name:')) return line.split(':')[1].trim();
  }
  return '';
}

void _createDirectory(String path) {
  final dir = Directory(path);
  if (!dir.existsSync()) dir.createSync(recursive: true);
}

void _createFile(String path, String content) {
  final file = File(path);
  if (!file.existsSync()) {
    file.createSync(recursive: true);
    file.writeAsStringSync(content);
  }
}

void _addToImportsFile(String path, String projectName, String featureName, List<String> files) {
  final file = File(path);
  if (file.existsSync()) {
    String content = file.readAsStringSync();
    StringBuffer exports = StringBuffer();
    exports.writeln('\\n// --- \$featureName modules export ---');
    for (var f in files) {
      String p = f.replaceFirst('lib/', 'package:\$projectName/');
      if (!content.contains(p)) exports.writeln("export '\$p';");
    }
    file.writeAsStringSync(exports.toString(), mode: FileMode.append);
  }
}

void _addRoute(String className) {
  final file = File('lib/router/app_routes.dart');
  if (!file.existsSync()) return;
  String content = file.readAsStringSync();
  String name = className[0].toLowerCase() + className.substring(1);
  String line = '  static String \${name}View = "/\${name}View";';
  if (content.contains(line)) return;
  int idx = content.lastIndexOf('}');
  file.writeAsStringSync(content.substring(0, idx) + '\$line\\n' + content.substring(idx));
}

void _addPage(String className) {
  final file = File('lib/router/app_pages.dart');
  if (!file.existsSync()) return;
  String content = file.readAsStringSync();
  String name = className[0].toLowerCase() + className.substring(1);
  String entry = '\\n    GetPage(\\n      name: Routes.\${name}View,\\n      page: () => \${className}View(),\\n      binding: \${className}Binding(),\\n    ),';
  int idx = content.lastIndexOf('];');
  file.writeAsStringSync(content.substring(0, idx) + '\$entry' + content.substring(idx));
}

String _toSnakeCase(String text) => text.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_\${m.group(0)!.toLowerCase()}').replaceAll(RegExp(r'^_'), '');
String _toCamelCase(String text) => text.split('_').map((w) => w.isEmpty ? '' : '\${w[0].toUpperCase()}\${w.substring(1)}').join('');

String _viewTemplate(String c, String p) => "import 'package:\$p/core/utils/constants/imports.dart';\\n\\nclass \${c}View extends GetView<\${c}Controller> {\\n  const \${c}View({super.key});\\n  @override\\n  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('\${c}View')), body: Center(child: Text('\${c}View is working')));\\n}";
String _controllerTemplate(String c, String p) => "import 'package:\$p/core/utils/constants/imports.dart';\\n\\nclass \${c}Controller extends GetxController { final \${c}Repository _repository = \${c}Repository(); }";
String _bindingTemplate(String c, String p) => "import 'package:\$p/core/utils/constants/imports.dart';\\n\\nclass \${c}Binding extends Bindings { @override void dependencies() { Get.lazyPut<\${c}Controller>(() => \${c}Controller()); } }";
String _repositoryTemplate(String c, String p) => "import 'package:\$p/core/utils/constants/imports.dart';\\n\\nclass \${c}Repository { }";
''');

  // ৪. pubspec.yaml নতুন করে তৈরি করা (নিখুঁত পদ্ধতির জন্য)
  print('Step 4: Writing a clean and structured pubspec.yaml...');
  print('Step 4: Writing a clean pubspec.yaml (Auto-detecting SDK)...');

  // অটো ভার্সন ডিটেক্ট করা
  final String currentDartVersion = Platform.version.split(' ').first;
  final pubspecFile = File('pubspec.yaml');

  final String newPubspecContent =
      '''
name: $projectName
description: "A new Flutter project for $projectName."
# The following line prevents the package from being accidentally published to
# pub.dev using `flutter pub publish`. This is preferred for private packages.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=$currentDartVersion <4.0.0'

# RPS Scripts for automation
scripts:
  gen: flutter gen-l10n && flutter pub run build_runner build --delete-conflicting-outputs
  clean:android: "flutter clean && flutter pub get && cd android && ./gradlew clean && cd .."
  clean:ios: "flutter clean && flutter pub get && cd ios && rm -rf Podfile.lock && pod install && cd .."
  clean:flutter: flutter clean && flutter pub get
  clean:force: "flutter clean && rm -rf pubspec.lock && rm -rf ios/Pods ios/Podfile.lock && rm -rf android/.gradle android/app/build && flutter pub get && cd ios && pod cache clean --all && pod deintegrate && pod setup && pod install && cd .."
  run:dev: flutter run --flavor dev
  run:prod: flutter run --flavor prod
  run: flutter run

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  

dev_dependencies:
  flutter_test:
    sdk: flutter
  

# For information on the generic Dart part of this file, see the
# following page: https://dart.dev/tools/pub/pubspec
flutter_gen :
  output: lib/generated/assets/
  line_length: 100

# The following section is specific to Flutter packages.
flutter:
  generate: true
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
    - assets/videos/
    - assets/animations/
    - assets/vectors/
    - .env

# An image asset can refer to one or more resolution-specific "variants", see
  # https://flutter.dev/to/resolution-aware-images

  # For details regarding adding assets from package dependencies, see
  # https://flutter.dev/to/asset-from-package

  # To add custom fonts to your application, add a fonts section here,
  # in this "flutter" section. Each entry in this list should have a
  # "family" key with the font family name, and a "fonts" key with a
  # list giving the asset and other descriptors for the font. For
  # example:
  fonts:
    - family: Roboto
      fonts:
        - asset: assets/fonts/Roboto-Thin.ttf
          weight: 100
        - asset: assets/fonts/Roboto-LightItalic.ttf
          weight: 300
          style: italic
        - asset: assets/fonts/Roboto-Light.ttf
          weight: 300
        - asset: assets/fonts/Roboto-Regular.ttf
          weight: 400
        - asset: assets/fonts/Roboto-Medium.ttf
          weight: 500
        - asset: assets/fonts/Roboto-Bold.ttf
          weight: 700
        - asset: assets/fonts/Roboto-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Roboto-SemiBoldItalic.ttf
          style: italic
          weight: 600
        - asset: assets/fonts/Roboto-ExtraBold.ttf
          style: italic
          weight: 800
        - asset: assets/fonts/Roboto-ExtraBold.ttf
          weight: 800
        - asset: assets/fonts/Roboto-Black.ttf
          weight: 900
  #
  # For details regarding fonts from package dependencies,
  # see https://flutter.dev/to/font-from-package
  ''';

  await pubspecFile.writeAsString(newPubspecContent);
  print('✅ pubspec.yaml generated successfully with proper indentation.');

  // ৫. প্যাকেজ ইন্সটলেশন
  print('Step 5: Installing all dependencies...');
  final packages = [
    'cupertino_icons',
    'flutter_screenutil',
    'get',
    'google_fonts',
    'url_launcher',
    'intl',
    'logger',
    'video_player',
    'dio',
    'pretty_dio_logger',
    'connectivity_plus',
    'dio_smart_retry',
    'dio_cache_interceptor',
    'get_it',
    'geolocator',
    'permission_handler',
    'location',
    'shared_preferences',
    'carousel_slider',
    'shimmer',
    'cached_network_image',
    'flutter_svg',
    'intl_phone_field',
    'webview_flutter',
    'image_picker',
    'file_picker',
    'lottie',
    'zo_animated_border',
    'app_settings',
    'firebase_core',
    'firebase_analytics',
    'firebase_crashlytics',
    'google_maps_flutter',
    'rps',
    'firebase_messaging',
    'flutter_dotenv',
    'get_storage',
  ];
  await Process.run('flutter', ['pub', 'add', ...packages], runInShell: true);

  final devPackages = [
    'flutter_lints',
    'change_app_package_name',
    'build_runner',
    'flutter_gen_runner',
    'flutter_flavorizr',
  ];
  await Process.run('flutter', [
    'pub',
    'add',
    '--dev',
    ...devPackages,
  ], runInShell: true);

  // ৬. RPS গ্লোবাল এক্টিভেশন
  print('Step 6: Activating RPS globally...');
  await Process.run('dart', [
    'pub',
    'global',
    'activate',
    'rps',
  ], runInShell: true);

  // main.dart রি-রাইট করা (আপনার দেওয়া কোড অনুযায়ী)
  print('📝 Overwriting lib/main.dart...');
  File('lib/main.dart').writeAsStringSync('''
import 'core/utils/constants/imports.dart';

void main() async {
WidgetsFlutterBinding.ensureInitialized();

await dotenv.load(fileName: ".env");
await LocalStorageService().init();
await Get.putAsync<LocalizationService>(() async {
    final service = LocalizationService();
    await service.onInit();
    return service;
  });

DioHelper().init();

runApp(const MyApp());

}
''');

  // App.dart তৈরি
  File('lib/app.dart').writeAsStringSync('''
import 'package:$projectName/router/app_pages.dart';
import 'core/utils/constants/imports.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return GetMaterialApp(
          initialRoute: Routes.splashView,
          getPages: AppPages.pages,
          initialBinding: GlobalBinder(),
          themeMode: ThemeMode.light,
          theme: AppTheme.lightTheme,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en', 'US'), Locale('bn', 'BD')],
          locale: LocalizationService.to.currentLocale,
        );
      },
    );
  }
}
''');

  // ৭. লিব ফোল্ডার এবং বয়লারপ্লেট তৈরি
  print('Step 7: Generating Boilerplate files and Architecture...');

  final libFolders = [
    'lib/l10n',
    'lib/router',
    'lib/features',
    'lib/features/splash',
    'lib/features/splash/views',
    'lib/features/splash/widgets',
    'lib/features/splash/bindings',
    'lib/features/splash/controllers',
    'lib/features/splash/models',
    'lib/features/splash/repositories',
    'lib/core',
    'lib/core/bindings',
    'lib/core/common',
    'lib/core/common/widgets',
    'lib/core/common/styles',
    'lib/core/common/controllers',
    'lib/core/common/repositories',
    'lib/core/common/models',
    'lib/core/interfaces',
    'lib/core/localization',
    'lib/core/network',
    'lib/core/services',
    'lib/core/theme',
    'lib/core/theme/custom_theme',
    'lib/core/utils',
    'lib/core/utils/constants',
    'lib/core/utils/device',
    'lib/core/utils/formatters',
    'lib/core/utils/helpers',
    'lib/core/utils/logging',
    'lib/core/utils/validators',
  ];
  for (var folder in libFolders) {
    await Directory(folder).create(recursive: true);
  }

  // ফোল্ডার তৈরি শেষ, এখন ফাইল রাইট করা হবে
  print('📝 Writing files into folders...');

  // ARB Files (Localization)
  File('lib/l10n/app_en.arb').writeAsStringSync('''
  {
    "appName": "$projectName",
    "welcomeMessage": "Welcome to $projectName",
    "helloWorld": "Hello World!"
  }
  ''');

  File('lib/l10n/app_bn.arb').writeAsStringSync('''
  {
    "appName": "প্রজেক্ট $projectName",
    "welcomeMessage": "$projectName প্রজেক্টে আপনাকে স্বাগতম",
    "helloWorld": "হ্যালো ওয়ার্ল্ড!"
  }
  ''');

  print('\n--- app pages generating... ---');
  File('lib/router/app_pages.dart').writeAsStringSync('''
  import 'package:$projectName/core/utils/constants/imports.dart';

  class AppPages {
    static List<GetPage> pages = [
      GetPage(name: Routes.splashView, page: () => SplashView(),
        binding: SplashBinding(),),
      
    ];
  }
  ''');

  print('\n--- app routes generating... ---');
  File('lib/router/app_routes.dart').writeAsStringSync('''
  abstract class Routes {
  static String splashView = "/splashView";
  static String loginView = "/loginView";
  }
  ''');

  print('\n--- splash view generating... ---');
  File('lib/features/splash/views/splash_view.dart').writeAsStringSync('''
  import 'package:$projectName/core/utils/constants/imports.dart';

  class SplashView extends GetView<SplashController> {
    const SplashView({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text('SplashView')),
        body: const Center(
          child: Text('SplashView is working'),
        ),
      );
    }
  }
  ''');

  print('\n--- splash controller generating... ---');
  File(
    'lib/features/splash/controllers/splash_controller.dart',
  ).writeAsStringSync('''
  import 'package:$projectName/core/utils/constants/imports.dart';

  class SplashController extends GetxController {
    final SplashRepository _repository = SplashRepository();
    
    // Add your logic here
  }
  ''');

  print('\n--- splash binding generating... ---');
  File('lib/features/splash/bindings/splash_binding.dart').writeAsStringSync('''
  import 'package:$projectName/core/utils/constants/imports.dart';

  class SplashBinding extends Bindings {
    @override
    void dependencies() {
      Get.lazyPut<SplashController>(
        () => SplashController(),
      );
    }
  }
  ''');

  print('\n--- splash repository generating... ---');
  File(
    'lib/features/splash/repositories/splash_repository.dart',
  ).writeAsStringSync('''
  import 'package:$projectName/core/utils/constants/imports.dart';

  class SplashRepository {
    // final HttpMethod _httpMethod = HttpMethod();

    // Add API calls here
  }
  ''');

  print('\n--- global binder generating... ---');
  File('lib/core/bindings/global_binder.dart').writeAsStringSync('''
  import '../utils/constants/imports.dart';

  class GlobalBinder extends Bindings {
    @override
    void dependencies() {
      // Initialize your global controllers or services here
      // Example: Get.put(DioHelper(), permanent: true);
    }
  }
  ''');

  print('\n--- global text style generating... ---');

  // ফোল্ডারটি নিশ্চিত করা হচ্ছে
  Directory('lib/core/common/styles').createSync(recursive: true);

  File('lib/core/common/styles/global_text_style.dart').writeAsStringSync('''
    import '../../utils/constants/imports.dart';

    TextStyle getTextStyle({
      double fontSize = 14.0,
      FontWeight fontWeight = FontWeight.w400,
      double lineHeight = 12.0,
      TextAlign textAlign = TextAlign.center,
      Color color = AppColors.white,
    }) {
      return TextStyle(
        fontFamily: 'Roboto',
        fontSize: fontSize.sp,
        fontWeight: fontWeight,
        height: fontSize.sp / lineHeight.sp,
        color: color,
      );
    }

  ''');

  print('\n--- localization extension generating... ---');

  // ফোল্ডারটি নিশ্চিত করা হচ্ছে
  Directory('lib/core/localization').createSync(recursive: true);

  File('lib/core/localization/localization_extension.dart').writeAsStringSync(
    '''
  import 'package:$projectName/core/utils/constants/imports.dart';
  import 'package:$projectName/generated/l10n/app_localizations.dart';

  extension LocalizationExtension on BuildContext {
    AppLocalizations get tr => AppLocalizations.of(this)!;
  }
  ''',
  );

  print('\n--- localization service generating... ---');

  // ফোল্ডারটি নিশ্চিত করা হচ্ছে
  Directory('lib/core/localization').createSync(recursive: true);

  File('lib/core/localization/localization_service.dart').writeAsStringSync('''
  import 'package:$projectName/core/utils/constants/imports.dart';
  import 'package:$projectName/generated/l10n/app_localizations.dart';

  // How to use:
  // await LocalizationService.to.changeLanguage('bn'); // Bangla
  // await LocalizationService.to.changeLanguage('en'); // English

  class LocalizationService extends GetxService {
    static LocalizationService get to => Get.find();

    // Default English
    Locale currentLocale = const Locale('en', 'US');

    @override
    Future<void> onInit() async {
      super.onInit();
      _loadLanguage();
    }

    void _loadLanguage() {
      final savedCode = LocalStorageService().languageCode;
      if (savedCode != null) {
        currentLocale = Locale(savedCode);
      }
      Get.updateLocale(currentLocale);
    }

    Future<void> changeLanguage(String languageCode) async {
      currentLocale = Locale(languageCode);
      await Get.updateLocale(currentLocale);

      // LocalStorageService- save the selected language code
      await LocalStorageService().saveLanguageCode(languageCode);
    }

    Future<void> resetToEnglish() async {
      await changeLanguage('en');
    }

    // simple tr getter
    static AppLocalizations get tr => AppLocalizations.of(Get.context!)!;
  }
  ''');

  print('\n--- dio helper generating... ---');

  // ফোল্ডারটি নিশ্চিত করা হচ্ছে
  Directory('lib/core/network').createSync(recursive: true);

  File('lib/core/network/dio_helper.dart').writeAsStringSync('''
  // ignore_for_file: unrelated_type_equality_checks

  import '../utils/constants/imports.dart';
  import 'package:dio/dio.dart';

  class DioHelper {
    static final DioHelper _instance = DioHelper._internal();
    factory DioHelper() => _instance;
    DioHelper._internal();

    late Dio dio;

    Future<void> init() async {
      dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.apiUrl,
          connectTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 15),
          receiveDataWhenStatusError: true,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      // PrettyDioLogger - Debugging এর জন্য দারুণ
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          error: true,
          compact: false,
        ),
      );

      // Connectivity + Custom Log + Auth Handle
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            var connectivity = await Connectivity().checkConnectivity();
            if (connectivity == ConnectivityResult.none) {
              AppLoggerHelper.error('No Internet! Request blocked.');
              return handler.reject(DioException(requestOptions: options));
            }
            AppLoggerHelper.info("→ \${options.method} \${options.uri}");
            handler.next(options);
          },
          onError: (err, handler) {
            if (err.response?.statusCode == 401) {
              AppLoggerHelper.warning(
                "401 Unauthorized detected! Redirecting to login...",
              );

              // Token expire 
              Get.offAllNamed(Routes.loginView);

              return handler.reject(err);
            }
            AppLoggerHelper.error("✗ Error: \${err.message}");
            handler.next(err);
          },
        ),
      );
    }
  }
  ''');

  print('\n--- http method generating... ---');

  // ফোল্ডার নিশ্চিত করা হচ্ছে
  Directory('lib/core/network').createSync(recursive: true);

  File('lib/core/network/http_method.dart').writeAsStringSync('''
import '../utils/constants/imports.dart';
import 'package:dio/dio.dart';

class HttpMethod {
  final Dio _dio = DioHelper().dio;

  Map<String, dynamic> headers = {'Authorization': 'Bearer your_token'};

  // GET
  Future<dynamic> get({
    required String path,
    Map<String, dynamic>? queryParameters,
    bool isAuthRequired = false,
    CancelToken? cancelToken,
    String? customUrl,
  }) async {
    try {
      // if custom url
      final String url = customUrl != null ? "\$customUrl\$path" : path;

      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: isAuthRequired ? Options(headers: headers) : null,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST
  Future<dynamic> post({
    required String path,
    required Map<String, dynamic> data,
    bool isAuthRequired = false,
    CancelToken? cancelToken,
    String? customUrl,
  }) async {
    try {
      // if custom url
      final String url = customUrl != null ? "\$customUrl\$path" : path;

      final response = await _dio.post(
        url,
        data: data,
        options: isAuthRequired ? Options(headers: headers) : null,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT
  Future<dynamic> put({
    required String path,
    required Map<String, dynamic> data,
    bool isAuthRequired = false,
    CancelToken? cancelToken,
    String? customUrl,
  }) async {
    try {
      // if custom url
      final String url = customUrl != null ? "\$customUrl\$path" : path;

      final response = await _dio.put(
        url,
        data: data,
        options: isAuthRequired ? Options(headers: headers) : null,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PATCH
  Future<dynamic> patch({
    required String path,
    required Map<String, dynamic> data,
    bool isAuthRequired = false,
    CancelToken? cancelToken,
    String? customUrl,
  }) async {
    try {
      // if custom url
      final String url = customUrl != null ? "\$customUrl\$path" : path;

      final response = await _dio.patch(
        url,
        data: data,
        options: isAuthRequired ? Options(headers: headers) : null,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE
  Future<dynamic> delete({
    required String path,
    Map<String, dynamic>? data,
    bool isAuthRequired = false,
    CancelToken? cancelToken,
    String? customUrl,
  }) async {
    try {
      // if custom url
      final String url = customUrl != null ? "\$customUrl\$path" : path;

      final response = await _dio.delete(
        url,
        data: data,
        options: isAuthRequired ? Options(headers: headers) : null,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error Handling
  Exception _handleError(DioException e) {
    if (e.response != null) {
      final message =
          e.response?.data['error'] ??
          e.response?.statusMessage ??
          'Unknown error';
      AppLoggerHelper.error('Error Message: \$message');
      Get.snackbar(
        "Error",
        message,
        backgroundColor: AppColors.red,
        colorText: Colors.white,
      );

      return Exception('\$message (Status: \${e.response?.statusCode})');
    } else {
      return Exception('Network error: \${e.message}');
    }
  }
}
''');

  print('\n--- analytics service generating... ---');

  // ফোল্ডারটি নিশ্চিত করা হচ্ছে
  Directory('lib/core/services').createSync(recursive: true);

  File('lib/core/services/analytics_service.dart').writeAsStringSync('''
import '../utils/constants/imports.dart';

class AnalyticsService extends GetxService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logCustomEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: eventName, parameters: parameters);
      if (kDebugMode) {
        AppLoggerHelper.debug(
          '📊 Analytics Event Logged: \$eventName | Params: \$parameters',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLoggerHelper.debug('❌ Analytics Error: \$e');
      }
    }
  }
}
''');

  print('\n--- crashlytics service generating... ---');

  // ফোল্ডারটি নিশ্চিত করা হচ্ছে
  Directory('lib/core/services').createSync(recursive: true);

  File('lib/core/services/crashlytics_service.dart').writeAsStringSync('''
import 'package:$projectName/core/utils/constants/imports.dart';

class CrashlyticsService extends GetxService {
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // Non-fatal error recording (e.g., within a try-catch block)
  Future<void> recordError(
    dynamic exception,
    StackTrace stack, {
    dynamic reason,
  }) async {
    await _crashlytics.recordError(exception, stack, reason: reason);
    if (kDebugMode) {
      AppLoggerHelper.debug('🛑 [Crashlytics] Error Logged: \$exception');
    }
  }

  // Log breadcrumbs to track user steps before a crash
  Future<void> log(String message) async {
    await _crashlytics.log(message);
    if (kDebugMode) {
      AppLoggerHelper.debug('📝 [Crashlytics] Log: \$message');
    }
  }

  // Set user identifier for personalized crash reports
  Future<void> setUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  // Error with extra context data
  Future<void> setCustomKey(String key, dynamic value) async {
    if (value is int) {
      await _crashlytics.setCustomKey(key, value);
    } else if (value is String) {
      await _crashlytics.setCustomKey(key, value);
    } else if (value is bool) {
      await _crashlytics.setCustomKey(key, value);
    } else if (value is double) {
      await _crashlytics.setCustomKey(key, value);
    }
  }
}
''');

  print('\n--- location service generating... ---');

  // ফোল্ডার নিশ্চিত করা হচ্ছে
  Directory('lib/core/services').createSync(recursive: true);

  File('lib/core/services/location_service.dart').writeAsStringSync('''
import 'package:app_settings/app_settings.dart';
import 'package:$projectName/core/utils/constants/imports.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';

class LocationService extends GetxService {
  final loc.Location _location = loc.Location();
  final Rxn<Position> position = Rxn<Position>();

  RxBool isLocationEnabled = false.obs;
  RxBool hasLocationPermission = false.obs;

  Future<Position?> checkAndRequestLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      await _showCustomEnableLocationDialog();
      return null;
    }

    final permission = await Permission.location.request();

    if (permission.isDenied || permission.isPermanentlyDenied) {
      await _showCustomPermissionDialog();
      return null;
    }

    isLocationEnabled.value = true;
    hasLocationPermission.value = true;

    Position currentPos = await Geolocator.getCurrentPosition();
    position.value = currentPos;
    AppLoggerHelper.debug(
      'Location: \${currentPos.latitude}, \${currentPos.longitude}',
    );
    return currentPos;
  }

  Future<void> _showCustomEnableLocationDialog() async {
    await Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.white,
        title: const Text(
          'Location Services Disabled',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'To use location features, please enable Location Services in your device settings.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              AppSettings.openAppSettings(type: AppSettingsType.location);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    await Future.delayed(const Duration(seconds: 1));
    await checkAndRequestLocation();
  }

  Future<void> _showCustomPermissionDialog() async {
    await Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.white,
        title: const Text(
          'Permission Required',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This app needs location permission. Please enable it in Settings.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              AppSettings.openAppSettings(type: AppSettingsType.location);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    await Future.delayed(const Duration(seconds: 1));
    await checkAndRequestLocation();
  }
}
''');

  print('\n--- media service generating... ---');

  // ফোল্ডারটি নিশ্চিত করা হচ্ছে
  Directory('lib/core/services').createSync(recursive: true);

  File('lib/core/services/media_service.dart').writeAsStringSync('''
import 'dart:io';
import 'package:$projectName/core/utils/constants/imports.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../common/widgets/custom_bottom_sheet.dart';


class MediaService {
  // static Future<File?> pickMedia(
  //   String title, {
  //   bool showCamera = true,
  //   bool showGallery = true,
  //   bool showFile = true,
  //   bool isCrop = false,
  //   CropAspectRatioPreset? cropRatio,
  //   CropStyle? cropStyle,
  // }) async {
  //   final ImagePicker picker = ImagePicker();

  //   final dynamic result = await showCustomBottomSheet(
  //     backgroundColor: AppColors.white,
  //     contentWidgets: [
  //       const SizedBox(height: 10),

  //       Text(
  //         title,
  //         style: getTextStyle(
  //           fontSize: 16,
  //           fontWeight: FontWeight.bold,
  //           color: AppColors.white,
  //         ),
  //       ),
  //       const SizedBox(height: 25),

  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceAround,
  //         children: [
  //           // --- Camera Option ---
  //           if (showCamera)
  //             _buildOption(
  //               icon: Icons.camera_alt,
  //               label: "Camera",
  //               onTap: () async {
  //                 final XFile? photo = await picker.pickImage(
  //                   source: ImageSource.camera,
  //                   imageQuality: 80,
  //                 );

  //                 if (photo != null) {
  //                   File file = File(photo.path);
  //                   if (isCrop) {
  //                     File? cropped = await _cropImage(
  //                       file,
  //                       cropRatio,
  //                       cropStyle,
  //                     );
  //                     if (cropped != null) Get.back(result: cropped);
  //                   } else {
  //                     Get.back(result: file);
  //                   }
  //                 }
  //               },
  //             ),

  //           // --- Gallery Option ---
  //           if (showGallery)
  //             _buildOption(
  //               icon: Icons.photo_library,
  //               label: "Gallery",
  //               onTap: () async {
  //                 final XFile? image = await picker.pickImage(
  //                   source: ImageSource.gallery,
  //                   imageQuality: 80,
  //                 );

  //                 if (image != null) {
  //                   File file = File(image.path);
  //                   if (isCrop) {
  //                     File? cropped = await _cropImage(
  //                       file,
  //                       cropRatio,
  //                       cropStyle,
  //                     );
  //                     if (cropped != null) Get.back(result: cropped);
  //                   } else {
  //                     Get.back(result: file);
  //                   }
  //                 }
  //               },
  //             ),

  //           // --- File Option ---
  //           if (showFile)
  //             _buildOption(
  //               icon: Icons.snippet_folder,
  //               label: "File",
  //               onTap: () async {
  //                 FilePickerResult? result = await FilePicker.platform
  //                     .pickFiles(
  //                       type: FileType.custom,
  //                       allowedExtensions: [
  //                         'pdf', 'doc', 'docx', 'jpg', 'png', 'jpeg', 'gif', 'mp3', 'mp4', 'avi',
  //                       ],
  //                     );
  //                 if (result != null && result.files.single.path != null) {
  //                   Get.back(result: File(result.files.single.path!));
  //                 }
  //               },
  //             ),
  //         ],
  //       ),
  //       const SizedBox(height: 10),
  //     ],
  //   );

  //   if (result != null && result is File) {
  //     return result;
  //   }
  //   return null;
  // }

  // static Widget _buildOption({
  //   required IconData icon,
  //   required String label,
  //   required VoidCallback onTap,
  // }) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Column(
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.all(15),
  //           decoration: BoxDecoration(
  //             color: AppColors.white.withOpacity(0.1),
  //             shape: BoxShape.circle,
  //             border: Border.all(color: AppColors.white, width: 1.5),
  //           ),
  //           child: Icon(icon, size: 28, color: AppColors.white),
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           label,
  //           style: getTextStyle(
  //             fontSize: 13,
  //             fontWeight: FontWeight.w600,
  //             color: AppColors.white,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // static Future<File?> _cropImage(
  //   File imageFile,
  //   CropAspectRatioPreset? presetRatio,
  //   CropStyle? cropStyle,
  // ) async {
  //   try {
  //     CroppedFile? croppedFile = await ImageCropper().cropImage(
  //       sourcePath: imageFile.path,
  //       uiSettings: [
  //         AndroidUiSettings(
  //           toolbarTitle: 'Image Editor',
  //           toolbarColor: AppColors.primary,
  //           toolbarWidgetColor: Colors.white,
  //           statusBarColor: AppColors.primary,
  //           backgroundColor: AppColors.white,
  //           activeControlsWidgetColor: AppColors.primary,
  //           initAspectRatio: presetRatio ?? CropAspectRatioPreset.original,
  //           lockAspectRatio: presetRatio != null,
            
  //         ),
  //         IOSUiSettings(
  //           title: 'Image Editor',
  //           doneButtonTitle: 'Done',
  //           cancelButtonTitle: 'Cancel',
  //           aspectRatioLockEnabled: presetRatio != null,
  //           resetAspectRatioEnabled: presetRatio == null,
            
  //         ),
  //       ],
  //     );

  //     if (croppedFile != null) {
  //       return File(croppedFile.path);
  //     }
  //   } catch (e) {
  //     AppLoggerHelper.debug("Crop Error: \$e");
  //   }
  //   return null;
  // }
}
''');

  print('\n--- network service generating... ---');

  // Ensure the directory exists
  Directory('lib/core/services').createSync(recursive: true);

  File('lib/core/services/network_service.dart').writeAsStringSync('''
/**
 * --- NetworkService ---
 * * Why use this service?
 * 1. To monitor the app's real-time internet connectivity.
 * 2. To automatically show a custom warning dialog when the internet is disconnected.
 * 3. To share the connection status (isConnected) across the entire app using GetX.
 * * * How to use?
 * 1. Register in GlobalBinder: Get.put(NetworkService(), permanent: true);
 * 2. To check current status: if (Get.find<NetworkService>().isConnected.value) { ... }
 * 3. Use Obx() in UI for real-time connectivity updates.
 */

import '../utils/constants/imports.dart';

class NetworkService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  
  // Observable boolean to track connection status
  RxBool isConnected = true.obs;

  @override
  void onInit() {
    super.onInit();
    checkInitialConnection();
    _listenConnectivityChanges();
  }

  /// Initial check when the service starts
  Future<void> checkInitialConnection() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
  }

  /// Listens for real-time connectivity changes (WiFi, Mobile Data, etc.)
  void _listenConnectivityChanges() {
    _connectivity.onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results);
    });
  }

  /// Updates the status and handles UI feedback (Dialog)
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // If the list does not contain 'none' and is not empty, connection is available
    final bool connected =
        !results.contains(ConnectivityResult.none) && results.isNotEmpty;

    isConnected.value = connected;

    if (!connected) {
      // Show warning dialog if not already open
      if (Get.isDialogOpen != true) {
        Get.dialog(
          CustomWarningDialog(
            message: "Internet connection is turned off. Please check your network settings.",
            showOkButton: false,
            barrierDismissible: true,
          ),
          barrierDismissible: true,
        );
      }
    } else {
      // Automatically close the dialog if internet connection is restored
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    }
  }
}
''');

  print('\n--- notification service generating... ---');

  // Ensuring the directory exists
  Directory('lib/core/services').createSync(recursive: true);

  File('lib/core/services/notification_service.dart').writeAsStringSync('''
/**
 * --- NotificationService ---
 * * Why use this service?
 * 1. To manage Firebase Cloud Messaging (FCM) configurations.
 * 2. To handle foreground and background push notification events.
 * 3. To request user permissions and generate unique FCM tokens for targeting.
 * * How to use?
 * 1. Initialize in main.dart: await NotificationService().initialize();
 * 2. Handle background logic: Use the static background handler provided below.
 */

import 'package:$projectName/core/utils/constants/imports.dart';

class NotificationService {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission for notifications (iOS/Android 13+)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Generate and log FCM Token for backend targeting
      String? token = await messaging.getToken();
      AppLoggerHelper.debug("FCM Token: \$token");

      // Set up background notification handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Listen for notifications while the app is in the foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLoggerHelper.debug('Message received in foreground: \${message.data}');
        if (message.notification != null) {
          AppLoggerHelper.debug(
            'Notification Title: \${message.notification!.title}',
          );
          
          // Optional: Show a local notification or snackbar here
          /*
          Get.snackbar(
            message.notification!.title ?? '',
            message.notification!.body ?? '',
            snackPosition: SnackPosition.TOP,
          );
          */
        }
      });
    } else {
      AppLoggerHelper.warning('User declined or has not accepted notification permissions');
    }
  }

  /// Static handler for background/terminated messages
  /// Must be a top-level function or a static method
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    // Ensure Firebase is initialized if you need to use other Firebase services here
    // await Firebase.initializeApp();
    AppLoggerHelper.debug(
      "Handling a background message: \${message.messageId}",
    );
  }
}
''');

  print('\n--- storage service generating... ---');

  // Ensuring the directory exists
  Directory('lib/core/services').createSync(recursive: true);

  File('lib/core/services/storage_service.dart').writeAsStringSync('''
/**
 * --- StorageService ---
 * * Why use this service?
 * 1. To provide a centralized way to handle local data persistence.
 * 2. To wrap SharedPreferences with type-safe getter and setter methods.
 * 3. To maintain a Singleton instance for memory efficiency.
 * * How to use?
 * 1. Initialize in main.dart: await LocalStorageService().init();
 * 2. Access via Singleton: LocalStorageService().saveAccessToken('token_here');
 */

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  // Singleton pattern
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  late SharedPreferences _prefs;

  /// Initialize SharedPreferences (call once in main.dart)
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─────────────────────────────────────────────────────
  // Basic CRUD methods (generic and type-safe)
  // ─────────────────────────────────────────────────────

  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  String? getString(String key) => _prefs.getString(key);

  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  int? getInt(String key) => _prefs.getInt(key);

  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  double? getDouble(String key) => _prefs.getDouble(key);

  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  Future<bool> clearAll() async {
    return await _prefs.clear();
  }

  // ─────────────────────────────────────────────────────
  // Common app-specific helper methods
  // ─────────────────────────────────────────────────────

  // Auth / Token
  Future<void> saveAccessToken(String token) async {
    await setString('access_token', token);
  }

  String? get accessToken => getString('access_token');

  Future<void> clearAuth() async {
    await remove('access_token');
  }

  // Theme / Dark Mode
  Future<void> saveDarkMode(bool isDark) async {
    await setBool('is_dark_mode', isDark);
  }

  bool get isDarkMode => getBool('is_dark_mode') ?? false;

  // Language / Locale
  Future<void> saveLanguageCode(String langCode) async {
    await setString('language_code', langCode);
  }

  String? get languageCode => getString('language_code') ?? 'en';

  // Onboarding / First Launch
  Future<void> setOnboardingCompleted() async {
    await setBool('onboarding_completed', true);
  }

  bool get isOnboardingCompleted => getBool('onboarding_completed') ?? false;
}
''');

  print('\n--- app theme generating... ---');

  // Ensuring the directory exists
  Directory('lib/core/theme').createSync(recursive: true);

  File('lib/core/theme/theme.dart').writeAsStringSync('''
/**
 * --- AppTheme ---
 * * Why use this?
 * 1. To centralize both Light and Dark mode configurations.
 * 2. To maintain a consistent UI across the app using Material 3.
 * 3. To modularize widget-specific themes (AppBar, Buttons, TextFields, etc.).
 * * How to use?
 * 1. In App.dart: 
 * MaterialApp(
 * themeMode: ThemeMode.system,
 * theme: AppTheme.lightTheme,
 * darkTheme: AppTheme.darkTheme,
 * )
 */

import 'package:flutter/material.dart';
import 'custom_theme/app_bar_theme.dart';
import 'custom_theme/elevated_button_theme.dart';
import 'custom_theme/text_field_theme.dart';
import 'custom_theme/text_theme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: Colors.red,
    scaffoldBackgroundColor: Colors.white,
    textTheme: AppTextTheme.lightTextTheme,
    elevatedButtonTheme: AppElevatedButtonTheme.lightElevatedButtonTheme,
    appBarTheme: App_BarTheme.lightAppBarTheme,
    inputDecorationTheme: AppTextFormFieldTheme.lightInputDecorationTheme,
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: Colors.red,
    scaffoldBackgroundColor: Colors.black,
    textTheme: AppTextTheme.darkTextTheme,
    elevatedButtonTheme: AppElevatedButtonTheme.darkElevatedButtonTheme,
    appBarTheme: App_BarTheme.darkAppBarTheme,
    inputDecorationTheme: AppTextFormFieldTheme.darkInputDecorationTheme,
  );
}
''');

  print('\n--- custom text theme generating... ---');

  // Ensuring the directory exists (lib/core/theme/custom_theme)
  // Note: I used 'custom_theme' to match your previous theme.dart imports
  Directory('lib/core/theme/custom_theme').createSync(recursive: true);

  File('lib/core/theme/custom_theme/text_theme.dart').writeAsStringSync('''
/**
 * --- AppTextTheme ---
 * * Why use this?
 * 1. To maintain a standardized typography system across the app.
 * 2. To easily switch between Light and Dark mode text colors.
 * 3. Following Material Design 3 typography scales (Display, Headline, Title, Body, Label).
 */

import 'package:flutter/material.dart';

class AppTextTheme {
  AppTextTheme._();

  static const TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold, color: Colors.black),
    displayMedium: TextStyle(fontSize: 45.0, fontWeight: FontWeight.w600, color: Colors.black87),
    displaySmall: TextStyle(fontSize: 36.0, fontWeight: FontWeight.w500, color: Colors.black87),
    headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.black),
    headlineMedium: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w600, color: Colors.black87),
    headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w500, color: Colors.black87),
    titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w600, color: Colors.black87),
    titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500, color: Colors.black87),
    titleSmall: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: Colors.black87),
    bodyLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal, color: Colors.black87),
    bodyMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal, color: Colors.black87),
    bodySmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal, color: Colors.black54),
    labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black),
    labelMedium: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500, color: Colors.black54),
    labelSmall: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w500, color: Colors.black45),
  );

  static const TextTheme darkTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold, color: Colors.white),
    displayMedium: TextStyle(fontSize: 45.0, fontWeight: FontWeight.w600, color: Colors.white70),
    displaySmall: TextStyle(fontSize: 36.0, fontWeight: FontWeight.w500, color: Colors.white70),
    headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.white),
    headlineMedium: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w600, color: Colors.white70),
    headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w500, color: Colors.white70),
    titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w600, color: Colors.white70),
    titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500, color: Colors.white70),
    titleSmall: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: Colors.white70),
    bodyLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal, color: Colors.white70),
    bodyMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal, color: Colors.white60),
    bodySmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal, color: Colors.white54),
    labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
    labelMedium: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500, color: Colors.white60),
    labelSmall: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w500, color: Colors.white54),
  );
}
''');

  print('\n--- custom elevated button theme generating... ---');

  // Ensuring the directory exists (lib/core/theme/custom_theme)
  Directory('lib/core/theme/custom_theme').createSync(recursive: true);

  File(
    'lib/core/theme/custom_theme/elevated_button_theme.dart',
  ).writeAsStringSync('''
/**
 * --- AppElevatedButtonTheme ---
 * * Why use this?
 * 1. To provide a consistent look for all ElevatedButtons across the app.
 * 2. To handle different button states (Enabled, Disabled) automatically.
 * 3. To reduce boilerplate code in UI screens by defining global styles.
 */

import 'package:flutter/material.dart';
import '../../common/styles/global_text_style.dart';

class AppElevatedButtonTheme {
  AppElevatedButtonTheme._();

  static final ElevatedButtonThemeData lightElevatedButtonTheme =
      ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(0),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.grey; // Disabled text color
            }
            return Colors.white; // Default text color
          }),
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.grey.shade300; // Disabled background color
            }
            return Colors.blue; // Default background color
          }),
          side: WidgetStateProperty.all(const BorderSide(color: Colors.blue)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 18),
          ),
          textStyle: WidgetStateProperty.all(
            getTextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  static final ElevatedButtonThemeData darkElevatedButtonTheme = ElevatedButtonThemeData(
    style: ButtonStyle(
      elevation: WidgetStateProperty.all(0),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.grey.shade600; // Disabled text color in dark mode
        }
        return Colors.white; // Default text color
      }),
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.grey.shade800; // Disabled background color in dark mode
        }
        return Colors.blueGrey; // Default dark background color
      }),
      side: WidgetStateProperty.all(const BorderSide(color: Colors.blueGrey)),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(vertical: 18),
      ),
      textStyle: WidgetStateProperty.all(
        getTextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
''');

  print('\n--- custom text field theme generating... ---');

  // Ensuring the directory exists (lib/core/theme/custom_theme)
  Directory('lib/core/theme/custom_theme').createSync(recursive: true);

  File('lib/core/theme/custom_theme/text_field_theme.dart').writeAsStringSync(
    '''
/**
 * --- AppTextFormFieldTheme ---
 * * Why use this?
 * 1. To standardize the look of all TextFields/TextFormFields in the app.
 * 2. To handle different states (Focused, Error, Enabled) globally.
 * 3. To automatically adapt to Light and Dark modes.
 */

import 'package:flutter/material.dart';
import '../../common/styles/global_text_style.dart';

class AppTextFormFieldTheme {
  AppTextFormFieldTheme._();

  static final InputDecorationTheme lightInputDecorationTheme =
      InputDecorationTheme(
        errorMaxLines: 3,
        prefixIconColor: Colors.grey,
        suffixIconColor: Colors.grey,
        labelStyle: getTextStyle(fontSize: 14, color: Colors.black),
        hintStyle: getTextStyle(fontSize: 14, color: Colors.black),
        errorStyle: getTextStyle(fontSize: 12, color: Colors.red),
        floatingLabelStyle: getTextStyle(color: Colors.black),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Colors.grey),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(
            color: Colors.black,
          ), 
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Colors.orange),
        ),
      );

  static final InputDecorationTheme darkInputDecorationTheme =
      InputDecorationTheme(
        errorMaxLines: 3,
        prefixIconColor: Colors.grey,
        suffixIconColor: Colors.grey,
        labelStyle: getTextStyle(fontSize: 14, color: Colors.white),
        hintStyle: getTextStyle(fontSize: 14, color: Colors.white70),
        errorStyle: getTextStyle(fontSize: 12, color: Colors.redAccent),
        floatingLabelStyle: getTextStyle(color: Colors.white70),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Colors.grey),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(
            color: Colors.white,
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Colors.orangeAccent),
        ),
      );
}
''',
  );

  print('\n--- custom text theme generating... ---');

  // Ensuring the directory exists (lib/core/theme/custom_theme)
  Directory('lib/core/theme/custom_theme').createSync(recursive: true);

  File('lib/core/theme/custom_theme/text_theme.dart').writeAsStringSync('''
/**
 * --- AppTextTheme ---
 * * Why use this?
 * 1. To maintain a standardized typography system throughout the app.
 * 2. To ensure easy switching between Light and Dark mode text colors.
 * 3. Follows Material Design 3 typography scales for consistency.
 */

import 'package:flutter/material.dart';

class AppTextTheme {
  AppTextTheme._();

  static const TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold, color: Colors.black),
    displayMedium: TextStyle(fontSize: 45.0, fontWeight: FontWeight.w600, color: Colors.black87),
    displaySmall: TextStyle(fontSize: 36.0, fontWeight: FontWeight.w500, color: Colors.black87),
    headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.black),
    headlineMedium: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w600, color: Colors.black87),
    headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w500, color: Colors.black87),
    titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w600, color: Colors.black87),
    titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500, color: Colors.black87),
    titleSmall: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: Colors.black87),
    bodyLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal, color: Colors.black87),
    bodyMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal, color: Colors.black87),
    bodySmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal, color: Colors.black54),
    labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black),
    labelMedium: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500, color: Colors.black54),
    labelSmall: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w500, color: Colors.black45),
  );

  static const TextTheme darkTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold, color: Colors.white),
    displayMedium: TextStyle(fontSize: 45.0, fontWeight: FontWeight.w600, color: Colors.white70),
    displaySmall: TextStyle(fontSize: 36.0, fontWeight: FontWeight.w500, color: Colors.white70),
    headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.white),
    headlineMedium: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w600, color: Colors.white70),
    headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w500, color: Colors.white70),
    titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w600, color: Colors.white70),
    titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500, color: Colors.white70),
    titleSmall: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: Colors.white70),
    bodyLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal, color: Colors.white70),
    bodyMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal, color: Colors.white60),
    bodySmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal, color: Colors.white54),
    labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
    labelMedium: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500, color: Colors.white60),
    labelSmall: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w500, color: Colors.white54),
  );
}
''');

  print('\n--- animation path constants generating... ---');

  // Ensuring the directory exists
  Directory('lib/core/utils/constants').createSync(recursive: true);

  File('lib/core/utils/constants/animation_path.dart').writeAsStringSync('''
/**
 * --- AnimationPath ---
 * * Why use this?
 * 1. To centralize all animation asset paths (Lottie, Rive, etc.).
 * 2. To avoid hardcoding strings throughout the UI.
 * 3. To make asset refactoring easier.
 */

class AnimationPath {
  AnimationPath._();

  // Animations should be placed in assets/animations/
  static const String logoAnimation1 = 'assets/animations/logo_animation.json';
  static const String loadingAnimation = 'assets/animations/loading.json';
  static const String successAnimation = 'assets/animations/success.json';
  static const String errorAnimation = 'assets/animations/error.json';
}
''');

  print('\n--- api constants generating... ---');

  // Ensuring the directory exists
  Directory('lib/core/utils/constants').createSync(recursive: true);

  File('lib/core/utils/constants/api_constants.dart').writeAsStringSync('''
/**
 * --- ApiConstants ---
 * * Why use this?
 * 1. To centralize all Base URLs and API Endpoints.
 * 2. To avoid hardcoding URLs in Repository or Service layers.
 * 3. To easily switch between Development, Staging, and Production environments.
 */

import 'package:$projectName/core/utils/constants/imports.dart';

class ApiConstants {
  ApiConstants._();

  // --- Base URLs ---
  static const String baseUrl = "https://api.example.com/v1"; // Replace with your actual domain
  static const String stagingUrl = "https://staging-api.example.com/v1";
  
  // Example for DioHelper or HttpMethod
  static String get apiUrl => baseUrl;

  // --- Endpoints ---
  
  // Auth Endpoints
  static const String login = "/auth/login";
  static const String register = "/auth/register";
  static const String logout = "/auth/logout";
  static const String refreshToken = "/auth/refresh-token";

  // --- Static Headers (If needed) ---
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
''');

  print('\n--- app text constants generating... ---');

  // Ensuring the directory exists
  Directory('lib/core/utils/constants').createSync(recursive: true);

  File('lib/core/utils/constants/app_text.dart').writeAsStringSync('''
/**
 * --- AppText ---
 * * Why use this?
 * 1. To centralize all hardcoded strings used in the app.
 * 2. To avoid "Magic Strings" and reduce typos across the UI.
 * 3. To make future localization (Multi-language) implementation easier.
 */

class AppText {
  AppText._();

}
''');

  print('\n--- app colors constants generating... ---');

  // Ensuring the directory exists
  Directory('lib/core/utils/constants').createSync(recursive: true);

  File('lib/core/utils/constants/colors.dart').writeAsStringSync('''
/**
 * --- AppColors ---
 * * Why use this?
 * 1. To maintain a consistent color scheme throughout the application.
 * 2. To easily update brand colors from a single location.
 * 3. To provide a clean way to access HEX or Flutter Material colors in the UI.
 * * How to use?
 * 1. Use it in widgets: Container(color: AppColors.primary);
 * 2. Use it in Themes: primaryColor: AppColors.primary;
 */

import 'imports.dart';

class AppColors {
  AppColors._();

  // Primary Branding Colors
  static const Color primary = Color(0xFF006837); // Example: Green
  static const Color white = Color(0xFFFFFFFF); // Example: White
  static const Color red = Color(0xFFFF0000); // Example: Red
  
}
''');

  print('\n--- enums constants generating... ---');

  // Ensuring the directory exists
  Directory('lib/core/utils/constants').createSync(recursive: true);

  File('lib/core/utils/constants/enums.dart').writeAsStringSync('''
/**
 * --- Enums ---
 * * Why use this?
 * 1. To define a fixed set of named constants.
 * 2. To avoid hardcoding strings for logic (e.g., Request types, Order status).
 * 3. To improve code readability and prevent logic errors.
 */

/// LIST OF Enums
/// They cannot be created inside a class.
library;

// HTTP Request Methods for Network Layer
enum RequestMethod { get, post, put, patch, delete }

''');

  print('\n--- icon path constants generating... ---');

  // Ensuring the directory exists
  Directory('lib/core/utils/constants').createSync(recursive: true);

  File('lib/core/utils/constants/icon_path.dart').writeAsStringSync('''
/**
 * --- IconPath ---
 * * Why use this?
 * 1. To centralize all icon asset paths (SVG, PNG, etc.).
 * 2. To prevent "Magic Strings" and typos when using icons in the UI.
 * 3. To make it easier to swap icons globally by updating a single path.
 */

class IconPath {
  IconPath._();

  // Icons should be placed in assets/icons/
  static const String _basePath = 'assets/icons';

}
''');

  print('\n--- image path constants generating... ---');

  // Ensuring the directory exists
  Directory('lib/core/utils/constants').createSync(recursive: true);

  File('lib/core/utils/constants/image_path.dart').writeAsStringSync('''
/**
 * --- ImagePath ---
 * * Why use this?
 * 1. To centralize all image asset paths (PNG, JPG, WEBP, etc.).
 * 2. To avoid hardcoding strings and prevent typos in the UI.
 * 3. To make asset refactoring or path changes easier globally.
 */

class ImagePath {
  ImagePath._();

  // Base paths for organization
  static const String _basePath = 'assets/images';

}
''');

  print('\n--- custom bottom sheet widget generating... ---');

  // Ensuring the directory exists
  Directory('lib/core/common/widgets').createSync(recursive: true);

  File('lib/core/common/widgets/custom_bottom_sheet.dart').writeAsStringSync('''
/**
 * --- CustomBottomSheet ---
 * * Why use this?
 * 1. To provide a consistent and branded bottom sheet design across the app.
 * 2. To easily inject any list of widgets as content.
 * 3. Handles basic UI elements like a close button and logo automatically.
 * * How to use?
 * await showCustomBottomSheet(
 * contentWidgets: [Text("Hello World"), CustomButton(...)],
 * backgroundColor: AppColors.primary,
 * );
 */

import 'package:$projectName/core/utils/constants/imports.dart';

Future<dynamic> showCustomBottomSheet({
  required List<Widget> contentWidgets,
  bool isDismissible = true,
  Color? backgroundColor,
  double topPadding = 20,
  double bottomPadding = 10,
}) async {
  return Get.bottomSheet(
    Container(
      margin: const EdgeInsets.all(12),
      width: double.infinity,
      child: Card(
        elevation: 8,
        color: backgroundColor ?? AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            // --- 1. Header Background ---
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: backgroundColor ?? AppColors.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),

            // --- 2. Close Button ---
            Positioned(
              right: 8,
              top: 8,
              child: SizedBox(
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.close, color: AppColors.white, size: 24),
                ),
              ),
            ),

            // --- 3. Main Content ---
            Padding(
              padding: EdgeInsets.only(
                top: 20,
                bottom: bottomPadding,
                left: 15,
                right: 15,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo / Animation Placeholder
                  Center(
                    child: Lottie.asset(
                      AnimationPath.logoAnimation1,
                      width: 120,
                      height: 70,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(height: 70),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Dynamic Content Widgets
                  ...contentWidgets,

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true,
    barrierColor: Colors.black54,
    isDismissible: isDismissible,
    enableDrag: true,
  );
}
''');

  print('\n--- music path constants generating... ---');

  // Ensuring the directory exists
  Directory('lib/core/utils/constants').createSync(recursive: true);

  File('lib/core/utils/constants/music_path.dart').writeAsStringSync('''
/**
 * --- MusicPath ---
 * * Why use this?
 * 1. To centralize all audio asset paths (MP3, WAV, etc.).
 * 2. To avoid hardcoding strings and prevent typos in the audio player logic.
 * 3. To make asset refactoring or path changes easier globally.
 */

class MusicPath {
  MusicPath._();

  // Music assets should be placed in assets/music/
  static const String _basePath = 'assets/music';
}
''');

  print('\n--- video path constants generating... ---');

  // Ensuring the directory exists
  Directory('lib/core/utils/constants').createSync(recursive: true);

  File('lib/core/utils/constants/video_path.dart').writeAsStringSync('''
/**
 * --- VideoPath ---
 * * How to use?
 * 1. Register in pubspec.yaml: assets/videos/
 * 2. In code: VideoPlayerController.asset(VideoPath.splashVideo);
 */

class VideoPath {
  VideoPath._();

  // Base path for videos
  static const String _basePath = 'assets/videos';
}
''');

  print('\n--- device utility generating... ---');

  // Ensuring the directory exists
  Directory('lib/core/utils/device').createSync(recursive: true);

  File('lib/core/utils/device/device_utility.dart').writeAsStringSync('''
/**
 * --- AppDeviceUtility ---
 * * Why use this?
 * 1. To centralize all device-specific logic (Screen size, Keyboard, Orientation).
 * 2. To avoid repeating MediaQuery or SystemChrome calls throughout the UI.
 * 3. To provide helper methods for platform-specific checks (iOS/Android).
 * * How to use?
 * 1. Get screen height: double height = AppDeviceUtility.getScreenHeight();
 * 2. Hide keyboard: AppDeviceUtility.hideKeyboard(context);
 * 3. Check platform: if (AppDeviceUtility.isAndroid()) { ... }
 */

import 'dart:io';
import 'package:location/location.dart';
import '../constants/imports.dart';

class AppDeviceUtility {
  AppDeviceUtility._();

  static final Location _location = Location();

  /// Ensures location services are enabled
  static Future<bool> ensureLocationReady() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
    }
    return serviceEnabled;
  }

  /// Hides the software keyboard
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  /// Sets the status bar color dynamically
  static Future<void> setStatusBarColor(Color color) async {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: color),
    );
  }

  static bool isLandscapeOrientation(BuildContext context) {
    final viewInsets = View.of(context).viewInsets;
    return viewInsets.bottom == 0;
  }

  static bool isPortraitOrientation(BuildContext context) {
    final viewInsets = View.of(context).viewInsets;
    return viewInsets.bottom != 0;
  }

  /// Toggles full screen mode
  static void setFullScreen(bool enable) {
    SystemChrome.setEnabledSystemUIMode(
      enable ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  static double getScreenHeight() {
    return MediaQuery.of(Get.context!).size.height;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getPixelRatio() {
    return MediaQuery.of(Get.context!).devicePixelRatio;
  }

  static double getStatusBarHeight() {
    return MediaQuery.of(Get.context!).padding.top;
  }

  static double getBottomNavigationBarHeight() {
    return kBottomNavigationBarHeight;
  }

  static double getAppBarHeight() {
    return kToolbarHeight;
  }

  static double getKeyboardHeight() {
    final viewInsets = MediaQuery.of(Get.context!).viewInsets;
    return viewInsets.bottom;
  }

  static Future<bool> isKeyboardVisible() async {
    final viewInsets = View.of(Get.context!).viewInsets;
    return viewInsets.bottom > 0;
  }

  static Future<bool> isPhysicalDevice() async {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Simple haptic feedback vibration
  static void vibrate(Duration duration) {
    HapticFeedback.vibrate();
    Future.delayed(duration, () => HapticFeedback.vibrate());
  }

  static Future<void> setPreferredOrientations(
    List<DeviceOrientation> orientations,
  ) async {
    await SystemChrome.setPreferredOrientations(orientations);
  }

  static void hideStatusBar() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  static void showStatusBar() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  /// Checks internet connectivity by looking up a reliable domain
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static bool isIOS() => Platform.isIOS;

  static bool isAndroid() => Platform.isAndroid;

  /// Launches external URLs in the browser or respective apps
  static void launchUrl(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      AppLoggerHelper.error('Could not launch \$url');
    }
  }
}
''');

  print('\n--- app formatters utility generating... ---');

  // Ensuring the directory exists
  Directory('lib/core/utils/formatters').createSync(recursive: true);

  File('lib/core/utils/formatters/app_formatters.dart').writeAsStringSync('''
/**
 * --- AppForMatters ---
 * * Why use this?
 * 1. To centralize all data formatting logic (Date, Currency, Phone).
 * 2. To ensure a consistent data representation across the entire UI.
 * 3. To wrap the 'intl' package for easier and reusable formatting.
 * * How to use?
 * 1. Format date: String date = AppForMatters.formatDate(DateTime.now());
 * 2. Format money: String price = AppForMatters.formatCurrency(250.0);
 * 3. Format phone: String phone = AppForMatters.formatPhoneNumber("01712345678");
 */

import 'package:intl/intl.dart';

class AppForMatters {
  AppForMatters._();

  /// Formats a DateTime object into a specific string format.
  static String getFormattedDate(
    DateTime date, {
    String format = 'dd MMM yyyy',
  }) {
    return DateFormat(format).format(date);
  }

  /// Default date formatter (dd-MMM-yyyy)
  static String formatDate(DateTime? date) {
    date ??= DateTime.now();
    return DateFormat('dd-MMM-yyyy').format(date);
  }

  /// Formats double amounts into currency strings (Default: USD \$)
  static String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: '\\\$',
    ).format(amount);
  }

  /// Formats raw phone strings into readable formats
  static String formatPhoneNumber(String phoneNumber) {
    // Assuming a 10-digit format: (123) 456-7890
    if (phoneNumber.length == 10) {
      return '(\${phoneNumber.substring(0, 3)}) \${phoneNumber.substring(3, 6)}-\${phoneNumber.substring(6)}';
    } 
    // Assuming an 11-digit format (e.g., Bangladesh or US with country code)
    else if (phoneNumber.length == 11) {
      return '(\${phoneNumber.substring(0, 4)}) \${phoneNumber.substring(4, 7)}-\${phoneNumber.substring(7)}';
    }
    
    return phoneNumber;
  }
}
''');

  print('\n--- app helper utility generating... ---');

  // Ensuring the directory exists
  Directory('lib/core/utils/helpers').createSync(recursive: true);

  File('lib/core/utils/helpers/app_helper.dart').writeAsStringSync('''
/**
 * --- AppHelperFunctions ---
 * * Why use this?
 * 1. To centralize common UI tasks like showing SnackBar or Dialogs.
 * 2. To provide quick access to screen dimensions and theme status.
 * 3. To handle data manipulation (like removing duplicates or truncating text) globally.
 * * How to use?
 * 1. Show SnackBar: AppHelperFunctions.showSnackBar("Success!");
 * 2. Check Dark Mode: bool isDark = AppHelperFunctions.isDarkMode(context);
 * 3. Screen Height: double h = AppHelperFunctions.screenHeight();
 */

import '../constants/imports.dart';

class AppHelperFunctions {
  AppHelperFunctions._();

  /// Shows a simple SnackBar using the current context
  static void showSnackBar(String message) {
    ScaffoldMessenger.of(
      Get.context!,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Shows a standard Alert Dialog
  static void showAlert(String title, String message) {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Simple navigation helper using Flutter Navigator
  static void navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  /// Truncates long text and adds ellipsis (...)
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    } else {
      return '\${text.substring(0, maxLength)}...';
    }
  }

  /// Checks if the current theme is Dark Mode
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Size screenSize() {
    return MediaQuery.of(Get.context!).size;
  }

  static double screenHeight() {
    return MediaQuery.of(Get.context!).size.height;
  }

  static double screenWidth() {
    return MediaQuery.of(Get.context!).size.width;
  }

  /// Generic helper to remove duplicates from any List
  static List<T> removeDuplicates<T>(List<T> list) {
    return list.toSet().toList();
  }

  /// Wraps a list of widgets into rows based on specified row size
  static List<Widget> wrapWidgets(List<Widget> widgets, int rowSize) {
    final wrappedList = <Widget>[];
    for (var i = 0; i < widgets.length; i += rowSize) {
      final rowChildren = widgets.sublist(
        i,
        i + rowSize > widgets.length ? widgets.length : i + rowSize,
      );
      wrappedList.add(Row(children: rowChildren));
    }
    return wrappedList;
  }
}
''');

  print('\n--- app logger helper utility generating... ---');

  // Ensuring the directory exists
  Directory('lib/core/utils/logging').createSync(recursive: true);

  File('lib/core/utils/logging/logger.dart').writeAsStringSync('''
/**
 * --- AppLoggerHelper ---
 * * Why use this?
 * 1. To provide structured and readable logs in the console.
 * 2. To easily differentiate between Debug, Info, Warning, and Error messages.
 * 3. To include StackTrace automatically during error logging for faster debugging.
 * * How to use?
 * 1. Debug: AppLoggerHelper.debug("Fetching data...");
 * 2. Error: AppLoggerHelper.error("API Failed", errorResponse);
 * 3. Info: AppLoggerHelper.info("User logged in");
 */

import '../constants/imports.dart';
import 'package:logger/logger.dart';

class AppLoggerHelper {
  AppLoggerHelper._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // Number of method calls to be displayed
      errorMethodCount: 8, // Number of method calls if stacktrace is provided
      lineLength: 120, // Width of the output
      colors: true, // Colorful log messages
      printEmojis: true, // Print an emoji for each log message
      printTime: false, // Should each log print contain a timestamp
    ),
    level: Level.debug, 
  );

  /// Log a debug message (Green)
  static void debug(String message) {
    _logger.d(message);
  }

  /// Log an info message (Blue)
  static void info(String message) {
    _logger.i(message);
  }

  /// Log a warning message (Yellow)
  static void warning(String message) {
    _logger.w(message);
  }

  /// Log an error message (Red) with StackTrace
  static void error(String message, [dynamic error]) {
    _logger.e(
      message, 
      error: error, 
      stackTrace: StackTrace.current
    );
  }
}
''');

  print('\n--- app validator utility generating... ---');

  // Ensuring the directory exists
  Directory('lib/core/utils/validators').createSync(recursive: true);

  File('lib/core/utils/validators/app_validator.dart').writeAsStringSync('''
/**
 * --- AppValidator ---
 * * Why use this?
 * 1. To centralize all form validation logic (Email, Password, Phone).
 * 2. To ensure consistent security and data integrity across all forms.
 * 3. To provide user-friendly error messages for invalid inputs.
 * * How to use?
 * 1. In TextFormField: validator: (value) => AppValidator.validateEmail(value),
 */

class AppValidator {
  AppValidator._();

  /// Validates an email address using Regex
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required.';
    }

    // Regular expression for email validation
    final emailRegExp = RegExp(r'^[\\w\\-.]+@([\\w-]+\\.)+[\\w-]{2,4}\$');

    if (!emailRegExp.hasMatch(value)) {
      return 'Invalid email address.';
    }

    return null;
  }

  /// Validates password strength (Length, Uppercase, Number, Special Character)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }

    // Check for minimum password length
    if (value.length < 6) {
      return 'Password must be at least 6 characters long.';
    }

    // Check for uppercase letters
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter.';
    }

    // Check for numbers
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number.';
    }

    // Check for special characters
    if (!value.contains(RegExp(r'[!@#\\\$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character.';
    }
    
    return null;
  }

  /// Validates phone number (Default: 10 or 11 digits)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required.';
    }

    // Regular expression for phone number validation (Modified for 10-11 digits)
    final phoneRegExp = RegExp(r'^\\d{10,11}\$');

    if (!phoneRegExp.hasMatch(value)) {
      return 'Invalid phone number format (10-11 digits required).';
    }

    return null;
  }
  
  /// General empty field validator
  static String? validateEmptyText(String? fieldName, String? value) {
    if (value == null || value.isEmpty) {
      return '\$fieldName is required.';
    }
    return null;
  }
}
''');

  print('\n--- custom warning dialog widget generating... ---');

  // Ensuring the directory exists
  Directory('lib/core/common/widgets').createSync(recursive: true);

  File(
    'lib/core/common/widgets/custom_warning_dialog_layout.dart',
  ).writeAsStringSync('''
/**
 * --- CustomWarningDialog ---
 * * Why use this?
 * 1. To show important alerts or warnings (like No Internet).
 * 2. To maintain a branded look for all dialogs.
 * 3. Supports optional "OK" button and custom callback logic.
 */

import 'package:$projectName/core/utils/constants/imports.dart';


class CustomWarningDialog extends StatelessWidget {
  final String message;
  final bool showOkButton;
  final bool barrierDismissible;
  final VoidCallback? onOkPressed;

  const CustomWarningDialog({
    super.key,
    required this.message,
    this.showOkButton = true,
    this.barrierDismissible = false,
    this.onOkPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        width: double.infinity,
        child: Card(
          elevation: 8,
          color: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 29),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Image.asset(
                        'Assets.animations.logoAnimation.path',
                        width: 120,
                        height: 70,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      message,
                      style: getTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 14),

                    if (showOkButton)
                      if (showOkButton)
                        SizedBox(
                          width: 140,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors.red, // or your preferred color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              onOkPressed?.call();
                            },
                            child: Text(
                              'OK',
                              style: getTextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
''');

  print('\n--- app bar theme generating... ---');

  // Ensuring the directory exists
  Directory('lib/core/theme/custom_theme').createSync(recursive: true);

  File('lib/core/theme/custom_theme/app_bar_theme.dart').writeAsStringSync('''
// ignore_for_file: camel_case_types

/**
 * --- App_BarTheme ---
 * * Why use this?
 * 1. To maintain a consistent look for AppBars across both Light and Dark modes.
 * 2. To handle Status Bar (SystemUiOverlayStyle) icons and background globally.
 * 3. To remove redundant AppBar configuration code from every UI screen.
 */

import 'package:$projectName/core/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../common/styles/global_text_style.dart';

class App_BarTheme {
  App_BarTheme._();

  static final AppBarTheme lightAppBarTheme = AppBarTheme(
    foregroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    backgroundColor: Colors.white,
    iconTheme: const IconThemeData(color: Colors.black), // Updated to black for visibility on white BG

    titleTextStyle: getTextStyle(
      color: Colors.black,
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    ),
    actionsIconTheme: const IconThemeData(color: Colors.black),
    centerTitle: true,
    systemOverlayStyle: SystemUiOverlayStyle.dark, // Black icons for light background
  );

  static final AppBarTheme darkAppBarTheme = AppBarTheme(
    foregroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    backgroundColor: const Color(0xFF212121), // Consistent dark background
    iconTheme: const IconThemeData(color: Colors.white),
    titleTextStyle: getTextStyle(
      color: Colors.white,
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    ),
    actionsIconTheme: const IconThemeData(color: Colors.white),
    centerTitle: true,
    systemOverlayStyle: SystemUiOverlayStyle.light, // White icons for dark background
  );
}
''');

  print('\n--- central imports file generating... ---');

  // Ensuring the directory exists
  Directory('lib/core/utils/constants').createSync(recursive: true);

  File('lib/core/utils/constants/imports.dart').writeAsStringSync('''
/**
 * --- Centralized Imports ---
 * * Why use this?
 * 1. To manage all external packages and internal custom files in one place.
 * 2. To avoid long and messy import lists at the top of every UI file.
 * 3. To make it easier to refactor or update package/file references.
 * * How to use?
 * Just add: import 'package:$projectName/core/utils/constants/imports.dart';
 */

// --- External Packages ---
export 'package:flutter/material.dart';
export 'package:flutter/foundation.dart';
export 'package:flutter/services.dart';
export 'package:get/get.dart';
export 'package:get/route_manager.dart';
export 'package:get/get_navigation/src/root/internacionalization.dart';
export 'package:lottie/lottie.dart';
export 'package:get_storage/get_storage.dart';
export 'package:connectivity_plus/connectivity_plus.dart';
export 'package:pretty_dio_logger/pretty_dio_logger.dart';
export 'package:flutter_dotenv/flutter_dotenv.dart';
export 'package:firebase_core/firebase_core.dart';
export 'package:firebase_messaging/firebase_messaging.dart';
export 'package:firebase_analytics/firebase_analytics.dart';
export 'package:firebase_crashlytics/firebase_crashlytics.dart';
export 'package:geolocator/geolocator.dart';
export 'package:flutter_screenutil/flutter_screenutil.dart';
export 'package:video_player/video_player.dart';
export 'package:google_fonts/google_fonts.dart';
export 'package:url_launcher/url_launcher_string.dart';
export 'package:logger/logger.dart';
export 'package:carousel_slider/carousel_slider.dart';
export 'package:shimmer/shimmer.dart';
export 'package:zo_animated_border/zo_animated_border.dart';
export 'package:cached_network_image/cached_network_image.dart';
export 'package:intl_phone_field/intl_phone_field.dart';
export 'package:flutter_localizations/flutter_localizations.dart';
export 'package:shared_preferences/shared_preferences.dart';


// --- Core App Files ---
export 'package:$projectName/app.dart';
export 'package:$projectName/router/app_routes.dart';
export 'package:$projectName/core/bindings/global_binder.dart';

// --- Core Services ---
export 'package:$projectName/core/network/dio_helper.dart';
export 'package:$projectName/core/network/http_method.dart';
export 'package:$projectName/core/services/media_service.dart';
export 'package:$projectName/core/services/notification_service.dart';
export 'package:$projectName/core/services/analytics_service.dart';
export 'package:$projectName/core/services/crashlytics_service.dart';
export 'package:$projectName/core/services/network_service.dart';
export 'package:$projectName/core/services/location_service.dart';
export 'package:$projectName/core/services/storage_service.dart';
export 'package:$projectName/core/localization/localization_service.dart';
export 'package:$projectName/core/localization/localization_extension.dart';

// --- Core Utilities & Constants ---
export 'package:$projectName/core/utils/logging/logger.dart';
export 'package:$projectName/core/utils/helpers/app_helper.dart';
export 'package:$projectName/core/utils/device/device_utility.dart';
export 'package:$projectName/core/utils/formatters/app_formatters.dart';
export 'package:$projectName/core/utils/constants/colors.dart';
export 'package:$projectName/core/utils/constants/video_path.dart';
export 'package:$projectName/core/utils/constants/api_constants.dart';
export 'package:$projectName/core/utils/constants/image_path.dart';
export 'package:$projectName/core/utils/constants/icon_path.dart';
export 'package:$projectName/core/utils/constants/animation_path.dart';
export 'package:$projectName/core/theme/theme.dart';
export 'package:$projectName/core/common/widgets/custom_warning_dialog_layout.dart';

// --- Generated Files ---
export 'package:$projectName/generated/l10n/app_localizations.dart';


// --- Common Widgets & Styles ---
export 'package:$projectName/core/common/styles/global_text_style.dart';



// --- Splash Modules ---
export 'package:$projectName/features/splash/bindings/splash_binding.dart';
export 'package:$projectName/features/splash/views/splash_view.dart';
export 'package:$projectName/features/splash/controllers/splash_controller.dart';
export 'package:$projectName/features/splash/repositories/splash_repository.dart';


''');

  print('\n' + '=' * 60);
  print('🏁  PROJECT ARCHITECTURE IS READY!');
  print('=' * 60);
  print('\n⚠️  IMPORTANT: YOU MUST RUN THESE COMMANDS MANUALLY NOW:');
  print('------------------------------------------------------------');
  print(' cd $projectName');
  print(' importing roboto font');
  print(' rps gen');
  print(' flutter run');
  print('------------------------------------------------------------');
  print('=' * 60 + '\n');
}
