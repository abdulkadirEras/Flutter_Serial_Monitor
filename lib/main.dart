import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:serial_monitor/BaslangicEkrani.dart';
import 'package:window_size/window_size.dart';

void main() {
  //ekranın min küçültülme değeri ayarlandı
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('Serial Terminal');
    //uygulamayı görünmez yapıyor
    setWindowVisibility(visible: true);
    setWindowMinSize(const Size(1015, 600));
  }

  runApp(const Uygulamam());
}

class Uygulamam extends StatelessWidget {
  const Uygulamam({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serial Port',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      //home: const AnaEkran(title: 'Serial Terminal'),
      home: BaslangicEkrani(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AnaEkran extends StatefulWidget {
  const AnaEkran({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<AnaEkran> createState() => _AnaEkranDurumu();
}

int sayac = 0;

SerialPort? _serialPort;
int _secilenBaudRate = 115200;
int _secilenDataBits = 8;
int _secilenParity = 0;
String _secilenStringParity = "None";
int _secilenStopBits = 1;
int _secilenRTS = 0;
int _secilenCTS = 0;
int _secilenXON_XOFF = 0;
String _secilenHandShaking = "None";
List<Uint8List> receiveDataList = [];
final _veriGondermeText = TextEditingController();
late FocusNode _veriGondermeFocusu;
late FocusNode _m1VeriNode;
final _gonderilenVeriler = [];
//final _gelenVeriler = [];

final List _gelenVeriler = [];

bool _scrolGonderilenAnahtari = false;
final ScrollController _gonderilenVerilerKontrol = ScrollController();

bool _scrolGelenAnahtari = false;
final ScrollController _gelenVerilerKontrol = ScrollController();

/// declare a cound variable with initial value

ValueNotifier<int> _gelenVeriSayaci = ValueNotifier<int>(0);
ValueNotifier<int> _gonderilenVeriSayaci = ValueNotifier<int>(0);

ValueNotifier<int> _m1Sayaci = ValueNotifier<int>(0);
ValueNotifier<int> _m2Sayaci = ValueNotifier<int>(0);
ValueNotifier<int> _m3Sayaci = ValueNotifier<int>(0);
ValueNotifier<int> _m4Sayaci = ValueNotifier<int>(0);
ValueNotifier<int> _m5Sayaci = ValueNotifier<int>(0);
ValueNotifier<int> _m6Sayaci = ValueNotifier<int>(0);

bool m1Anahtar = false;
bool m2Anahtar = false;
bool m3Anahtar = false;
bool m4Anahtar = false;
bool m5Anahtar = false;
bool m6Anahtar = false;

bool boslukKontrol = false;

/// declare a timer
Timer? timer1;
Timer? timer2;
Timer? timer3;
Timer? timer4;
Timer? timer5;
Timer? timer6;

final m1SureKontrol = TextEditingController();
final m1VeriKontrol = TextEditingController();
final m2SureKontrol = TextEditingController();
final m2VeriKontrol = TextEditingController();
final m3SureKontrol = TextEditingController();
final m3VeriKontrol = TextEditingController();
final m4SureKontrol = TextEditingController();
final m4VeriKontrol = TextEditingController();
final m5SureKontrol = TextEditingController();
final m5VeriKontrol = TextEditingController();
final m6SureKontrol = TextEditingController();
final m6VeriKontrol = TextEditingController();

final ButtonStyle butonGorsel1 = ElevatedButton.styleFrom(
  foregroundColor: Colors.black,
  backgroundColor: Colors.white,
  textStyle: const TextStyle(color: Colors.black),
  shape: RoundedRectangleBorder(
    //to set border radius to button
      borderRadius: BorderRadius.circular(30)),
  side: const BorderSide(color: Colors.red, width: 2.0),
);
final ButtonStyle butonGorsel2 = ElevatedButton.styleFrom(
  foregroundColor: Colors.black,
  backgroundColor: Colors.white,
  textStyle: const TextStyle(color: Colors.black),
  shape: RoundedRectangleBorder(
    //to set border radius to button
      borderRadius: BorderRadius.circular(30)),
  side: const BorderSide(color: Colors.green, width: 2.0),
);

void VeriGonder() {
  if (_veriGondermeText.text.isNotEmpty) {
    if (boslukKontrol == true) {
      debugPrint("cr ve lf eklendi");
      //CR = Carriage Return = \r,  LF = Line Feed =\n
      if (_serialPort!.write(Uint8List.fromList(
          ("${_veriGondermeText.text}\r\n").codeUnits)) ==
          ("${_veriGondermeText.text}\r\n").codeUnits.length) {
        _gonderilenVeriler.add(_veriGondermeText.text);

        _veriGondermeText.text = '';
      }
    } else {
      if (_serialPort!
          .write(Uint8List.fromList(_veriGondermeText.text.codeUnits)) ==
          _veriGondermeText.text.codeUnits.length) {
        _gonderilenVeriler.add(_veriGondermeText.text);

        _veriGondermeText.text = '';
      }
    }
    _gonderilenVeriSayaci.value++;
  }
}

class _AnaEkranDurumu extends State<AnaEkran> {
  List<SerialPort> portList = [];
  String veri = "";

  @override
  void initState() {
    super.initState();

    _veriGondermeFocusu = FocusNode();
    _m1VeriNode = FocusNode();

    _m1Sayaci.value = 0;
    _m2Sayaci.value = 0;
    _m3Sayaci.value = 0;
    _m4Sayaci.value = 0;
    _m5Sayaci.value = 0;
    _m6Sayaci.value = 0;

    m1SureKontrol.text = "1000";
    m2SureKontrol.text = "1000";
    m3SureKontrol.text = "1000";
    m4SureKontrol.text = "1000";
    m5SureKontrol.text = "1000";
    m6SureKontrol.text = "1000";
    var i = 0;
    for (final name in SerialPort.availablePorts) {
      final sp = SerialPort(name);
      if (kDebugMode) {
        print('${++i}) $name');
        print('\tDescription: ${sp.description ?? ''}');
        print('\tManufacturer: ${sp.manufacturer}');
        print('\tSerial Number: ${sp.serialNumber}');
        print('\tProduct ID: 0x${sp.productId?.toRadixString(16) ?? 00}');
        print('\tVendor ID: 0x${sp.vendorId?.toRadixString(16) ?? 00}');
      }
      portList.add(sp);
    }
    if (portList.isNotEmpty) {
      _serialPort = portList.first;
    }
  }

  @override
  void dispose() {
    m1SureKontrol.dispose();
    m1VeriKontrol.dispose();

    m2SureKontrol.dispose();
    m2VeriKontrol.dispose();

    m3SureKontrol.dispose();
    m3VeriKontrol.dispose();

    m4SureKontrol.dispose();
    m4VeriKontrol.dispose();

    m5SureKontrol.dispose();
    m5VeriKontrol.dispose();

    m6SureKontrol.dispose();
    m6VeriKontrol.dispose();

    _veriGondermeFocusu.dispose();
    _m1VeriNode.dispose();

    _gonderilenVerilerKontrol.dispose();
    _gelenVerilerKontrol.dispose();

    _gelenVeriSayaci.dispose();
    _gonderilenVeriSayaci.dispose();

    _m1Sayaci.dispose();
    _m2Sayaci.dispose();
    _m3Sayaci.dispose();
    _m4Sayaci.dispose();
    _m5Sayaci.dispose();
    _m6Sayaci.dispose();

    _timer!.cancel();
    timer1!.cancel();
    timer2!.cancel();
    timer3!.cancel();
    timer4!.cancel();
    timer5!.cancel();
    timer6!.cancel();

    _serialPort!.close();
    _serialPort!.dispose();
    super.dispose();
  }

  void changedDropDownItem(SerialPort sp) {
    setState(() {
      _serialPort = sp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
          ? AppBar(
        toolbarHeight: 50,
        title: Text(widget.title,
            style: const TextStyle(
                fontFamily: "Wallpoet-Regular", fontSize: 35)),
        centerTitle: true,
        shadowColor: _serialPort != null && _serialPort!.isOpen
            ? Colors.green
            : Colors.red,
        actions: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 0.5),
            child: IconButton(
              icon: Icon(
                  _serialPort != null && _serialPort!.isOpen
                      ? Icons.usb //şart sağlanırsa bu çalışır
                      : Icons.usb_off, //sağlanmaz ise bu çalışır,
                  //bağlantıya göre kırmızı veya yeşil rengi alması için
                  color: _serialPort != null && _serialPort!.isOpen
                      ? Colors.green //şart sağlanırsa bu çalışır
                      : Colors.red, //sağlanmaz ise bu çalışır
                  size: 35.0),
              //ikonun üzerine uzun basıldığında çıkan yazı
              tooltip: 'Cihaz ile Bağlantı Durumu',
              //ikona basıldığında yapılacaklar için
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(milliseconds: 700),
                    width: 300.0,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35.0),
                    ),
                    // mobil uygulama herhangi bir cihaza bağlıysa yazılacak text bağlı değilse yazılacaklar
                    content: _serialPort != null && _serialPort!.isOpen
                        ? Text(
                        "${_serialPort!.manufacturer} CİHAZINA BAĞLI")
                        : const Text('BAĞLANTI YOK'),
                  ),
                );
              },
            ),
          )
        ],
      )
          : null,
      body: SafeArea(
        child: Container(
          color: Colors.blueGrey,
          height: double.infinity,
          child: Column(
            children: <Widget>[
              Expanded(
                flex: 0,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.0),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    border: Border.all(
                      color: _serialPort != null && _serialPort!.isOpen
                          ? Colors.green
                          : Colors.red,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        flex: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 1, vertical: 0.5),
                          child: FloatingActionButton.small(
                            //ekranda iki floatbutton olduğunda hata çıkarıyor engellemek için
                            heroTag: "btn1",
                            //ikonun üzerine mouse ile gelindiğinde çıkan yazı
                            tooltip: 'Portları yinele',
                            //isExtended: true,
                            onPressed: () {
                              setState(() {
                                if (SerialPort.availablePorts.isEmpty) {
                                  debugPrint("port list silindi");
                                  for (int i = 0; i < portList.length; i++) {
                                    portList.removeAt(i);
                                  }
                                }
                                for (final name in SerialPort.availablePorts) {
                                  final sp = SerialPort(name);
                                  bool ayniVarMi = false;
                                  //aynı cihazdan başka varsa tekrar atama yaptırmıyoruz
                                  for (int i = 0; i < portList.length; i++) {
                                    //port isimleri kontrol edilerek aynı var mı diye kontrol ediliyor
                                    if (portList[i].name == name) {
                                      ayniVarMi = true;
                                      debugPrint("aynı çıktı");
                                    }
                                  }
                                  if (ayniVarMi == false) {
                                    debugPrint("sp değeri: $sp");
                                    portList.add(sp);
                                  }
                                }
                                if (portList.isNotEmpty) {
                                  _serialPort = portList.first;
                                } else {
                                  debugPrint("portList boş");
                                }
                              });
                            },
                            backgroundColor: Colors.white,
                            //basılı tutulduğunda görünen renk
                            splashColor: Colors.deepPurpleAccent,
                            focusColor: Colors.red,
                            //mouse ile üzerine geldiğinde değişecek renk
                            hoverColor: Colors.lightGreenAccent,
                            //içerisindeki ikonun beyaz rengini değiştiriyor
                            foregroundColor: Colors.indigo,
                            //floating butonun border rengini ayarlama
                            shape: StadiumBorder(
                                side: BorderSide(
                                    color: _serialPort != null &&
                                        _serialPort!.isOpen
                                        ? Colors.green
                                        : Colors.red,
                                    width: 2)),
                            child: const Icon(Icons.refresh),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 0,
                        child: Column(
                          children: [
                            const YaziGirme(metin: "Port"),
                            Container(
                              width: 270,
                              height: 45,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color:
                                  _serialPort != null && _serialPort!.isOpen
                                      ? Colors.green
                                      : Colors.red,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: DropdownButton(
                                isExpanded: true,
                                //grimsi çizgiyi iptal etmek için
                                underline: Container(),
                                value: _serialPort,
                                hint: const Text("Bağlı bir cihaz yok"),
                                dropdownColor: Colors.grey,
                                focusColor: Colors.pink,
                                iconEnabledColor: Colors.lime,
                                iconDisabledColor: Colors.red,
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(30.0)),
                                items: portList.map((item) {
                                  return DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                          "${item.name}: ${item.description ?? ''}"));
                                }).toList(),
                                onChanged: (e) {
                                  changedDropDownItem(e as SerialPort);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 2.0,
                      ),
                      Expanded(
                        flex: 0,
                        child: Column(
                          children: [
                            const YaziGirme(
                              metin: "Baud Rate",
                            ),
                            Container(
                                height: 35,
                                width: 100,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 0.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: _serialPort != null &&
                                        _serialPort!.isOpen
                                        ? Colors.green
                                        : Colors.red,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: BaudRateSecimi()),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 0,
                        child: Column(
                          children: [
                            const YaziGirme(
                              metin: "Data Bits",
                            ),
                            Container(
                              height: 35,
                              width: 50,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 0.5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color:
                                  _serialPort != null && _serialPort!.isOpen
                                      ? Colors.green
                                      : Colors.red,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: DataBitsSecimi(),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 0,
                        child: Column(
                          children: [
                            const YaziGirme(
                              metin: "Parity",
                            ),
                            Container(
                              height: 35,
                              width: 90,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 0.5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color:
                                  _serialPort != null && _serialPort!.isOpen
                                      ? Colors.green
                                      : Colors.red,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: ParitySecimi(),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 0,
                        child: Column(
                          children: [
                            const YaziGirme(metin: "Stop Bits"),
                            Container(
                              height: 35,
                              width: 50,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 0.5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color:
                                  _serialPort != null && _serialPort!.isOpen
                                      ? Colors.green
                                      : Colors.red,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: StopBitSecimi(),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 0,
                        child: Column(
                          children: [
                            const YaziGirme(metin: "HandShaking"),
                            Container(
                              height: 45,
                              width: 110,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color:
                                  _serialPort != null && _serialPort!.isOpen
                                      ? Colors.green
                                      : Colors.red,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: HandShakingSecimi(),
                            ),
                          ],
                        ),
                      ),
                      const Expanded(
                          flex: 1,
                          child: SizedBox(
                            width: 0.05,
                          )),
                      Expanded(
                        flex: 0,
                        child: Container(
                          width: 55,
                          height: 55,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 2, vertical: 0.5),
                          child: FloatingActionButton(
                            clipBehavior: Clip.antiAlias,
                            //ikonun üzerine mouse ile gelindiğinde çıkan yazı
                            tooltip: _serialPort != null && _serialPort!.isOpen
                                ? "Bağlantıyı Kes"
                                : 'Bağlantı Kur',
                            isExtended: true,
                            onPressed: () {
                              if (_serialPort == null) {
                                return;
                              }
                              if (_serialPort!.isOpen) {
                                _scrolGelenAnahtari = false;
                                _scrolGonderilenAnahtari = false;
                                _serialPort!.close();
                                debugPrint('${_serialPort!.name} closed!');
                              } else {
                                if (_serialPort!
                                    .open(mode: SerialPortMode.readWrite) &&
                                    _serialPort!.isOpen) {
                                  SerialPortConfig config = _serialPort!.config;
                                  // https://www.sigrok.org/api/libserialport/0.1.1/a00007.html#gab14927cf0efee73b59d04a572b688fa0
                                  // https://www.sigrok.org/api/libserialport/0.1.1/a00004_source.html
                                  config.baudRate = _secilenBaudRate;
                                  config.parity = _secilenParity;
                                  config.bits = _secilenDataBits;
                                  config.cts = _secilenCTS;
                                  config.rts = _secilenRTS;
                                  config.stopBits = _secilenStopBits;
                                  config.xonXoff = _secilenXON_XOFF;

                                  _serialPort!.config = config;
                                  if (_serialPort!.isOpen) {
                                    debugPrint('${_serialPort!.name} acildi!');
                                  }

                                  setState(() {});
                                  veri = "";
                                  final reader = SerialPortReader(_serialPort!);

                                  reader.stream.listen((data) {
                                    debugPrint(
                                        "---------------------------------------------------------");
                                    debugPrint('alinan veriler: $data');

                                    for (int i = 0; i < data.length; i++) {
                                      if (data[i] == 10) {
                                        veri =
                                            veri +"\r";
                                        _gelenVeriler.add(veri);
                                        veri = "";
                                      }
                                      if (data[i] != 10) {
                                        veri =
                                            veri + String.fromCharCode(data[i]);
                                        //if (_gelenVeriler.isEmpty) {
                                        // _gelenVeriler.add(veri);
                                        //}
                                        //else {
                                        //  _gelenVeriler[
                                        //  _gelenVeriler.length - 1] = veri;
                                        //}
                                        _gelenVeriSayaci.value++;
                                      }
                                    }

                                    receiveDataList.add(data);

                                    //setState(() {});
                                  }, onError: (error) {
                                    if (error is SerialPortError) {
                                      debugPrint(
                                          'error: ${error.message}, code: ${error.errorCode}');
                                    }
                                  });
                                }
                              }
                              debugPrint("ekran tekrar çizdirldi");
                              setState(() {});
                            },
                            backgroundColor: Colors.white,
                            //basılı tutulduğunda görünen renk
                            splashColor: Colors.deepPurpleAccent,
                            focusColor: Colors.red,
                            //mouse ile üzerine geldiğinde değişecek renk
                            hoverColor:
                            _serialPort != null && _serialPort!.isOpen
                                ? Colors.redAccent
                                : Colors.lightGreenAccent,
                            //içerisindeki ikonun beyaz rengini değiştiriyor
                            foregroundColor: Colors.indigo,
                            //floating butonun border rengini ayarlama
                            shape: StadiumBorder(
                                side: BorderSide(
                                    color: _serialPort != null &&
                                        _serialPort!.isOpen
                                        ? Colors.green
                                        : Colors.red,
                                    width: 2)),
                            child: Icon(
                                _serialPort != null && _serialPort!.isOpen
                                    ? Icons.usb_off
                                    : Icons.usb,
                                color:
                                _serialPort != null && _serialPort!.isOpen
                                    ? Colors.red
                                    : Colors.green),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 0,
                child: Container(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 2.0, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    border: Border.all(
                      color: _serialPort != null && _serialPort!.isOpen
                          ? Colors.green
                          : Colors.red,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: GelenVerilerTile(),
                ),
              ),
              Expanded(
                flex: 4,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    side: BorderSide(
                      color: _serialPort != null && _serialPort!.isOpen
                          ? Colors.green
                          : Colors.red,
                      width: 2.0,
                    ),
                  ),
                  margin: const EdgeInsets.only(
                      left: 4.0, right: 4.0, bottom: 2.0, top: 1),
                  child: ValueListenableBuilder<int>(
                      valueListenable: _gelenVeriSayaci,
                      builder: (_, value, __) => GelenVerilerListesi()),
                ),
              ),
              Expanded(
                flex: 0,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.0),
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    border: Border.all(
                      color: _serialPort != null && _serialPort!.isOpen
                          ? Colors.green
                          : Colors.red,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: GonderilenVerilerTile(),
                ),
              ),
              Expanded(
                flex: 4,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    side: BorderSide(
                      color: _serialPort != null && _serialPort!.isOpen
                          ? Colors.green
                          : Colors.red,
                      width: 2.0,
                    ),
                  ),
                  margin: const EdgeInsets.only(
                      left: 4.0, right: 4.0, bottom: 2, top: 2),
                  //widgettaki bildirimleri dinlemek için NotificationListener kullanıldı
                  child: ValueListenableBuilder<int>(
                      valueListenable: _gonderilenVeriSayaci,
                      builder: (_, value, __) => GonderilenVerilerListesi()),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 0.0),
                decoration: const BoxDecoration(
                  color: Colors.indigo,
                  //border: Border.all(
                  //  width: 1,
                  //  color: _serialPort != null && _serialPort!.isOpen
                  //      ? Colors.green
                  //      : Colors.red,
                  //),
                  //borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  //mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 3.0,
                          horizontal: 2.0,
                        ),
                        child: VeriGondermeTextAlani(),
                      ),
                    ),
                    Expanded(
                      flex: 0,
                      child: TextButton.icon(
                        onPressed: (_serialPort != null && _serialPort!.isOpen)
                            ? () {
                          VeriGonder();
                          //setState(() {});
                        }
                            : null,
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text(
                          "Gönder",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        const YaziGirme(
                          metin: "CR+LF",
                        ),
                        Checkbox(
                          side: const BorderSide(color: Colors.red, width: 2),
                          hoverColor: Colors.lightGreenAccent,
                          checkColor: Colors.white,
                          activeColor: Colors.green,
                          value: boslukKontrol,
                          onChanged: (bool? value) {
                            setState(() {
                              boslukKontrol = value!;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      flex: 1,
                      child: ValueListenableBuilder(
                        valueListenable: _m1Sayaci,
                        builder: (context, value, _) {
                          return M1Macrosu();
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      flex: 1,
                      child: ValueListenableBuilder(
                        valueListenable: _m2Sayaci,
                        builder: (context, value, _) {
                          return M2Macrosu();
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      flex: 1,
                      child: ValueListenableBuilder(
                        valueListenable: _m3Sayaci,
                        builder: (context, value, _) {
                          return M3Macrosu();
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      flex: 1,
                      child: ValueListenableBuilder(
                        valueListenable: _m4Sayaci,
                        builder: (context, value, _) {
                          return M4Macrosu();
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      flex: 1,
                      child: ValueListenableBuilder(
                        valueListenable: _m5Sayaci,
                        builder: (context, value, _) {
                          return M5Macrosu();
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      flex: 1,
                      child: ValueListenableBuilder(
                        valueListenable: _m6Sayaci,
                        builder: (context, value, _) {
                          return M6Macrosu();
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//macro veri boş uyarı mesajı
Future uyariMesaji(String veri, context) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(35),
      ),
      title: const Text(
        "HATA",
        style: TextStyle(color: Colors.red),
      ),
      content: Text("$veri Veri Alanı Boş"),
      actions: <Widget>[
        ElevatedButton(
          style: butonGorsel1,
          onPressed: () {
            Navigator.of(ctx).pop();
          },
          child: const Text("Tamam"),
        ),
      ],
    ),
  );
}

//macro veri girme alanı
int simdikiDeger = 0;

bool _uzunBasmayiBirakti = false;
Future<String?> _showTextInputDialog(BuildContext context) async {
  //DENEME

  return showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(35),
              side: BorderSide(
                  color: (_serialPort != null && _serialPort!.isOpen)
                      ? Colors.green
                      : Colors.red,
                  width: 2)),
          title: Column(
            children: const [
              Text('Macro Ayarlaması', style: TextStyle(color: Colors.indigo)),
              Divider(
                thickness: 2.0,
                height: 20,
                color: Colors.indigo,
              ),
            ],
          ),
          insetPadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.all(5.0),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          content: StatefulBuilder(
            builder: (BuildContext context, setState) {
              // Get available height and width of the build area of this widget. Make a choice depending on the size.
              void _sureArttir(TextEditingController macroSayaci) {
                simdikiDeger = int.parse(macroSayaci.text);
                setState(() {
                  simdikiDeger++;
                  macroSayaci.text =
                      (simdikiDeger).toString(); // incrementing value
                });
              }

              void _sureAzalt(TextEditingController macroSayaci) {
                simdikiDeger = int.parse(macroSayaci.text);
                setState(() {
                  simdikiDeger--;
                  if (simdikiDeger <= 0) {
                    simdikiDeger = 1;
                  }
                  macroSayaci.text =
                      (simdikiDeger).toString(); // incrementing value
                });
              }

              void _ArttirmaAzaltmayiBirak() {
                if (_timer != null) {
                  print("cancel timer durduruludu ");
                  _timer!.cancel();
                }

                _uzunBasmayiBirakti = true;
              }

              return SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                width: MediaQuery.of(context).size.width - 400,
                child: ListView(
                  children: [
                    ShowDialogMacrolari(
                      macroKac: "1",
                      mSure: m1SureKontrol,
                      mVeri: m1VeriKontrol,
                      mSureArttir: _sureArttir,
                      mSureAzalt: _sureAzalt,
                      mSureArtAzaltBirak: _ArttirmaAzaltmayiBirak,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ShowDialogMacrolari(
                      macroKac: "2",
                      mSure: m2SureKontrol,
                      mVeri: m2VeriKontrol,
                      mSureArttir: _sureArttir,
                      mSureAzalt: _sureAzalt,
                      mSureArtAzaltBirak: _ArttirmaAzaltmayiBirak,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ShowDialogMacrolari(
                      macroKac: "3",
                      mSure: m3SureKontrol,
                      mVeri: m3VeriKontrol,
                      mSureArttir: _sureArttir,
                      mSureAzalt: _sureAzalt,
                      mSureArtAzaltBirak: _ArttirmaAzaltmayiBirak,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ShowDialogMacrolari(
                      macroKac: "4",
                      mSure: m4SureKontrol,
                      mVeri: m4VeriKontrol,
                      mSureArttir: _sureArttir,
                      mSureAzalt: _sureAzalt,
                      mSureArtAzaltBirak: _ArttirmaAzaltmayiBirak,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ShowDialogMacrolari(
                      macroKac: "5",
                      mSure: m5SureKontrol,
                      mVeri: m5VeriKontrol,
                      mSureArttir: _sureArttir,
                      mSureAzalt: _sureAzalt,
                      mSureArtAzaltBirak: _ArttirmaAzaltmayiBirak,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ShowDialogMacrolari(
                      macroKac: "6",
                      mSure: m6SureKontrol,
                      mVeri: m6VeriKontrol,
                      mSureArttir: _sureArttir,
                      mSureAzalt: _sureAzalt,
                      mSureArtAzaltBirak: _ArttirmaAzaltmayiBirak,
                    ),
                    const SizedBox(
                      width: 50,
                      height: 20,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            ElevatedButton(
              style: butonGorsel1,
              child: const Text("Kapat"),
              onPressed: () {
                Navigator.pop(context);
              }, //Yapılacak işlem buraya yazılacak
            ),
            ElevatedButton(
              style: butonGorsel2,
              child: const Text('Tamam'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(
              width: 2,
            )
          ],
        );
      });
    },
  );
}

Timer? _timer;

class ShowDialogMacrolari extends StatelessWidget {
  ShowDialogMacrolari({
    super.key,
    required this.macroKac,
    required this.mSure,
    required this.mVeri,
    required this.mSureArttir,
    required this.mSureAzalt,
    required this.mSureArtAzaltBirak,
  });
  final String macroKac;
  final TextEditingController mSure;
  final TextEditingController mVeri;
  final Function mSureArttir;
  final Function mSureAzalt;
  final Function mSureArtAzaltBirak;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  flex: 1,
                  //özel yapılan spin number giriş
                  child: TextFormField(
                    onEditingComplete: () {
                      _m1VeriNode.requestFocus();
                    },
                    controller: mSure,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(50.0)),
                        borderSide:
                        BorderSide(color: Colors.indigo, width: 2.0),
                      ),
                      contentPadding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(50),
                        ),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: false, signed: false),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    GestureDetector(
                      child: Container(
                        margin: EdgeInsets.all(1.0),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(
                              Radius.circular(15.0),
                            ),
                            border: Border.all(color: Colors.indigo)),
                        padding: EdgeInsets.all(1),
                        //color: Colors.white,
                        child: const Icon(Icons.keyboard_arrow_up,
                            color: Colors.green),
                      ),
                      onTap: () {
                        mSureArttir(mSure);
                      },
                      onLongPressEnd:
                          (LongPressEndDetails _uzunBasmayiBiraktiBilgisi) {
                        mSureArtAzaltBirak();
                      },
                      onLongPress: () {
                        _uzunBasmayiBirakti = false;
                        Future.delayed(Duration(milliseconds: 200), () {
                          if (!_uzunBasmayiBirakti) {
                            _timer = Timer.periodic(Duration(milliseconds: 10),
                                    (timer) {
                                  mSureArttir(mSure);
                                });
                          }
                        });
                      },
                      onLongPressUp: () {
                        mSureArtAzaltBirak();
                      },
                      onLongPressMoveUpdate: (LongPressMoveUpdateDetails
                      _uzunBasmayaBasladiBilgisi) {
                        if (_uzunBasmayaBasladiBilgisi
                            .localOffsetFromOrigin.distance >
                            20) {
                          mSureArtAzaltBirak();
                        }
                      },
                    ),
                    GestureDetector(
                      child: Container(
                        margin: EdgeInsets.all(1.0),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(
                              Radius.circular(15.0),
                            ),
                            border: Border.all(color: Colors.indigo)),
                        padding: EdgeInsets.all(1),
                        //color: Colors.white,
                        child: const Icon(Icons.keyboard_arrow_down,
                            color: Colors.red),
                      ),
                      onTap: () {
                        mSureAzalt(mSure);
                      },
                      onLongPressEnd:
                          (LongPressEndDetails _uzunBasmayiBiraktiBilgisi) {
                        mSureArtAzaltBirak();
                      },
                      onLongPress: () {
                        _uzunBasmayiBirakti = false;
                        Future.delayed(Duration(milliseconds: 200), () {
                          if (!_uzunBasmayiBirakti) {
                            _timer = Timer.periodic(Duration(milliseconds: 10),
                                    (timer) {
                                  mSureAzalt(mSure);
                                });
                          }
                        });
                      },
                      onLongPressUp: () {
                        mSureArtAzaltBirak();
                      },
                      onLongPressMoveUpdate: (LongPressMoveUpdateDetails
                      _uzunBasmayaBasladiBilgisi) {
                        if (_uzunBasmayaBasladiBilgisi
                            .localOffsetFromOrigin.distance >
                            20) {
                          mSureArtAzaltBirak();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: TextField(
            //focusNode: _m1VeriNode,
            controller: mVeri,
            //textfield ın içerisine yazılacak olan yazıyı ortaya yazmak için
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(50.0)),
                borderSide: BorderSide(color: Colors.indigo, width: 2.0),
              ),
              contentPadding:
              const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(50),
                ),
              ),
              labelText: mVeri.text.isEmpty
                  ? "M$macroKac: Veri Girin"
                  : "M$macroKac:  ${mVeri.text}",
            ),
            onSubmitted: (text) {
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }
}

class YaziGirme extends StatelessWidget {
  const YaziGirme({super.key, this.metin});

  final String? metin;
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Center(
        child: Text(
          "$metin",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
      ),
    ]);
  }
}

class BaudRateSecimi extends StatefulWidget {
  const BaudRateSecimi({super.key});

  @override
  State<BaudRateSecimi> createState() => _BaudRateSecimiDurumu();
}

class _BaudRateSecimiDurumu extends State<BaudRateSecimi> {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
        isExpanded: true,

        //grimsi çizgiyi iptal etmek için
        underline: Container(),
        borderRadius: const BorderRadius.all(Radius.circular(30.0)),
        hint: const Text("Baud Rate"),
        value: _secilenBaudRate,
        items: <int>[
          600,
          1200,
          2400,
          4800,
          9600,
          14400,
          19200,
          28800,
          38400,
          56000,
          57600,
          115200,
          128000,
        ].map((int value) {
          return DropdownMenuItem<int>(
            value: value,
            child: Text(value.toString()),
          );
        }).toList(),
        onChanged: (yeniDeger) {
          _secilenBaudRate = yeniDeger!;
          debugPrint("secilen değer: $yeniDeger");
          setState(() {});
        });
  }
}

class DataBitsSecimi extends StatefulWidget {
  const DataBitsSecimi({super.key});

  @override
  State<DataBitsSecimi> createState() => _DataBitsSecimiDurumu();
}

class _DataBitsSecimiDurumu extends State<DataBitsSecimi> {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
        isExpanded: true,
        dropdownColor: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(30.0)),
        //grimsi çizgiyi iptal etmek için
        underline: Container(),
        hint: const Text("Data Bits"),
        value: _secilenDataBits,
        items: <int>[5, 6, 7, 8].map((int value) {
          return DropdownMenuItem<int>(
            value: value,
            child: Text(value.toString()),
          );
        }).toList(),
        onChanged: (yeniDeger) {
          setState(() {
            _secilenDataBits = yeniDeger!;
            debugPrint("secilen değer: $yeniDeger");
          });
        });
  }
}

class ParitySecimi extends StatefulWidget {
  const ParitySecimi({super.key});

  @override
  State<ParitySecimi> createState() => _ParitySecimiDurumu();
}

class _ParitySecimiDurumu extends State<ParitySecimi> {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
        isExpanded: true,
        dropdownColor: Colors.white,
        value: _secilenStringParity,
        borderRadius: const BorderRadius.all(Radius.circular(30.0)),
        //grimsi çizgiyi iptal etmek için
        underline: Container(),
        hint: const Text("Parity"),
        items: <String>["None", "Even", "Odd"].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value.toString()),
          );
        }).toList(),
        onChanged: (yeniDeger) {
          setState(() {
            if (yeniDeger == "None") {
              _secilenStringParity = "None";
              _secilenParity = 0;
            } else if (yeniDeger == "Even") {
              _secilenStringParity = "Even";
              _secilenParity = 1;
            } else if (yeniDeger == "Odd") {
              _secilenStringParity = "Odd";
              _secilenParity = 2;
            }
            debugPrint("secilen değer: $_secilenParity");
          });
        });
  }
}

class StopBitSecimi extends StatefulWidget {
  const StopBitSecimi({super.key});

  @override
  State<StopBitSecimi> createState() => _StopBitSecimiDurumu();
}

class _StopBitSecimiDurumu extends State<StopBitSecimi> {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
        isExpanded: true,
        dropdownColor: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(30.0)),
        //grimsi çizgiyi iptal etmek için
        underline: Container(),
        hint: const Text("Stop Bits"),
        value: _secilenStopBits,
        items: <int>[1, 2].map((int value) {
          return DropdownMenuItem<int>(
            value: value,
            child: Text(value.toString()),
          );
        }).toList(),
        onChanged: (yeniDeger) {
          setState(() {
            _secilenStopBits = yeniDeger!;
            debugPrint("secilen değer: $yeniDeger");
          });
        });
  }
}

class HandShakingSecimi extends StatefulWidget {
  const HandShakingSecimi({super.key});

  @override
  State<HandShakingSecimi> createState() => _HandShakingSecimiState();
}

class _HandShakingSecimiState extends State<HandShakingSecimi> {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
        isExpanded: true,
        value: _secilenHandShaking,
        dropdownColor: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(30.0)),
        //grimsi çizgiyi iptal etmek için
        underline: Container(),
        hint: const Text("HandShaking"),
        items: <String>[
          "None",
          "RTS/CTS",
          "XON/XOFF",
          "RTS/CTS+XON/XOFF",
        ].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value.toString()),
          );
        }).toList(),
        onChanged: (yeniDeger) {
          if (yeniDeger == "None") {
            _secilenHandShaking = "None";
            _secilenRTS = 0;
            _secilenCTS = 0;
            _secilenXON_XOFF = 0;
          } else if (yeniDeger == "RTS/CTS") {
            _secilenHandShaking = "RTS/CTS";
            _secilenRTS = 1;
            _secilenCTS = 1;
            _secilenXON_XOFF = 0;
          } else if (yeniDeger == "XON/XOFF") {
            _secilenHandShaking = "XON/XOFF";
            _secilenRTS = 0;
            _secilenCTS = 0;
            _secilenXON_XOFF = 1;
          } else if (yeniDeger == "RTS/CTS+XON/XOFF") {
            _secilenHandShaking = "RTS/CTS+XON/XOFF";
            _secilenRTS = 1;
            _secilenCTS = 1;
            _secilenXON_XOFF = 1;
          }
          setState(() {});
          debugPrint("secilen CTS değeri: $_secilenCTS");
          debugPrint("secilen RTS değeri: $_secilenRTS");
          debugPrint("secilen XON_XOFF değeri: $_secilenXON_XOFF");
        });
  }
}

class GelenVerilerTile extends StatefulWidget {
  const GelenVerilerTile({super.key});

  @override
  State<GelenVerilerTile> createState() => _GelenVerilerTileState();
}

class _GelenVerilerTileState extends State<GelenVerilerTile> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      title: const Text("Okunan Veriler "),
      textColor: Colors.white,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: const EdgeInsets.all(4.0),
            icon: Icon(Icons.keyboard_double_arrow_down,
                color: _scrolGelenAnahtari &&
                    (_serialPort != null && _serialPort!.isOpen)
                    ? Colors.green
                    : Colors.red, //true ise bu çalışır
                size: 35.0),
            tooltip: "Gelen verilerdeki Scroll'u otomatik aşağıya indir",
            onPressed: (_serialPort != null && _serialPort!.isOpen)
                ? () {
              _scrolGelenAnahtari = !_scrolGelenAnahtari;
              setState(() {});
            }
                : null,
          ),
          IconButton(
            padding: const EdgeInsets.all(4.0),
            icon: const Icon(Icons.delete_forever_rounded,
                color: Colors.white, size: 35.0),
            tooltip: 'Gelen verileri temizleyin.',
            onPressed: () {
              _gelenVeriSayaci.value = 0;
              //gönderilen verileri ekrandan silmek için
              if (receiveDataList.isNotEmpty || _gelenVeriler.isNotEmpty) {
                for (int i = receiveDataList.length - 1; i >= 0; i--) {
                  receiveDataList.removeAt(i);
                }
                for (int i = _gelenVeriler.length - 1; i >= 0; i--) {
                  _gelenVeriler.removeAt(i);
                }
              }

              //ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              //    duration: const Duration(milliseconds: 400),
              //    width: 210.0,
              //    // Width of the SnackBar.
              //    behavior: SnackBarBehavior.floating,
              //    shape: RoundedRectangleBorder(
              //      borderRadius: BorderRadius.circular(35.0),
              //    ),
              //    content: const Text("GELEN VERİLER TEMİZLENDİ")));
            },
          ),
        ],
      ),
    );
  }
}

