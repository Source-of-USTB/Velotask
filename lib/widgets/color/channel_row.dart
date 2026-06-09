import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velotask/l10n/app_localizations.dart';

class ChannelRow extends StatefulWidget {
  final Color color;
  final ValueChanged<Color> onChanged;
  final String channel;

  const ChannelRow({
    super.key,
    required this.color,
    required this.onChanged,
    required this.channel,
  });

  @override
  State<ChannelRow> createState() => _ChannelRowState();
}

class _ChannelRowState extends State<ChannelRow> {
  late TextEditingController _ctrl;
  late FocusNode _focus;
  int _lastValid = 0;

  @override
  void initState() {
    super.initState();
    _lastValid = _channelVal(widget.color, widget.channel);
    _ctrl = TextEditingController(text: _lastValid.toString());
    _focus = FocusNode();
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(ChannelRow old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus) {
      final v = _channelVal(widget.color, widget.channel);
      if (v != _lastValid || widget.channel != old.channel) {
        _lastValid = v;
        _ctrl.text = v.toString();
      }
    }
  }

  int _channelVal(Color c, String ch) {
    switch (ch) {
      case 'R':
        return (c.r * 255).round();
      case 'G':
        return (c.g * 255).round();
      case 'B':
        return (c.b * 255).round();
      case 'A':
        return (c.a * 255).round();
      default:
        return 0;
    }
  }

  void _onFocusChange() {
    if (_focus.hasFocus) return;
    final raw = _ctrl.text;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 0 || parsed > 255) {
      _ctrl.text = _lastValid.toString();
      return;
    }
    if (parsed == _lastValid) return;
    _lastValid = parsed;
    final ch = widget.channel;
    final c = widget.color;
    final r = ch == 'R' ? parsed : (c.r * 255).round();
    final g = ch == 'G' ? parsed : (c.g * 255).round();
    final b = ch == 'B' ? parsed : (c.b * 255).round();
    final a = ch == 'A' ? parsed : (c.a * 255).round();
    widget.onChanged(Color.fromARGB(a, r, g, b));
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chLabel = widget.channel == 'R'
        ? l10n.redLabel
        : widget.channel == 'G'
        ? l10n.greenLabel
        : widget.channel == 'B'
        ? l10n.blueLabel
        : l10n.alphaLabel;

    return Row(
      children: [
        SizedBox(width: 20, child: Text(chLabel)),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 6,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Expanded(
            child: Slider(
              value: _lastValid.toDouble(),
              min: 0,
              max: 255,
              onChanged: (v) {
                final iv = v.round();
                _ctrl.text = iv.toString();
                setState(() => _lastValid = iv);
              },
              onChangeEnd: (v) {
                final iv = v.round();
                final ch = widget.channel;
                final c = widget.color;
                final r = ch == 'R' ? iv : (c.r * 255).round();
                final g = ch == 'G' ? iv : (c.g * 255).round();
                final b = ch == 'B' ? iv : (c.b * 255).round();
                final a = ch == 'A' ? iv : (c.a * 255).round();
                widget.onChanged(Color.fromARGB(a, r, g, b));
              },
            ),
          ),
        ),
      ],
    );
  }
}
