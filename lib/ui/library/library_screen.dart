import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/design_system.dart';
import '../../core/design/dot_cover.dart';
import '../../core/design/dream_atmosphere.dart';
import '../../core/log/app_log.dart';
import '../../di/providers.dart';
import '../../domain/model/frozen_book.dart';
import '../../domain/model/models.dart';
import '../settings/settings_components.dart';
import 'book_pdf.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool _loading = false, _failed = false;
  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  Future<void> _refresh() async {
    if (_loading) return;
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
    return SettingsDetailFrame(
      title: '내가 완성한 책',
      description: '완성할 때의 문장과 출처를 그대로 보관해요.',
      onBack: () => Navigator.pop(context),
      child: ref
          .watch(completedBooksProvider)
          .when(
            loading: () => const Center(child: Text('책을 불러오는 중이에요.')),
            error: (_, _) => Center(
              child: MongButton.ghost(
                label: '다시 불러오기',
                onPressed: () => ref.invalidate(completedBooksProvider),
              ),
            ),
            data: (list) => ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              children: [
                if (_failed)
                  const Text('서버의 책을 확인하지 못했어요. 이 기기에 보관된 책은 열 수 있어요.'),
                if (_loading) const MetaText('완성본을 확인하는 중'),
                for (final book in list)
                  SettingsNavigationRow(
                    title: book.title,
                    subtitle:
                        'VOL.${book.volumeNo.toString().padLeft(2, '0')} · 완성본 v1',
                    onTap: () => Navigator.push(
                      context,
                      quietPageRoute(CompletedBookScreen(book: book)),
                    ),
                  ),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text('아직 완성한 책이 없어요. 꿈에서 자란 원고를 이곳에 보관할 수 있어요.'),
                  ),
                if (volume != null &&
                    volume.status != VolumeStatus.completed) ...[
                  const SizedBox(height: 32),
                  MongActionGroup(
                    primary: EditorialButton(
                      label: volume.status == VolumeStatus.completing
                          ? '완성본 저장 상태'
                          : '원고 완성 준비',
                      onPressed: () => Navigator.push(
                        context,
                        quietPageRoute(CompletionScreen(volumeId: volume.id)),
                      ),
                    ),
                  ),
                ],
                MongButton.ghost(
                  label: '서버에서 다시 확인',
                  onPressed: _loading ? null : _refresh,
                ),
              ],
            ),
          ),
    );
  }
}

class CompletionScreen extends ConsumerStatefulWidget {
  const CompletionScreen({super.key, required this.volumeId});
  final String volumeId;
  @override
  ConsumerState<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends ConsumerState<CompletionScreen> {
  final _title = TextEditingController(), _note = TextEditingController();
  BookCompletionPreview? _preview;
  bool _loading = true, _saving = false, _review = false;
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

  @override
  Widget build(BuildContext context) {
    final book =
        (ref.watch(completedBooksProvider).value ?? const <FrozenBook>[])
            .where((b) => b.volumeId == widget.volumeId)
            .firstOrNull;
    if (book != null) return CompletedBookScreen(book: book);
    final request = ref.watch(completionRequestProvider(widget.volumeId)).value;
    Widget child;
    if (request?.status == 'pending') {
      child = MongFlowPage(
        content: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('완성본 저장을 기다리고 있어요.'),
            SizedBox(height: 16),
            Text(
              '이 화면을 닫아도 요청은 남아요. 연결되면 같은 요청으로 이어서 저장해요. 서버 확인 전에는 완성됐다고 표시하지 않아요.',
            ),
          ],
        ),
        actions: MongActionGroup(
          primary: EditorialButton(
            label: '저장 다시 확인',
            onPressed: () async {
              try {
                await ref.read(bookStoreProvider).retry(widget.volumeId);
                await ref.read(bookStoreProvider).refresh();
              } on Object {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('저장 상태를 아직 확인하지 못했어요. 요청은 보관하고 있어요.'),
                    ),
                  );
                }
              }
            },
          ),
        ),
      );
    } else if (_loading) {
      child = const Center(child: Text('현재 원고를 확인하는 중이에요.'));
    } else if (request?.status == 'conflict' &&
        _checkedConflict != request?.requestId) {
      child = MongFlowPage(
        content: const Text(
          '원고나 작업 상태가 바뀌었어요. 제목과 작가의 말은 유지했어요. 현재 원고를 다시 확인해 주세요.',
        ),
        actions: MongActionGroup(
          primary: EditorialButton(label: '현재 원고 다시 확인', onPressed: _load),
        ),
      );
    } else if (_preview == null) {
      child = MongFlowPage(
        content: Text(_error ?? '원고를 확인하지 못했어요.'),
        actions: MongActionGroup(
          primary: EditorialButton(label: '다시 확인', onPressed: _load),
        ),
      );
    } else if (!_preview!.eligible || _preview!.busy) {
      child = MongFlowPage(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _preview!.busy ? '진행 중인 장면이 있어요.' : '조금 더 원고를 쌓아 주세요.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              '단편은 재료 70% 이상, 본문이 있는 장면 5개 이상, 두 꿈에 걸쳐 반복된 연결 재료가 필요해요. 수치는 문학적 완결을 보장하지 않아요.',
            ),
            const SizedBox(height: 16),
            const Text('새 엔딩이나 문장 편집 없이 현재 원고를 고정하는 완성본이에요.'),
          ],
        ),
        actions: MongActionGroup(
          primary: EditorialButton(
            label: '계속 쌓기',
            onPressed: () => Navigator.pop(context),
          ),
          secondary: [MongButton.ghost(label: '상태 다시 확인', onPressed: _load)],
        ),
      );
    } else {
      child = ListView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          if (request?.status == 'conflict')
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text('원고나 작업 상태가 바뀌었어요. 현재 원고를 다시 확인한 뒤 새 요청으로 확정해 주세요.'),
            ),
          Text(
            _review ? '이 원고를 한 권으로 보관할까요?' : '작품의 이름을 붙여 주세요.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          if (!_review) ...[
            TextField(
              controller: _title,
              maxLength: 120,
              decoration: const InputDecoration(labelText: '책 제목'),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _note,
              maxLength: 10000,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: '작가의 말 · 선택',
                hintText: '직접 쓴 말만 담겨요. 비워 두어도 괜찮아요.',
              ),
            ),
          ] else ...[
            Text(_title.text, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(
              '${(_preview!.document['scenes'] as List).length}개 장면 · 기록 순서 그대로 · 완성본 v1',
            ),
            const SizedBox(height: 16),
            const Text(
              '기존 문장을 고정해 보관해요. 새 엔딩이나 문장 개정은 하지 않아요. 이후 변경은 이 완성본에 섞이지 않아요. 저장만 한 꿈은 보관함에 남아요.',
            ),
            if (_note.text.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('작가의 말'),
              Text(_note.text),
            ],
          ],
          if (_error != null) ...[const SizedBox(height: 16), Text(_error!)],
          const SizedBox(height: 32),
          MongActionGroup(
            primary: EditorialButton(
              label: _saving
                  ? '저장 요청 중'
                  : _review
                  ? '원고 완성하기'
                  : '내용 확인',
              onPressed: _saving
                  ? null
                  : () => _review
                        ? _save()
                        : setState(() {
                            if (_title.text.trim().isEmpty) {
                              _error = '책 제목을 적어 주세요.';
                            } else {
                              _error = null;
                              _review = true;
                              FocusManager.instance.primaryFocus?.unfocus();
                            }
                          }),
            ),
            secondary: [
              MongButton.ghost(
                label: _review ? '제목과 작가의 말 수정' : '계속 쌓기',
                onPressed: _saving
                    ? null
                    : () => _review
                          ? setState(() => _review = false)
                          : Navigator.pop(context),
              ),
            ],
          ),
        ],
      );
    }
    return SettingsDetailFrame(
      title: '원고 완성하기',
      description: '기존 문장을 그대로 보관하는 완성본이에요.',
      onBack: () => Navigator.pop(context),
      child: child,
    );
  }
}