class GelenVerilerListesi extends StatelessWidget {
  const GelenVerilerListesi({super.key});

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotification: (bildirim) {
        return true;
      },
      child: ListView.builder(
        controller: _gelenVerilerKontrol,
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: _gelenVeriler.length,
        itemBuilder: (context, index) {
          var mesaj = "";
          mesaj = _gelenVeriler[index];
          if (_scrolGelenAnahtari) {
            if (_scrolGelenAnahtari &&
                (_gelenVerilerKontrol.position.pixels !=
                    _gelenVerilerKontrol.position.maxScrollExtent)) {
              _gelenVerilerKontrol
                  .jumpTo(_gelenVerilerKontrol.position.maxScrollExtent);
            }
          }
          /*
                          OUTPUT for raw bytes
                          return Text(receiveDataList[index].toString());
                          */
          /* output for string */
          return Dismissible(
            //alttaki yorum satırı olan key de hata veriyor.
            //key: Key(mesaj),
            key: UniqueKey(),

            onDismissed: (direction) {
              //mesaj listTile dan mesajı siler.
              _gelenVeriSayaci.value--;
              _gelenVeriler.removeAt(index);
            },
            //mesajı kaydırılırken kırmızı bir arka plan gösterir.
            background: Container(color: Colors.red),
            //mesajı göster
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    mesaj,
                    style: const TextStyle(
                        fontSize: 16.0,
                        backgroundColor: Colors.white,
                        color: Colors.black),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class GonderilenVerilerTile extends StatefulWidget {
  const GonderilenVerilerTile({super.key});

  @override
  State<GonderilenVerilerTile> createState() => _GonderilenVerilerTileDurumu();
}

class _GonderilenVerilerTileDurumu extends State<GonderilenVerilerTile> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      title: const Text("Gönderilen Veriler"),
      tileColor: Colors.indigo,
      textColor: Colors.white,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: const EdgeInsets.all(4.0),
            icon: const Icon(Icons.table_rows_rounded,
                color: Colors.white, //true ise bu çalışır
                size: 35.0),
            tooltip: 'Macro Ayarlamalarını Yapın',
            onPressed: () async {
              await _showTextInputDialog(context);
              if (m1VeriKontrol.text.isNotEmpty) {
                debugPrint("sonuc: ${m1VeriKontrol.text}");
              } else {
                debugPrint("macro m1 boş");
              }
            },
          ),
          IconButton(
            padding: const EdgeInsets.all(4.0),
            icon: Icon(Icons.keyboard_double_arrow_down,
                color: _scrolGonderilenAnahtari &&
                    (_serialPort != null && _serialPort!.isOpen)
                    ? Colors.green
                    : Colors.red, //true ise bu çalışır
                size: 35.0),
            tooltip: "Gönderilen verilerdeki Scroll'u otomatik aşağıya indir",
            onPressed: (_serialPort != null && _serialPort!.isOpen)
                ? () {
              _scrolGonderilenAnahtari = !_scrolGonderilenAnahtari;
              setState(() {});
            }
                : null,
          ),
          IconButton(
            padding: const EdgeInsets.all(4.0),
            icon: const Icon(Icons.delete_forever_rounded,
                color: Colors.white, //true ise bu çalışır
                size: 35.0),
            tooltip: 'Gönderilen verileri temizleyin.',
            onPressed: () {
              //gönderilen verileri ekrandan silmek için
              if (_gonderilenVeriler.isNotEmpty) {
                for (int i = _gonderilenVeriler.length - 1; i >= 0; i--) {
                  _gonderilenVeriler.removeAt(i);
                }
              }
              _gonderilenVeriSayaci.value = 0;

              //ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              //    duration: const Duration(milliseconds: 400),
              //    width: 250.0,
              //    // Width of the SnackBar.
              //    behavior: SnackBarBehavior.floating,
              //    shape: RoundedRectangleBorder(
              //      borderRadius: BorderRadius.circular(35.0),
              //    ),
              //    content: const Text("GÖNDERİLEN VERİLER TEMİZLENDİ")));
            },
          ),
        ],
      ),
    );
  }
}

