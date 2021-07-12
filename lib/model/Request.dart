import 'package:cloud_firestore/cloud_firestore.dart';
import 'Destination.dart';
import 'User.dart';

class Request {
  String _id;
  String _status;
  User _passageiro;
  User _motorista;
  Destination _destination;

  Request() {
    Firestore db = Firestore.instance;

    DocumentReference ref = db.collection("requests").document();
    this.id = ref.documentID;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> dadosPassenger = {
      "name": this.passageiro.name,
      "email": this.passageiro.email,
      "typeUser": this.passageiro.typeUser,
      "idUser": this.passageiro.idUser,
      "latitude": this.passageiro.latitude,
      "longitude": this.passageiro.longitude,
    };

    Map<String, dynamic> dadosDestination = {
      "rua": this.destination.rua,
      "numero": this.destination.numero,
      "bairro": this.destination.bairro,
      "cep": this.destination.cep,
      "latitude": this.destination.latitude,
      "longitude": this.destination.longitude,
    };

    Map<String, dynamic> dadosRequest = {
      "id": this.id,
      "status": this.status,
      "passageiro": dadosPassenger,
      "motorista": null,
      "destination": dadosDestination,
    };

    return dadosRequest;
  }

  Destination get destination => _destination;

  set destination(Destination value) {
    _destination = value;
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
