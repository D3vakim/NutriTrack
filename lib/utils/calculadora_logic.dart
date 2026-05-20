import 'package:flutter/material.dart';
// Import necessário do Flutter
// Função principal para cálculo do IMC — nome claro e objetivo
Melhoria: adicionar validação para evitar altura ou peso <= 0 (evita erro ou resultado infinito)
//Fórmula correta do cálculo de IMC
  
String calcularImc(double weight, double height) {
  double imc = weight / (height * height);

  if (imc < 18.5) {
    return "Abaixo do Peso (${imc.toStringAsPrecision(4)})";
  } else if (imc >= 18.5 && imc < 25.0) {
    return "Peso Ideal (${imc.toStringAsPrecision(4)})";
  } else if (imc >= 25.0 && imc < 30.0) {
    return "Levemente Acima do Peso (${imc.toStringAsPrecision(4)})";
  } else if (imc >= 30.0 && imc < 35.0) {
    return "Obesidade Grau I (${imc.toStringAsPrecision(4)})";
  } else if (imc >= 35.0 && imc < 40.0) {
    return "Obesidade Grau II (${imc.toStringAsPrecision(4)})";
  } else {
    return "Obesidade Grau III (${imc.toStringAsPrecision(4)})";
  }
}

Color getImcColor(double imc) {
  if (imc < 18.5) {
    return const Color(0xFF1565C0); // azul escuro
  } else if (imc < 25.0) {
    return const Color(0xFF2E7D32); // verde escuro
  } else if (imc < 30.0) {
    return const Color(0xFFF57F17); // amarelo escuro
  } else if (imc < 35.0) {
    return const Color(0xFFE65100); // laranja escuro
  } else {
    return const Color(0xFFB71C1C); // vermelho escuro
  }
}

Color getImcBackgroundColor(double imc) {
  if (imc < 18.5) {
    return const Color(0xFFE3F2FD);
  } else if (imc < 25.0) {
    return const Color(0xFFE8F5E9);
  } else if (imc < 30.0) {
    return const Color(0xFFFFFDE7);
  } else if (imc < 40.0) {
    return const Color(0xFFFFF3E0);
  } else {
    return const Color(0xFFFFEBEE);
  }
}

IconData getImcIcon(double imc) {
  if (imc < 18.5) {
    return Icons.trending_down;
  } else if (imc < 25.0) {
    return Icons.check_circle_outline;
  } else if (imc < 30.0) {
    return Icons.trending_up;
  } else if (imc < 40.0) {
    return Icons.warning_amber_outlined;
  } else {
    return Icons.dangerous_outlined;
  }
}
