import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
//import 'package:get/get_core/src/get_main.dart';
import 'package:login_biometrico/home_page.dart';
import 'package:login_biometrico/my_button.dart';
import 'package:http/http.dart' as http;
import 'package:login_biometrico/my_text_field.dart';
import 'package:login_biometrico/storage_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

//import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget{
  LoginPage({super.key, required this.boolI, required this.usuarioAuth});
  final bool boolI;
  final StorageItem? usuarioAuth;


  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late bool boolValue=false;
  final StorageService _storageService = StorageService();
  late String primerToken;
  bool firstAuth=false;
  bool secondAuth=false;
  //late StorageItem storageItem;
  late StorageItem? userItem = widget.usuarioAuth;
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _firstBiometricAuthentication = false;
  late bool isAutheticating=false;
  bool _isFingerprintEnabled = false;
  late bool _authenticated=false;
  late bool _canCheckBiometric;
  bool _useBiometric = false;
  bool _isLoading = false;
  String _errorMessage = "";
  String _authorized = 'No autorizado';
  late List<BiometricType> _availableBiometrics;
  //String autherized="No Autherized";

  Future<void> _checkFingerprintStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      boolValue = prefs.getBool('fingerprint_enabled') ?? false;
    });
  }
  Future<void> _checkBiometric()async{
    bool canCheckBiometrics = false;
    try{
      canCheckBiometrics=await _localAuth.canCheckBiometrics;
    }on PlatformException catch(e){
      print(e);
    }
    if(!mounted) return;
    setState(() {
      _canCheckBiometric=canCheckBiometrics;
    });
  }

  Future<void> _getAvailableBiometric()async{
    List<BiometricType> availableBiometric=[];
    try{
      availableBiometric=await _localAuth.getAvailableBiometrics();
    }on PlatformException catch(e){
      print(e);
    }
    setState(() {
      _availableBiometrics=availableBiometric;
    });
  }
  @override
  void initState() {
    // TODO: implement initState
    _checkBiometric();
    _getAvailableBiometric();
  }

  Future<void> _authenticate() async {
    print("Holiiii");
    bool isAuthenticated = false;
    try {
      isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to log in',
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
    if (!mounted) return;
    setState(() {
      _authenticated = isAuthenticated;
      _errorMessage = "null";
      if (!_firstBiometricAuthentication) {
        _firstBiometricAuthentication = true;
        Navigator.push(context, MaterialPageRoute(builder: (context)=> HomePage(boolFinal: widget.boolI,user: null,)));
      }
    });
  }

  Future<bool> _login(String username, String password) async {
    //final String username = usernameController.text.trim();
    //final String password = passwordController.text.trim();

    final url = Uri.parse('http://172.20.10.2:3003/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if(response.statusCode == 200){
      print("todo ok!!!!!!!");
      setState(() {
      _useBiometric = true;
      _isLoading = false;
      });
      Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
      final token = jsonDecode(response.body)['token'];
      final decodedToken = JwtDecoder.decode(token);
      final SharedPreferences prefs = await _prefs;
      prefs.setString('token', token);
      final String? tokenGuardado = prefs.getString('token');
      setState(() {
        primerToken=tokenGuardado!;
      });
      print("Tokeennnnnnn!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
      print(tokenGuardado);
      // Navigate to the home page
      Navigator.push(context, MaterialPageRoute(builder: (context)=> HomePage(boolFinal: widget.boolI,user: null,)));
      return true;
    }else{
      print("Entro aqui");
      return false;
    }
  }
  Future<void> _cancelAuthentication() async {
    await _localAuth.stopAuthentication();
    setState(() => isAutheticating = false);
  }
  Future<void> _authenticateWithFingerprint(StorageItem user) async {
    setState(() {
      isAutheticating = true;
      secondAuth=true;
    });
    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Please place your finger on the sensor',
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );
    } catch (e) {
      print(e);
    }

    setState(() {
      isAutheticating= false;
      //firstAuth=true;
      //secondAuth=false;
    });

    if (authenticated&&secondAuth==true) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('fingerprint_enabled', true);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomePage(boolFinal: widget.boolI,user: user )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(
                height: 50,
              ),
              const Icon(
                Icons.supervised_user_circle,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 50),
              Text("Bienvenido",
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 16
              ),),
              const SizedBox(height: 50),
              MyTextField(
                controller: usernameController,
                hinText: 'Usuario',
                obscureText: false,
              ),
              const SizedBox(height: 20,),
              MyTextField(
                controller: passwordController,
                hinText: 'Contraseña',
                obscureText: true,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  final result = await _login(usernameController.value.text,
                    passwordController.value.text);
                  /*
                  final StorageItem storageItem = StorageItem(usernameController.value.text, passwordController.value.text,"token",primerToken);
                  setState(() {
                    userItem=storageItem;
                  });
                    _storageService.writeSecureData(storageItem);
                    print(passwordController.value.text);
                  setState(() {
                    isAutheticating = false;
                    firstAuth=true;
                    secondAuth=false;
                    userItem=storageItem;
                  });
                  */
                  if (result) {
                    secondAuth=true;
                    print("Entro aqui!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => AuthFingerprint(boolFinger: false, user: usernameController.value.text,pass: passwordController.value.text,secondAuth: secondAuth,)),
                    );
                  } else {
                    //print("Entro aqui2!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Usuario o contraseña incorrecto')));
                  }
                },
                child: Text('Ingresa')
              ),
              if (_errorMessage != "")
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  )
                ),
                Text('Estado actual: $_authorized\n'),
                if (widget.boolI)
                  if (isAutheticating&&secondAuth==true)
                    ElevatedButton(
                      onPressed: _cancelAuthentication,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const <Widget> [
                          Text('Cancelar autenticación'),
                          Icon(Icons.cancel),
                        ],
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: (){
                        //userItem=storageItem;
                        _authenticateWithFingerprint(userItem!);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const <Widget>[
                          Text('Autenticar'),
                          Icon(Icons.fingerprint),
                        ],
                      ),
                    ),
            ],
          ),
        ))
    );
  }
}
class AuthFingerprint extends StatefulWidget {
  AuthFingerprint({super.key, required this.boolFinger, required this.user, required this.pass, required this.secondAuth});
  bool boolFinger;
  final String user;
  final String pass;
  late final bool secondAuth;
  @override
  _AuthFingerprintState createState() => _AuthFingerprintState();
}

