import 'package:graphql/client.dart';

extension CustomGraphqlErrorExtension on GraphQLError {
  String get errorFullMessage {
    var errorMsg = '';
    if (extensions?['code'] != null) {
      errorMsg = "Code : ${extensions!['code']}";
    }
    if (extensions?['schemaName'] != null) {
      errorMsg = "$errorMsg , Schema : ${extensions!['schemaName']},";
    }
    if (path?.first != null) {
      errorMsg = '$errorMsg  Path : ${path?.first} ,';
    }
    return '$errorMsg , Message : $message';
  }
}
