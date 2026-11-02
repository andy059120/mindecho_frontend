import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../app/theme.dart';
import '../../core/platform/local_media_store.dart';
import '../../shared/widgets.dart';
import '../../shared/system_symbol.dart';
import '../auth/auth_widgets.dart';
import '../dashboard/widgets.dart';

Future<void> showTreasure(BuildContext context, LocalMediaStore store) =>
    showCupertinoSheet<void>(
      context: context,
      scrollableBuilder: (_, controller) =>
          TreasurePage(store: store, scrollController: controller),
    );

class TreasurePage extends StatefulWidget {
  const TreasurePage({required this.store, this.scrollController, super.key});
  final LocalMediaStore store;
  final ScrollController? scrollController;
  @override
  State<TreasurePage> createState() => _TreasurePageState();
}

class _TreasurePageState extends State<TreasurePage> {
  List<LocalItem> _items = [];
  bool _loading = true, _busy = false, _loadFailed = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
      _error = null;
    });
    try {
      final items = await widget.store.load();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadFailed = true;
          _error = '無法讀取本機收藏，請稍後再試';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _commit(List<LocalItem> next) async {
    final wasBusy = _busy;
    setState(() => _busy = true);
    try {
      await widget.store.save(next);
      if (mounted) setState(() => _items = next);
    } finally {
      if (mounted) setState(() => _busy = wasBusy);
    }
  }

  Future<void> _edit([LocalItem? item]) async {
    if (_busy || _loading || _loadFailed) return;
    final result = await showCupertinoSheet<(String, String)>(
      context: context,
      scrollableBuilder: (_, _) => _TextEditor(initial: item),
    );
    if (result == null || !mounted) return;
    final next = LocalItem(
      id: item?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      kind: 'text',
      title: result.$1,
      detail: result.$2,
      date: item?.date ?? DateTime.now(),
    );
    try {
      await _commit(
        item == null
            ? [..._items, next]
            : _items.map((e) => e.id == item.id ? next : e).toList(),
      );
    } catch (_) {
      if (mounted) setState(() => _error = '文字尚未儲存，請重試');
    }
  }

  Future<void> _pick(String kind) async {
    if (_busy || _loading || _loadFailed) return;
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      final file = kind == 'image'
          ? await picker.pickImage(source: ImageSource.gallery)
          : await picker.pickVideo(source: ImageSource.gallery);
      if (file != null) {
        final item = await widget.store.importFile(file.path, kind);
        await _commit([..._items, item]);
      }
    } catch (_) {
      if (mounted) setState(() => _error = '無法新增檔案，請檢查照片權限與儲存空間');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(LocalItem item) async {
    if (_busy || _loading || _loadFailed) return;
    if (!await confirm(
          context,
          title: '刪除收藏',
          message: '確定要刪除「${item.title}」嗎？',
          action: '刪除',
          destructive: true,
        ) ||
        !mounted) {
      return;
    }
    try {
      await _commit(_items.where((e) => e.id != item.id).toList());
      if (item.filename != null) await widget.store.removeFile(item.filename!);
    } catch (_) {
      if (mounted) setState(() => _error = '刪除失敗，請重試');
    }
  }

  Future<void> _move(LocalItem item, int delta) async {
    if (_busy || _loading || _loadFailed) return;
    final kindItems = _items.where((e) => e.kind == item.kind).toList();
    final index = kindItems.indexWhere((e) => e.id == item.id),
        target = index + delta;
    if (target < 0 || target >= kindItems.length) return;
    final next = [..._items];
    final i = next.indexOf(item), j = next.indexOf(kindItems[target]);
    next[i] = next[j];
    next[j] = item;
    try {
      await _commit(next);
    } catch (_) {
      if (mounted) setState(() => _error = '排序尚未儲存');
    }
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    child: SafeArea(
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(28),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '支撐我的片刻',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.orange.withValues(alpha: .15),
                  ),
                  child: const SystemSymbol(
                    'xmark',
                    size: 16,
                    weight: 'bold',
                    color: AppColors.title,
                    fallback: CupertinoIcons.xmark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('時光寶盒', style: headingStyle),
          const SizedBox(height: 4),
          const Text(
            '文字、圖片與影片都會儲存在這支手機，可不限量新增。',
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 20),
          if (_error != null) ErrorNotice(_error!, onRetry: _load),
          if (_loading || _busy) const CupertinoActivityIndicator(),
          for (final section in [
            ('text', '文字', '寫下支撐你的話與片刻感受，可新增多筆'),
            ('image', '圖片', '收集讓你感到安心的畫面，可新增多張'),
            ('video', '影片', '留下能提醒你勇氣的片段，可新增多支'),
          ]) ...[
            Row(
              children: [
                Text(
                  section.$2,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    section.$3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.title.withValues(alpha: .6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  color: AppColors.orange.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(10),
                  onPressed: _busy || _loading || _loadFailed
                      ? null
                      : () =>
                            section.$1 == 'text' ? _edit() : _pick(section.$1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SystemSymbol(
                        'plus.circle.fill',
                        size: 12,
                        color: AppColors.title,
                        fallback: CupertinoIcons.plus_circle_fill,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '新增${section.$2}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.title,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!_items.any((e) => e.kind == section.$1))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '尚未新增${section.$2}內容',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.title.withValues(alpha: .6),
                  ),
                ),
              ),
            for (final item in _items.where((e) => e.kind == section.$1))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MindCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.kind == 'text') ...[
                        Text(item.title, style: headingStyle),
                        const SizedBox(height: 8),
                        Text(item.detail, style: const TextStyle(fontSize: 15)),
                      ] else
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(context).push(
                            CupertinoPageRoute<void>(
                              builder: (_) => _MediaPreview(
                                item: item,
                                store: widget.store,
                              ),
                            ),
                          ),
                          child: item.kind == 'image'
                              ? FutureBuilder(
                                  future: widget.store.bytes(item.filename!),
                                  builder: (context, snapshot) =>
                                      snapshot.connectionState ==
                                              ConnectionState.done &&
                                          snapshot.data == null
                                      ? const Text('無法讀取這個檔案')
                                      : snapshot.data == null
                                      ? const SizedBox(
                                          height: 120,
                                          child: Center(
                                            child: CupertinoActivityIndicator(),
                                          ),
                                        )
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Image.memory(
                                            snapshot.data!,
                                            height: 160,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                )
                              : const SizedBox(
                                  height: 100,
                                  child: Center(
                                    child: Icon(
                                      CupertinoIcons.play_circle,
                                      size: 48,
                                    ),
                                  ),
                                ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '${item.date.year}/${item.date.month}/${item.date.day}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                          const Spacer(),
                          if (item.kind == 'text')
                            textAction('編輯', () => _edit(item)),
                          const SizedBox(width: 12),
                          textAction('↑', () => _move(item, -1)),
                          const SizedBox(width: 12),
                          textAction('↓', () => _move(item, 1)),
                          const SizedBox(width: 12),
                          textAction(
                            '刪除',
                            () => _delete(item),
                            color: CupertinoColors.systemRed,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    ),
  );
}

class _TextEditor extends StatefulWidget {
  const _TextEditor({this.initial});
  final LocalItem? initial;
  @override
  State<_TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<_TextEditor> {
  late final _title = TextEditingController(text: widget.initial?.title),
      _detail = TextEditingController(text: widget.initial?.detail);
  String? _error;
  @override
  void dispose() {
    _title.dispose();
    _detail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(
      middle: Text(widget.initial == null ? '新增文字' : '編輯文字'),
      trailing: textAction('取消', () => Navigator.pop(context), size: 17),
    ),
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AuthField('標題', controller: _title),
          const SizedBox(height: 20),
          const Text('內容', style: headingStyle),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _detail,
            minLines: 8,
            maxLines: 12,
            padding: const EdgeInsets.all(14),
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(color: CupertinoColors.systemRed),
            ),
          AuthAction(
            '儲存',
            onPressed: () {
              if (_title.text.trim().isEmpty || _detail.text.trim().isEmpty) {
                setState(() => _error = '請填寫標題與內容');
                return;
              }
              Navigator.pop(context, (_title.text.trim(), _detail.text.trim()));
            },
          ),
        ],
      ),
    ),
  );
}

class _MediaPreview extends StatefulWidget {
  const _MediaPreview({required this.item, required this.store});
  final LocalItem item;
  final LocalMediaStore store;
  @override
  State<_MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<_MediaPreview> {
  VideoPlayerController? _player;
  String? _error;
  @override
  void initState() {
    super.initState();
    if (widget.item.kind == 'video') _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final path = await widget.store.path(widget.item.filename!);
      if (!mounted) return;
      final player = VideoPlayerController.file(File(path));
      _player = player;
      await player.initialize();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _error = '無法播放這部影片');
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    backgroundColor: CupertinoColors.black,
    navigationBar: const CupertinoNavigationBar(middle: Text('預覽')),
    child: SafeArea(
      child: Center(
        child: _error != null
            ? Text(
                _error!,
                style: const TextStyle(color: CupertinoColors.white),
              )
            : widget.item.kind == 'image'
            ? FutureBuilder(
                future: widget.store.bytes(widget.item.filename!),
                builder: (context, snapshot) => snapshot.data == null
                    ? const CupertinoActivityIndicator()
                    : InteractiveViewer(child: Image.memory(snapshot.data!)),
              )
            : _player?.value.isInitialized != true
            ? const CupertinoActivityIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _player!.value.aspectRatio,
                    child: VideoPlayer(_player!),
                  ),
                  VideoProgressIndicator(_player!, allowScrubbing: true),
                  CupertinoButton(
                    onPressed: () async {
                      if (_player!.value.isPlaying) {
                        await _player!.pause();
                      } else {
                        await _player!.play();
                      }
                      if (mounted) setState(() {});
                    },
                    child: Icon(
                      _player!.value.isPlaying
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.play_fill,
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}
