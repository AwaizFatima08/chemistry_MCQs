import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:igcse_chemistry_mcqs/ui/question_view.dart';

void main() {
  testWidgets('table text shrinks only when a word is wider than its column', (
    tester,
  ) async {
    const style = TextStyle(fontSize: 16);
    late double wide, narrow;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            const words = ['Increases', 'Unchanged', 'Fast'];
            wide = fitWordsFontSize(context, words, 500, style: style);
            narrow = fitWordsFontSize(context, words, 70, style: style);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(wide, 16);
    expect(narrow, lessThan(16));
    expect(narrow, greaterThanOrEqualTo(10));
  });
}
