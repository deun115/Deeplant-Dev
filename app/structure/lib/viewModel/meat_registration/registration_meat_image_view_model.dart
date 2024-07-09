//
//
// 육류 이미지 등록 viewModel.
//
//

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:structure/components/custom_dialog.dart';
import 'package:structure/config/userfuls.dart';
import 'package:structure/dataSource/remote_data_source.dart';
import 'package:structure/model/meat_model.dart';
import 'package:structure/dataSource/local_data_source.dart';
import 'package:structure/model/user_model.dart';

class RegistrationMeatImageViewModel with ChangeNotifier {
  final MeatModel meatModel;
  final UserModel userModel;

  RegistrationMeatImageViewModel(this.meatModel, this.userModel) {
    _initialize();
  }

  // 초기 변수
  String date = '-';
  String userName = '-';

  late DateTime time;

  String? imagePath;
  bool isLoading = false;

  File? imageFile;

  late BuildContext _context;

  /// String_to_DateTime method
  void fetchDate(String dateString) {
    DateTime? date = parseDate(dateString);

    if (date != null) {
      time = date;
    } else {
      print('DateString format is not valid.');
    }
  }

  /// 등록 정보 지정 (등록 날짜, 등록자)
  void _setInfo() {
    time = DateTime.now();
    date = '${time.year}.${time.month}.${time.day}';
    userName = userModel.name ?? '-';
  }

  /// Date_parse
  DateTime? parseDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// 초기 할당
  void _initialize() {
    if (meatModel.seqno == 0) {
      // 원육 데이터
      // 등록, 수정
      imagePath = meatModel.imagePath;
      if (imagePath != null && meatModel.freshmeat != null) {
        userName = meatModel.freshmeat!['userName'] ?? '-';
        if (meatModel.freshmeat!['createdAt'] != null) {
          fetchDate(meatModel.freshmeat!['createdAt']);
          date = '${time.year}.${time.month}.${time.day}';
        }
      }
    } else {
      // 처리육 데이터
      imagePath = meatModel.deepAgedImage;
      if (imagePath != null && meatModel.deepAgedFreshmeat != null) {
        userName = meatModel.deepAgedFreshmeat!["userName"] ?? '-';
        if (meatModel.deepAgedFreshmeat!["createdAt"] != null) {
          fetchDate(meatModel.deepAgedFreshmeat!["createdAt"]);
          date = '${time.year}.${time.month}.${time.day}';
        }
      }
    }

    notifyListeners();
  }

  /// 이미지 촬영을 위한 메소드
  Future<void> pickImage(BuildContext context) async {
    String? imgPath = await context.push('/home/registration/image/camera');

    // 반환된 사진이 있으면 저장 팝업 생성
    if (imgPath != null) {
      if (context.mounted) {
        showSaveImageDialog(context, imgPath, () {
          // 재설정
          context.pop();
        }, () {
          // 저장
          isLoading = true; // 로딩 활성화
          notifyListeners();

          imagePath = imgPath;
          imageFile = File(imgPath);
          _setInfo();

          isLoading = false; // 로딩 비활성화
          notifyListeners();
          context.pop();
        });
      }
    } else {
      // 사진 찍기 오류
      print('Image error');
    }
  }

  /// 사진 초기화
  void deleteImage(BuildContext context) {
    showDeletePhotoDialog(context, () {
      imagePath = null;
      imageFile = null;
      date = '-';
      userName = '-';
      notifyListeners();
      context.pop();
    });
  }

  /// 데이터 등록
  Future<void> saveMeatData(BuildContext context) async {
    isLoading = true;
    notifyListeners();
    _context = context;
    try {
      if (meatModel.seqno == 0) {
        // 원육
        meatModel.imagePath = imagePath;
        meatModel.freshmeat ??= {};
        meatModel.freshmeat!['userId'] = meatModel.userId;
        meatModel.freshmeat!['userName'] = userName;
        meatModel.freshmeat!['createdAt'] = Usefuls.getCurrentDate();
        if (meatModel.id == null) {
          // 등록
        } else {
          // 수정
          await _sendImageToFirebase();
          await RemoteDataSource.sendMeatData(
              'sensory-eval', meatModel.toJsonFresh());
        }
      } else {
        // 처리육
        meatModel.deepAgedImage = imagePath;
        meatModel.deepAgedFreshmeat ??= {};
        meatModel.deepAgedFreshmeat!['userId'] = meatModel.userId;
        meatModel.deepAgedFreshmeat!['userName'] = userName;
        meatModel.deepAgedFreshmeat!['createdAt'] = Usefuls.getCurrentDate();
        await _sendImageToFirebase();
        await RemoteDataSource.sendMeatData(
            'sensory-eval',
            jsonEncode({
              "id": meatModel.id,
              "createdAt": meatModel.deepAgedFreshmeat!['createdAt'],
              "userId": meatModel.deepAgedFreshmeat!['userId'],
              "seqno": meatModel.seqno
            }));
      }
      meatModel.checkCompleted();
      if (context.mounted) await tempSave(context);
      _movePage();
    } catch (e) {
      print('에러발생: $e');
    }

    isLoading = false;

    notifyListeners();
  }

  /// 페이지 이동
  void _movePage() {
    if (meatModel.seqno == 0) {
      // 원육
      if (meatModel.id == null) {
        //등록
        _context.go('/home/registration');
      } else {
        // 수정
        _context.go('/home/data-manage-normal/edit');
      }
    } else {
      // 처리육
      _context.go('/home/data-manage-researcher/add/processed-meat');
    }
  }

  /// 이미지를 파이어베이스에 저장
  Future<void> _sendImageToFirebase() async {
    try {
      // fire storage에 육류 이미지 저장
      final refMeatImage = FirebaseStorage.instance
          .ref()
          .child('sensory_evals/${meatModel.id}-${meatModel.seqno}.png');
      print(imagePath);

      if (imagePath!.contains('http')) {
        // db 사진
        final http.Response response =
            await http.get(Uri.parse(meatModel.imagePath!));
        final Uint8List imageData = Uint8List.fromList(response.bodyBytes);
        await refMeatImage.putData(
          imageData,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        // 기기 사진
        await refMeatImage.putFile(
          imageFile!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }
    } catch (e) {
      print(e);
      // 에러 페이지
      throw Error();
    }
  }

  /// 임시저장
  Future<void> tempSave(BuildContext context) async {
    isLoading = true;
    notifyListeners();
    try {
      dynamic response = await LocalDataSource.saveDataToLocal(
          meatModel.toJsonTemp(), meatModel.userId!);
      if (response == null) Error();
      isLoading = false;
      notifyListeners();
      _context = context;
    } catch (e) {
      print('에러발생: $e');
    }
    isLoading = false;
    notifyListeners();
  }
}
