import '../data/repository/category_repository.dart';
import '../data/models/chore_category.dart';

/// Service class that provides access to chore categories.
/// Acts as an intermediary between the UI layer and the data layer
/// for category-related operations.
class CategoryService {
  final CategoryRepository _categoryRepo = CategoryRepository();

  /// Retrieves all chore categories from the database.
  Future<List<ChoreCategory>> getAll() async {
    return await _categoryRepo.getAll();
  }

  /// Retrieves a single category by its ID.
  Future<ChoreCategory?> getById(int id) async {
    return await _categoryRepo.getById(id);
  }

  /// Inserts a new category into the database.
  Future<int> insert(ChoreCategory category) async {
    return await _categoryRepo.insert(category);
  }

  /// Deletes a category by its ID.
  Future<int> delete(int id) async {
    return await _categoryRepo.delete(id);
  }
}
