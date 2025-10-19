// Shared book resources used across the app. Keep these four stable resources
// and reference them from multiple lists so the app shows the same working
// books in different order across pages.
final List<Map<String, String>> bookResources = [
  {
    'title': 'Introduction to Data Science',
    'author': 'John Doe',
    // local asset (included in repo)
    'image': 'lib/assets/data_science.png',
  },
  {
    'title': 'Advanced Calculus',
    'author': 'Jane Smith',
    'image': 'https://picsum.photos/id/1025/400/600',
  },
  {
    'title': 'Introduction to Quantum Computing',
    'author': 'Robert Johnson',
    'image': 'https://picsum.photos/id/109/400/600',
  },
  {
    'title': 'Foundations of Data Science',
    'author': 'Alice Brown',
    'image': 'https://picsum.photos/id/107/400/600',
  },
];
