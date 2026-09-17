import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pettebook/datainsertion.dart';

void main() {

	Future<bool> mockDbCheck(String column, String isbn) async {
		if (column == 'isbn_13' && isbn == '1234567890123') {
			return true;
		}

		return false;
	}

	test('Throws StateError if ISBN length is invalid', () async {
		expect(() => isPresentISBN('12345', fakeDbCheck: mockDbCheck), throwsStateError);
	});

	test('Returns true when ISBN_13 is found in database', () async {
		const testIsbn = '1234567890123';

		final result = await isPresentISBN(testIsbn, fakeDbCheck: mockDbCheck);
		expect(result, isTrue);
	});

	test('Returns false when ISBN_10 is NOT found in database.', () async {
		const testIsbn = '1234567890';
		final result = await isPresentISBN(testIsbn, fakeDbCheck: mockDbCheck);

		expect(result, isFalse);
	});
}
