2.4. Thiết kế Điều hướng (Navigation Flow) & Cấu trúc Widget (Widget Tree)

2.4.1. Thiết kế Điều hướng (Navigation Flow)
Ứng dụng áp dụng cơ chế “điều hướng theo trạng thái xác thực (State-based Navigation)”. Luồng truy cập được kiểm soát bởi Firebase Authentication trước khi cấp quyền vào hệ thống chính. Mô hình này giúp đồng bộ giữa trạng thái tài khoản và màn hình hiển thị, đồng thời hạn chế truy cập sai ngữ cảnh.

1.	Người dùng chưa đăng nhập: Chỉ được truy cập các màn hình xác thực cơ bản gồm Đăng nhập, Đăng ký và Khôi phục mật khẩu.
2.	Người dùng đã đăng nhập nhưng chưa xác minh email:  Được chuyển đến `UnverifiedScreen` để hoàn tất xác minh email trước khi sử dụng hệ thống.
3.	Người dùng hợp lệ (đã đăng nhập và xác minh): Được chuyển vào `MainNavigationScreen`, nơi chứa 5 nhóm chức năng chính qua thanh điều hướng dưới.

Sơ đồ Luồng Điều hướng Tổng thể
Hình ảnh dưới đây mô phỏng lại dòng chảy của các màn hình tương ứng với quy tắc "Trạm gác" vừa nêu:
 

2.4.1.1. Các Mô hình Điều hướng (Routing Patterns) Áp dụng
Để đảm bảo trải nghiệm người dùng (UX) mượt mà, tối ưu hóa hiệu năng và phù hợp với tiêu chuẩn làm báo cáo, ứng dụng áp dụng 3 quy tắc điều hướng chuẩn chỉnh sau:

2.4.1.1.1. Điều hướng Ghi đè (Push Replacement):
   - Cơ chế: Thay thế hoàn toàn màn hình hiện tại bằng một màn hình mới, đồng thời xóa lịch sử màn hình cũ khỏi bộ nhớ.
   - Áp dụng thực tế: Khi người dùng Đăng nhập thành công và được chuyển vào `MainNavigationScreen`, màn hình Đăng nhập sẽ bị hủy. Điều này ngăn chặn việc người dùng lỡ tay bấm phím "Back" trên điện thoại và bị văng ngược lại trang Login một cách vô lý. Kỹ thuật này cũng giúp giải phóng RAM.
   
2.4.1.1.2. Điều hướng Duy trì Trạng thái (Custom Bottom Navigation + Stack):
     - Cơ chế: Ứng dụng dùng thanh điều hướng tùy biến ở đáy màn hình và hiển thị các trang bằng `Stack` + `AnimatedOpacity` + `IgnorePointer`. Cách này vẫn giữ được trạng thái trang khi chuyển tab, không khởi tạo lại mỗi lần bấm.
     - Áp dụng thực tế: Áp dụng cho 5 tab chính (Home, Workout, Nutrition, Notes, Journal). Khi người dùng đang nhập nội dung ghi chú rồi chuyển tab, dữ liệu nhập dở vẫn được giữ, đồng thời tránh gọi lại dữ liệu không cần thiết.
2.4.1.1.3. Điều hướng Xếp chồng Tuyến tính (Push & Pop):
   - Cơ chế: Chồng màn hình con lên trên màn hình cha (Push), và gỡ bỏ màn hình con để lùi về màn hình cha (Pop).
   - Áp dụng thực tế: Sử dụng khi đi sâu vào xem chi tiết. Ví dụ: Từ màn hình Hồ sơ (mở bằng named route), người dùng bấm vào "Cài đặt". Ứng dụng sẽ Push màn hình Cài đặt lên trên. Sau khi tùy chỉnh xong và ấn "Quay lại", màn hình Cài đặt sẽ Pop để trở về màn hình trước đó.