class CompletedBookScreen extends ConsumerStatefulWidget {
  const CompletedBookScreen({super.key, required this.book});
  final FrozenBook book;
  @override
  ConsumerState<CompletedBookScreen> createState() =>
      _CompletedBookScreenState();
}

class _CompletedBookScreenState extends ConsumerState<CompletedBookScreen> {
  bool _exporting = false, _starting = false;
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
      if (!mounted) return;
      setState(() => _message = bookPdfShareMessage(status));
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
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
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
    final book = widget.book, prefs = ref.watch(uiPreferencesProvider);
    return SettingsDetailFrame(
      title: book.title,
      description:
          'VOL.${book.volumeNo.toString().padLeft(2, '0')} · 완성본 v1 · 원고와 분리해 보관',
      onBack: () => Navigator.pop(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          // DESIGN.md §8: even the finished cover keeps dropout and blur.
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(MongRadius.panel),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DreamAtmosphere(night: context.isNight),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(MongSpace.lg),
                      child: DotCover(spec: homeCoverSpec(book.volumeId, 1)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: MongSpace.xl),
          MongActionGroup(
            primary: MongButton(
              label: _exporting ? 'PDF 준비 중' : 'PDF 저장·공유',
              onPressed: _exporting ? null : _export,
            ),
            secondary: [
              MongButton.ghost(
                label: _starting ? '다음 권 여는 중' : '다음 권 시작',
                onPressed: _starting ? null : _next,
              ),
            ],
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!),
          ],
          const SizedBox(height: 32),
          for (final scene in book.scenes) ...[
            Text(
              (scene['title'] as String?)?.isNotEmpty == true
                  ? scene['title'] as String
                  : '장면',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            for (final raw in scene['passages'] as List) ...[
              Text(
                (raw as Map)['text'] as String,
                style: manuscriptStyle(context, scale: prefs.readerScale),
              ),
              if (prefs.showOrigins)
                MetaText(switch (raw['origin']) {
                  'D' => '꿈에서',
                  'U' => '내가 씀',
                  _ => '연결·각색',
                }),
              const SizedBox(height: 24),
            ],
            const SizedBox(height: 24),
          ],
          if (book.authorNote?.isNotEmpty == true) ...[
            const Text('작가의 말'),
            const SizedBox(height: 16),
            Text(book.authorNote!),
          ],
        ],
      ),
    );
  }
}

class FinishedVolumeHome extends ConsumerWidget {
  const FinishedVolumeHome({super.key, required this.volume});
  final Volume volume;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
    child: MongFlowPage(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 280,
            child: DreamAtmosphere(night: context.isNight, memoryObject: true),
          ),
          const SizedBox(height: 24),
          Text(
            volume.status == VolumeStatus.completing
                ? '완성본 저장을 기다리고 있어요.'
                : '한 권의 이야기가 남았어요.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(volume.title ?? '완성한 책을 다시 열어 보세요.'),
        ],
      ),
      actions: MongActionGroup(
        primary: EditorialButton(
          label: volume.status == VolumeStatus.completing
              ? '저장 상태 확인'
              : '완성본 열기',
          onPressed: () => Navigator.push(
            context,
            quietPageRoute(CompletionScreen(volumeId: volume.id)),
          ),
        ),
      ),
    ),
  );
}
