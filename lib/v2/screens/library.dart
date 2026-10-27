// V2 completed books (DESIGN_V2.md §8): the completion request, the shelf of
// completed books and the frozen book itself. Every rule stays in BookStore
// (eligibility, revision, pending/conflict requests, next volume) and in the
// shared PDF helper; these screens only draw its states, as V1 did.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/log/app_log.dart';
import '../../di/providers.dart';
import '../../domain/model/frozen_book.dart';
import '../../domain/model/models.dart';
import '../../domain/progress.dart';
import '../../ui/library/book_pdf.dart';
import '../components/buttons.dart';
import '../components/feedback.dart';
import '../components/inputs.dart';
import '../components/progress.dart';
import '../components/rows.dart';
import '../design/dot_matrix.dart';
import '../design/halftone.dart';
import '../design/surface.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'format.dart';
import 'settings.dart' show V2SettingsFrame;
import 'v2_providers.dart';

String _volumeLabel(int volumeNo) =>
    'VOL.${volumeNo.toString().padLeft(2, '0')}';

V2Motif _bookMotif(FrozenBook book) => motifFor(
  coverMotifId: book.toJson()['cover_motif_id'] as String?,
  volumeId: book.volumeId,
);

/// The shelf of completed books, and the way to the completion request.
class V2LibraryScreen extends ConsumerStatefulWidget {
  const V2LibraryScreen({super.key});

  @override
  ConsumerState<V2LibraryScreen> createState() => _V2LibraryScreenState();
}

