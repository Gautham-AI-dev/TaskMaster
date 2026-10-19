/// A user-requested movie search. Does not invent showtimes or availability.
class MovieAvailabilityRequest {
  final String movie;
  final String city;

  MovieAvailabilityRequest({required String movie, required String city})
      : movie = movie.trim(),
        city = city.trim() {
    if (this.movie.isEmpty || this.city.isEmpty) {
      throw ArgumentError('Movie and city are required');
    }
  }

  String get description => 'Check BookMyShow tickets for $movie in $city';
}
