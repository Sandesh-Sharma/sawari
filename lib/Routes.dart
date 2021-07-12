import 'package:flutter/material.dart';
import 'package:uber/screens/Drive.dart';
import 'package:uber/screens/Register.dart';
import 'package:uber/screens/Home.dart';
import 'package:uber/screens/DriverPanel.dart';
import 'package:uber/screens/PassengerPanel.dart';

class Rotas {
  static Route<dynamic> gerarRotas(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case "/":
        return MaterialPageRoute(builder: (_) => Home());
      case "/cadastro":
        return MaterialPageRoute(builder: (_) => Cadastro());
      case "/painel-motorista":
        return MaterialPageRoute(builder: (_) => PainelDriver());
      case "/painel-passageiro":
        return MaterialPageRoute(builder: (_) => PainelPassenger());
      case "/corrida":
        return MaterialPageRoute(builder: (_) => Corrida(args));
      default:
        _erroRota();
    }
  }

  static Route<dynamic> _erroRota() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Tela não encontrada!"),
        ),
        body: Center(
          child: Center(
            child: Text(
              "Tela não encontrada!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    });
  }
}
