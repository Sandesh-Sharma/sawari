import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uber/util/RequestStatus.dart';
import 'package:uber/util/UserFirebase.dart';

class PainelMotorista extends StatefulWidget {
  @override
  _PainelMotoristaState createState() => _PainelMotoristaState();
}

class _PainelMotoristaState extends State<PainelMotorista> {
  List<String> itensMenu = ["Deslogar"];
  final _controller = StreamController<QuerySnapshot>.broadcast();
  Firestore db = Firestore.instance;

  _deslogarUser() async {
    FirebaseAuth auth = FirebaseAuth.instance;

    await auth.signOut();
    Navigator.pushReplacementNamed(context, "/");
  }

  _escolhaMenuItem(String escolha) {
    switch (escolha) {
      case "Deslogar":
        _deslogarUser();
        break;
      case "Configurações":
        break;
    }
  }

  Stream<QuerySnapshot> _adicionarListenerRequisicoes() {
    final stream = db
        .collection("requests")
        .where("status", isEqualTo: StatusRequest.WAITING)
        .snapshots();

    stream.listen((dados) {
      _controller.add(dados);
    });
  }

  _recuperaRequestAtivaMotorista() async {
    //Recupera dados do usuario logado
    FirebaseUser firebaseUser = await UserFirebase.getUserAtual();

    //Recupera requisicao ativa
    DocumentSnapshot documentSnapshot = await db
        .collection("active_request_motorista")
        .document(firebaseUser.uid)
        .get();

    var dadosRequest = documentSnapshot.data;

    if (dadosRequest == null) {
      _adicionarListenerRequisicoes();
    } else {
      String idRequest = dadosRequest["request_id"];
      Navigator.pushReplacementNamed(context, "/corrida", arguments: idRequest);
    }
  }

  @override
  void initState() {
    super.initState();

    /*
    Recupera requisicao ativa para verificar se motorista está
    atendendo alguma requisição e envia ele para tela de corrida
    */
    _recuperaRequestAtivaMotorista();
  }

  @override
  Widget build(BuildContext context) {
    var mensagemCarregando = Container(
      decoration: BoxDecoration(
        image: DecorationImage(
            image: AssetImage("assets/images/fundo.png"), fit: BoxFit.cover),
      ),
      child: Column(
        // crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Container(
              //padding: EdgeInsets.fromLTRB(40, 16, 32, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        'assets/images/icon.png',
                        width: 50,
                        height: 45,
                      ),
                      Text(
                        "UBER",
                        style: TextStyle(
                          fontSize: 30,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    "Carregando requisições",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  CircularProgressIndicator(),
                ],
              ),
              decoration: BoxDecoration(
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: Offset(1.0, 6.0),
                    blurRadius: 40.0,
                  ),
                ],
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withOpacity(0.7),
              ),
              height: 200,
              width: 250,
            ),
          ),
        ],
      ),
    );

    var mensagemNaoTemDados = Container(
      decoration: BoxDecoration(
        image: DecorationImage(
            image: AssetImage("assets/images/fundo.png"), fit: BoxFit.cover),
      ),
      child: Column(
        // crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Container(
              //padding: EdgeInsets.fromLTRB(40, 16, 32, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        'assets/images/icon.png',
                        width: 50,
                        height: 45,
                      ),
                      Text(
                        "UBER",
                        style: TextStyle(
                          fontSize: 30,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(30, 8, 16, 8),
                    child: Text(
                      "Você não tem nenhuma requisição !",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              decoration: BoxDecoration(
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: Offset(1.0, 6.0),
                    blurRadius: 40.0,
                  ),
                ],
                borderRadius: BorderRadius.circular(10),
                color: Colors.white.withOpacity(0.7),
              ),
              height: 200,
              width: 250,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Painel motorista"),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: _escolhaMenuItem,
            itemBuilder: (context) {
              return itensMenu.map((String item) {
                return PopupMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList();
            },
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage("assets/images/fundo.png"), fit: BoxFit.cover),
        ),
        child: StreamBuilder<QuerySnapshot>(
            stream: _controller.stream,
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                case ConnectionState.waiting:
                  return mensagemCarregando;
                  break;
                case ConnectionState.active:
                case ConnectionState.done:
                  if (snapshot.hasError) {
                    return Text("Erro ao carregar os dados!");
                  } else {
                    QuerySnapshot querySnapshot = snapshot.data;
                    if (querySnapshot.documents.length == 0) {
                      return mensagemNaoTemDados;
                    } else {
                      return ListView.separated(
                          itemCount: querySnapshot.documents.length,
                          separatorBuilder: (context, indice) => Divider(
                                height: 0,
                                //color: Colors.grey,
                              ),
                          itemBuilder: (context, indice) {
                            List<DocumentSnapshot> requests =
                                querySnapshot.documents.toList();
                            DocumentSnapshot item = requests[indice];

                            String idRequest = item["id"];
                            String namePassageiro = item["passageiro"]["name"];
                            String rua = item["destino"]["rua"];
                            String numero = item["destino"]["numero"];

                            return Padding(
                              padding: EdgeInsets.fromLTRB(8, 8, 8, 4),
                              child: Container(
                                decoration: BoxDecoration(
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      offset: Offset(1.0, 6.0),
                                      blurRadius: 40.0,
                                    ),
                                  ],
                                  color: Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(10),
                                    topRight: const Radius.circular(10),
                                    bottomLeft: const Radius.circular(10),
                                    bottomRight: const Radius.circular(10),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: ListTile(
                                    title: Text(
                                      namePassageiro,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    subtitle: Text(
                                      "destino: $rua, $numero",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    onTap: () {
                                      Navigator.pushNamed(context, "/corrida",
                                          arguments: idRequest);
                                    },
                                  ),
                                ),
                              ),
                            );
                          });
                    }
                  }

                  break;
              }
            }),
      ),
    );
  }
}
