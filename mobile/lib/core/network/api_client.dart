import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../error/app_exception.dart';
import '../utils/secure_storage.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await AppStorage.instance.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final msg = error.response?.data?['error'] ?? error.message ?? 'Bir hata oluştu';
        handler.reject(DioException(
          requestOptions: error.requestOptions,
          error: AppException(msg.toString(), statusCode: error.response?.statusCode),
        ));
      },
    ));
  }

  Dio get dio => _dio;
}
