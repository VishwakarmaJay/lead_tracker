import 'package:lead_tracker/core/utils/phone_normalizer.dart';
import 'package:lead_tracker/src/settings/providers/settings_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'phone_normalizer_provider.g.dart';

/// Phone normaliser using the default country code from Settings.
@riverpod
PhoneNormalizer phoneNormalizer(Ref ref) {
  final code = ref.watch(settingsProvider).value?.defaultCountryCallingCode;
  return PhoneNormalizer(defaultCountryCode: code ?? '+91');
}