class GonderilenVerilerListesi extends StatelessWidget {
  const GonderilenVerilerListesi({super.key});

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotification: (bildirim) {
        return true;
      },
      child: ListView.builder(
        controller: _gonderilenVerilerKontrol,
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: _gonderilenVeriler.length,
        itemBuilder: (context, index) {
          var mesaj = '';
          mesaj = _gonderilenVeriler[index];
          if (_scrolGonderilenAnahtari) {
            // //şuanki scrol konumu ile en son scrol konumu kontrol edildikten sonra scrolu aşağı indirme çalışıyor
            if (_scrolGonderilenAnahtari &&
                (_gonderilenVerilerKontrol.position.pixels !=
                    _gonderilenVerilerKontrol.position.maxScrollExtent)) {
              _gonderilenVerilerKontrol
                  .jumpTo(_gonderilenVerilerKontrol.position.maxScrollExtent);
            }
          }
          return Dismissible(
            //alttaki yorum satırı olan key de hata veriyor.
            //key: Key(mesaj),
            key: UniqueKey(),
            onDismissed: (direction) {
              //mesaj listTile dan mesajı siler.

              _gonderilenVeriler.removeAt(index);
              _gonderilenVeriSayaci.value--;
            },
            //mesajı kaydırılırken kırmızı bir arka plan gösterir.
            background: Container(color: Colors.red),
            child: Row(
              children: [
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    mesaj,
                    style: const TextStyle(
                        fontSize: 16.0,
                        backgroundColor: Colors.white,
                        color: Colors.black),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class VeriGondermeTextAlani extends StatefulWidget {
  const VeriGondermeTextAlani({super.key});

  @override
  State<VeriGondermeTextAlani> createState() => _VeriGondermeTextAlaniDurumu();
}

class _VeriGondermeTextAlaniDurumu extends State<VeriGondermeTextAlani> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: (_serialPort != null && _serialPort!.isOpen) ? true : false,
      controller: _veriGondermeText,
      focusNode: _veriGondermeFocusu,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(50.0)),
          borderSide: BorderSide(color: Colors.green, width: 2.0),
        ),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(50),
          ),
        ),
        labelText: "Veri Gönder",
        labelStyle: TextStyle(
            color: (_serialPort != null && _serialPort!.isOpen)
                ? Colors.green
                : Colors.red,
            backgroundColor: Colors.white),
      ),
      onSubmitted: (text) {
        VeriGonder();
        _veriGondermeFocusu.requestFocus();
        //setState(() {});
      },
    );
  }
}

