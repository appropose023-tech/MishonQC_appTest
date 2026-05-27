import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

class ApiService {

  static final ApiService _instance =
      ApiService._internal();

  factory ApiService() => _instance;

  late Dio dio;

  ApiService._internal() {

    dio = Dio(

      BaseOptions(

        baseUrl:
            "http://104.154.76.47:5001",

        connectTimeout:
            Duration(seconds: 30),

        receiveTimeout:
            Duration(seconds: 60),

        headers: {

          "Accept":
              "application/json"
        },
      ),
    );

    final cookieJar = CookieJar();

    dio.interceptors.add(

      CookieManager(cookieJar),
    );
  }
}