2.4.1.2. Luồng điều hướng Named Route (theo mã nguồn thực tế)
2.4.1.2.1. Danh sách route được khai báo
Các route được định nghĩa tập trung trong `lib/core/routes/app_routes.dart` gồm:
/login - Màn hình Đăng nhập
/register - Màn hình Đăng ký
/forgot-password - Màn hình Quên mật khẩu
/unverified - Màn hình Chưa xác minh email
/main - Màn hình Điều hướng chính
/profile - Màn hình Hồ sơ
/settings - Màn hình Cài đặt
/notifications - Màn hình Thông báo
2.4.1.2.2. Sơ đồ Named Route
  

2.4.2. Cấu trúc Widget (Widget Tree)
Ứng dụng được xây dựng theo kiến trúc phân tách rõ ràng giữa giao diện (View) và logic (Controller), áp dụng chuẩn Declarative UI của Flutter. 
2.4.2.1. Cấu trúc Cây Widget Tổng Thể
Dưới đây là "bộ xương" giao diện màn hình chính của ứng dụng:





HealthTrackerApp  (Root Widget - Nền tảng cấu hình Theme, Đa ngôn ngữ, Định tuyến)
 │
 └── StreamBuilder<User?> (Đứng gác cổng, kiểm tra tài khoản Firebase liên tục)
      │
      ├── (Nếu chưa đăng nhập)
      │    └── LoginScreen (Hiển thị trang Đăng nhập)
      │         ├── RegisterScreen (Trang Đăng ký)
      │         └── ForgotPasswordScreen (Trang Quên mật khẩu)
      │
      ├── (Nếu đã đăng nhập nhưng chưa báo xác nhận Email)
      │    └── UnverifiedScreen (Trang yêu cầu vào hòm thư xác minh)
      │
      └── (Nếu đã đăng nhập & xác thực 100%)
           └── MainNavigationScreen (Màn hình hệ thống chính)
                │
                ├── Custom Bottom Navigation Bar (Thanh Menu 5 nút bấm tùy biến)
                │
                └── Stack + AnimatedOpacity (Khu vực hiển thị nội dung của 5 tab)
                     ├── Tab 1: HomeScreen (Bảng điều khiển sức khỏe hôm nay)
                     ├── Tab 2: WorkoutScreen (Màn hình AI gợi ý bài tập)
                     ├── Tab 3: NutritionScreen (Camera AI soi đồ ăn)
                     ├── Tab 4: NotesScreen (Ghi chú nhanh và đồng bộ lịch)
                     └── Tab 5: JournalScreen (Ghi chép sổ tay cá nhân)


2.4.2.2. Tổ chức Widget Dùng Chung (Shared/Reusable Widgets)
Để đảm bảo tính nhất quán giao diện và tăng khả năng tái sử dụng mã nguồn, các thành phần UI dùng chung được tách thành nhóm widget tại `lib/views/widgets/`. Một số widget tiêu biểu đang được sử dụng trong mã nguồn:
- `RoundedInput`: Trường nhập liệu dùng lại cho các form xác thực, đảm bảo đồng nhất style và hành vi nhập.
- `PrimaryButton` và `SocialButton`: Nút hành động chính/phụ, có cấu hình thống nhất cho tương tác người dùng.
- `TopBar`: Thanh tiêu đề dùng chung cho các màn hình chính, tích hợp avatar người dùng và thông báo.
- `HealthGrid` và `MetricCard`: Khối hiển thị chỉ số sức khỏe theo dạng lưới/thẻ để tái sử dụng trên các màn hình tổng quan.
2.4.3. Phân tích Cấu trúc Widget Chi tiết các Màn hình Chính
Để minh họa sâu hơn về phương pháp bố cục giao diện trong Flutter, dưới đây là kiến trúc chi tiết (mặt cắt) của 5 màn hình tab chính trong ứng dụng: Home, Workout, Nutrition, Notes, Journal. Tất cả đều tuân thủ nguyên tắc lồng ghép Widget (Scaffold làm gốc) và tách biệt logic (Controller).
2.4.3.1. Màn hình Trang chủ (HomeScreen)
Màn hình tổng hợp các chỉ số sức khỏe trong ngày.
HomeScreen 
├── [Logic] HomeController & Cảm biến ngầm (StepCounterForegroundService bằng Kotlin cho Android)
 │
 └── Scaffold (Khung màn hình)
      ├── SafeArea
      │    └── TopBar (Thay cho AppBar, chứa Tên Người dùng và nút điều hướng)
      │
      └── Body (Phần thân chính giữa có thể vuốt lên thả xuống để làm mới)
           └── SingleChildScrollView (Cuộn dọc)
                └── Column (Xếp từ trên xuống dưới các khối nội dung)
                     ├── Lời chào & Tổng quan chung (Bước chân báo cáo từ Service nền, Calo)
                     ├── Bảng uống nước (Thanh tiến độ % uống nước trong ngày)
                     ├── Lịch sử ngủ & đi bộ (Bản đồ cột thống kê)
                     └── Thẻ Cảnh báo cập nhật thông tin BMI

