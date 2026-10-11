/// Client-side form checks for usability only; the API validates again (BR-071).
class Validators {
  Validators._();

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phone = RegExp(r'^[0-9+\-\s]{8,20}$');
  static final _password = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,100}$');

  static String? required(String? value, [String field = 'This field']) =>
      value == null || value.trim().isEmpty ? '$field is required' : null;

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    return _email.hasMatch(value.trim()) ? null : 'Enter a valid email';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return _password.hasMatch(value) ? null : 'At least 8 characters with a letter and a digit';
  }

  static String? phone(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) return required ? 'Phone number is required' : null;
    return _phone.hasMatch(value.trim()) ? null : 'Enter a valid phone number';
  }

  static String? money(String? value, {bool allowZero = true}) {
    final number = num.tryParse((value ?? '').replaceAll('.', '').replaceAll(',', ''));
    if (number == null) return 'Enter a number';
    if (number < 0 || (!allowZero && number == 0)) return 'Must be greater than 0';
    return null;
  }

  static String? positiveInt(String? value) {
    final number = int.tryParse(value ?? '');
    return number == null || number <= 0 ? 'Enter a whole number greater than 0' : null;
  }
}

/// Parses "1.250.000" / "1250000" into a number.
num? parseMoney(String value) => num.tryParse(value.replaceAll('.', '').replaceAll(',', '').trim());
