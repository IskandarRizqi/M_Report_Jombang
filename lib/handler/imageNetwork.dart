import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class ImageNetwork {
  getimageprofil() async {
    EasyLoading.show(status: 'Loading', maskType: EasyLoadingMaskType.black);
    Image img = Image.asset(
      'assets/images/def_img.png',
      width: 39,
      height: 39,
      fit: BoxFit.fill,
    );

    var url = '';
    SharedPreferences locStor = await SharedPreferences.getInstance();
    var usr = locStor.getString('user');
    if (usr != null && usr != '') {
      var usrDcd = jsonDecode(usr);
      if (usrDcd['avatar'] != null) {
        url = usrDcd['avatar'];
      }
    }

    try {
      img = Image.network(
        url,
        width: 39,
        height: 39,
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/images/def_img.png',
          width: 39,
          height: 39,
          fit: BoxFit.fill,
        ),
      );
    } catch (e) {}
    EasyLoading.dismiss();
    return img;
  }

  getimageprofilpage() async {
    EasyLoading.show(status: 'Loading', maskType: EasyLoadingMaskType.black);
    Image img = Image.asset(
      'assets/images/def_img.png',
      width: 135,
      height: 135,
      fit: BoxFit.fill,
    );

    var url = '';
    SharedPreferences locStor = await SharedPreferences.getInstance();
    var usr = locStor.getString('user');

    if (usr != null && usr.isNotEmpty) {
      var usrDcd = jsonDecode(usr);
      url = usrDcd['avatar'] ?? '';
    }

    try {
      img = Image.network(
        url,
        width: 135,
        height: 135,
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/images/def_img.png',
          width: 135,
          height: 135,
          fit: BoxFit.fill,
        ),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
    EasyLoading.dismiss();
    return img;
  }

  Future<File> getImgaNewtworkFile(Uri url) async {
    final res = await http.get(url);
    final dir = await getTemporaryDirectory();
    final String pth = dir.path;
    final String img = url.toString().split('/').last;
    final fil = File('$pth/$img');
    fil.writeAsBytesSync(res.bodyBytes);
    return fil;
  }
}
