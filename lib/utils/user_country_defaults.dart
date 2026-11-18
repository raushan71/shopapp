import 'package:itrsp_shop/models/common/all_country_model/country.dart';
import 'package:itrsp_shop/models/eCommerce/authentication/user.dart';

User withDefaultCountry(User user, Country? defaultCountry) {
  final name = defaultCountry?.name?.trim();
  final code = defaultCountry?.phoneCode?.trim();
  if (name == null || name.isEmpty || code == null || code.isEmpty) return user;

  final country = user.country?.trim() ?? '';
  final phoneCode = user.phoneCode?.trim() ?? '';
  final sameCountry = country.toLowerCase() == name.toLowerCase();
  final sameCode =
      phoneCode.replaceFirst(RegExp(r'^\+'), '') ==
      code.replaceFirst(RegExp(r'^\+'), '');
  // Fill missing fields only when both are absent or the existing half matches.
  // This avoids combining an existing foreign dial code with the admin country.
  return user.copyWith(
    country: country.isEmpty && (phoneCode.isEmpty || sameCode) ? name : null,
    phoneCode: phoneCode.isEmpty && (country.isEmpty || sameCountry)
        ? code
        : null,
  );
}
