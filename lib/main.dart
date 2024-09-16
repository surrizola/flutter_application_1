import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom;
import 'dart:math' as math;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const String appTitle = 'Gaucho Wind';
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(useMaterial3: true),
      //home: HomeScreen(),
      initialRoute: '/home', // Define '/home' como la ruta inicial
      routes: <String, WidgetBuilder>{
        '/home': (BuildContext context) => const HomeScreen(),
        '/second': (BuildContext context) => const MyHomeWidget(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {

    const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const String appTitle = 'Gaucho Wind';

    return Scaffold(
      appBar: AppBar(
        title: const Text(appTitle),
      ),
      // Agregamos el Drawer para el menú
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menú de navegación',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Norden'),
              onTap: () {
                // Cierra el Drawer antes de navegar
                Navigator.pop(context);
                // Navegar a la ruta '/home'
                Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (Route<dynamic> route) => false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Otro'),
              onTap: () {
                // Cierra el Drawer antes de navegar
                Navigator.pop(context);
                // Navegar a la ruta '/second'
                Navigator.pushNamed(context, '/second');
              },
            ),
          ],
        ),
      ),
      body: const FavoriteWidget(),
    );
  }
}



class MyHomeWidget extends StatefulWidget {
  const MyHomeWidget({super.key});

  @override
  State<MyHomeWidget> createState() => _MyHomeWidgetState();
}

class _MyHomeWidgetState extends State<MyHomeWidget> {
  bool _isFavorited = true;
  int _favoriteCount = 41;
  void _toggleFavorite() {
    setState(() {
      if (_isFavorited) {
        _favoriteCount -= 1;
        _isFavorited = false;
      } else {
        _favoriteCount += 1;
        _isFavorited = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Column(children: [
      Text('$_favoriteCount'),
      ElevatedButton(
          child: Text("Test link " '$_favoriteCount'),
          onPressed: () => _toggleFavorite()
          //onPressed: () => Navigator.pushNamed(context, "/second")
          ),
      ElevatedButton(
        child: const Text("HOME"),
        onPressed: () => Navigator.pushNamed(context, "/home"),
        //onPressed: () => Navigator.pushNamed(context, "/second")
      ),
    ]));
  }
  // ···
}

class FavoriteWidget extends StatefulWidget {
  const FavoriteWidget({super.key});

  @override
  State<FavoriteWidget> createState() => _FavoriteWidgetState();
}

class _FavoriteWidgetState extends State<FavoriteWidget> {
  void _calldata(String id) async {
    _count += 1;

    final Uri url1 = Uri.parse(
        "https://meteo.comisionriodelaplata.org/ecsCommand.php?c=telemetry/updateTelemetry");
    final response1 = await http.get(url1, headers: {
      'User-Agent':
          'Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.64 Safari/537.11',
      'Accept': '/',
      'Connection': 'keep-alive',
      "Content-type": "text/plain; charset=UTF-8"
    });

    //print(response1.headers);
    //print(response1.bodyBytes);
    final cookiesHeader = response1.headers['set-cookie'];

// Procesar las cookies
    Map<String, String> cookies = {};
    String cookieHeader = "";
    if (cookiesHeader != null) {
      // Separar cookies por coma
      List<String> cookiesList = cookiesHeader.split(',');
      for (String cookie in cookiesList) {
        // Separar nombre y valor
        List<String> cookieParts = cookie.split(';');
        String cookieNameValue = cookieParts[0];
        List<String> nameValue = cookieNameValue.split('=');
        if (nameValue.length == 2) {
          cookies[nameValue[0].trim()] = nameValue[1].trim();
        }
      }

      // Construir el encabezado Cookie con las cookies extraídas
      cookieHeader =
          cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    } else {
      print('No cookies found');
    }

    //String s = const Utf8Codec().decode(response1.bodyBytes);
    //String body_1 = response1.body;
    final Uri url = Uri.parse(
        "https://meteo.comisionriodelaplata.org/ecsCommand.php?c=telemetry/updateTelemetry&p=1&p1=2&p2=1&p3=1&p4=update");
    final responsePilote = await http.get(url, headers: {
      HttpHeaders.userAgentHeader:
          'Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.64 Safari/537.11',
      HttpHeaders.acceptHeader: "/",
      HttpHeaders.connectionHeader: 'keep-alive',
      "Content-type": "application/json",
      /* "Cookie": "mariweb_session=1105d33082bcc346b73f16b2f97443ce" */
      "Cookie": cookieHeader
    });

    final String bodyRes = const Utf8Codec().decode(responsePilote.bodyBytes);
    int index = bodyRes.indexOf("{");
    if (index > 0) {
      final respObject = jsonDecode(bodyRes.substring(index));
      String htmlString = Uri.decodeComponent(respObject['wind']['latest']);
      dom.Document document = parse(htmlString);
      List<dom.Element> cells = document.querySelectorAll('tr td');
      // Obtener los valores de las celdas
      for (var cell in cells) {
        print(cell.text);
      }

      String date = cells[0].text;
      String wind = cells[1].text;
      String gust = cells[2].text;
      String dirText = cells[4].text;
      double dirDouble = double.parse(dirText);
      String dir = degreeToDir(dirDouble);
      //respObject.wind.chart.gust.series[1].data
      setState(() {
        _knots = wind;
        _gust = gust;
        _date = date;
        _direction = dir;
        _degrees = dirText;
        _degreesD = dirDouble;
        _name = respObject['dlg_title'];
      });
    } else {
      setState(() {
        _title = "error pilote sin datos";
      });
    }
  }

  String degreeToDir(deg) {
    if (deg > 11.25 && deg < 33.75) {
      return "NNE";
    } else if (deg > 33.75 && deg < 56.25) {
      return "ENE";
    } else if (deg > 56.25 && deg < 78.75) {
      return "E";
    } else if (deg > 78.75 && deg < 101.25) {
      return "ESE";
    } else if (deg > 101.25 && deg < 123.75) {
      return "ESE";
    } else if (deg > 123.75 && deg < 146.25) {
      return "SE";
    } else if (deg > 146.25 && deg < 168.75) {
      return "SSE";
    } else if (deg > 168.75 && deg < 191.25) {
      return "S";
    } else if (deg > 191.25 && deg < 213.75) {
      return "SSW";
    } else if (deg > 213.75 && deg < 236.25) {
      return "SW";
    } else if (deg > 236.25 && deg < 258.75) {
      return "WSW";
    } else if (deg > 258.75 && deg < 281.25) {
      return "W";
    } else if (deg > 281.25 && deg < 303.75) {
      return "WNW";
    } else if (deg > 303.75 && deg < 326.25) {
      return "NW";
    } else if (deg > 326.25 && deg < 348.75) {
      return "NNW";
    } else {
      return "N";
    }
  }

  void extractDataFromPilote(respObject) {
    List items = respObject['wind']['chart']['gust']['series'];
    List gust_list = items[0]['data'];
    List wind_list = items[1]['data'];
    //respObject.wind.chart.gust.series[1].data;

    List wind_last = wind_list[wind_list.length - 1];
    List gust_last = gust_list[gust_list.length - 1];
  }

  String _knots = 'x';
  String _gust = 'x';
  String _degrees = "x";
  double _degreesD = 90;
  String _direction = "X";
  String _name = "X";
  String _date = "X";
  //Map body = {};
  String _title = "Norden";
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            iconSize: 28,
            tooltip: 'Refresh',
            onPressed: () {
              _calldata("14");
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primer Card: Contiene la flecha de dirección y la velocidad
            Card(
              elevation: 5,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment
                      .center, // Centra verticalmente los elementos
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$_knots knts',
                            style: theme.textTheme.headlineLarge),
                        Text('$_gust gust', style: theme.textTheme.labelLarge),
                      ],
                    ),
                    WindDirectionArrow(
                        directionDegrees: _degreesD), // Flecha de dirección
                  ],
                ),
              ),
            ),

            // Segundo Card: Contiene la dirección en texto y los grados
            Card(
              elevation: 5,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                title: Text('$_name', style: theme.textTheme.bodySmall),
                subtitle: Text('$_date', style: theme.textTheme.bodySmall),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$_degrees °', style: theme.textTheme.labelMedium),
                    Text('$_direction',
                        style: theme.textTheme.headlineMedium), // Dirección
                  ],
                ),
              ),
            ),

            // Contador y otros elementos
            SizedBox(height: 10),
            Text('$_count', style: theme.textTheme.bodyMedium),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
