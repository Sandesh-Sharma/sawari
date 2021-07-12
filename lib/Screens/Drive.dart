import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uber/model/Highlighter.dart';
import 'package:uber/model/User.dart';
import 'package:uber/util/RequestStatus.dart';
import 'package:uber/util/UserFirebase.dart';

class Corrida extends StatefulWidget {
  String idRequest;

  Corrida(this.idRequest);

  @override
  _CorridaState createState() => _CorridaState();
}

class _CorridaState extends State<Corrida> {
  Completer<GoogleMapController> _controller = Completer();
  CameraPosition _posicaoCamera =
      CameraPosition(target: LatLng(-23.563999, -46.653256));
  Set<Marker> _marcadores = {};
  Map<String, dynamic> _dadosRequest;
  String _idRequest;
  Position _localMotorista;
  String _statusRequest = StatusRequest.WAITING;

  //Controles para exibição na tela
  String _textoBotao = "Aceitar corrida";
  Color _corBotao = Color(0xff1ebbd8);
  Function _funcaoBotao;
  String _mensagemStatus = "";

  _alterarBotaoPrincipal(String texto, Color cor, Function funcao) {
    setState(() {
      _textoBotao = texto;
      _corBotao = cor;
      _funcaoBotao = funcao;
    });
  }

  _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  _adicionarListenerLocalizacao() {
    var geolocator = Geolocator();
    var locationOptions =
        LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);