class _AuthFingerprintState extends State<AuthFingerprint> {
  final usernameControllerF = TextEditingController();
  final passwordControllerF = TextEditingController();
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  bool _isAuthenticating = false;
  String tokenFinal="";
  final StorageService _storageService = StorageService();

  Future<bool> _login(String username, String password) async {
    //final String username = usernameController.text.trim();
    //final String password = passwordController.text.trim();

    final url = Uri.parse('http://172.20.10.2:3003/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if(response.statusCode == 200){
      print("todo ok!!!!!!!");
      setState(() {
      //_useBiometric = true;
      //_isLoading = false;
      });
      Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
      final token = jsonDecode(response.body)['token'];
      final decodedToken = JwtDecoder.decode(token);
      final SharedPreferences prefs = await _prefs;
      prefs.setString('token', token);
      final String? tokenGuardado = prefs.getString('token');
      setState(() {
        tokenFinal=tokenGuardado!;
      });
      print("/////Token Final//////");
      print(tokenFinal);
      // Navigate to the home page
      //Navigator.push(context, MaterialPageRoute(builder: (context)=> HomePage(boolFinal: widget.boolFinger,)));
      return true;
    }else{
      print("Entro aqui");
      return false;
    }
  }

  Future<void> _authenticateWithFingerprint() async {
    setState(() {
      _isAuthenticating = true;
    });
    bool authenticated = false;
    try {
      authenticated = await _localAuthentication.authenticate(
        localizedReason: 'Please place your finger on the sensor',
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );
    } catch (e) {
      print(e);
    }

    setState(() {
      _isAuthenticating = false;
      widget.boolFinger=true;
    });
    if (authenticated) {
      /*
      ElevatedButton(
        onPressed: () {
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Confirmar inicio de sesión con huella'),
            Icon(Icons.check),
          ],
        ),
      );
      */
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('fingerprint_enabled', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ingreso con Huella'),
      ),
      body:  SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 50,
              ),
              const Icon(
                Icons.fingerprint,
                size: 100,
              ),
              const SizedBox(
                height: 20,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    _isAuthenticating
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: _authenticateWithFingerprint,
                      child: Text('Authenticate with Fingerprint'),
                    ),
                    if(widget.boolFinger)
                      ElevatedButton(
                        child: Text("Confirma inicio de sesión con huella"),
                        onPressed: (){
                          showModalBottomSheet<void>(
                            context: context,
                            builder: (context){
                              return Container(
                                height: 400,
                                color: Colors.white,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Text("Confirma Inicio de sesión con huella"),
                                    MyTextField(controller: usernameControllerF, hinText: 'Usuario', obscureText: false),
                                    SizedBox(height: 10,),
                                    MyTextField(controller: passwordControllerF, hinText: 'contraseña', obscureText: true),
                                    SizedBox(height: 10,),
                                    ElevatedButton(
                                      child: const Text('Aceptar'),
                                      onPressed: () async {
                                        final result = await _login(usernameControllerF.value.text,passwordControllerF.value.text);
                                        if(result){
                                          if(usernameControllerF.value.text==widget.user&&passwordControllerF.value.text==widget.pass){
                                              //print("Entroooo");
                                            ////////////////////////////////////////////////////////
                                            /// Guardar usuario y contraseña en el Secure Storage///
                                            ////////////////////////////////////////////////////////
                                            final StorageItem storageItem = StorageItem(usernameControllerF.value.text, passwordControllerF.value.text,"token",tokenFinal);
                                            _storageService.writeSecureData(storageItem);
                                            print("Usuarios y contraseñas iguales");
                                            print(passwordControllerF.value.text);
                                            print ("/////////////lista de guardado////////////////");
                                            print(await _storageService.readSecureData(usernameControllerF.value.text));
                                            print(await _storageService.readSecureData("token"));
                                            //if (result) {
                                            print("Entro aqui finger!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(builder: (context) => HomePage(boolFinal: widget.boolFinger, user: storageItem,)),
                                            );
                                            //} else {
                                              //print("Entro aqui2!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
                                            //AlertDialog(content: Text("Usuario/contraseña Incorrectos"), actions:<Widget> [ElevatedButton(onPressed: (){Navigator.pop(context);}, child: Text("Aceptar"))]);
                                            //}
                                          }else{
                                            print("Usuario y contraseña no coinciden");
                                            /*
                                            print(widget.user);
                                            print("controlador");
                                            print(usernameControllerF.value.text);
                                            print("Usuario y contraseña no coinciden");
                                            print(widget.pass);
                                            print("controlador");
                                            print(passwordControllerF.value.text);
                                            */
                                            AlertDialog(content: Text("Usuario/contraseña no coinciden"), actions:<Widget> [ElevatedButton(onPressed: (){Navigator.pop(context);}, child: Text("Aceptar"))]);
                                          }
                                        }
                                      },
                                    )
                                  ]
                                ),
                              );
                            }
                          );
                        },
                      ),
                ]
              )
            ],
        ),
      )
      )
    );
  }
}