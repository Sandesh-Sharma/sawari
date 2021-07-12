import 'package:flutter/material.dart';
import 'package:uber/model/User.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Cadastro extends StatefulWidget {
  @override
  _CadastroState createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  TextEditingController _controllerNome = TextEditingController();
  TextEditingController _controllerEmail = TextEditingController();
  TextEditingController _controllerSenha = TextEditingController();
  bool _tipoUser = false;
  String _mensagemErro = "";

  _validarCampos() {
    //Recuperar dados dos campos
    String nome = _controllerNome.text;
    String email = _controllerEmail.text;
    String senha = _controllerSenha.text;

    //validar campos
    if (nome.isNotEmpty) {
      if (email.isNotEmpty && email.contains("@")) {
        if (senha.isNotEmpty && senha.length > 6) {
          User usuario = User();
          usuario.nome = nome;
          usuario.email = email;
          usuario.senha = senha;
          usuario.tipoUser = usuario.verificaTipoUser(_tipoUser);

          _cadastrarUser(usuario);
        } else {
          setState(() {
            _mensagemErro = "Preencha a senha! digite mais de 6 caracteres";
          });
        }
      } else {
        setState(() {
          _mensagemErro = "Preencha o E-mail válido";
        });
      }
    } else {
      setState(() {
        _mensagemErro = "Preencha o Nome";
      });
    }
  }

  _cadastrarUser(User usuario) {
    FirebaseAuth auth = FirebaseAuth.instance;
    Firestore db = Firestore.instance;

    auth
        .createUserWithEmailAndPassword(
      email: usuario.email,
      password: usuario.senha,
    )
        .then((firebaseUser) {
      db
          .collection("users")
          .document(firebaseUser.user.uid)
          .setData(usuario.toMap());

      //redireciona para o painel, de acordo com o tipoUser
      switch (usuario.tipoUser) {
        case "motorista":
          Navigator.pushNamedAndRemoveUntil(
              context, "/painel-motorista", (_) => false);
          break;
        case "passageiro":
          Navigator.pushNamedAndRemoveUntil(
              context, "/painel-passageiro", (_) => false);
          break;
      }
    }).catchError((error) {
      _mensagemErro =
          "Erro ao cadastrar usuário, verifique os campos e tente novamente!";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cadastro"),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage("assets/images/fundo.png"), fit: BoxFit.cover),
        ),
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Material(
                  borderRadius: BorderRadius.circular(6),
                  elevation: 30.0,
                  child: TextField(
                    controller: _controllerNome,
                    autofocus: true,
                    keyboardType: TextInputType.text,
                    style: TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                        hintText: "Nome completo",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6))),
                  ),
                ),
                SizedBox(
                  height: 4,
                ),
                Material(
                  borderRadius: BorderRadius.circular(6),
                  elevation: 30.0,
                  child: TextField(
                    controller: _controllerEmail,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                        hintText: "E-mail",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6))),
                  ),
                ),
                SizedBox(
                  height: 4,
                ),
                Material(
                  borderRadius: BorderRadius.circular(6),
                  elevation: 30.0,
                  child: TextField(
                    controller: _controllerSenha,
                    obscureText: true,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                        hintText: "Senha",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6))),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "Passageiro",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Switch(
                          activeColor: Color(0xff1ebbd8),
                          //activeTrackColor: Color(0xff1ebbd8),

                          inactiveThumbColor: Colors.black,
                          inactiveTrackColor: Colors.grey[900].withOpacity(0.8),
                          value: _tipoUser,
                          onChanged: (bool valor) {
                            setState(() {
                              _tipoUser = valor;
                            });
                          }),
                      Text(
                        "Motorista",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 10),
                  child: Material(
                    borderRadius: BorderRadius.circular(6),
                    elevation: 30.0,
                    child: RaisedButton(
                        child: Text(
                          "Cadastrar",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        color: Color(0xff1ebbd8),
                        padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                        onPressed: () {
                          _validarCampos();
                        }),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(
                    child: Text(
                      _mensagemErro,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 20,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
