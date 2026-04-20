import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config/stripe_config.dart';


class StripeService {

  static const Map<String, String> _testTokens = {
    '2222222222222222': 'tok_visa',
    '4444444444444444': 'tok_visa_debit',
    '33333333333333333': 'tok_mastercard',
    '1111111111111111': 'tok_mastercard_debit',
    '5555555555555555': 'tok_chargedDeclined',
    '0000000000000000': 'tok_chargedDeclinedInsufficientFunds',
  };

  static Future <Map<String, dynamic>> processPayment({
    required double amount,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,
  }) async {
    final amountInCentavos = (amount * 100).round().toString();
    final cleanCard = cardNumber.replaceAll('', '');
    final token = _testTokens[cleanCard];

    if (token == null) {
      return <String, dynamic>{
        'success': false,
        'error': 'unknown test card'
      };
    }
    try {
      final response = await http.post(
        Uri.parse('${StripeConfig.apiUrl}/payment_intents'),
        headers: <String, String>{
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },

        body: <String, String>{
          'amount': amountInCentavos,
          'currency': 'php',
          'payment_method_types[]': 'card',
          'payment_method_data[type]': 'card',
          'payment_method_data[card][token]': token,
          'confirm': 'true',
        },
      );
      final data = jsonDecode(response.body) as Map <String, dynamic>;

      if (response.statusCode == 200 && data['status'] == 'succeeded') {
        return <String, dynamic>{
          'success': true,
          'id': data['id'].toString(),
          'amount': (data['amount'] as num) / 100,
          'status': data['status'].toString(),
        };
      } else {
        final errorMsg = data['error'] is Map
            ? (data['error'] as Map) ['message']?.toString() ?? 'payment failed'
            : 'payment Failed';
        return <String, dynamic>{'success': false, 'error': errorMsg};
      }
    } catch (e) {
      return <String, dynamic>{
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
