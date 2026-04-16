class HardwareConstants {
  static const Map<String, List<String>> panelBrandData = {
    'Adani': [
      'Elan Shine 144',
      'Elan Shine 132',
      'Eternal Shine',
      'Custom Series',
    ],
    'Waaree': ['Elite', 'Arka', 'Custom Series'],
    'Custom (Other Brand)': ['Custom Model'],
  };

  static const Map<String, List<String>> panelCapacityData = {
    'Elan Shine 144': ['520W', '525W', '530W', '535W', '540W', '545W'],
    'Elan Shine 132': ['605W', '610W', '615W', '620W', '630W', '640W'],
    'Eternal Shine': ['520W', '530W', '540W', '550W'],
    'Elite': ['560W', '580W', '600W', '625W', '645W'],
    'Arka': ['515W', '520W', '530W', '540W', '545W'],
  };

  static const Map<String, List<String>> inverterBrandData = {
    'Polycab': ['PSIS', 'PSIT', 'Custom Model'],
    'Solaryaan': ['Single Phase', 'SYT', 'Custom Model'],
    'Custom (Other Brand)': ['Custom Model'],
  };

  static const Map<String, List<String>> inverterCapacityData = {
    'PSIS': ['1.0kW', '2.0kW', '3.0kW', '4.0kW', '5.0kW', '6.0kW'],
    'PSIT': ['5.0kW', '10.0kW', '20.0kW', '30.0kW', '50.0kW', '100.0kW'],
    'Single Phase': ['2.0kW', '3.0kW', '4.0kW', '5.0kW', '6.0kW'],
    'SYT': ['5.0kW', '10.0kW', '15.0kW', '20.0kW', '30.0kW', '50.0kW', '100.0kW'],
  };
}
