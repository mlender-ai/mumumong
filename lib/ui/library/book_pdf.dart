import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/log/app_log.dart';
import '../../data/export/completed_volume_pdf.dart';
import '../../domain/model/frozen_book.dart';

typedef ShareBookPdf =
    Future<ShareResultStatus> Function(FrozenBook book, {Rect? origin});

/// Composes the frozen book's PDF and opens the system share sheet. Shared by
/// every interface so the file, its name and the log events never differ.
/// Logs ids and status only.
Future<ShareResultStatus> shareCompletedBookPdf(
  FrozenBook book, {
  Rect? origin,
}) async {
  try {
    final fonts = await Future.wait([
      rootBundle.load('assets/fonts/MaruBuri-Regular.ttf'),
      rootBundle.load('assets/fonts/MaruBuri-Bold.ttf'),
    ]);
    final bytes = await CompletedVolumePdfComposer(
      maruRegular: fonts[0].buffer.asUint8List(),
      maruBold: fonts[1].buffer.asUint8List(),
    ).compose(book.pdfSnapshot);
    final result = await SharePlus.instance.share(
      ShareParams(
        title: book.title,
        files: [XFile.fromData(bytes, mimeType: 'application/pdf')],
        fileNameOverrides: ['MUMUMONG_VOL${book.volumeNo}.pdf'],
        sharePositionOrigin: origin,
      ),
    );
    AppLog.event('pdf_export_success', {
      'volume_id': book.volumeId,
      'status': result.status.name,
    });
    return result.status;
  } on Object {
    AppLog.event('pdf_export_failed', {
      'volume_id': book.volumeId,
      'code': 'export_unavailable',
    });
    rethrow;
  }
}

final bookPdfShareProvider = Provider<ShareBookPdf>(
  (ref) => shareCompletedBookPdf,
);

/// Copy for the outcome of a share, shared by V1 and V2.
String bookPdfShareMessage(ShareResultStatus status) =>
    status == ShareResultStatus.dismissed
    ? '공유를 취소했어요. 완성본은 그대로 보관돼요.'
    : 'PDF를 준비했어요. 저장 위치는 공유창이나 다운로드 목록에서 확인해 주세요.';

const bookPdfFailedMessage = 'PDF를 준비하지 못했어요. 완성본은 그대로예요. 다시 시도해 주세요.';
