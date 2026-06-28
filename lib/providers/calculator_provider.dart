import 'package:flutter/material.dart';

class CalculatorProvider with ChangeNotifier {
  String _display = '';
  String _result = '';
  final List<String> _history = [];

  String get display => _display;
  String get result => _result;
  List<String> get history => _history;

  void append(String value) {
    if (value == '.' && _display.endsWith('.')) return;
    
    // Prevent double operators
    if (_isOperator(value) && _display.isNotEmpty && _isOperator(_display[_display.length - 1])) {
      _display = _display.substring(0, _display.length - 1) + value;
    } else {
      _display += value;
    }
    
    _autoEvaluate();
    notifyListeners();
  }

  void clear() {
    _display = '';
    _result = '';
    notifyListeners();
  }

  void delete() {
    if (_display.isNotEmpty) {
      _display = _display.substring(0, _display.length - 1);
      _autoEvaluate();
      notifyListeners();
    }
  }

  bool _isOperator(String char) {
    return char == '+' || char == '-' || char == '×' || char == '÷' || char == '%';
  }

  void _autoEvaluate() {
    if (_display.isEmpty) {
      _result = '';
      return;
    }
    
    // Don't evaluate if ends with operator
    if (_isOperator(_display[_display.length - 1])) {
      return;
    }

    try {
      final parsed = _evaluateExpression(_display);
      _result = _formatResult(parsed);
    } catch (e) {
      _result = '';
    }
  }

  void evaluate() {
    if (_display.isEmpty) return;
    
    _autoEvaluate();
    if (_result.isNotEmpty) {
      _history.insert(0, '$_display = $_result');
      _display = _result;
      _result = '';
      notifyListeners();
    }
  }

  String _formatResult(double val) {
    if (val.isInfinite || val.isNaN) return 'Error';
    if (val == val.toInt().toDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  double _evaluateExpression(String expr) {
    // Standardize division and multiplication symbols
    String cleanExpr = expr.replaceAll('×', '*').replaceAll('÷', '/');
    
    // Simple custom parser for math expressions supporting +, -, *, /, %
    List<double> numbers = [];
    List<String> operators = [];

    int i = 0;
    while (i < cleanExpr.length) {
      if (cleanExpr[i] == '-' && (i == 0 || _isOperator(cleanExpr[i - 1]))) {
        // Negative number handling
        int start = i;
        i++;
        while (i < cleanExpr.length && (RegExp(r'[0-9.]').hasMatch(cleanExpr[i]))) {
          i++;
        }
        numbers.add(double.parse(cleanExpr.substring(start, i)));
      } else if (RegExp(r'[0-9.]').hasMatch(cleanExpr[i])) {
        int start = i;
        while (i < cleanExpr.length && (RegExp(r'[0-9.]').hasMatch(cleanExpr[i]))) {
          i++;
        }
        numbers.add(double.parse(cleanExpr.substring(start, i)));
      } else if (cleanExpr[i] == '*' || cleanExpr[i] == '/' || cleanExpr[i] == '+' || cleanExpr[i] == '-' || cleanExpr[i] == '%') {
        operators.add(cleanExpr[i]);
        i++;
      } else {
        i++;
      }
    }

    if (numbers.isEmpty) return 0.0;

    // First pass: handle multiplication, division and percentage (high precedence)
    int opIdx = 0;
    while (opIdx < operators.length) {
      String op = operators[opIdx];
      if (op == '*' || op == '/' || op == '%') {
        double num1 = numbers[opIdx];
        double num2 = numbers[opIdx + 1];
        double calc = 0;
        if (op == '*') calc = num1 * num2;
        if (op == '/') calc = num1 / num2;
        if (op == '%') calc = num1 % num2;

        numbers[opIdx] = calc;
        numbers.removeAt(opIdx + 1);
        operators.removeAt(opIdx);
      } else {
        opIdx++;
      }
    }

    // Second pass: handle addition and subtraction (low precedence)
    double resultVal = numbers[0];
    for (int j = 0; j < operators.length; j++) {
      String op = operators[j];
      double nextVal = numbers[j + 1];
      if (op == '+') resultVal += nextVal;
      if (op == '-') resultVal -= nextVal;
    }

    return resultVal;
  }
}