class M1Macrosu extends StatefulWidget {
  const M1Macrosu({super.key});

  @override
  State<M1Macrosu> createState() => _M1MacrosuDurumu();
}

class _M1MacrosuDurumu extends State<M1Macrosu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65,
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: (_serialPort != null && _serialPort!.isOpen)
            ? Colors.white
            : Colors.red,
        boxShadow: [
          BoxShadow(
              color: m1Anahtar ? Colors.green : Colors.red, spreadRadius: 2),
        ],
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.indigo,
          padding: const EdgeInsets.all(1.0),
        ),
        onPressed: (_serialPort != null && _serialPort!.isOpen)
            ? () {
          m1Anahtar = !m1Anahtar;

          if (m1Anahtar == true) {
            timer1 = Timer.periodic(
              Duration(milliseconds: int.parse(m1SureKontrol.text)),
                  (timer) {
                //kart ile haberleşmeyi bitirdiğimizde göndermeye devam ediyordu bunla göndermeyi kesiyoruz.
                if (!(_serialPort != null && _serialPort!.isOpen) ||
                    m1VeriKontrol.text.isEmpty) {
                  debugPrint("timer kapatıldı.");
                  timer.cancel();
                  m1Anahtar = false;
                }

                /// callback will be executed every 1 second, increament a count value
                /// on each callback
                /// Süre zarfında yapılacak işlem

                if (m1VeriKontrol.text.isNotEmpty) {
                  if (_serialPort!.write(Uint8List.fromList(
                      m1VeriKontrol.text.codeUnits)) ==
                      m1VeriKontrol.text.codeUnits.length) {
                    _gonderilenVeriler.add(m1VeriKontrol.text);
                    _m1Sayaci.value++;
                    _gonderilenVeriSayaci.value++;
                  }
                } else {
                  m1Anahtar = false;
                  uyariMesaji("Macro 1' in", context);
                  //bunu yazmayınca birsürü showdialog açıyor
                  timer.cancel();
                  setState(() {});
                }
              },
            );
          } else {
            timer1!.cancel();
          }
          setState(() {});
        }
            : null,
        onLongPress: () {
          _m1Sayaci.value = 0;
        },
        child: Text(
          'M1: ${_m1Sayaci.value}',
          style: const TextStyle(fontSize: 10, color: Colors.indigo),
        ),
      ),
    );
  }
}

