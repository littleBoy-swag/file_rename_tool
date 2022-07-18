import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:oktoast/oktoast.dart';
import 'package:path/path.dart';

class FileUtil {
  /// 文件重命名
  static Future<bool> renameFiles(String folderPath) async {
    // 1. 判断当前目录是否存在
    if (!_isFolderExist(folderPath)) {
      showToast("当前目录不存在，请重新选择");
      return false;
    }
    // 2. 先创建文件夹，在当前目录下保存重命名的文件
    String savePath = '$folderPath${Platform.pathSeparator}AfterTransByPf';
    var dir = Directory(savePath);
    if (_isFolderExist(savePath)) {
      showToast("当前文件夹已经存在，请删除当前目录下的AfterTransByPf文件夹");
      return false;
    }
    var createSuccess = false;
    try {
      dir.createSync();
      createSuccess = true;
    } on Exception catch (e) {
      print('exception $e');
    }
    if (!createSuccess) {
      showToast("文件夹创建失败，请重试");
      return false;
    }
    _innerRecursiveRenameOrDelete(folderPath, savePath);
    return true;
  }

  /// 文件夹是否存在
  static bool _isFolderExist(String path) {
    return Directory(path).existsSync();
  }

  static void _innerRecursiveRenameOrDelete(String src, String dest) {
    List<FileSystemEntity> fileList = Directory(src).listSync();
    for (FileSystemEntity fse in fileList) {
      FileSystemEntityType type = FileSystemEntity.typeSync(fse.path);
      if (type == FileSystemEntityType.directory) {
        /// 跳过与目标目录一样的文件夹(本身)
        if (fse.path == dest) {
          continue;
        }

        /// 是文件夹
        String subFolder = fse.path.replaceFirst(src, "");
        Directory newDir = Directory("$dest$subFolder");
        newDir.createSync(recursive: true);

        /// 递归处理
        _innerRecursiveRenameOrDelete(fse.path, newDir.path);
      } else if (type == FileSystemEntityType.file) {
        /// 是文件
        File file = File(fse.path);
        String fileName = basename(file.path);
        if(_needDelete(fileName)) {
          // file.deleteSync();
          continue;
        }
        String replaceStr = _needReplace(fileName);
        if (replaceStr.isEmpty) {
          continue;
        }

        /// 文件重命名并复制到指定文件夹
        String newFileName = _getNewFileName(fileName, replaceStr);
        file.copySync("$dest${Platform.pathSeparator}$newFileName");
      }
    }
  }

  static bool _needDelete(String fileName) {
    String fileNameNoSuffix = fileName;
    if (fileName.contains(".")) {
      fileNameNoSuffix = fileName.substring(0, fileName.lastIndexOf("."));
    }
    List<String> arr = fileNameNoSuffix.split("_");
    bool delete = false;
    if (arr.length > 1 && arr[0] == arr[1]) {
      delete = true;
    }
    return delete;
  }

  /// 获取新的文件名
  static String _getNewFileName(String fileName, String replaceStr) {
    return fileName.replaceFirst(
        replaceStr, md5.convert(utf8.encode(replaceStr)).toString());
  }

  /// 判断是否需要更换文件名
  /// 如果返回值为""则不需要替换
  static String _needReplace(String fileName) {
    String fileNameNoSuffix = fileName;
    if (fileName.contains(".")) {
      fileNameNoSuffix = fileName.substring(0, fileName.lastIndexOf("."));
    }
    List<String> arr = fileNameNoSuffix.split("_");
    bool match = false;
    if (arr.length > 1) {
      /// 简单手机号匹配
      match = RegExp(r"1[0-9]\d{9}$").hasMatch(arr[1]);
    }
    if (match) {
      return arr[1];
    }
    return "";
  }
}
