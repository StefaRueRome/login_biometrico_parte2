
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageItem {
  StorageItem(this.key, this.value, this.token, this.tValue);

  final String key;
  final String value;
  final String token;
  final String tValue;

}

class StorageService {
  final _secureStorage = const FlutterSecureStorage();

  Future<void> writeSecureData(StorageItem newItem) async {
    await _secureStorage.write(
      key: newItem.key, value: newItem.value, aOptions: _getAndroidOptions());
    await _secureStorage.write(key: newItem.token, value: newItem.tValue, aOptions: _getAndroidOptions());
  }

  AndroidOptions _getAndroidOptions() => const AndroidOptions(
    encryptedSharedPreferences: true,
  );

  Future<String?> readSecureData(String key) async {
    var readData = await _secureStorage.read(key: key, aOptions: _getAndroidOptions());
    return readData;
  }
  Future<bool> containsKeyInSecureData(String key) async {
    var containsKey = await _secureStorage.containsKey(key: key, aOptions: _getAndroidOptions());
    return containsKey;
  }
  Future<List> readAllSecureData() async {
    var allData = await _secureStorage.readAll(aOptions: _getAndroidOptions());
    var listFinal=[];

    List<StorageItem> list =
      allData.entries.map((e) => StorageItem(e.key, e.value, e.key, e.value)).toList();
    
    for (var i = 0; i < list.length; i++) {
      print(await list[i]);
      //print(listFinal[i]);
    }
    return listFinal;
  }
}