import 'package:graphql/client.dart';

import '../../../mobile_api.dart';

extension ResponseError on Response {
  bool get shouldRefresh {
    final data =
        errors != null &&
        errors!
            .where((e) {
              final code = e.extensions!['code'];
              return code != null &&
                      code == ExceptionEnum.unauthenticated.value ||
                  code == ExceptionEnum.unauthorized.value;
            })
            .toList()
            .isNotEmpty;

    return data;
  }
}