class M2Macrosu extends StatefulWidget {
  const M2Macrosu({super.key});

  @override
  State<M2Macrosu> createState() => _M2MacrosuDurumu();
}

class _M2MacrosuDurumu extends State<M2Macrosu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65,
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: (_serialPort != null && _serialPort!.isOpen)
            ? Colors.white
            : Colors.red,
        boxShadow: [
          BoxShadow(
              color: m2Anahtar ? Colors.green : Colors.red, spreadRadius: 2),
        ],
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.indigo,
          padding: const EdgeInsets.all(1.0),
        ),
        onPressed: (_serialPort != null && _serialPort!.isOpen)
            ? () {
          m2Anahtar = !m2Anahtar;

          if (m2Anahtar == true) {
            timer2 = Timer.periodic(
              Duration(milliseconds: int.parse(m2SureKontrol.text)),
                  (timer) {
                //kart ile haberleşmeyi bitirdiğimizde göndermeye devam ediyordu bunla göndermeyi kesiyoruz.
                if (!(_serialPort != null && _serialPort!.isOpen)) {
                  debugPrint("timer kapatıldı.");
                  timer.cancel();
                  m2Anahtar = false;
                }

                /// Süre zarfında yapılacak işlem

                if (m2VeriKontrol.text.isNotEmpty) {
                  if (_serialPort!.write(Uint8List.fromList(
                      m2VeriKontrol.text.codeUnits)) ==
                      m2VeriKontrol.text.codeUnits.length) {
                    _gonderilenVeriler.add(m2VeriKontrol.text);
                    _m2Sayaci.value++;
                    _gonderilenVeriSayaci.value++;
                  }
                } else {
                  m2Anahtar = false;
                  uyariMesaji("Macro 2' nin", context);
                  //bunu yazmayınca birsürü showdialog açıyor
                  timer.cancel();
                  //stateful widget yaparsan aşağıdakini yorumdan kaldır
                  setState(() {});
                }
              },
            );
          } else {
            timer2!.cancel();
          }
          //stateful widget yaparsan aşağıdakini yorumdan kaldır
          setState(() {});
        }
            : null,
        onLongPress: () {
          _m2Sayaci.value = 0;
        },
        child: Text(
          'M2: ${_m2Sayaci.value}',
          style: const TextStyle(fontSize: 10, color: Colors.indigo),
        ),
      ),
    );
  }
}

