import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

typedef void QRViewCreatedCallback(QRViewController controller);


/*
  TODO зачем нужна хуйня с creationParams на страте - не понятно.
  Она по факту просто делает размер вьюхи нулевым. Настоящий размер 
  получается через ключ, который нужно пробросить в компонент и _вероятно_ который
  делает роут не до конца очищаемым после закрытия.
  1. Попробовать сделать так, чтобы вьюха открывалась без ключей. Для этого перепишу init на получение Size
  2. Потом вообще выкинуть этот инит и передавать либо на старте в пропсах, либо вообще без них
  upd: почему-то эта залупа настойчиво продолжает сканить с выключенной вьюхой, пришлось делать pauseScanner.
  Решение очень временное, нужно думать как убрать. Может быть это из-за того, что метод хендлер торчит наружу прямо в мою модель.
  Если бы он остался где-то на уровне обертки дарта то его бы выкинуло давно.
*/
class LastQrScannerPreview extends StatefulWidget {
  const LastQrScannerPreview({
    Key key,
    this.onQRViewCreated,
  }) : super(key: key);

  final QRViewCreatedCallback onQRViewCreated;

  @override
  State<StatefulWidget> createState() => _QRViewState();
}

class _QRViewState extends State<LastQrScannerPreview> {
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'last_qr_scanner/qrview',
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'last_qr_scanner/qrview',
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: _CreationParams.fromWidget(0, 0).toMap(),
        creationParamsCodec: StandardMessageCodec(),
      );
    }

    return Text(
        '$defaultTargetPlatform is not yet supported by the text_view plugin');
  }

  void _onPlatformViewCreated(int id) {
    if (widget.onQRViewCreated == null) {
      return;
    }
    widget.onQRViewCreated(new QRViewController._(id));
  }
}

class _CreationParams {
  _CreationParams({this.width, this.height});

  static _CreationParams fromWidget(double width, double height) {
    return _CreationParams(
      width: width,
      height: height,
    );
  }

  final double width;
  final double height;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'width': width,
      'height': height,
    };
  }
}

class QRViewController {
  QRViewController._(int id)
      : channel = MethodChannel('last_qr_scanner/qrview_$id');
  final MethodChannel channel;

  void init(Size size) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      channel.invokeMethod("setDimensions",
          {"width": size.width, "height": size.height});
    }
  }

  void toggleTorch() {
    channel.invokeMethod("toggleTorch");
  }

  void pauseScanner() {
    channel.invokeMethod("pauseScanner");
  }

  void resumeScanner() {
    channel.invokeMethod("resumeScanner");
  }
}
