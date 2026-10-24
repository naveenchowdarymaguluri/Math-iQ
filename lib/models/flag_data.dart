/// One flag entry: country name + ISO 3166-1 alpha-2 code.
/// Flag image URL: https://flagsapi.com/{code}/flat/64.png
class FlagCountry {
  final String name;
  final String code; // ISO 3166-1 alpha-2, e.g. "JP"

  const FlagCountry(this.name, this.code);

  String get imageUrl => 'https://flagsapi.com/$code/flat/64.png';
}

/// Pool of 60 countries for the flag quiz.
const List<FlagCountry> kFlagPool = [
  FlagCountry('Japan', 'JP'),
  FlagCountry('Brazil', 'BR'),
  FlagCountry('Canada', 'CA'),
  FlagCountry('Germany', 'DE'),
  FlagCountry('India', 'IN'),
  FlagCountry('Australia', 'AU'),
  FlagCountry('Mexico', 'MX'),
  FlagCountry('South Africa', 'ZA'),
  FlagCountry('France', 'FR'),
  FlagCountry('Italy', 'IT'),
  FlagCountry('Spain', 'ES'),
  FlagCountry('United Kingdom', 'GB'),
  FlagCountry('United States', 'US'),
  FlagCountry('China', 'CN'),
  FlagCountry('Argentina', 'AR'),
  FlagCountry('Egypt', 'EG'),
  FlagCountry('Nigeria', 'NG'),
  FlagCountry('Kenya', 'KE'),
  FlagCountry('South Korea', 'KR'),
  FlagCountry('Indonesia', 'ID'),
  FlagCountry('Turkey', 'TR'),
  FlagCountry('Netherlands', 'NL'),
  FlagCountry('Switzerland', 'CH'),
  FlagCountry('Sweden', 'SE'),
  FlagCountry('Norway', 'NO'),
  FlagCountry('Denmark', 'DK'),
  FlagCountry('Portugal', 'PT'),
  FlagCountry('Poland', 'PL'),
  FlagCountry('Greece', 'GR'),
  FlagCountry('Ukraine', 'UA'),
  FlagCountry('Thailand', 'TH'),
  FlagCountry('Vietnam', 'VN'),
  FlagCountry('Philippines', 'PH'),
  FlagCountry('Malaysia', 'MY'),
  FlagCountry('Singapore', 'SG'),
  FlagCountry('New Zealand', 'NZ'),
  FlagCountry('Peru', 'PE'),
  FlagCountry('Colombia', 'CO'),
  FlagCountry('Chile', 'CL'),
  FlagCountry('Morocco', 'MA'),
  FlagCountry('Ethiopia', 'ET'),
  FlagCountry('Ghana', 'GH'),
  FlagCountry('Pakistan', 'PK'),
  FlagCountry('Bangladesh', 'BD'),
  FlagCountry('Iran', 'IR'),
  FlagCountry('Israel', 'IL'),
  FlagCountry('Czech Republic', 'CZ'),
  FlagCountry('Hungary', 'HU'),
  FlagCountry('Romania', 'RO'),
  FlagCountry('Austria', 'AT'),
  FlagCountry('Belgium', 'BE'),
  FlagCountry('Finland', 'FI'),
  FlagCountry('Cuba', 'CU'),
  FlagCountry('Jamaica', 'JM'),
  FlagCountry('Nepal', 'NP'),
  FlagCountry('Sri Lanka', 'LK'),
  FlagCountry('Iraq', 'IQ'),
  FlagCountry('Jordan', 'JO'),
  FlagCountry('Saudi Arabia', 'SA'),
  FlagCountry('Russia', 'RU'),
];