class M3Macrosu extends StatefulWidget {
  M3Macrosu({super.key});

  @override
  State<M3Macrosu> createState() => _M3MacrosuDurumu();
}

class _M3MacrosuDurumu extends State<M3Macrosu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65,
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: (_serialPort != null && _serialPort!.isOpen)
            ? Colors.white
            : Colors.red,
        boxShadow: [
          BoxShadow(
              color: m3Anahtar ? Colors.green : Colors.red, spreadRadius: 2),
        ],
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.indigo,
          padding: const EdgeInsets.all(1.0),
        ),
        onPressed: (_serialPort != null && _serialPort!.isOpen)
            ? () {
          m3Anahtar = !m3Anahtar;

          if (m3Anahtar == true) {
            timer3 = Timer.periodic(
              Duration(milliseconds: int.parse(m3SureKontrol.text)),
                  (timer) {
                //kart ile haberleşmeyi bitirdiğimizde göndermeye devam ediyordu bunla göndermeyi kesiyoruz.
                if (!(_serialPort != null && _serialPort!.isOpen)) {
                  debugPrint("timer kapatıldı.");
                  timer.cancel();
                  m3Anahtar = false;
                }

                /// callback will be executed every 1 second, increament a count value
                /// on each callback
                /// Süre zarfında yapılacak işlem

                if (m3VeriKontrol.text.isNotEmpty) {
                  if (_serialPort!.write(Uint8List.fromList(
                      m3VeriKontrol.text.codeUnits)) ==
                      m3VeriKontrol.text.codeUnits.length) {
                    _gonderilenVeriler.add(m3VeriKontrol.text);
                    _m3Sayaci.value++;
                    _gonderilenVeriSayaci.value++;
                  }
                } else {
                  m3Anahtar = false;
                  uyariMesaji("Macro 3' ün", context);
                  //bunu yazmayınca birsürü showdialog açıyor
                  timer.cancel();
                  setState(() {});
                }
              },
            );
          } else {
            timer3!.cancel();
          }
          setState(() {});
        }
            : null,
        onLongPress: () {
          _m3Sayaci.value = 0;
        },
        child: Text(
          'M3: ${_m3Sayaci.value}',
          style: const TextStyle(fontSize: 10, color: Colors.indigo),
        ),
      ),
    );
  }
}

