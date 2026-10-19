import 'package:flutter_test/flutter_test.dart';
import 'package:taskmaster/movie_availability.dart';

void main() {
  test('movie and city are required', () {
    expect(
      () => MovieAvailabilityRequest(movie: '', city: 'Vizag'),
      throwsArgumentError,
    );
  });

  test('request describes the chosen movie and city', () {
    final request = MovieAvailabilityRequest(
      movie: '  Sample Movie  ',
      city: '  Visakhapatnam ',
    );
    expect(
      request.description,
      'Check BookMyShow tickets for Sample Movie in Visakhapatnam',
    );
  });
}
