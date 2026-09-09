import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/category.dart';
import '../models/employee_session.dart';
import '../models/product_lite.dart';
import '../models/visit_operation.dart';
import 'api_exceptions.dart';

// Visit metadata returned by POST /api/inventory/visits.
class VisitStart {
  final int id;
  final int storeId;
  final String storeName;
  const VisitStart({required this.id, required this.storeId, required this.storeName});
}

class ApiClient {
  final http.Client _http;
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  String _extractMessage(http.Response resp) {
    try {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      return (body['message'] ?? body['error']) as String? ??
          'Request failed (${resp.statusCode})';
    } catch (_) {
      return 'Request failed (${resp.statusCode})';
    }
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request();
    } catch (e) {
      throw NetworkException(e);
    }
  }

  T _okOrThrow<T>(http.Response resp, T Function(dynamic body) onOk) {
    if (resp.statusCode == 200) return onOk(resp.body.isEmpty ? null : jsonDecode(resp.body));
    final msg = _extractMessage(resp);
    if (resp.statusCode == 401 || resp.statusCode == 403) {
      throw UnauthorizedException(resp.statusCode, msg);
    }
    throw UnknownApiException(resp.statusCode, msg);
  }

  // ---- Config ----------------------------------------------------------

  // GET /api/config?orgId= — no auth, callable before login. orgId is
  // required to get org-specific properties (like appName) merged in —
  // omitting it only returns global (org=0) ones. Per
  // to_Frontend_AI_On_Inventory_Task [11]: `appName` is already a parsed
  // {ar, en} object, not a raw JSON string.
  Future<Map<String, dynamic>?> getAppName({int orgId = AppConfig.defaultOrganizationId}) async {
    final resp = await _send(
      () => _http.get(_uri('/api/config').replace(queryParameters: {'orgId': '$orgId'})),
    );
    return _okOrThrow(
        resp, (body) => (body as Map<String, dynamic>)['appName'] as Map<String, dynamic>?);
  }

  // ---- Auth ----------------------------------------------------------

  // POST /api/pos/auth/login  { username, pinCode }
  Future<EmployeeSession> login(String username, String pinCode) async {
    final resp = await _send(
      () => _http.post(
        _uri('/api/pos/auth/login'),
        headers: _headers(),
        body: jsonEncode({'username': username, 'pinCode': pinCode}),
      ),
    );
    return _okOrThrow(resp, (body) => EmployeeSession.fromJson(body as Map<String, dynamic>));
  }

  // ---- Products (existing endpoint, reused as-is) ---------------------

  // GET /api/products/search?q=&storeId=&page=&size=
  Future<List<ProductLite>> searchProducts({
    required String token,
    required int storeId,
    required String q,
    int page = 0,
    int size = 30,
  }) async {
    final resp = await _send(
      () => _http.get(
        _uri('/api/products/search').replace(queryParameters: {
          'q': q,
          'storeId': '$storeId',
          'page': '$page',
          'size': '$size',
        }),
        headers: _headers(token: token),
      ),
    );
    return _okOrThrow(resp, _parseProductList);
  }

  // GET /api/products?storeId=&page=&size= — default browsable listing
  // (no query text required, unlike /search which 400s on an empty q).
  Future<List<ProductLite>> getProducts({
    required String token,
    required int storeId,
    int page = 0,
    int size = 50,
  }) async {
    final resp = await _send(
      () => _http.get(
        _uri('/api/products').replace(queryParameters: {
          'storeId': '$storeId',
          'page': '$page',
          'size': '$size',
        }),
        headers: _headers(token: token),
      ),
    );
    return _okOrThrow(resp, _parseProductList);
  }

  // GET /api/categories?storeId= — per to_Frontend_AI_On_Inventory_Task [10].
  Future<List<Category>> getCategories({required String token, required int storeId}) async {
    final resp = await _send(
      () => _http.get(
        _uri('/api/categories').replace(queryParameters: {'storeId': '$storeId'}),
        headers: _headers(token: token),
      ),
    );
    return _okOrThrow(resp, (body) {
      final list = body as List<dynamic>;
      return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  List<ProductLite> _parseProductList(dynamic body) {
    final map = body as Map<String, dynamic>;
    // Real key is "products" (confirmed against the live response) — not
    // "items"/"content" as originally assumed, which is why search/browse
    // silently returned nothing.
    final list = (map['products'] as List<dynamic>?) ?? const [];
    return list.map((e) => ProductLite.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /api/products/barcode/{barcode}?storeId= — camera/hardware scan lookup.
  Future<ProductLite> getProductByBarcode(String barcode, {required String token, required int storeId}) async {
    final resp = await _send(
      () => _http.get(
        _uri('/api/products/barcode/${Uri.encodeComponent(barcode)}')
            .replace(queryParameters: {'storeId': '$storeId'}),
        headers: _headers(token: token),
      ),
    );
    if (resp.statusCode == 200) {
      return ProductLite.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
    }
    final msg = _extractMessage(resp);
    if (resp.statusCode == 404) throw ProductNotFoundException(404, msg);
    if (resp.statusCode == 409) throw ProductNotSellableException(409, msg);
    throw UnknownApiException(resp.statusCode, msg);
  }

  // GET /api/inventory/stock/{storeId} — current on-hand quantity per product.
  Future<Map<int, int>> getStock({required String token, required int storeId}) async {
    final resp = await _send(
      () => _http.get(_uri('/api/inventory/stock/$storeId'), headers: _headers(token: token)),
    );
    return _okOrThrow(resp, (body) {
      final list = body as List<dynamic>;
      return {
        for (final e in list)
          ((e as Map<String, dynamic>)['productId'] as num).toInt(): (e['quantity'] as num).toInt(),
      };
    });
  }

  // ---- Inventory visits -----------------------------------------------
  // Contract per ~/git/to_Frontend_AI_On_Inventory_Task.

  // POST /api/inventory/visits  { storeId } — the employee's chosen working
  // store for this visit (picked locally on the frontend; there is no
  // backend store-selection call anymore, see to_Frontend_AI_On_Inventory_Task [8]).
  Future<VisitStart> startVisit(String token, int storeId) async {
    final resp = await _send(
      () => _http.post(
        _uri('/api/inventory/visits'),
        headers: _headers(token: token),
        body: jsonEncode({'storeId': storeId}),
      ),
    );
    return _okOrThrow(resp, (body) {
      final map = body as Map<String, dynamic>;
      return VisitStart(
        id: (map['id'] as num).toInt(),
        storeId: (map['storeId'] as num).toInt(),
        storeName: map['storeName'] as String? ?? '',
      );
    });
  }

  // POST /api/inventory/visits/{visitId}/operations
  Future<int> addOperation({
    required String token,
    required int visitId,
    required VisitOperation operation,
  }) async {
    final resp = await _send(
      () => _http.post(
        _uri('/api/inventory/visits/$visitId/operations'),
        headers: _headers(token: token),
        body: jsonEncode(operation.toRequestJson()),
      ),
    );
    return _okOrThrow(resp, (body) => ((body as Map<String, dynamic>)['id'] as num).toInt());
  }

  // DELETE /api/inventory/visits/{visitId}/operations/{operationId}
  Future<void> deleteOperation({
    required String token,
    required int visitId,
    required int operationId,
  }) async {
    final resp = await _send(
      () => _http.delete(
        _uri('/api/inventory/visits/$visitId/operations/$operationId'),
        headers: _headers(token: token),
      ),
    );
    _okOrThrow(resp, (_) => null);
  }

  // POST /api/inventory/visits/{visitId}/complete
  Future<void> completeVisit({required String token, required int visitId}) async {
    final resp = await _send(
      () => _http.post(
        _uri('/api/inventory/visits/$visitId/complete'),
        headers: _headers(token: token),
      ),
    );
    _okOrThrow(resp, (_) => null);
  }
}
