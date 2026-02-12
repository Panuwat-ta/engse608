class Province {
  final String name;
  final double latitude;
  final double longitude;

  Province({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

final List<Province> provinces = [
  Province(name: 'Bangkok', latitude: 13.7563, longitude: 100.5018),
  Province(name: 'Chiang Mai', latitude: 18.7883, longitude: 98.9853),
  Province(name: 'Phuket', latitude: 7.8804, longitude: 98.3923),
  Province(name: 'Khon Kaen', latitude: 16.4322, longitude: 102.8236),
  Province(name: 'Nakhon Ratchasima', latitude: 14.9751, longitude: 102.0932),
  Province(name: 'Songkhla', latitude: 7.1996, longitude: 100.5951),
  Province(name: 'Chon Buri', latitude: 13.3611, longitude: 100.9847),
];