/*
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
        appBar: AppBar(
          title: Text(_title),
        ),
        body: SingleChildScrollView(
            child: Column(children: [
          Text('$_knots knts', style: theme.textTheme.displayLarge),
          Text('$_guust gust', style: theme.textTheme.displaySmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('  $_direction ', style: theme.textTheme.displayMedium),
              Text('  $_degrees ° ', style: theme.textTheme.displaySmall),
            ],
          ),
          Text(_name),
          Text(_date),
          Text('$_count'),
          IconButton(
            icon: const Icon(Icons.refresh),
            iconSize: 72,
            onPressed: () {
              _calldata("14");
            },
          ),
        ])));
  }
  */
}

void main() {
/*
  runApp(
    // Wrap the root widget with the AppStateProvider
    
    AppStateProvider(
      state: appState,
      child: const MaterialApp(
        home: MyApp(),
      ),
    ),
  );
  */

  runApp( MyApp());
}

class WindDirectionArrow extends StatelessWidget {
  final double directionDegrees;

  WindDirectionArrow({required this.directionDegrees});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      child: CustomPaint(
        painter: ArrowPainter(directionDegrees),
      ),
    );
  }
}

class ArrowPainter extends CustomPainter {
  final double directionDegrees;

  ArrowPainter(this.directionDegrees);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final double arrowLength = size.width * 0.6;
    final double arrowWidth = size.width * 0.15;

    // Convertimos los grados a radianes y sumamos 180° (en radianes)
    final double radians = (directionDegrees + 180) * math.pi / 180;

    final Path arrowPath = Path();
    arrowPath.moveTo(0, -arrowLength); // Punta de la flecha
    arrowPath.lineTo(arrowWidth, 0); // Base derecha de la flecha
    arrowPath.lineTo(-arrowWidth, 0); // Base izquierda de la flecha
    arrowPath.close();

    // Mueve la flecha al centro del canvas
    canvas.translate(size.width / 2, size.height / 2);

    // Gira el canvas según los grados de dirección
    canvas.rotate(radians);

    // Dibuja la flecha
    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// child: Counter(),

/*
class ButtonSection extends StatelessWidget {
  const ButtonSection({super.key});

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).primaryColor;
    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ButtonWithText(
            color: color,
            icon: Icons.call,
            label: 'CALL ',
          ),
          ButtonWithText(
            color: color,
            icon: Icons.north_east,
            label: 'ROUTE',
          ),
          ButtonWithText(
            color: color,
            icon: Icons.share,
            label: 'SHARE',
          ),
        ],
      ),
    );
  }
}

class ButtonWithText extends StatelessWidget {
  const ButtonWithText({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
*/

