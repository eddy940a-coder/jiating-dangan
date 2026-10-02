import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// 设备端 OCR（Google ML Kit 文字识别）。
///
/// 图片只在手机本地参与推理，不会上传到任何服务器；中文单据使用
/// `TextRecognitionScript.chinese`。
///
/// 注意：ML Kit 的中文识别模型由 Google Play 服务按需下载，首次使用需要联网。
/// 若设备没有 Google Play 服务或下载失败，会抛出 `OcrException`，
/// 调用方应引导用户改为手动录入，而不是让流程卡死。
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  final ImagePicker _picker = ImagePicker();

  /// 拍照或从相册选图，返回图片路径；用户取消返回 null。
  Future<String?> pickImage({required bool fromCamera}) async {
    final file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2160,
      imageQuality: 92,
    );
    return file?.path;
  }

  /// 识别图片中的文字。
  Future<String> recognize(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer =
        TextRecognizer(script: TextRecognitionScript.chinese);
    try {
      final result = await recognizer.processImage(inputImage);
      return result.text;
    } catch (e) {
      throw OcrException(
        '文字识别失败，可能是首次使用需要联网下载识别模型，'
        '或当前设备不支持。你也可以改为手动录入。'
        '（$e）',
      );
    } finally {
      await recognizer.close();
    }
  }
}

/// OCR 不可用（缺 Google Play 服务 / 模型下载失败等）
class OcrException implements Exception {
  OcrException(this.message);
  final String message;

  @override
  String toString() => message;
}
