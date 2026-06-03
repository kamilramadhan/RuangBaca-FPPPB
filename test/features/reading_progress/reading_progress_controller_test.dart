import 'package:flutter_test/flutter_test.dart';
import 'package:ruang_baca/features/reading_progress/reading_progress.dart';

void main() {
  late ReadingProgressController controller;

  setUp(() {
    controller = ReadingProgressController(
      InMemoryReadingProgressRepository(),
    );
  });

  test('create lalu load menampilkan entri baru', () async {
    await controller.createProgress(
      bookTitle: 'Dune',
      currentPage: 10,
      totalPages: 412,
    );

    expect(controller.items, hasLength(1));
    expect(controller.items.first.bookTitle, 'Dune');
    expect(controller.inProgressCount, 1);
  });

  test('currentPage di-clamp tidak melebihi totalPages', () async {
    await controller.createProgress(
      bookTitle: 'Over',
      currentPage: 999,
      totalPages: 100,
    );

    expect(controller.items.first.currentPage, 100);
    expect(controller.items.first.isFinished, isTrue);
  });

  test('updateCurrentPage mengubah halaman', () async {
    await controller.createProgress(
      bookTitle: 'Sapiens',
      currentPage: 0,
      totalPages: 500,
    );
    final entry = controller.items.first;

    await controller.updateCurrentPage(entry, 250);

    expect(controller.items.first.currentPage, 250);
    expect(controller.items.first.percentage, 0.5);
  });

  test('markAsFinished menandai selesai', () async {
    await controller.createProgress(
      bookTitle: 'Done',
      currentPage: 5,
      totalPages: 200,
    );

    await controller.markAsFinished(controller.items.first);

    expect(controller.items.first.isFinished, isTrue);
    expect(controller.finishedCount, 1);
  });

  test('deleteProgress menghapus entri', () async {
    await controller.createProgress(
      bookTitle: 'Hapus',
      currentPage: 1,
      totalPages: 10,
    );
    final id = controller.items.first.id;

    await controller.deleteProgress(id);

    expect(controller.items, isEmpty);
    expect(controller.isEmpty, isTrue);
  });

  test('history terurut dari update terbaru', () async {
    await controller.createProgress(
      bookTitle: 'A',
      currentPage: 0,
      totalPages: 10,
    );
    await controller.createProgress(
      bookTitle: 'B',
      currentPage: 0,
      totalPages: 10,
    );
    // Update A agar updatedAt-nya paling baru.
    await controller.updateCurrentPage(controller.items.last, 5);

    expect(controller.items.first.bookTitle, 'A');
  });
}
