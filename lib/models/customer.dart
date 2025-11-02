import 'package:json_annotation/json_annotation.dart';
import 'address.dart';

part 'customer.g.dart';

@JsonSerializable()
class Customer {
  @JsonKey(name: 'id')
  final int? id;

  @JsonKey(name: 'id_default_group')
  final int defaultGroupId;

  @JsonKey(name: 'id_lang')
  final int langId;

  @JsonKey(name: 'firstname')
  final String firstName;

  @JsonKey(name: 'lastname')
  final String lastName;

  @JsonKey(name: 'email')
  final String email;

  @JsonKey(name: 'passwd')
  final String? password;

  @JsonKey(name: 'birthday')
  final String? birthday;

  @JsonKey(name: 'newsletter', defaultValue: false)
  final bool newsletter;

  @JsonKey(name: 'optin', defaultValue: false)
  final bool optin;

  @JsonKey(name: 'active', defaultValue: true)
  final bool active;

  @JsonKey(name: 'phone', defaultValue: null)
  final String? phone;

  @JsonKey(name: 'phone_mobile', defaultValue: null)
  final String? mobilePhone;

  @JsonKey(name: 'associations', defaultValue: {})
  final CustomerAssociations associations;

  @JsonKey(name: 'date_add')
  final String? dateAdded;

  @JsonKey(name: 'date_upd')
  final String? dateUpdated;

  const Customer({
    this.id,
    required this.defaultGroupId,
    required this.langId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.password,
    this.birthday,
    this.newsletter = false,
    this.optin = false,
    this.active = true,
    this.phone,
    this.mobilePhone,
    this.associations = const CustomerAssociations(),
    this.dateAdded,
    this.dateUpdated,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => _$CustomerFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerToJson(this);

  // Helper methods
  String get fullName => '$firstName $lastName';

  List<Address> get addresses => associations.addresses ?? [];

  DateTime? get registrationDate {
    if (dateAdded == null) return null;
    try {
      return DateTime.parse(dateAdded!);
    } catch (e) {
      return null;
    }
  }

  // For creating new customers
  Customer copyWith({
    int? id,
    int? defaultGroupId,
    int? langId,
    String? firstName,
    String? lastName,
    String? email,
    String? password,
    String? birthday,
    bool? newsletter,
    bool? optin,
    bool? active,
    String? phone,
    String? mobilePhone,
    CustomerAssociations? associations,
    String? dateAdded,
    String? dateUpdated,
  }) {
    return Customer(
      id: id ?? this.id,
      defaultGroupId: defaultGroupId ?? this.defaultGroupId,
      langId: langId ?? this.langId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      password: password ?? this.password,
      birthday: birthday ?? this.birthday,
      newsletter: newsletter ?? this.newsletter,
      optin: optin ?? this.optin,
      active: active ?? this.active,
      phone: phone ?? this.phone,
      mobilePhone: mobilePhone ?? this.mobilePhone,
      associations: associations ?? this.associations,
      dateAdded: dateAdded ?? this.dateAdded,
      dateUpdated: dateUpdated ?? this.dateUpdated,
    );
  }
}

@JsonSerializable()
class CustomerAssociations {
  @JsonKey(name: 'addresses', defaultValue: [])
  final List<Address>? addresses;

  @JsonKey(name: 'groups', defaultValue: [])
  final List<CustomerGroup>? groups;

  const CustomerAssociations({
    this.addresses,
    this.groups,
  });

  factory CustomerAssociations.fromJson(Map<String, dynamic> json) => _$CustomerAssociationsFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerAssociationsToJson(this);
}

@JsonSerializable()
class CustomerGroup {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'name')
  final String name;

  const CustomerGroup({
    required this.id,
    required this.name,
  });

  factory CustomerGroup.fromJson(Map<String, dynamic> json) => _$CustomerGroupFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerGroupToJson(this);
}

// Auth related models
@JsonSerializable()
class AuthResponse {
  @JsonKey(name: 'customer')
  final Customer customer;

  @JsonKey(name: 'session_token')
  final String? sessionToken;

  @JsonKey(name: 'success')
  final bool success;

  @JsonKey(name: 'message')
  final String? message;

  const AuthResponse({
    required this.customer,
    this.sessionToken,
    required this.success,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class LoginRequest {
  @JsonKey(name: 'email')
  final String email;

  @JsonKey(name: 'password')
  final String password;

  @JsonKey(name: 'remember_me', defaultValue: false)
  final bool rememberMe;

  const LoginRequest({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class RegisterRequest {
  @JsonKey(name: 'firstname')
  final String firstName;

  @JsonKey(name: 'lastname')
  final String lastName;

  @JsonKey(name: 'email')
  final String email;

  @JsonKey(name: 'password')
  final String password;

  @JsonKey(name: 'birthday')
  final String? birthday;

  @JsonKey(name: 'newsletter', defaultValue: false)
  final bool newsletter;

  @JsonKey(name: 'optin', defaultValue: false)
  final bool optin;

  @JsonKey(name: 'phone')
  final String? phone;

  const RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.birthday,
    this.newsletter = false,
    this.optin = false,
    this.phone,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) => _$RegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}