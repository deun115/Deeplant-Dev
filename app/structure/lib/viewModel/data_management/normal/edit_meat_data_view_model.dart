//
//
// 데이터 수정(열람) 페이지 (ViewModel) : Normal
//
//

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:structure/components/custom_pop_up.dart';
import 'package:structure/config/usefuls.dart';
import 'package:structure/dataSource/remote_data_source.dart';
import 'package:structure/model/meat_model.dart';
import 'package:structure/model/user_model.dart';

class EditMeatDataViewModel with ChangeNotifier {
  MeatModel meatModel;
  UserModel userModel;
  BuildContext context;
  EditMeatDataViewModel(this.meatModel, this.userModel, this.context) {
    // 만약 데이터의 상태가 '대기중' 또는 '반려'이며, 3일 내 등록(반려) 데이터이면 수정 가능으로 만든다.
    String dday = meatModel.updatedAt ?? meatModel.createdAt!;
    if (meatModel.statusType != '승인' &&
        Usefuls.calculateDateDifference(dday) <= 3) {
      isEditable = true;
    }

    if (userModel.type != 'Normal') {
      isNormal = false;
    }
  }
  bool isLoading = false;

  bool isEditable = false;
  bool isNormal = true;

  void clicekdBasic() {
    if (isNormal) {
      // 일반
      if (isEditable) {
        context.go('/home/data-manage-normal/edit/info-editable');
      } else {
        context.go('/home/data-manage-normal/edit/info');
      }
    } else {
      // 연구원
      context.go('/home/data-manage-researcher/approve/info');
    }
  }

  void clickedImage() {
    if (isNormal) {
      if (isEditable) {
        context.go('/home/data-manage-normal/edit/image-editable');
      } else {
        context.go('/home/data-manage-normal/edit/image');
      }
    } else {
      context.go('/home/data-manage-researcher/approve/image');
    }
  }

  void clicekdFresh() {
    if (isNormal) {
      if (isEditable) {
        context.go('/home/data-manage-normal/edit/freshmeat-editable');
      } else {
        context.go('/home/data-manage-normal/edit/freshmeat');
      }
    } else {
      context.go('/home/data-manage-researcher/approve/freshmeat');
    }
  }

  bool showAcceptBtn() {
    return !isNormal && meatModel.statusType != '승인';
  }

  /// 육류 데이터 승이
  Future<void> acceptMeatData(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      final response =
          await RemoteDataSource.confirmMeatData(meatModel.meatId!);

      if (response == 200) {
        isLoading = false;
        notifyListeners();

        if (context.mounted) context.pop();
      } else {
        throw ErrorDescription(response);
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();

      debugPrint('Error: $e');
      if (context.mounted) showErrorPopup(context, error: e.toString());
    }

    isLoading = false;
    notifyListeners();
  }

  /// 육류 데이터 반려
  Future<void> rejectMeatData(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await RemoteDataSource.rejectMeatData(meatModel.meatId!);
      if (response == 200) {
        isLoading = false;
        notifyListeners();

        if (context.mounted) context.pop();
      } else {
        throw ErrorDescription(response);
      }
    } catch (e) {
      isLoading = false;
      notifyListeners();

      debugPrint('Error: $e');
      if (context.mounted) showErrorPopup(context, error: e.toString());
    }

    isLoading = false;
    notifyListeners();
  }
}