    geolocator.getPositionStream(locationOptions).listen((Position position) {
      if (position != null) {
        if (_idRequest != null && _idRequest.isNotEmpty) {
          if (_statusRequest != StatusRequest.WAITING) {
            //Atualiza local do passageiro
            UserFirebase.atualizarDadosLocalizacao(
                _idRequest, position.latitude, position.longitude);
          } else {
            //waiting
            setState(() {
              _localMotorista = position;
            });
            _statusAguardando();
          }
        }
      }
    });
  }

  _recuperaUltimaLocalizacaoConhecida() async {
    Position position = await Geolocator()
        .getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);

    if (position != null) {
      //Atualizar localização em tempo real do motorista

    }
  }

  _movimentarCamera(CameraPosition cameraPosition) async {
    GoogleMapController googleMapController = await _controller.future;
    googleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  _exibirHighlight(Position local, String icone, String infoWindow) async {
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: pixelRatio), icone)
        .then((BitmapDescriptor bitmapDescriptor) {
      Marker marcador = Marker(
          markerId: MarkerId(icone),
          position: LatLng(local.latitude, local.longitude),
          infoWindow: InfoWindow(title: infoWindow),
          icon: bitmapDescriptor);

      setState(() {
        _marcadores.add(marcador);
      });
    });
  }

  _recuperarRequest() async {
    String idRequest = widget.idRequest;

    Firestore db = Firestore.instance;
    DocumentSnapshot documentSnapshot =
        await db.collection("requests").document(idRequest).get();
  }

  _adicionarListenerRequest() async {
    Firestore db = Firestore.instance;

    await db
        .collection("requests")
        .document(_idRequest)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.data != null) {
        _dadosRequest = snapshot.data;

        Map<String, dynamic> dados = snapshot.data;
        _statusRequest = dados["status"];

        switch (_statusRequest) {
          case StatusRequest.WAITING:
            _statusAguardando();
            break;
          case StatusRequest.ON_MY_WAY:
            _statusACaminho();
            break;
          case StatusRequest.TRAVEL:
            _statusEmViagem();
            break;
          case StatusRequest.FINISHED:
            _statusFinalizada();
            break;
          case StatusRequest.CONFIRMED:
            _statusConfirmada();
            break;
        }
      }
    });
  }

  _aceitarCorrida() async {
    //Recuperar dados do motorista
    User motorista = await UserFirebase.getDadosUserLogado();
    motorista.latitude = _localMotorista.latitude;
    motorista.longitude = _localMotorista.longitude;

    Firestore db = Firestore.instance;
    String idRequest = _dadosRequest["id"];

    db.collection("requests").document(idRequest).updateData({
      "motorista": motorista.toMap(),
      "status": StatusRequest.ON_MY_WAY,
    }).then((_) {
      //atualiza requisicao ativa
      String idPassageiro = _dadosRequest["passageiro"]["idUser"];
      db.collection("active_request").document(idPassageiro).updateData({
        "status": StatusRequest.ON_MY_WAY,
      });

      //Salvar requisicao ativa para motorista
      String idMotorista = motorista.idUser;
      db.collection("active_request_motorista").document(idMotorista).setData({
        "request_id": idRequest,
        "user_id": idMotorista,
        "status": StatusRequest.ON_MY_WAY,
      });
    });
  }

  _statusAguardando() {
    _alterarBotaoPrincipal("Aceitar corrida", Color(0xff1ebbd8), () {
      _aceitarCorrida();
    });

    double latitudeDestination = _dadosRequest["passageiro"]["latitude"];
    double longitudeDestination = _dadosRequest["passageiro"]["longitude"];

    double latitudeOrigem = _dadosRequest["motorista"]["latitude"];
    double longitudeOrigem = _dadosRequest["motorista"]["longitude"];

    Highlight marcadorOrigem = Highlight(
        LatLng(latitudeOrigem, longitudeOrigem),
        "assets/images/motorista.png",
        "Local motorista");

    Highlight marcadorDestination = Highlight(
        LatLng(latitudeDestination, longitudeDestination),
        "assets/images/passageiro.png",
        "Local destino");

    _exibirCentralizarDoisHighlightes(marcadorOrigem, marcadorDestination);
  }

  _statusACaminho() {
    _mensagemStatus = "A caminho do passageiro";
    _alterarBotaoPrincipal("Iniciar corrida", Color(0xff1ebbd8), () {
      _iniciarCorrida();
    });
    double latitudeDestination = _dadosRequest["passageiro"]["latitude"];
    double longitudeDestination = _dadosRequest["passageiro"]["longitude"];

    double latitudeOrigem = _dadosRequest["motorista"]["latitude"];
    double longitudeOrigem = _dadosRequest["motorista"]["longitude"];

    Highlight marcadorOrigem = Highlight(
        LatLng(latitudeOrigem, longitudeOrigem),
        "assets/images/motorista.png",
        "Local motorista");

    Highlight marcadorDestination = Highlight(
        LatLng(latitudeDestination, longitudeDestination),
        "assets/images/passageiro.png",
        "Local destino");

    _exibirCentralizarDoisHighlightes(marcadorOrigem, marcadorDestination);
  }

  _finalizarCorrida() {
    Firestore db = Firestore.instance;
    db
        .collection("requests")
        .document(_idRequest)
        .updateData({"status": StatusRequest.FINISHED});

    String idPassageiro = _dadosRequest["passageiro"]["idUser"];
    db
        .collection("active_request")
        .document(idPassageiro)
        .updateData({"status": StatusRequest.FINISHED});

    String idMotorista = _dadosRequest["motorista"]["idUser"];
    db
        .collection("active_request_motorista")
        .document(idMotorista)
        .updateData({"status": StatusRequest.FINISHED});
  }

  _statusFinalizada() async {
    //Calcula valor da corrida
    double latitudeDestination = _dadosRequest["destino"]["latitude"];
    double longitudeDestination = _dadosRequest["destino"]["longitude"];

    double latitudeOrigem = _dadosRequest["origem"]["latitude"];
    double longitudeOrigem = _dadosRequest["origem"]["longitude"];

    double distanciaEmMetros = await Geolocator().distanceBetween(
        latitudeOrigem,
        longitudeOrigem,
        latitudeDestination,
        longitudeDestination);

    //Converte para KM
    double distanciaKm = distanciaEmMetros / 1000;

    //8 é o valor cobrado por KM
    double valorViagem = distanciaKm * 8;

    //Formatar valor travel
    var f = new NumberFormat("#,##0.00", "pt_BR");
    var valorViagemFormatado = f.format(valorViagem);

    _mensagemStatus = "Viagem finished";
    _alterarBotaoPrincipal(
        "Confirmar - R\$ ${valorViagemFormatado}", Color(0xff1ebbd8), () {
      _confirmarCorrida();
    });

    _marcadores = {};
    Position position = Position(
        latitude: latitudeDestination, longitude: longitudeDestination);
    _exibirHighlight(position, "assets/images/destino.png", "Destination");

    CameraPosition cameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude), zoom: 19);

    _movimentarCamera(cameraPosition);
  }

  _statusConfirmada() {
    Navigator.pushReplacementNamed(context, "/painel-motorista");
  }

  _confirmarCorrida() {
    Firestore db = Firestore.instance;
    db
        .collection("requests")
        .document(_idRequest)
        .updateData({"status": StatusRequest.CONFIRMED});

    String idPassageiro = _dadosRequest["passageiro"]["idUser"];
    db.collection("active_request").document(idPassageiro).delete();

    String idMotorista = _dadosRequest["motorista"]["idUser"];
    db.collection("active_request_motorista").document(idMotorista).delete();
  }

  _statusEmViagem() {
    _mensagemStatus = "Em travel";
    _alterarBotaoPrincipal("Finalizar corrida", Color(0xff1ebbd8), () {
      _finalizarCorrida();
    });

    double latitudeDestination = _dadosRequest["destino"]["latitude"];
    double longitudeDestination = _dadosRequest["destino"]["longitude"];

    double latitudeOrigem = _dadosRequest["motorista"]["latitude"];
    double longitudeOrigem = _dadosRequest["motorista"]["longitude"];

    Highlight marcadorOrigem = Highlight(
        LatLng(latitudeOrigem, longitudeOrigem),
        "assets/images/motorista.png",
        "Local motorista");

    Highlight marcadorDestination = Highlight(
        LatLng(latitudeDestination, longitudeDestination),
        "assets/images/destino.png",
        "Local destino");

    _exibirCentralizarDoisHighlightes(marcadorOrigem, marcadorDestination);
  }

  _exibirCentralizarDoisHighlightes(
      Highlight marcadorOrigem, Highlight marcadorDestination) {
    double latitudeOrigem = marcadorOrigem.local.latitude;
    double longitudeOrigem = marcadorOrigem.local.longitude;

    double latitudeDestination = marcadorDestination.local.latitude;
    double longitudeDestination = marcadorDestination.local.longitude;

    //Exibir dois marcadores
    _exibirDoisHighlightes(marcadorOrigem, marcadorDestination);

    //'southwest.latitude <= northeast.latitude': is not true
    var nLat, nLon, sLat, sLon;

    if (latitudeOrigem <= latitudeDestination) {
      sLat = latitudeOrigem;
      nLat = latitudeDestination;
    } else {
      sLat = latitudeDestination;
      nLat = latitudeOrigem;
    }

    if (longitudeOrigem <= longitudeDestination) {
      sLon = longitudeOrigem;
      nLon = longitudeDestination;
    } else {
      sLon = longitudeDestination;
      nLon = longitudeOrigem;
    }
    //-23.560925, -46.650623
    _movimentarCameraBounds(LatLngBounds(
        northeast: LatLng(nLat, nLon), //nordeste
        southwest: LatLng(sLat, sLon) //sudoeste
        ));
  }

  _iniciarCorrida() {
    Firestore db = Firestore.instance;
    db.collection("requests").document(_idRequest).updateData({
      "origem": {
        "latitude": _dadosRequest["motorista"]["latitude"],
        "longitude": _dadosRequest["motorista"]["longitude"]
      },
      "status": StatusRequest.TRAVEL
    });

    String idPassageiro = _dadosRequest["passageiro"]["idUser"];
    db
        .collection("active_request")
        .document(idPassageiro)
        .updateData({"status": StatusRequest.TRAVEL});

    String idMotorista = _dadosRequest["motorista"]["idUser"];
    db
        .collection("active_request_motorista")
        .document(idMotorista)
        .updateData({"status": StatusRequest.TRAVEL});
  }

  _movimentarCameraBounds(LatLngBounds latLngBounds) async {
    GoogleMapController googleMapController = await _controller.future;
    googleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 100));
  }

  _exibirDoisHighlightes(
      Highlight marcadorOrigem, Highlight marcadorDestination) {
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    LatLng latLngOrigem = marcadorOrigem.local;
    LatLng latLngDestination = marcadorDestination.local;

    Set<Marker> _listaHighlightes = {};
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: pixelRatio),
            marcadorOrigem.caminhoImagem)
        .then((BitmapDescriptor icone) {
      Marker mOrigem = Marker(
          markerId: MarkerId(marcadorOrigem.caminhoImagem),
          position: LatLng(latLngOrigem.latitude, latLngOrigem.longitude),
          infoWindow: InfoWindow(title: marcadorOrigem.titulo),
          icon: icone);
      _listaHighlightes.add(mOrigem);
    });

    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: pixelRatio),
            marcadorDestination.caminhoImagem)
        .then((BitmapDescriptor icone) {
      Marker mDestination = Marker(
          markerId: MarkerId(marcadorDestination.caminhoImagem),
          position:
              LatLng(latLngDestination.latitude, latLngDestination.longitude),
          infoWindow: InfoWindow(title: marcadorDestination.titulo),
          icon: icone);
      _listaHighlightes.add(mDestination);
    });

    setState(() {
      _marcadores = _listaHighlightes;
    });
  }

  @override
  void initState() {
    super.initState();

    _idRequest = widget.idRequest;

    // adicionar listener para mudanças na requisicao
    _adicionarListenerRequest();

    //_recuperaUltimaLocalizacaoConhecida();
    _adicionarListenerLocalizacao();
  }

  _escolhaMenuItem(String escolha) {
    switch (escolha) {
      case "Mapa 3D":
        // _deslogarUser();
        break;
    }
  }

  _deslogarUser() async {
    FirebaseAuth auth = FirebaseAuth.instance;

    await auth.signOut();
    Navigator.pushReplacementNamed(context, "/");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _mensagemStatus == ""
            ? Text("Painel corrida")
            : Text("Painel corrida - " + _mensagemStatus),
      ),
      body: Container(
        child: Stack(
          children: <Widget>[
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _posicaoCamera,
              onMapCreated: _onMapCreated,
              //myLocationEnabled: true,
              myLocationButtonEnabled: false,
              markers: _marcadores,
              zoomControlsEnabled: false,
              //-23,559200, -46,658878
            ),
            Positioned(
              right: 0,
              left: 0,
              bottom: 0,
              child: Padding(
                padding: Platform.isIOS
                    ? EdgeInsets.fromLTRB(20, 10, 20, 25)
                    : EdgeInsets.all(10),
                child: RaisedButton(
                    child: Text(
                      _textoBotao,
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    color: _corBotao,
                    padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    onPressed: _funcaoBotao),
              ),
            )
          ],
        ),
      ),
    );
  }
}
