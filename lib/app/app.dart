import 'package:lms_chatbot/ui/bottom_sheets/notice/notice_sheet.dart';
import 'package:lms_chatbot/ui/dialogs/info_alert/info_alert_dialog.dart';
import 'package:lms_chatbot/ui/views/home/home_view.dart';
import 'package:lms_chatbot/ui/views/startup/startup_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:lms_chatbot/ui/views/login/login_view.dart';
import 'package:lms_chatbot/ui/views/signup/signup_view.dart';
import 'package:lms_chatbot/ui/views/register/register_view.dart';
import 'package:lms_chatbot/core/services/authservice.dart';
// @stacked-import

@StackedApp(
  routes: [
    MaterialRoute(page: HomeView),
    MaterialRoute(page: StartupView),
    MaterialRoute(page: LoginView),
    MaterialRoute(page: SignupView),
    MaterialRoute(page: RegisterView),
// @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: AuthService),
    // @stacked-service
  ],
  bottomsheets: [
    StackedBottomsheet(classType: NoticeSheet),
    // @stacked-bottom-sheet
  ],
  dialogs: [
    StackedDialog(classType: InfoAlertDialog),
    // @stacked-dialog
  ],
)
class App {}