class _V2LibraryScreenState extends ConsumerState<V2LibraryScreen> {
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  Future<void> _refresh() async {
    if (_loading || !mounted) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      await ref.read(bookStoreProvider).refresh();
    } on Object {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final volume = ref.watch(activeVolumeProvider).value;
    final books = ref.watch(completedBooksProvider);
    return V2SettingsFrame(
      title: '내가 완성한 책',
      description: '완성할 때의 문장과 출처를 그대로 보관해요.',
      children: [
        books.when(
          loading: () => const V2InlineStatus('책을 불러오는 중이에요.', waiting: true),
          error: (_, _) => V2InlineStatus(
            '책을 불러오지 못했어요.',
            action: V2Button.secondary(
              label: '다시 불러오기',
              onPressed: () => ref.invalidate(completedBooksProvider),
            ),
          ),
          data: (list) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: V2Space.md),
              if (_failed) ...[
                const V2Notice(
                  message: '서버의 책을 확인하지 못했어요. 이 기기에 보관된 책은 열 수 있어요.',
                ),
                const SizedBox(height: V2Space.md),
              ],
              if (_loading) ...[
                const V2Meta('완성본을 확인하는 중'),
                const SizedBox(height: V2Space.xs),
              ],
              for (final book in list)
                V2ListRow(
                  title: book.title,
                  subtitle:
                      '${_volumeLabel(book.volumeNo)} · 완성본 v1 · ${v2DotDate(book.completedAt.toLocal())}',
                  onTap: () => Navigator.of(
                    context,
                  ).push(v2Route(V2CompletedBookScreen(book: book))),
                ),
              if (list.isEmpty)
                const V2InlineStatus(
                  '아직 완성한 책이 없어요. 꿈에서 자란 원고를 이곳에 보관할 수 있어요.',
                ),
              if (volume != null &&
                  volume.status != VolumeStatus.completed) ...[
                const SizedBox(height: V2Space.lg),
                V2Button(
                  label: volume.status == VolumeStatus.completing
                      ? '완성본 저장 상태'
                      : '원고 완성 준비',
                  expand: true,
                  onPressed: () => Navigator.of(
                    context,
                  ).push(v2Route(V2CompletionScreen(volumeId: volume.id))),
                ),
              ],
              const SizedBox(height: V2Space.xs),
              Center(
                child: V2TextAction(
                  label: '서버에서 다시 확인',
                  onPressed: _loading ? null : _refresh,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Freezing the current manuscript as one book. No new ending, no rewrite.
class V2CompletionScreen extends ConsumerStatefulWidget {
  const V2CompletionScreen({super.key, required this.volumeId});

  final String volumeId;

  @override
  ConsumerState<V2CompletionScreen> createState() => _V2CompletionScreenState();
}

class _V2CompletionScreenState extends ConsumerState<V2CompletionScreen> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  BookCompletionPreview? _preview;
  bool _loading = true;
  bool _saving = false;
  bool _review = false;
  String? _error;
  String? _checkedConflict;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _review = false;
    });
    try {
      final store = ref.read(bookStoreProvider);
      await store.refresh();
      final request = await store.watchRequest(widget.volumeId).first;
      final result = await store.prepare(widget.volumeId);
      if (!mounted) return;
      if (_title.text.isEmpty) {
        _title.text =
            request?.title ?? ref.read(activeVolumeProvider).value?.title ?? '';
      }
      if (_note.text.isEmpty) _note.text = request?.authorNote ?? '';
      setState(() {
        _preview = result;
        _checkedConflict = request?.status == 'conflict'
            ? request?.requestId
            : null;
      });
    } on Object {
      if (mounted) {
        setState(
          () => _error = '동기화할 변경이 있거나 연결을 확인하지 못했어요. 기록은 그대로예요. 다시 확인해 주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _preview == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(bookStoreProvider)
          .complete(
            widget.volumeId,
            _preview!,
            _title.text,
            _note.text.isEmpty ? null : _note.text,
          );
      AppLog.event('volume_completion_requested', {
        'volume_id': widget.volumeId,
      });
    } on Object {
      if (mounted) {
        setState(
          () => _error = '완성본을 저장하지 못했어요. 제목과 작가의 말은 유지했어요. 원고를 다시 확인해 주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toReview() => setState(() {
    if (_title.text.trim().isEmpty) {
      _error = '책 제목을 적어 주세요.';
    } else {
      _error = null;
      _review = true;
      FocusManager.instance.primaryFocus?.unfocus();
    }
  });

  Future<void> _retryPending() async {
    try {
      await ref.read(bookStoreProvider).retry(widget.volumeId);
      await ref.read(bookStoreProvider).refresh();
    } on Object {
      if (mounted) showV2Toast(context, '저장 상태를 아직 확인하지 못했어요. 요청은 보관하고 있어요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final book =
        (ref.watch(completedBooksProvider).value ?? const <FrozenBook>[])
            .where((b) => b.volumeId == widget.volumeId)
            .firstOrNull;
    if (book != null) return V2CompletedBookScreen(book: book, fresh: true);
    final request = ref.watch(completionRequestProvider(widget.volumeId)).value;
    final volume = ref.watch(activeVolumeProvider).value;
    final List<Widget> body;
    if (request?.status == 'pending') {
      body = [
        _Manuscript(volume: volume, volumeId: widget.volumeId),
        const _Lead('완성본 저장을 기다리고 있어요.'),
        const _Copy(
          '이 화면을 닫아도 요청은 남아요. 연결되면 같은 요청으로 이어서 저장해요. 서버 확인 전에는 완성됐다고 표시하지 않아요.',
        ),
        const SizedBox(height: V2Space.lg),
        V2Button(label: '저장 다시 확인', expand: true, onPressed: _retryPending),
      ];
    } else if (_loading) {
      body = const [V2InlineStatus('현재 원고를 확인하는 중이에요.', waiting: true)];
    } else if (request?.status == 'conflict' &&
        _checkedConflict != request?.requestId) {
      body = [
        const _Copy('원고나 작업 상태가 바뀌었어요. 제목과 작가의 말은 유지했어요. 현재 원고를 다시 확인해 주세요.'),
        const SizedBox(height: V2Space.lg),
        V2Button(label: '현재 원고 다시 확인', expand: true, onPressed: _load),
      ];
    } else if (_preview == null) {
      body = [
        V2InlineStatus(
          _error ?? '원고를 확인하지 못했어요.',
          action: V2Button.secondary(label: '다시 확인', onPressed: _load),
        ),
      ];
    } else if (!_preview!.eligible || _preview!.busy) {
      body = [
        _Manuscript(volume: volume, volumeId: widget.volumeId),
        _Lead(_preview!.busy ? '진행 중인 장면이 있어요.' : '조금 더 원고를 쌓아 주세요.'),
        const _Copy(
          '단편은 재료 70% 이상, 본문이 있는 장면 5개 이상, 두 꿈에 걸쳐 반복된 연결 재료가 필요해요. 수치는 문학적 완결을 보장하지 않아요.',
        ),
        const SizedBox(height: V2Space.sm),
        const _Copy('새 엔딩이나 문장 편집 없이 현재 원고를 고정하는 완성본이에요.'),
        const SizedBox(height: V2Space.lg),
        V2Button(
          label: '계속 쌓기',
          expand: true,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        Center(
          child: V2TextAction(label: '상태 다시 확인', onPressed: _load),
        ),
      ];
    } else {
      final scenes = (_preview!.document['scenes'] as List).length;
      body = [
        if (request?.status == 'conflict') ...[
          const SizedBox(height: V2Space.md),
          const V2Notice(
            message: '원고나 작업 상태가 바뀌었어요. 현재 원고를 다시 확인한 뒤 새 요청으로 확정해 주세요.',
          ),
        ],
        if (_review) ...[
          _Manuscript(
            volume: volume,
            volumeId: widget.volumeId,
            caption: _title.text.trim(),
            meta: '$scenes개 장면 · 기록 순서 그대로 · 완성본 v1',
          ),
          const _Lead('이 원고를 한 권으로 보관할까요?'),
          const _Copy(
            '기존 문장을 고정해 보관해요. 새 엔딩이나 문장 개정은 하지 않아요. 이후 변경은 이 완성본에 섞이지 않아요. 저장만 한 꿈은 보관함에 남아요.',
          ),
          if (_note.text.isNotEmpty) ...[
            const SizedBox(height: V2Space.md),
            const V2Meta('작가의 말'),
            const SizedBox(height: V2Space.xxs),
            Text(_note.text, style: V2Type.body),
          ],
        ] else ...[
          const _Lead('작품의 이름을 붙여 주세요.'),
          const SizedBox(height: V2Space.xs),
          V2TextField(
            controller: _title,
            label: '책 제목',
            maxLength: 120,
            fieldKey: const Key('v2-book-title'),
          ),
          const SizedBox(height: V2Space.sm),
          V2TextField(
            controller: _note,
            label: '작가의 말 · 선택',
            hint: '직접 쓴 말만 담겨요. 비워 두어도 괜찮아요.',
            maxLength: 10000,
            minLines: 3,
            maxLines: 6,
            fieldKey: const Key('v2-book-note'),
          ),
        ],
        if (_error case final error?) ...[
          const SizedBox(height: V2Space.sm),
          Semantics(
            liveRegion: true,
            child: Text(
              error,
              style: V2Type.bodySmall.copyWith(color: V2Color.alert),
            ),
          ),
        ],
        const SizedBox(height: V2Space.lg),
        V2Button(
          label: _review ? '원고 완성하기' : '내용 확인',
          expand: true,
          loading: _saving,
          loadingLabel: '저장 요청 중',
          onPressed: _saving ? null : (_review ? _save : _toReview),
        ),
        Center(
          child: V2TextAction(
            label: _review ? '제목과 작가의 말 수정' : '계속 쌓기',
            onPressed: _saving
                ? null
                : () => _review
                      ? setState(() => _review = false)
                      : Navigator.of(context).maybePop(),
          ),
        ),
      ];
    }
    return V2SettingsFrame(
      title: '원고 완성하기',
      description: '기존 문장을 그대로 보관하는 완성본이에요.',
      backLabel: '돌아가기',
      children: body,
    );
  }
}

/// The frozen book: its cover prints to its last clarity once, then the
/// text reads in the reader's own type. It never changes after completion.
class V2CompletedBookScreen extends ConsumerStatefulWidget {
  const V2CompletedBookScreen({
    super.key,
    required this.book,
    this.fresh = false,
  });

  final FrozenBook book;

  /// Opened right after completion: the cover prints its last clarity.
  final bool fresh;

  @override
  ConsumerState<V2CompletedBookScreen> createState() =>
      _V2CompletedBookScreenState();
}

class _V2CompletedBookScreenState extends ConsumerState<V2CompletedBookScreen> {
  bool _exporting = false;
  bool _starting = false;
  String? _message;

  Future<void> _export() async {
    if (_exporting) return;
    setState(() {
      _exporting = true;
      _message = null;
    });
    try {
      final box = context.findRenderObject() as RenderBox?;
      final status = await ref.read(bookPdfShareProvider)(
        widget.book,
        origin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
      if (mounted) setState(() => _message = bookPdfShareMessage(status));
    } on Object {
      if (mounted) setState(() => _message = bookPdfFailedMessage);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _next() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      await ref.read(bookStoreProvider).next(widget.book);
      ref.read(libraryReturnHomeProvider.notifier).state++;
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on Object {
      if (mounted) {
        setState(() => _message = '다음 권을 열지 못했어요. 완성본은 그대로 보관돼요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final prefs = ref.watch(uiPreferencesProvider);
    final preview = ref.watch(v2PreviewProvider);
    final scenes = book.scenes;
    final reading = V2Type.reading.copyWith(
      fontSize: V2Type.reading.fontSize! * prefs.readerScale,
    );
    return V2SettingsFrame(
      title: book.title,
      description: '${_volumeLabel(book.volumeNo)} · 완성본 v1 · 원고와 분리해 보관',
      backLabel: '돌아가기',
      children: [
        const SizedBox(height: V2Space.lg),
        V2CompletionReveal(
          motif: _bookMotif(book),
          seed: v2Seed(book.volumeId),
          playKey: widget.fresh ? 'book-${book.requestId}' : null,
        ),
        const SizedBox(height: V2Space.lg),
        V2Button(
          label: 'PDF 저장·공유',
          icon: Icons.ios_share_rounded,
          expand: true,
          loading: _exporting,
          loadingLabel: 'PDF 준비 중',
          onPressed: _exporting ? null : _export,
        ),
        const SizedBox(height: V2Space.xs),
        V2Button.secondary(
          label: '다음 권 시작',
          expand: true,
          loading: _starting,
          loadingLabel: '다음 권 여는 중',
          onPressed: _starting || preview ? null : _next,
        ),
        if (preview) ...[
          const SizedBox(height: V2Space.xs),
          const V2Meta('미리보기에서는 다음 권을 열지 않아요.', textAlign: TextAlign.center),
        ],
        if (_message case final message?) ...[
          const SizedBox(height: V2Space.sm),
          Semantics(
            liveRegion: true,
            child: Text(message, style: V2Type.bodySmall),
          ),
        ],
        const SizedBox(height: V2Space.xxl),
        for (var i = 0; i < scenes.length; i++) ...[
          V2DotMatrix(
            (i + 1).toString().padLeft(2, '0'),
            pitch: 2.4,
            color: V2Color.sky600,
            semanticsLabel: '${i + 1}장',
          ),
          const SizedBox(height: V2Space.xs),
          Semantics(
            header: true,
            child: Text(
              v2KeepAll(
                (scenes[i]['title'] as String?)?.trim().isNotEmpty == true
                    ? scenes[i]['title'] as String
                    : '장면 ${i + 1}',
              ),
              style: V2Type.title,
            ),
          ),
          const SizedBox(height: V2Space.md),
          for (final raw in scenes[i]['passages'] as List) ...[
            Text(v2KeepAll((raw as Map)['text'] as String), style: reading),
            if (prefs.showOrigins) ...[
              const SizedBox(height: V2Space.xxs),
              V2Meta(switch (raw['origin']) {
                'D' => '꿈에서 온 문장',
                'U' => '내가 쓴 문장',
                _ => '장면을 잇는 문장',
              }),
            ],
            const SizedBox(height: V2Space.md),
          ],
          const SizedBox(height: V2Space.lg),
        ],
        if (book.authorNote case final note? when note.isNotEmpty) ...[
          const Divider(height: V2Space.xl, color: V2Color.hairline),
          Semantics(
            header: true,
            child: const Text('작가의 말', style: V2Type.title),
          ),
          const SizedBox(height: V2Space.sm),
          Text(v2KeepAll(note), style: reading),
        ],
      ],
    );
  }
}

/// The current manuscript on its paper card, optionally titled.
class _Manuscript extends StatelessWidget {
  const _Manuscript({
    required this.volume,
    required this.volumeId,
    this.caption,
    this.meta,
  });

  final Volume? volume;
  final String volumeId;
  final String? caption;
  final String? meta;

  @override
  Widget build(BuildContext context) {
    final current = volume;
    final progress = current == null
        ? 0.0
        : progressRatio(
            progressMu: current.progressMu,
            targetMu: current.targetMu,
          ).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(top: V2Space.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 248),
          child: V2Surface(
            kind: V2SurfaceKind.paper,
            radius: V2Radius.card,
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: .8,
                  child: V2Manuscript(
                    motif: motifFor(
                      coverMotifId: current?.coverMotifId,
                      volumeId: volumeId,
                    ),
                    seed: v2Seed(volumeId),
                    progress: progress,
                    semanticsLabel: '현재 원고, 재료 ${(progress * 100).round()}%',
                  ),
                ),
                if (caption case final text? when text.isNotEmpty) ...[
                  const SizedBox(height: V2Space.sm),
                  Text(v2KeepAll(text), style: V2Type.title),
                ],
                if (meta case final line?) ...[
                  const SizedBox(height: V2Space.xxs),
                  V2Meta(line),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Lead extends StatelessWidget {
  const _Lead(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: V2Space.lg, bottom: V2Space.xs),
    child: Semantics(
      header: true,
      child: Text(v2KeepAll(text), style: V2Type.title),
    ),
  );
}

class _Copy extends StatelessWidget {
  const _Copy(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(v2KeepAll(text), style: V2Type.body.copyWith(color: V2Color.ink2));
}
