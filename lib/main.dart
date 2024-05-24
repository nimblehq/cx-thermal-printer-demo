import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart';
import 'package:serial_port_win32/serial_port_win32.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("Started");

  final portCOM2 = SerialPort("COM2", openNow: true, BaudRate: 19200);

  final receipt = await printReceiptWithThermal();
  portCOM2.writeBytesFromUint8List(Uint8List.fromList(receipt));

  // FIXME: THIS IS IMPORTANT, IT MUST SLEEP!!!
  sleep(const Duration(seconds: 2));
  portCOM2.close();
}

Future<List<int>> printReceiptWithThermal() async {
  final profile = await CapabilityProfile.load();
  final generator = Generator(PaperSize.mm80, profile);
  List<int> bytes = [];

  final ByteData data = await rootBundle.load('./assets/images/logo.png');
  final Uint8List imgBytes = data.buffer.asUint8List();
  final image = decodeImage(imgBytes);
  bytes += generator.imageRaster(image!);
  bytes += generator.feed(1);

  bytes += generator.text('Nimble CX Ltd,', styles: const PosStyles(align: PosAlign.center));
  bytes += generator.text('Order Number: #A88488', styles: const PosStyles(align: PosAlign.center), linesAfter: 2);
  bytes += generator.text('  Fried Chicken (Crispy AF) Set x1         200\$', styles: const PosStyles(align: PosAlign.left, bold: true));
  bytes += generator.text('    With fries (Large AF) x1', styles: const PosStyles(align: PosAlign.left));
  bytes += generator.text('    Coke (White) x1', styles: const PosStyles(align: PosAlign.left));

  generator.feed(2);
  bytes += generator.text('Sub Total: 2000\$', styles: const PosStyles(align: PosAlign.center, bold: true), linesAfter: 1);
  bytes += generator.text('Thank you and don\'t come again!', styles: const PosStyles(align: PosAlign.center), linesAfter: 1);
  bytes += generator.text('==============', styles: const PosStyles(align: PosAlign.center), linesAfter: 1);

  final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
  generator.barcode(Barcode.upcA(barData));
  bytes += generator.barcode(Barcode.upcA(barData));

  bytes += generator.cut();
  return bytes;
}
