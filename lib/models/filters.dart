class Filters {
  final String pickup;
  final String destination;
  final int? seats;
  final String timeSlot; // 'all' | 'morning' | 'afternoon' | 'evening' | 'night'

  Filters({
    this.pickup = '',
    this.destination = '',
    this.seats,
    this.timeSlot = 'all',
  });

  Filters copyWith({
    String? pickup,
    String? destination,
    int? seats,
    String? timeSlot,
  }) {
    return Filters(
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      seats: seats ?? this.seats,
      timeSlot: timeSlot ?? this.timeSlot,
    );
  }
}
