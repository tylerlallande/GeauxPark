enum ParkingPermit {
  commuter,
  westCampusResident,
  eastCampusResident,
  nicholsonGatewayResident,
  greekResident,
  unionSquareGarage,
  lawSchool,
  universityHigh,
  motorcycle,
  parkAndGeaux,
  employeeA,
  employeeB,
  employeeC,
  employeeD,
  officialBusiness,
  employeeGarageC,
  visitor,
  event,
}

extension ParkingPermitPresentation on ParkingPermit {
  String get id => switch (this) {
    ParkingPermit.commuter => 'commuter',
    ParkingPermit.westCampusResident => 'west-campus-resident',
    ParkingPermit.eastCampusResident => 'east-campus-resident',
    ParkingPermit.nicholsonGatewayResident => 'nicholson-gateway-resident',
    ParkingPermit.greekResident => 'greek-resident',
    ParkingPermit.unionSquareGarage => 'union-square-garage',
    ParkingPermit.lawSchool => 'law-school',
    ParkingPermit.universityHigh => 'university-high',
    ParkingPermit.motorcycle => 'motorcycle',
    ParkingPermit.parkAndGeaux => 'park-and-geaux',
    ParkingPermit.employeeA => 'employee-a',
    ParkingPermit.employeeB => 'employee-b',
    ParkingPermit.employeeC => 'employee-c',
    ParkingPermit.employeeD => 'employee-d',
    ParkingPermit.officialBusiness => 'official-business',
    ParkingPermit.employeeGarageC => 'employee-garage-c',
    ParkingPermit.visitor => 'visitor',
    ParkingPermit.event => 'event',
  };

  String get label => switch (this) {
    ParkingPermit.commuter => 'Commuter',
    ParkingPermit.westCampusResident => 'West Campus Resident',
    ParkingPermit.eastCampusResident => 'East Campus Resident',
    ParkingPermit.nicholsonGatewayResident => 'Nicholson Gateway Resident',
    ParkingPermit.greekResident => 'Greek Resident',
    ParkingPermit.unionSquareGarage => 'Union Square Garage',
    ParkingPermit.lawSchool => 'Law School',
    ParkingPermit.universityHigh => 'University High',
    ParkingPermit.motorcycle => 'Motorcycle',
    ParkingPermit.parkAndGeaux => 'Park & Geaux',
    ParkingPermit.employeeA => 'Employee A',
    ParkingPermit.employeeB => 'Employee B',
    ParkingPermit.employeeC => 'Employee C',
    ParkingPermit.employeeD => 'Employee D',
    ParkingPermit.officialBusiness => 'Official Business',
    ParkingPermit.employeeGarageC => 'Employee Garage C',
    ParkingPermit.visitor => 'Visitor',
    ParkingPermit.event => 'Game-day event',
  };

  String get description => switch (this) {
    ParkingPermit.commuter => 'Off-campus student commuter access',
    ParkingPermit.westCampusResident => 'West campus housing access',
    ParkingPermit.eastCampusResident => 'East campus housing access',
    ParkingPermit.nicholsonGatewayResident =>
      'Nicholson Gateway resident access',
    ParkingPermit.greekResident => 'Greek housing resident access',
    ParkingPermit.unionSquareGarage => 'Union Square Garage floors 3–6',
    ParkingPermit.lawSchool => 'LSU Law Center parking access',
    ParkingPermit.universityHigh => 'University Lab School access',
    ParkingPermit.motorcycle => 'Motorcycle and moped parking',
    ParkingPermit.parkAndGeaux => 'Park & Geaux remote lots',
    ParkingPermit.employeeA => 'Commuter, Park & Geaux, and X lots',
    ParkingPermit.employeeB => 'Employee B and lower-access zones',
    ParkingPermit.employeeC => 'Assigned C lot and lower-access zones',
    ParkingPermit.employeeD => 'Designated employee reserved space',
    ParkingPermit.officialBusiness => 'Approved multi-lot business access',
    ParkingPermit.employeeGarageC => 'Union Square Garage employee access',
    ParkingPermit.visitor => 'Visitor and hourly parking access',
    ParkingPermit.event => 'Event-specific or game-day parking',
  };
}

ParkingPermit? parkingPermitFromId(String id) {
  final normalized = id.trim().toLowerCase();
  for (final permit in ParkingPermit.values) {
    if (permit.id == normalized) return permit;
  }
  return null;
}
