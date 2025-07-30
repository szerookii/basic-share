class HealthMeasurement {
  final DateTime date;
  final String id;
  final double? fat;
  final double? muscle;
  final double? bone;
  final double? water;
  final double? weight;
  final double? calories;
  final double? height;

  HealthMeasurement({
    required this.date,
    required this.id,
    this.fat,
    this.muscle,
    this.bone,
    this.water,
    this.weight,
    this.calories,
    this.height,
  });

  factory HealthMeasurement.fromJson(Map<String, dynamic> json) {
    double? parseNum(dynamic v) => v == null ? null : (v as num).toDouble();
    return HealthMeasurement(
      date: DateTime.parse(json['date'] as String),
      id: json['id'] as String,
      fat: parseNum(json['fat']),
      muscle: parseNum(json['muscle']),
      bone: parseNum(json['bone']),
      water: parseNum(json['water']),
      weight: parseNum(json['weight']),
      calories: parseNum(json['calories']),
      height: parseNum(json['height']),
    );
  }
}

class Member {
  final String name;
  final List<String> addOns;
  final String cardnumber;
  final String dateofbirth;
  final String country;
  final String gender;
  final String membershipnumber;
  final String membershipType;
  final String email;
  final String mobilephone;
  final String firstname;
  final String prefix;
  final String lastname;
  final String id;
  final String homeClubId;
  final String homeClub;
  final String homeClubLcid;
  final String deviceId;
  final String accessMethod;
  final String marketingId;
  final String externalId;
  final String latestMembershipStartDate;
  final String latestMembershipEndDate;
  final bool hasDebt;
  final MembershipOptions membershipOptions;

  Member({
    required this.name,
    required this.addOns,
    required this.cardnumber,
    required this.dateofbirth,
    required this.country,
    required this.gender,
    required this.membershipnumber,
    required this.membershipType,
    required this.email,
    required this.mobilephone,
    required this.firstname,
    required this.prefix,
    required this.lastname,
    required this.id,
    required this.homeClubId,
    required this.homeClub,
    required this.homeClubLcid,
    required this.deviceId,
    required this.accessMethod,
    required this.marketingId,
    required this.externalId,
    required this.latestMembershipStartDate,
    required this.latestMembershipEndDate,
    required this.hasDebt,
    required this.membershipOptions,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      name: json['name'] as String,
      addOns: List<String>.from(json['addOns'] as List<dynamic>),
      cardnumber: json['cardnumber'] as String,
      dateofbirth: json['dateofbirth'] as String,
      country: json['country'] as String,
      gender: json['gender'] as String,
      membershipnumber: json['membershipnumber'] as String,
      membershipType: json['membershipType'] as String,
      email: json['email'] as String,
      mobilephone: json['mobilephone'] as String,
      firstname: json['firstname'] as String,
      prefix: json['prefix'] as String,
      lastname: json['lastname'] as String,
      id: json['id'] as String,
      homeClubId: json['homeClubId'] as String,
      homeClub: json['homeClub'] as String,
      homeClubLcid: json['homeClubLcid'] as String,
      deviceId: json['deviceId'] as String,
      accessMethod: json['accessMethod'] as String,
      marketingId: json['marketingId'] as String,
      externalId: json['externalId'] as String,
      latestMembershipStartDate: json['latestMembershipStartDate'] as String,
      latestMembershipEndDate: json['latestMembershipEndDate'] as String,
      hasDebt: json['hasDebt'] as bool,
      membershipOptions: json['membershipOptions'] != null
          ? MembershipOptions.fromJson(json['membershipOptions'])
          : MembershipOptions(linkedServices: []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'addOns': addOns,
      'cardnumber': cardnumber,
      'dateofbirth': dateofbirth,
      'country': country,
      'gender': gender,
      'membershipnumber': membershipnumber,
      'membershipType': membershipType,
      'email': email,
      'mobilephone': mobilephone,
      'firstname': firstname,
      'prefix': prefix,
      'lastname': lastname,
      'id': id,
      'homeClubId': homeClubId,
      'homeClub': homeClub,
      'homeClubLcid': homeClubLcid,
      'deviceId': deviceId,
      'accessMethod': accessMethod,
      'marketingId': marketingId,
      'externalId': externalId,
      'latestMembershipStartDate': latestMembershipStartDate,
      'latestMembershipEndDate': latestMembershipEndDate,
      'hasDebt': hasDebt,
      'membershipOptions': membershipOptions.toJson(),
    };
  }
}

class MembershipOptions {
  final List<String> linkedServices;

  MembershipOptions({required this.linkedServices});

  factory MembershipOptions.fromJson(Map<String, dynamic> json) {
    return MembershipOptions(
      linkedServices:
          List<String>.from(json['LinkedServices'] as List<dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'LinkedServices': linkedServices,
    };
  }
}

class Visit {
  final String swipeDateTime;
  final String clubName;
  final String clubId;

  Visit(
      {required this.swipeDateTime,
      required this.clubName,
      required this.clubId});

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      swipeDateTime: json['swipeDateTime'],
      clubName: json['clubName'],
      clubId: json['clubId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'swipeDateTime': swipeDateTime,
      'clubName': clubName,
      'clubId': clubId,
    };
  }
}

class TokenExpiredException implements Exception {
  final String message;

  TokenExpiredException(this.message);

  @override
  String toString() => 'TokenExpiredException: $message';
}
