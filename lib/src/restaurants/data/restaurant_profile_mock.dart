/// FAKE DATA for the restaurant profile, standing in for fields the API
/// doesn't send yet. Each real value wins when present; delete the fallback
/// here once the endpoint exists.
///
/// API still needed:
///  - GET /restaurants/{id}: `open_days_label` ("daily" / "Mon – Sat").
abstract final class RestaurantProfileMock {
  static const openDaysLabel = 'daily';
}
