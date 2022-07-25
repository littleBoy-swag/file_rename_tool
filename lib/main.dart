import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:oktoast/oktoast.dart';
import 'package:window_manager/window_manager.dart';

import 'file_util2.dart';

void main() async {
  if (Platform.isWindows) {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
        size: Size(800, 600),
        center: true
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return OKToast(
        child: MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Rename File Tool'),
          builder: EasyLoading.init(),
    ));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WindowListener {
  String _folderPath = "";
  String _targetDir = "";

  void _preventClose() async {
    await windowManager.setPreventClose(true);
    setState(() {});
  }

  void _getFolderPath() async {
    final String? path = await getDirectoryPath();
    if (path != null) {
      setState(() {
        _folderPath = path;
      });
    }
  }

  void _renameFile() async {
    EasyLoading.show(status: "正在处理");
    bool result = await FileUtil2.renameFiles(_folderPath, 50);
    EasyLoading.dismiss();
    if (result) {
      showDialog<void>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text("提示"),
              content: const Text("处理完成"),
              actions: [
                TextButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text("确定"))
              ],
            );
          });
    }
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _preventClose();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    EasyLoading.dismiss();
    bool isClose = await windowManager.isPreventClose();
    if (isClose) {
      showDialog<void>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text("提示"),
              content: const Text("即将关闭本程序，是否继续？"),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text("取消")),
                TextButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await windowManager.destroy();
                    },
                    child: const Text("确定"))
              ],
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text("文件目录："),
                Text(_folderPath.isEmpty ? "请选择要处理的目录" : _folderPath),
                TextButton(onPressed: _getFolderPath, child: const Text("选择目录"))
              ],
            ),
            TextButton(onPressed: _renameFile, child: const Text("开始处理")),
          ],
        ),
      ),
    );
  }
}
