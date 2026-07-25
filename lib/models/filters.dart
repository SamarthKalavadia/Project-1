class Filters {
  final String pickup;
  final String destination;
  final int? seats;
  final String timeSlot; // 'all' | 'morning' | 'afternoon' | 'evening' | 'night'
  final String genderPreference; // 'all' | 'Boys only' | 'Girls only'

  Filters({
    this.pickup = '',
    this.destination = '',
    this.seats,
    this.timeSlot = 'all',
    this.genderPreference = 'all',
  });

  Filters copyWith({
    String? pickup,
    String? destination,
    int? seats,
    String? timeSlot,
    String? genderPreference,
  }) {
    return Filters(
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      seats: seats ?? this.seats,
      timeSlot: timeSlot ?? this.timeSlot,
      genderPreference: genderPreference ?? this.genderPreference,
    );
  }
}
