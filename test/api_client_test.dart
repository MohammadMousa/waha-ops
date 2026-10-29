import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:waha_ops/services/api_client.dart';

void main() {
  sessionTests();
  test('logout posts to the pos logout endpoint with the bearer token', () async {
    late http.Request seen;
    final api = ApiClient(httpClient: MockClient((req) async {
      seen = req;
      return http.Response('', 200);
    }));
    await api.logout('tok');
    expect(seen.method, 'POST');
    expect(seen.url.path, '/api/pos/auth/logout');
    expect(seen.headers['Authorization'], 'Bearer tok');
  });

  test('login sends session properties', () async {
    late Map<String, dynamic> body;
    final api = ApiClient(httpClient: MockClient((req) async {
      body = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response('{"token":"t","employeeId":1,"organizationId":1,"permissions":[],"stores":[]}', 200);
    }));
    await api.login('u', '1234');
    expect((body['sessionProperties'] as Map).containsKey('os'), isTrue);
    expect(body.containsKey('appVersion'), isTrue);
  });

  test('a 401 on an authenticated call reports the session as ended', () async {
    var ended = 0;
    final api = ApiClient(httpClient: MockClient((_) async => http.Response('{"message":"x"}', 401)))
      ..onSessionEnded = () => ended++;
    await expectLater(api.me('tok'), throwsA(isA<Exception>()));
    expect(ended, 1);
  });
}

void sessionTests() {
  test('mySessions parses items, info and current', () async {
    final api = ApiClient(httpClient: MockClient((req) async {
      expect(req.url.path, '/api/auth/me/sessions');
      return http.Response(
          '{"items":[{"ref":"a","current":true,"info":{"os":"Android","osVersion":"13","model":"Samsung X"},"appVersion":"1.0.0","createdAt":"2026-10-29T10:00:00Z","lastSeenAt":null},{"ref":"b","current":false,"info":null}]}',
          200);
    }));
    final list = await api.mySessions('tok');
    expect(list.length, 2);
    expect(list[0].current, isTrue);
    expect(list[0].model, 'Samsung X');
    expect(list[1].model, isNull);
  });

  test('signOutOthers and signOutSession hit the right endpoints', () async {
    final seen = <String>[];
    final api = ApiClient(httpClient: MockClient((req) async {
      seen.add('${req.method} ${req.url.path}');
      return http.Response(req.method == 'POST' ? '{"signedOut":2}' : '{"disconnected":1}', 200);
    }));
    expect(await api.signOutOthers('tok'), 2);
    await api.signOutSession('tok', 'abc');
    expect(seen, ['POST /api/auth/me/sessions/sign-out-others', 'DELETE /api/auth/me/sessions/abc']);
  });
}