class M4Macrosu extends StatefulWidget {
  const M4Macrosu({super.key});

  @override
  State<M4Macrosu> createState() => _M4MacrosuDurumu();
}

class _M4MacrosuDurumu extends State<M4Macrosu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65,
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: (_serialPort != null && _serialPort!.isOpen)
            ? Colors.white
            : Colors.red,
        boxShadow: [
          BoxShadow(
              color: m4Anahtar ? Colors.green : Colors.red, spreadRadius: 2),
        ],
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.indigo,
          padding: const EdgeInsets.all(1.0),
        ),
        onPressed: (_serialPort != null && _serialPort!.isOpen)
            ? () async {
          m4Anahtar = !m4Anahtar;

          if (m4Anahtar == true) {
            timer4 = Timer.periodic(
              Duration(milliseconds: int.parse(m4SureKontrol.text)),
                  (timer) {
                //kart ile haberleşmeyi bitirdiğimizde göndermeye devam ediyordu bunla göndermeyi kesiyoruz.
                if (!(_serialPort != null && _serialPort!.isOpen)) {
                  debugPrint("timer kapatıldı.");
                  timer.cancel();
                  m4Anahtar = false;
                }

                /// callback will be executed every 1 second, increament a count value
                /// on each callback
                /// Süre zarfında yapılacak işlem

                if (m4VeriKontrol.text.isNotEmpty) {
                  if (_serialPort!.write(Uint8List.fromList(
                      m4VeriKontrol.text.codeUnits)) ==
                      m4VeriKontrol.text.codeUnits.length) {
                    _gonderilenVeriler.add(m4VeriKontrol.text);
                    _m4Sayaci.value++;
                    _gonderilenVeriSayaci.value++;
                  }
                } else {
                  m4Anahtar = false;
                  uyariMesaji("Macro 4' ün", context);
                  //bunu yazmayınca birsürü showdialog açıyor
                  timer.cancel();
                  setState(() {});
                }
              },
            );
          } else {
            timer4!.cancel();
          }
          setState(() {});
        }
            : null,
        onLongPress: () {
          _m4Sayaci.value = 0;
        },
        child: Text(
          'M4: ${_m4Sayaci.value}',
          style: const TextStyle(fontSize: 10, color: Colors.indigo),
        ),
      ),
    );
  }
}

