import 'package:draw_and_guess_promax/model/play_mode.dart';

final availablePlayMode = [
  PlayMode(
    mode: 'Vẽ và đoán',
    description: 'Chế độ cơ bản nhất, vẽ và đoán từ.',
    howToPlay:
        'Mỗi lượt chơi sẽ có một người vẽ, những người chơi còn lại phải đoán chính xác từ mà người vẽ đang cố miêu tả.\n\nNgười vẽ không được phép sử dụng các chữ cái, số trong bức tranh của mình.\n\nNgười nào càng đoán đúng nhiều bức tranh thì điểm nhận được sẽ càng cao.',
  ),
  PlayMode(
    mode: 'Tam sao thất bản',
    description: 'Nghệ thuật biến chuyện đơn giản thành... một DRAMA!',
    howToPlay:
        'Ở lượt đầu tiên, bạn được vẽ một bức tranh theo ý thích của mình\n\nSau đó những người còn lại sẽ vẽ bức tranh của họ dựa trên bức vừa rồi của bạn.\n\nVà bùm! Để xem cuối cùng bức tranh tuyệt vời của bạn trở thành gì nhé!',
  ),
  PlayMode(
    mode: 'Tuyệt tác',
    description: 'Cùng nhau tạo ra những tác phẩm nghệ thuật đỉnh cao.',
    howToPlay:
        'Hệ thống sẽ chọn ra một từ ngẫu nhiên một từ để mọi người cùng vẽ.\n\nSau khi hết giờ thì mọi người cùng nhau chấm điểm bức tranh của bạn để tìm ra bức tranh xuất sắc nhất.\n\nVẽ càng đẹp, càng điểm cao. Hãy cho họ thấy chất nghệ sĩ trong bạn!',
  ),
];
