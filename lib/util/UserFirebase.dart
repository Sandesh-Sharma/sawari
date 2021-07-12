import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uber/model/User.dart';

class UserFirebase {
  static Future<FirebaseUser> getUserAtual() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    return await auth.currentUser();
  }

  static Future<User> getDadosUserLogado() async {
    FirebaseUser firebaseUser = await getUserAtual();
    String idUser = firebaseUser.uid;

    Firestore db = Firestore.instance;

    DocumentSnapshot snapshot =
        await db.collection("usuarios").document(idUser).get();

    Map<String, dynamic> dados = snapshot.data;
    String tipoUser = dados["tipoUser"];
    String email = dados["email"];
    String nome = dados["nome"];

    User usuario = User();
    usuario.idUser = idUser;
    usuario.tipoUser = tipoUser;
    usuario.email = email;
    usuario.nome = nome;

    return usuario;
  }

  static atualizarDadosLocalizacao(
      String idRequisicao, double lat, double lon) async {
    Firestore db = Firestore.instance;

    User motorista = await getDadosUserLogado();
    motorista.latitude = lat;
    motorista.longitude = lon;

    db.collection("requisicoes").document(idRequisicao).updateData(
      {
        "motorista": motorista.toMap(),
      },
    );
  }
}