class M5Macrosu extends StatefulWidget {
  const M5Macrosu({super.key});

  @override
  State<M5Macrosu> createState() => _M5MacrosuDurumu();
}

class _M5MacrosuDurumu extends State<M5Macrosu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65,
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: (_serialPort != null && _serialPort!.isOpen)
            ? Colors.white
            : Colors.red,
        boxShadow: [
          BoxShadow(
              color: m5Anahtar ? Colors.green : Colors.red, spreadRadius: 2),
        ],
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.indigo,
          padding: const EdgeInsets.all(1.0),
        ),
        onPressed: (_serialPort != null && _serialPort!.isOpen)
            ? () {
          m5Anahtar = !m5Anahtar;

          if (m5Anahtar == true) {
            timer5 = Timer.periodic(
              Duration(milliseconds: int.parse(m5SureKontrol.text)),
                  (timer) {
                //kart ile haberleşmeyi bitirdiğimizde göndermeye devam ediyordu bunla göndermeyi kesiyoruz.
                if (!(_serialPort != null && _serialPort!.isOpen)) {
                  debugPrint("timer kapatıldı.");
                  timer.cancel();
                  m5Anahtar = false;
                }

                /// callback will be executed every 1 second, increament a count value
                /// on each callback
                /// Süre zarfında yapılacak işlem

                if (m5VeriKontrol.text.isNotEmpty) {
                  if (_serialPort!.write(Uint8List.fromList(
                      m5VeriKontrol.text.codeUnits)) ==
                      m5VeriKontrol.text.codeUnits.length) {
                    _gonderilenVeriler.add(m5VeriKontrol.text);
                    _m5Sayaci.value++;
                    _gonderilenVeriSayaci.value++;
                  }
                } else {
                  m5Anahtar = false;
                  uyariMesaji("Macro 5' in", context);
                  //bunu yazmayınca birsürü showdialog açıyor
                  timer.cancel();
                  setState(() {});
                }
              },
            );
          } else {
            timer5!.cancel();
          }
          setState(() {});
        }
            : null,
        onLongPress: () {
          _m5Sayaci.value = 0;
        },
        child: Text(
          'M5: ${_m5Sayaci.value}',
          style: const TextStyle(fontSize: 10, color: Colors.indigo),
        ),
      ),
    );
  }
}

class M6Macrosu extends StatefulWidget {
  const M6Macrosu({super.key});

  @override
  State<M6Macrosu> createState() => _M6MacrosuDurumu();
}

class _M6MacrosuDurumu extends State<M6Macrosu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 65,
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: (_serialPort != null && _serialPort!.isOpen)
            ? Colors.white
            : Colors.red,
        boxShadow: [
          BoxShadow(
              color: m6Anahtar ? Colors.green : Colors.red, spreadRadius: 2),
        ],
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.indigo,
          padding: const EdgeInsets.all(1.0),
        ),
        onPressed: (_serialPort != null && _serialPort!.isOpen)
            ? () {
          m6Anahtar = !m6Anahtar;

          if (m6Anahtar == true) {
            timer6 = Timer.periodic(
              Duration(milliseconds: int.parse(m6SureKontrol.text)),
                  (timer) {
                //kart ile haberleşmeyi bitirdiğimizde göndermeye devam ediyordu bunla göndermeyi kesiyoruz.
                if (!(_serialPort != null && _serialPort!.isOpen)) {
                  debugPrint("timer kapatıldı.");
                  timer.cancel();
                  m6Anahtar = false;
                }

                /// callback will be executed every 1 second, increament a count value
                /// on each callback
                /// Süre zarfında yapılacak işlem

                if (m6VeriKontrol.text.isNotEmpty) {
                  if (_serialPort!.write(Uint8List.fromList(
                      m6VeriKontrol.text.codeUnits)) ==
                      m6VeriKontrol.text.codeUnits.length) {
                    _gonderilenVeriler.add(m6VeriKontrol.text);
                    _m6Sayaci.value++;
                    _gonderilenVeriSayaci.value++;
                  }
                } else {
                  m6Anahtar = false;
                  uyariMesaji("Macro 6' nın", context);
                  //bunu yazmayınca birsürü showdialog açıyor
                  timer.cancel();
                  setState(() {});
                }
              },
            );
          } else {
            timer6!.cancel();
          }
          setState(() {});
        }
            : null,
        onLongPress: () {
          _m6Sayaci.value = 0;
        },
        child: Text(
          'M6: ${_m6Sayaci.value}',
          style: const TextStyle(fontSize: 10, color: Colors.indigo),
        ),
      ),
    );
  }
}
