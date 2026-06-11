import '../dao/category_dao.dart';
import '../models/chore_category.dart';

class CategoryRepository {
  final CategoryDao _categoryDao = CategoryDao();

  Future<List<ChoreCategory>> getAll() async {
    return await _categoryDao.getAll();
  }

  Future<ChoreCategory?> getById(int id) async {
    return await _categoryDao.getById(id);
  }

  Future<int> insert(ChoreCategory category) async {
    return await _categoryDao.insert(category);
  }

  Future<int> delete(int id) async {
    return await _categoryDao.delete(id);
  }
}