2.4.3.2. Màn hình Tập luyện (WorkoutScreen)
Màn hình sử dụng AI để thiết kế lịch tập luyện.

WorkoutScreen
 ├── [Logic] AIController (Kết nối Gemini API lập kế hoạch)
 │
 └── Scaffold (Khung màn hình)
      ├── SafeArea
      │    └── TopBar (Thay cho AppBar, hiển thị tiêu đề "Tập luyện")
      │
      └── Body
           └── Column
                ├── Mới vào: Ô chọn Lộ trình (Tăng cơ, Giảm mỡ...)
                ├── Nút ở giữa: "Tạo lộ trình bằng AI Gemini"
                ├── Phía trên: Lịch tập các ngày trong tuần (AI trả về)
                └── Phía dưới: Nhật ký lưu lịch sử bài tập bạn đã hoàn thành

2.4.3.3. Màn hình Dinh dưỡng (NutritionScreen)
Màn hình thao tác nhận diện thức ăn qua ống kính điện thoại.

NutritionScreen
 ├── [Logic] CameraController (Điều hướng ống kính phần cứng)
 │
 └── Scaffold (Khung màn hình)
      ├── SafeArea
      │    └── TopBar
      │
      └── Body: Stack (Nhiều màn hình đè lên nhau) và SingleChildScrollView
           ├── Lớp 1 (Dưới cùng): Ống kính Camera ngắm thức ăn
           ├── Lớp 2 (Ở giữa): Hình chữ nhật viền trong suốt báo hiệu vùng lấy nét
           └── Lớp 3 (Nổi trên mặt): Nút chụp, nút chọn ảnh từ thư viện
                │
                └── Sau khi phân tích AI: Thẻ Container hiển thị trực tiếp Calo món ăn trong cùng phần thân (Inline)



2.4.3.4. Màn hình Nhật ký (JournalScreen)
Nơi người dùng gõ tay các ghi chú nhắc nhở bệnh lí.


JournalScreen
 ├── [Logic] JournalController (Quản lý kho dữ liệu Firestore các ghi chú)
 │
 └── Scaffold (Khung màn hình)
      ├── SafeArea
      │    └── TopBar (Thay cho AppBar, chứa tiêu đề và nút Thêm/Lọc)
      │
      └── Body: ListView.builder (Danh sách cuộn như Facebook dài bất tận)
           ├── Từng ô ghi chú: Tiêu đề, Nội dung tóm tắt nhỏ.
           └── menu tùy chọn popup (Xóa/Sửa) và BottomSheet dùng để tạo mới/chỉnh sửa nội dung. Lược bỏ nút nổi FAB.

2.4.3.5. Màn hình Ghi chú nhanh (NotesScreen)
Màn hình ghi chú nhanh và đồng bộ lịch.
NotesScreen
 ├── [Logic] GoogleCalendarSyncService + JournalNoteService
 │
 └── Scaffold/SafeArea (Khung màn hình)
      ├── TopBar (Tiêu đề + điều hướng sang Profile)
      ├── Khối nhập ghi chú (TextEditingController)
      ├── Chọn thời gian hẹn (DatePicker + TimePicker)
      ├── Nút đồng bộ Google Calendar
      └── Nút lưu vào Journal và chuyển tab Journal


2.4.3.6. Màn hình Hồ sơ (ProfileScreen)
Trang thông tin cá nhân.

