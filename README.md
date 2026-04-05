# Health Tracker App

Ung dung Flutter ho tro theo doi suc khoe ca nhan: tap luyen, dinh duong, nhat ky,
chi so hang ngay va cac goi y cai thien thoi quen song.

## Muc tieu du an

- Giup nguoi dung theo doi tinh trang suc khoe theo ngay/tuan.
- Luu lich su tap luyen, bua an, va ghi chu ca nhan.
- Cung cap giao dien truc quan, de su dung tren mobile.
- Tich hop Firebase de dong bo du lieu va xac thuc nguoi dung.

## Tinh nang chinh

- Dang nhap va quan ly tai khoan voi Firebase Auth.
- Theo doi workout (lich su, streak, tong quan calorie).
- Theo doi dinh duong va ghi chu meal/note.
- Dashboard tong hop tien do suc khoe.
- Local notifications va cac banner nhac nho.

## Phan chia cong viec (doi chieu thuc te)

Du lieu doi chieu duoc tong hop theo lich su commit tren nhanh `main`.

### Mapping tai khoan GitHub

- Tran Duc Trung: `DDuc-Trung`, `leminhhieu05102005-glith`
- Ta Anh Tuan: `tatuan2005`, `taanhtuan2005`
- Nguyen Xuan Lang: `L4ngx1`
- Ho Dien Dat: `D1Da-1103`
- Hoang Viet Trung: `lwlwlwlwsss`

### Bang phan chia va tien do

<table>
	<thead>
		<tr>
			<th>Thanh vien</th>
			<th>Vai tro</th>
			<th>Nhiem vu chinh</th>
			<th>Chi tiet cong viec phan cong</th>
			<th>Cong viec thuc te lam</th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td rowspan="3"><b>Tran Duc Trung</b></td>
			<td rowspan="3">UI/UX + Camera AI (Frontend)</td>
			<td rowspan="3">Thiet ke giao dien va tich hop nhan dien do an</td>
			<td>- Thiet ke UI (Home, theo doi suc khoe, nhap du lieu) + tich hop camera chup mon an</td>
			<td align="center">&#9745;</td>
		</tr>
		<tr>
			<td>- Gui anh len API</td>
			<td align="center">&#9745;</td>
		</tr>
		<tr>
			<td>- Nhan va hien thi ket qua (calories)</td>
			<td align="center">&#9745;</td>
		</tr>
		<tr>
			<td rowspan="3"><b>Ta Anh Tuan</b></td>
			<td rowspan="3">Sensor &amp; Tracking (Hardware)</td>
			<td rowspan="3">Xu ly du lieu tu phan cung</td>
			<td>- Dem buoc chan (accelerometer)</td>
			<td align="center">&#9745;</td>
		</tr>
		<tr>
			<td>- Theo doi giac ngu</td>
			<td align="center">&#9745;</td>
		</tr>
		<tr>
			<td>- Xu ly chay nen (background service)</td>
			<td align="center">&#9745;</td>
		</tr>
		<tr>
			<td rowspan="3"><b>Ho Dien Dat</b></td>
			<td rowspan="3">AI &amp; Xu ly thong minh</td>
			<td rowspan="3">Xay dung he thong AI va logic goi y</td>
			<td>- Xay API nhan dien do an (anh -&gt; ten + calories)</td>
			<td align="center">&#9745;</td>
		</tr>
		<tr>
			<td>- Xay logic goi y tap luyen</td>
			<td align="center">&#9745;</td>
		</tr>
		<tr>
			<td>- Goi y che do an uong phu hop</td>
			<td align="center">&#9745;</td>
		</tr>
		<tr>
			<td rowspan="4"><b>Nguyen Xuan Lang</b></td>
			<td rowspan="4">Backend &amp; Database</td>
			<td rowspan="4">Quan ly du lieu va he thong</td>
			<td>- Xay dung dang ky / dang nhap</td>
			<td align="center">&#9745;</td>
		</tr>
		<tr>
			<td>- Thiet ke database</td>
			<td align="center">&#9745;</td>
		</tr>
		<tr>
			<td>- Luu tru du lieu (calories, steps, sleep, weight)</td>
			<td align="center">&#9745;</td>
		</tr>
		<tr>
			<td>- Xay API de frontend su dung</td>
			<td align="center">&#9745;</td>
		</tr>
		<tr>
			<td rowspan="5"><b>Hoang Viet Trung</b></td>
			<td rowspan="5">Logic nghiep vu + Tien ich</td>
			<td rowspan="5">Phat trien tinh nang ho tro nguoi dung</td>
			<td>- Nhac uong nuoc</td>
			<td align="center">&#9745;</td>
		</tr>
		<tr>
			<td>- Lap lich tap luyen</td>
			<td align="center">&#9745;</td>
		</tr>
		<tr>
			<td>- Quan ly can nang</td>
			<td align="center">&#9745;</td>
		</tr>
		<tr>
			<td>- Voice -&gt; text ghi chu</td>
			<td align="center">&#9745;</td>
		</tr>
		<tr>
			<td>- Gamification (streak, badge)</td>
			<td align="center">&#9745;</td>
		</tr>
	</tbody>
</table>



## Cong nghe su dung

- Flutter + Dart
- Firebase (Auth, Firestore, Storage)
- State management theo module (controllers, viewmodels, services)
- Da nen tang: Android, iOS, Web, Windows, macOS, Linux

## Cai dat va chay du an

1. Cai Flutter SDK va kiem tra moi truong:

```bash
flutter doctor
```

2. Tai dependencies:

```bash
flutter pub get
```

3. Chay ung dung:

```bash
flutter run
```

4. Neu can chay tren thiet bi cu the:

```bash
flutter devices
flutter run -d <device_id>
```

## Cau truc du an

```text
health_tracker_app/
|- lib/
|  |- main.dart                 # Diem vao ung dung
|  |- config.dart               # Cau hinh chung
|  |- firebase_options.dart     # Cau hinh Firebase theo nen tang
|  |- controllers/              # Dieu khien luong du lieu/logic theo man hinh
|  |- models/                   # Data models
|  |- services/                 # Goi API, Firebase, xu ly nghiep vu
|  |- viewmodels/               # Trang thai va xu ly cho UI
|  |- views/                    # Cac man hinh UI chinh
|  |  |- main/                  # Home, Workout, Nutrition, Notes, Journal...
|  |- utils/                    # Ham ho tro, formatter, helpers
|- assets/
|  |- env/                      # Bien moi truong mau (.env.example)
|  |- images/                   # Tai nguyen hinh anh
|  |- models/                   # Tai nguyen model/static data
|- android/ ios/ web/ windows/ macos/ linux/
|  # Thu muc build cho tung nen tang
|- test/                        # Unit/Widget tests
|- firestore.rules              # Security rules Firestore
|- firestore.indexes.json       # Indexes Firestore
|- firebase.json                # Cau hinh Firebase hosting/emulators
|- pubspec.yaml                 # Dependencies va assets config
```

## Tai lieu lien quan

- [ARCHITECTURE.md](ARCHITECTURE.md): Tong quan kien truc.
- [FIREBASE_AUTH_CHECKLIST.md](FIREBASE_AUTH_CHECKLIST.md): Checklist xac thuc Firebase.
- [FIREBASE_AUTH_VERIFICATION.md](FIREBASE_AUTH_VERIFICATION.md): Huong dan verify auth.

## Luu y

- Khong commit file secrets (API keys, env production) len repository.
- Doi voi `assets/env`, chi dung file mau de chia se cau hinh.
- Truoc khi merge code, nen chay:

```bash
flutter analyze
flutter test
```
