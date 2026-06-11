import '../dao/account_dao.dart';
import '../models/app_user.dart';
import '../models/household.dart';

class AccountRepository {
  final AccountDao _dao = AccountDao();

  Future<int> insertUser(AppUser user) => _dao.insertUser(user);
  Future<AppUser?> getUserById(int id) => _dao.getUserById(id);
  Future<AppUser?> getUserByEmail(String email) => _dao.getUserByEmail(email);
  Future<int> updateUser(AppUser user) => _dao.updateUser(user);
  Future<void> setSession(int userId) => _dao.setSession(userId);
  Future<AppUser?> getSessionUser() => _dao.getSessionUser();
  Future<void> clearSession() => _dao.clearSession();
  Future<int> insertHousehold(Household household) =>
      _dao.insertHousehold(household);
  Future<Household?> getHouseholdById(int id) => _dao.getHouseholdById(id);
  Future<Household?> getHouseholdByCode(String code) =>
      _dao.getHouseholdByCode(code);
}