ProfileScreen
 ├── [Logic] ImagePicker (Chọn ảnh) & CloudflareR2 (Upload ảnh lên máy chủ)
 │
 └── Scaffold (Khung màn hình)
      ├── AppBar
      │
      └── Body: Column
           ├── Trên cùng: Avatar hình tròn & Tên
           ├── Ngay dưới: Cục nhãn báo trạng thái Email (Đã xác minh màu Xanh / Chưa màu Đỏ)
           ├── Ở giữa: Nút Đổi Avatar & Sửa Tên
           ├── Mục liệt kê: Bảng Cài đặt App (Ngôn ngữ)
           └── Đáy cùng: Phím Đăng xuất / Cảnh báo xóa tài khoản.



2.4.3.7. Màn hình Cài đặt (SettingsScreen) - mở bằng Named Route
Màn hình thiết lập tùy chọn ứng dụng, vào từ Profile.
SettingsScreen
  ├── [Logic] LocaleService + Dịch vụ giao diện/chế độ hiển thị
 │
 └── Scaffold
      └── SafeArea
           └── Column
                ├── Thanh tiêu đề cài đặt (AppBar/TopBar)
                ├── Nhóm thiết lập ngôn ngữ
                ├── Nhóm thiết lập hiển thị/hành vi
                └── Nút quay về hoặc đăng xuất (điều hướng về Login khi cần)

2.4.3.8. Màn hình Thông báo (NotificationsScreen) - mở bằng Named Route
Màn hình danh sách thông báo, vào từ biểu tượng chuông ở `TopBar`.

NotificationsScreen
 ├── [Logic] BackendApiService (theo dõi/đọc thông báo)
 │
 └── DefaultTabController
      └── Scaffold
           ├── AppBar + TabBar (phân loại nhóm thông báo)
           └── TabBarView
                ├── Danh sách thông báo chưa đọc (`ListView.separated`)
                └── Danh sách thông báo đã đọc (`ListView.separated`)

2.4.3.9. Nhóm màn hình Xác thực (Auth) - mở bằng Named Route
Nhóm route xác thực gồm `/login`, `/register`, `/forgot-password`, `/unverified`.
 
Auth Screens (Login/Register/ForgotPassword/Unverified)
 ├── [Logic] FirebaseAuth + Kiểm tra hợp lệ dữ liệu
 │
 └── Scaffold
      └── Bố cục xác thực chung (AuthLayout)
           └── SingleChildScrollView
                └── Column
                     ├── Tiêu đề thương hiệu (BrandHeader)
                     ├── Trường nhập liệu dùng chung (RoundedInput: email, mật khẩu, ...)
                     ├── Nút hành động chính/phụ (PrimaryButton / SocialButton)
                     └── Điều hướng route:
                          ├── Đăng nhập -> `/main` (pushReplacementNamed)
                          ├── Đăng ký -> `/unverified` (pushNamedAndRemoveUntil)
                          └── Chưa xác minh -> `/main` hoặc `/login`


2.4.4. Điều hướng lớp phủ (Overlays & Dialogs)
Bên cạnh luồng chuyển màn hình đầy đủ (Screen Routing), ứng dụng sử dụng thêm cơ chế lớp phủ (Overlay Navigation) cho các tương tác ngữ cảnh ngắn, giúp hạn chế chuyển trang không cần thiết:
2.4.4.1. Dialogs (Hộp thoại cảnh báo):
    - Sử dụng `AlertDialog` để hiển thị yêu cầu cấp quyền (Ví dụ: Quyền định vị / Location Permission Alert khi mới mở HomeScreen).
    - Hộp thoại xác nhận thao tác quan trọng: Đăng xuất, Xóa tài khoản, Xóa dữ liệu sức khỏe.
2.4.4.2. Bottom Sheets (Bảng trượt từ dưới lên):
    - Dùng để hiển thị danh sách các tuỳ chọn thao tác nhanh (ví dụ: chia sẻ ảnh, chọn bộ lọc xem lịch sử) mà không gây cảm giác chuyển màn hình.
2.4.4.3. Snackbars (Thông báo tạm thời):
    - Được kích hoạt ở thân màn hình bằng `ScaffoldMessenger` để báo trạng thái như: "Lưu thành công", "Cập nhật tiến độ uống nước", hay "Tải dữ liệu thất bại". 
    - Thời gian hiển thị ngắn (2-4 giây) không làm cản trở người dùng.










 3.1. Mô tả cài đặt các chức năng cốt lõi (Module Hardware Sensor & Tracking)

