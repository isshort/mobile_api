final class ShipperRegister {
  const ShipperRegister({
    this.fullName,
    this.tinOrNationalID,
    this.phoneNumber,
    this.email,
    this.companyLicense,
    this.location,
    this.regionServed,
    this.password,
  });
  factory ShipperRegister.fromJson(Map<String, dynamic> json) =>
      ShipperRegister(
        fullName: json['fullName'] as String?,
        tinOrNationalID: json['tinOrNationalID'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        email: json['email'] as String?,
        companyLicense: json['company_licence'] as String?,
        location: json['location'] as String?,
        regionServed: json['regionServed'] as String?,
        password: json['password'] as String?,
      );
  final String? fullName;
  final String? tinOrNationalID;
  final String? phoneNumber;
  final String? email;
  final String? companyLicense;
  final String? location;
  final String? regionServed;
  final String? password;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'fullName': fullName,
    'tinOrNationalID': tinOrNationalID,
    'phoneNumber': phoneNumber,
    'email': email,
    'company_licence': companyLicense,
    'location': location,
    'regionServed': regionServed,
    'password': password,
  };
}
