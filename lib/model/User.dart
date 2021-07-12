class User {
  String _idUser;
  String _nome;
  String _email;
  String _senha;
  String _tipoUser;

  double _latitude;
  double _longitude;

  User();

  double get latitude => _latitude;

  set latitude(double value) {
    _latitude = value;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      "idUser": this.idUser,
      "nome": this.nome,
      "email": this.email,
      "tipoUser": this.tipoUser,
      "latitude": this.latitude,
      "longitude": this.longitude,
    };

    return map;
  }

  String verificaTipoUser(bool tipoUser) {
    return tipoUser ? "motorista" : "passageiro";
  }

  String get tipoUser => _tipoUser;

  set tipoUser(String value) {
    _tipoUser = value;
  }

  String get senha => _senha;

  set senha(String value) {
    _senha = value;
  }

  String get email => _email;

  set email(String value) {
    _email = value;
  }

  String get nome => _nome;

  set nome(String value) {
    _nome = value;
  }

  String get idUser => _idUser;

  set idUser(String value) {
    _idUser = value;
  }

  double get longitude => _longitude;

  set longitude(double value) {
    _longitude = value;
  }
}