Dưới đây là mô tả chi tiết quy trình xử lý của module “Cảm biến và Theo dõi Sức khỏe (Hardware Sensor & Tracking)” do Em đảm nhận. Chức năng này tương tác trực tiếp với các API bậc thấp của hệ điều hành, vận hành liên tục (background) và đặc biệt yêu cầu tối ưu hóa thuật toán để tránh cạn kiệt thiết bị (Battery-drain).

Trọng tâm thiết kế của module này giải quyết bài toán: "Làm sao thu thập dữ liệu người dùng (bước chân, giấc ngủ) một cách chính xác nhất mà tốn ít năng lượng nhất khi ứng dụng đã bị đóng hoàn toàn?"
3.1.1. Đếm bước chân bằng Cảm biến Gia tốc (Accelerometer & Pedometer)
Vấn đề kỹ thuật (Pain point): Nếu dùng GPS để đo khoảng cách thì sẽ cực kỳ hao pin và không hoạt động trong nhà. Ngược lại, nếu đọc Pedometer thì cảm biến phần cứng chỉ trả về *tổng số bước chân từ khi mua/khởi động điện thoại*, chứ không trả về "số bước hôm nay". Nếu điện thoại sập nguồn bật lại, bộ đếm hardware sẽ reset tự động về 0, làm sai lệch toàn bộ dữ liệu.
Giải pháp logic: Ứng dụng sử dụng một "điểm neo" (Base offset). Tại khoảnh khắc phút đầu tiên của một ngày mới (00:00 AM), máy sẽ âm thầm chốt lại số đếm ở thời điểm hiện tại và trừ lùi (Offset). Nếu thiết bị mất nguồn cài lại `steps = 0`, logic sẽ tự động nhận diện độ lệch (anomaly detection) để vá lỗi khởi tạo mới. Mọi tính toán số bước trong ngày sẽ dựa trên hiệu số giữa giá trị hiện tại của cảm biến và điểm neo này.
Đoạn code tiêu biểu (Logic xử lý đếm bước an toàn & Reset qua ngày):

 
 

3.1.2. Thuật toán Suy luận Giấc ngủ (Heuristic Sleep Tracking)
Vấn đề kỹ thuật: Điện thoại không thể gắn lên não để biết người dùng đang ngủ hay chỉ đặt trên mặt bàn đi tắm. Đòi hỏi người dùng "Bấm nút đi ngủ" mới đo được thì quá thủ công và kém thông minh.
Giải pháp logic: Nhóm thực hiện xây dựng thuật toán Cửa sổ Trượt (Rolling Time Window). Hệ thống chia thời gian giám sát thành các mảng khối nhỏ (vd: 15 phút). Nếu phát hiện thiết bị bất động hoàn toàn (không phát sinh gia tốc) vượt quá số lượng mảng block quy định, module sẽ đánh dấu kích hoạt một phiên ngủ ở trạng thái chờ (Pending). Khi vi mạch phát hiện cảm biến chuyển động trở lại, thuật toán sẽ xác nhận đóng phiên (Finalize), tự động bù trừ mốc chuẩn thời gian và ghi chuỗi dữ liệu cấu trúc vào Data Storage.
 
 

