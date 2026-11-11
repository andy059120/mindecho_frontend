import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../../app/theme.dart';
import '../../shared/responsive_layout.dart';
import '../../core/storage/account_store.dart';
import '../../shared/widgets.dart';
import '../../shared/system_symbol.dart';
import '../auth/auth_widgets.dart';
import '../dashboard/controller.dart';
import '../dashboard/models.dart';
import '../dashboard/widgets.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({
    required this.controller,
    required this.store,
    this.initialDate,
    super.key,
  });
  final DashboardController controller;
  final AccountStore store;
  final DateTime? initialDate;
  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  late DateTime _selected = calendarDay(widget.initialDate ?? DateTime.now());
  void _history() => Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (_) => CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('日記歷史')),
        child: ContentFrame(
          maxWidth: 760,
          child: SafeArea(
            child: ListView(
              children: [
                for (final e in widget.controller.diaryEntries)
                  CupertinoListTile(
                    title: Text('${dayKey(e.date)} ${moodFor(e.mood).emoji}'),
                    subtitle: Text(
                      e.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      setState(() => _selected = calendarDay(e.date));
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        MindCard(
          color: const Color(0xFFFBF6F0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('選擇日期', style: headingStyle),
              const SizedBox(height: 10),
              CalendarMonth(
                selected: _selected,
                entries: widget.controller.diaryEntries,
                onSelected: (date) => setState(() => _selected = date),
              ),
            ],
          ),
        ),
        if (widget.controller.diaryEntries.any(
          (e) =>
              e.date.year == _selected.year && e.date.month == _selected.month,
        )) ...[
          const SizedBox(height: 16),
          const Text(
            '本月紀錄',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.controller.diaryEntries
                  .where(
                    (e) =>
                        e.date.year == _selected.year &&
                        e.date.month == _selected.month,
                  )
                  .length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final entry = widget.controller.diaryEntries
                    .where(
                      (e) =>
                          e.date.year == _selected.year &&
                          e.date.month == _selected.month,
                    )
                    .elementAt(index);
                return CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () =>
                      setState(() => _selected = calendarDay(entry.date)),
                  child: Container(
                    width: 36,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF6F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${entry.date.day}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.title,
                          ),
                        ),
                        Text(
                          moodFor(entry.mood).emoji,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (widget.controller.errors['diary'] != null)
          ErrorNotice(
            widget.controller.errors['diary']!,
            onRetry: widget.controller.loadDiaries,
          ),
        if (widget.controller.loading.contains('diary'))
          const CupertinoActivityIndicator(),
        DiaryEditor(
          key: ValueKey(dayKey(_selected)),
          controller: widget.controller,
          store: widget.store,
          date: _selected,
          onHistory: _history,
          onToday: () =>
              setState(() => _selected = calendarDay(DateTime.now())),
        ),
      ],
    ),
  );
}

class CalendarMonth extends StatefulWidget {
  const CalendarMonth({
    required this.selected,
    required this.entries,
    required this.onSelected,
    super.key,
  });
  final DateTime selected;
  final List<DiaryEntry> entries;
  final ValueChanged<DateTime> onSelected;
  @override
  State<CalendarMonth> createState() => _CalendarMonthState();
}

class _CalendarMonthState extends State<CalendarMonth> {
  late DateTime _month = DateTime(widget.selected.year, widget.selected.month);
  bool _showMonthPicker = false;
  @override
  void didUpdateWidget(CalendarMonth old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) {
      _month = DateTime(widget.selected.year, widget.selected.month);
      _showMonthPicker = false;
    }
  }

  void _move(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));
  Widget _arrow(String name, String label, int delta) => Semantics(
    label: label,
    button: true,
    excludeSemantics: true,
    onTap: () => _move(delta),
    child: CupertinoButton(
      padding: const EdgeInsets.all(8),
      minimumSize: const Size(32, 32),
      onPressed: () => _move(delta),
      child: SystemSymbol(
        name,
        size: 17,
        weight: 'semibold',
        color: AppColors.title,
        fallback: delta < 0
            ? CupertinoIcons.chevron_left
            : CupertinoIcons.chevron_right,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final first = DateTime(_month.year, _month.month),
        count = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = first.weekday % 7, weeks = ((offset + count) / 7).ceil();
    final today = calendarDay(DateTime.now());
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () =>
                      setState(() => _showMonthPicker = !_showMonthPicker),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_month.year}年${_month.month}月',
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: AppColors.title,
                        ),
                      ),
                      const SizedBox(width: 6),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: _showMonthPicker ? .25 : 0,
                        child: const SystemSymbol(
                          'chevron.right',
                          size: 12,
                          weight: 'semibold',
                          color: AppColors.title,
                          fallback: CupertinoIcons.chevron_right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _arrow('chevron.left', '上一個月', -1),
            const SizedBox(width: 12),
            _arrow('chevron.right', '下一個月', 1),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _showMonthPicker
              ? SizedBox(
                  height: weeks * 44.0 + 28,
                  child: CupertinoTheme(
                    data: CupertinoTheme.of(context).copyWith(
                      textTheme: CupertinoTheme.of(context).textTheme.copyWith(
                        dateTimePickerTextStyle: const TextStyle(
                          fontSize: 21,
                          color: AppColors.title,
                        ),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.monthYear,
                      initialDateTime: _month,
                      backgroundColor: const Color(0xFFFBF6F0),
                      onDateTimeChanged: (date) => setState(
                        () => _month = DateTime(date.year, date.month),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        for (final day in ['日', '一', '二', '三', '四', '五', '六'])
                          Expanded(
                            child: Text(
                              day,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (var week = 0; week < weeks; week++)
                      Row(
                        children: [
                          for (var col = 0; col < 7; col++)
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final day = week * 7 + col - offset + 1;
                                  if (day < 1 || day > count) {
                                    return const SizedBox(height: 44);
                                  }
                                  final date = DateTime(
                                        _month.year,
                                        _month.month,
                                        day,
                                      ),
                                      active =
                                          calendarDay(widget.selected) ==
                                          DateTime(
                                            _month.year,
                                            _month.month,
                                            day,
                                          );
                                  return Semantics(
                                    selected: active,
                                    child: CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 44),
                                      onPressed: () => widget.onSelected(date),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 160,
                                        ),
                                        width: 36,
                                        height: 36,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: active
                                              ? AppColors.title
                                              : null,
                                        ),
                                        child: Text(
                                          '$day',
                                          style: TextStyle(
                                            fontSize: 20,
                                            height: 1.2,
                                            fontWeight: date == today
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: active
                                                ? CupertinoColors.white
                                                : AppColors.title,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class DiaryEditor extends StatefulWidget {
  const DiaryEditor({
    required this.controller,
    required this.store,
    required this.date,
    this.compact = false,
    this.onHistory,
    this.onToday,
    super.key,
  });
  final DashboardController controller;
  final AccountStore store;
  final DateTime date;
  final bool compact;
  final VoidCallback? onHistory, onToday;
  @override
  State<DiaryEditor> createState() => _DiaryEditorState();
}

class _DiaryEditorState extends State<DiaryEditor> {
  final _text = TextEditingController();
  String _mood = 'OKAY';
  String? _id, _error, _message;
  bool _busy = false, _hydrating = true, _dirty = false;
  String get _draftKey => 'diary.draft.${dayKey(widget.date)}';
  @override
  void initState() {
    super.initState();
    _restore();
    _text.addListener(_persist);
  }

  Future<void> _restore() async {
    final entry = widget.controller.diaryOn(widget.date);
    _id = entry?.id;
    _text.text = entry?.content ?? '';
    _mood = entry?.mood ?? 'OKAY';
    try {
      final raw = await widget.store.read(_draftKey);
      if (raw != null && mounted) {
        final draft = jsonDecode(raw) as Map<String, dynamic>;
        _text.text = draft['content'] as String? ?? '';
        _mood = draft['mood'] as String? ?? 'OKAY';
        _dirty = true;
        _message = '已恢復未送出的日記草稿';
      }
    } catch (_) {
      if (mounted) _error = '無法讀取日記草稿';
    }
    if (mounted) {
      _hydrating = false;
      _syncEntry();
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(DiaryEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncEntry();
  }

  void _syncEntry() {
    if (_hydrating || _busy) return;
    final entry = widget.controller.diaryOn(widget.date);
    _id = entry?.id;
    if (!_dirty) {
      _hydrating = true;
      _text.text = entry?.content ?? '';
      _mood = entry?.mood ?? 'OKAY';
      _hydrating = false;
    }
  }

  void _persist() {
    if (_hydrating) return;
    _dirty = true;
    widget.store
        .write(_draftKey, jsonEncode({'content': _text.text, 'mood': _mood}))
        .catchError((Object _) {
          if (mounted) setState(() => _error = '草稿尚未儲存，請保留畫面並重試');
        });
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _error = null);
    if (_text.text.trim().isEmpty) {
      setState(() => _error = '請先寫下日記內容');
      return;
    }
    setState(() => _busy = true);
    try {
      final entry = await widget.controller.saveDiary(
        id: _id,
        content: _text.text,
        mood: _mood,
        date: widget.date,
      );
      await widget.store.write(_draftKey, null);
      if (mounted) {
        setState(() {
          _id = entry.id;
          _dirty = false;
          _message = '日記已儲存';
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = '儲存失敗：$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (_id == null || _busy) return;
    if (!await confirm(
          context,
          title: '刪除日記',
          message: '確定要刪除這篇日記嗎？',
          action: '刪除',
          destructive: true,
        ) ||
        !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.controller.deleteDiary(_id!);
      await widget.store.write(_draftKey, null);
      if (mounted) {
        setState(() {
          _id = null;
          _dirty = false;
          _hydrating = true;
          _text.clear();
          _hydrating = false;
          _message = '日記已刪除';
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _saveEnabled =>
      !_hydrating &&
      !widget.controller.loading.contains('diary') &&
      widget.controller.errors['diary'] == null;
  Widget _field() => SizedBox(
    height: widget.compact ? 140 : 180,
    child: CupertinoTextField(
      controller: _text,
      enabled: !_busy && !_hydrating,
      placeholder: widget.compact ? '開始寫下你的心情…' : null,
      expands: true,
      minLines: null,
      maxLines: null,
      textAlignVertical: TextAlignVertical.top,
      padding: const EdgeInsets.all(14),
      style: const TextStyle(color: AppColors.title, fontSize: 17),
      decoration: BoxDecoration(
        color: widget.compact ? CupertinoColors.white : AppColors.lightYellow,
        borderRadius: BorderRadius.circular(widget.compact ? 14 : 12),
        border: Border.all(
          color: widget.compact
              ? AppColors.lightBrown.withValues(alpha: .4)
              : CupertinoColors.systemGrey.withValues(alpha: .3),
        ),
      ),
    ),
  );
  List<Widget> _notices() => [
    if (_message != null)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          _message!,
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.systemGreen,
          ),
        ),
      ),
    if (_error != null)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          _error!,
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.systemRed,
          ),
        ),
      ),
  ];
  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return MindCard(
        color: const Color(0xFFFBF6F0),
        padding: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('寫日記', style: headingStyle),
            const SizedBox(height: 12),
            Text(
              '可以寫關於你今天發生的事，或是心情……',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.title.withValues(alpha: .55),
              ),
            ),
            const SizedBox(height: 12),
            _field(),
            const SizedBox(height: 16),
            const Text(
              '今天的心情',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _moodChoices(),
            const SizedBox(height: 16),
            AuthAction(
              '儲存日記',
              onPressed: _saveEnabled ? _save : null,
              busy: _busy,
              height: 46,
              fontSize: 17,
            ),
            ..._notices(),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Text('今天的心情', style: headingStyle)),
            Text(
              '已選擇：${moodFor(_mood).label}',
              style: const TextStyle(
                fontSize: 15,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _moodChoices(),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: Text('日記', style: headingStyle)),
            if (widget.onHistory != null)
              textAction('查看歷史日記', widget.onHistory, size: 12),
          ],
        ),
        const SizedBox(height: 12),
        _field(),
        const SizedBox(height: 16),
        MindCard(
          color: const Color(0xFFFBF6F0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${widget.date.year}年${widget.date.month}月${widget.date.day}日',
                      style: headingStyle,
                    ),
                  ),
                  if (widget.onToday != null)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: widget.onToday,
                      child: const Row(
                        children: [
                          SystemSymbol(
                            'calendar',
                            size: 12,
                            color: AppColors.title,
                            fallback: CupertinoIcons.calendar,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '今天',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.title,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 10),
                minimumSize: Size.zero,
                borderRadius: BorderRadius.circular(20),
                color: CupertinoColors.systemOrange,
                onPressed: _saveEnabled && !_busy ? _save : null,
                child: _busy
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SystemSymbol(
                            'tray.and.arrow.down.fill',
                            size: 17,
                            color: CupertinoColors.white,
                            fallback: CupertinoIcons.tray_arrow_down_fill,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '儲存',
                            style: TextStyle(
                              fontSize: 17,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        if (_id != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: textAction(
              '刪除此篇日記',
              _busy ? null : _delete,
              color: CupertinoColors.systemRed,
              size: 14,
            ),
          ),
        ..._notices(),
      ],
    );
  }

  Widget _moodChoices() => SizedBox(
    height: widget.compact ? 94 : 100,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: moods.length,
      padding: widget.compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16),
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final mood = moods[index];
        return CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: _busy || _hydrating
              ? null
              : () {
                  setState(() => _mood = mood.code);
                  _persist();
                },
          child: Container(
            width: widget.compact ? 70 : 90,
            margin: widget.compact
                ? const EdgeInsets.symmetric(vertical: 8)
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: widget.compact
                  ? (_mood == mood.code
                        ? AppColors.lightYellow
                        : CupertinoColors.white)
                  : const Color(0xFFFBF6F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _mood == mood.code
                    ? AppColors.userBubble
                    : CupertinoColors.systemGrey.withValues(alpha: .2),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  mood.emoji,
                  style: TextStyle(fontSize: widget.compact ? 22 : 34),
                ),
                const SizedBox(height: 6),
                Text(
                  mood.label,
                  style: const TextStyle(fontSize: 12, color: AppColors.title),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
