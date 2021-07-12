import 'package:cloud_firestore/cloud_firestore.dart';
import 'Destination.dart';
import 'User.dart';

class Request {
  String _id;
  String _status;
  User _passageiro;
  User _motorista;
  Destination _destino;

  Request() {
    Firestore db = Firestore.instance;

    DocumentReference ref = db.collection("requests").document();
    this.id = ref.documentID;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> dadosPassageiro = {
      "nome": this.passageiro.nome,
      "email": this.passageiro.email,
      "tipoUser": this.passageiro.tipoUser,
      "idUser": this.passageiro.idUser,
      "latitude": this.passageiro.latitude,
      "longitude": this.passageiro.longitude,
    };

    Map<String, dynamic> dadosDestination = {
      "rua": this.destino.rua,
      "numero": this.destino.numero,
      "bairro": this.destino.bairro,
      "cep": this.destino.cep,
      "latitude": this.destino.latitude,
      "longitude": this.destino.longitude,
    };

    Map<String, dynamic> dadosRequest = {
      "id": this.id,
      "status": this.status,
      "passageiro": dadosPassageiro,
      "motorista": null,
      "destino": dadosDestination,
    };

    return dadosRequest;
  }

  Destination get destino => _destino;

  set destino(Destination value) {
    _destino = value;
  }

  User get motorista => _motorista;

  set motorista(User value) {
    _motorista = value;
  }

  User get passageiro => _passageiro;

  set passageiro(User value) {
    _passageiro = value;
  }

  String get status => _status;

  set status(String value) {
    _status = value;
  }

  String get id => _id;

  set id(String value) {
    _id = value;
  }
}