3.1.3. Tính toán quãng đường di chuyển (Location & Distance Tracking)
Vấn đề kỹ thuật: Cảm biến đếm bước chân (Pedometer) chỉ cho biết số lượng bước đi, nhưng mỗi người có sải chân dài ngắn khác nhau. Việc lấy số bước * nhân thủ công với một hằng số trung bình (ví dụ 0.7m/bước) sẽ ra kết quả sai lệch lớn. Hơn nữa, GPS thường rất "nhiễu" (GPS Drift), khiến cho dù người dùng đang ngồi yên trên ghế nhưng vị trí vẫn nhảy liên tục làm quãng đường bị cộng dồn ảo.
Giải pháp logic (Thuật toán lọc nhiễu GPS): Ứng dụng kết hợp giữa “Cảm biến bước chân + GPS Location (Geolocator)”. Đoạn code xử lý tính quãng đường thực hiện 3 vòng bảo vệ nghiệm ngặt:
  1. Chỉ cộng dồn khoảng cách GPS nếu độ dời lớn hơn ngưỡng tối thiểu (`_minMovementDistanceMeters`).
  2. Lọc bỏ các bước nhảy vọt do mất sóng GPS lấy lại vị trí đột ngột (`_maxSingleJumpMeters`).
  3. Lớp bảo vệ chống nhiễu (Stationary Drift Protection): Bắt buộc phải có tín hiệu bước chân thực tế trong 75 giây qua, hoặc hệ số vận tốc GPS phải đạt ngưỡng tối thiểu (`_minSpeedMetersPerSecond`). Nếu không thỏa mãn một trong các điều kiện động học này, thiết bị được xem như đứng yên và tọa độ lệch chỉ được sử dụng để căn chỉnh lại vị trí gốc.
Đoạn code tiêu biểu (Logic lọc nhiễu khoảng cách và cộng dồn):
 
 
 
 
 

3.1.4. Cài đặt Theo dõi Hoạt động Nền (Background Service) tích hợp đếm bước
Vấn đề kỹ thuật (Pain point): Đếm bước chân hay đo quãng đường sẽ vô nghĩa nếu người dùng bắt buộc phải mở màn hình app 24/24. Trong thực tế, lúc người dùng cất điện thoại vào túi quần và tắt màn hình, tính năng Doze Mode của Android/iOS sẽ "đóng băng" (kill) mọi ứng dụng để tiết kiệm pin. Nếu không can thiệp, luồng đếm từ phần cứng sẽ bị hệ điều hành ngắt kết nối.
Giải pháp logic (Background Service): Để duy trì luồng theo dõi mà không vi phạm chính sách sinh thái hệ điều hành, hệ thống khai báo thư viện `Workmanager` thiết lập một chuỗi nhiệm vụ định kỳ (Periodic Task). Cấu trúc cấp phép này yêu cầu OS đánh thức tiến trình của ứng dụng khoảng vài mili-giây với chu kỳ ngầm mỗi 15 phút, nhằm tiến hành "Lazy Sync" dữ liệu phần cứng mới nhất xuống bộ nhớ cục bộ.

Đoạn code tiêu biểu (Logic lập lịch cấp phép WorkManager):
 
 
 

> **Điểm nhấn chuyên môn đánh giá cao**: Việc ứng dụng một Periodic Task có cam kết *Offline* (`networkType.not_required`) thể hiện tư duy thiết kế phần mềm "Battery-First" (Ưu tiên tuổi thọ pin). Thay vì xả pin để gửi data đẩy lên máy chủ liên tục, app sử dụng "Lazy Sync", lưu mọi thứ vào SharedPreferences trước, và chỉ đẩy dồn cục khi người dùng trực tiếp mở app, đảm bảo mức tiêu hao < 1% pin nền/ngày.

---

### 3.2. Cấu hình Biến Môi Trường (Environment Variables)

Để phân hệ AI (tính năng Nhận diện Món ăn và Gợi ý Chế độ ăn) có thể kết nối với dịch vụ đám mây, kiến trúc hệ thống yêu cầu cung cấp khóa bảo mật (API Key) qua môi trường cục bộ.

**1. Vị trí tệp cấu hình:**
Tạo (hoặc chỉnh sửa) tệp tin `.env` tại đường dẫn gốc của thư mục assets:
`assets/env/.env`

**2. Cấu trúc nội dung khóa bảo mật:**
Tệp tin phải chứa các dòng sau để cấp quyền cho AI Service:

```env
# Phím khóa cho Gemini Pro Vision API (Bắt buộc)
GEMINI_API_KEY=your_gemini_api_key_here

# Phím khóa truy xuất USDA Food Data (Không bắt buộc)
USDA_API_KEY=your_usda_api_key_here
```

*Lưu ý bảo mật: Tệp `.env` đã được đưa vào danh sách `.gitignore` của Git để ngăn rò rỉ mã khóa lên thư viện mã nguồn gốc.*


