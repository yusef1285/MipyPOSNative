import 'package:flutter/material.dart';

typedef KeypadCallback = void Function(String value);

class PosKeypad extends StatelessWidget {
  final KeypadCallback onInput;
  final VoidCallback? onBackspace;
  final VoidCallback? onClear;

  const PosKeypad({super.key, required this.onInput, this.onBackspace, this.onClear});

  Widget _button(String label, {Color? color, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: SizedBox(
        height: 64,
        child: Tooltip(
          message: 'Tecla $label',
          child: Semantics(
            label: 'Tecla $label',
            button: true,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color ?? Colors.grey.shade200,
                foregroundColor: color != null ? Colors.white : Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              onPressed: onTap,
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _button('1', onTap: () => onInput('1'))),
            Expanded(child: _button('2', onTap: () => onInput('2'))),
            Expanded(child: _button('3', onTap: () => onInput('3'))),
          ],
        ),
        Row(
          children: [
            Expanded(child: _button('4', onTap: () => onInput('4'))),
            Expanded(child: _button('5', onTap: () => onInput('5'))),
            Expanded(child: _button('6', onTap: () => onInput('6'))),
          ],
        ),
        Row(
          children: [
            Expanded(child: _button('7', onTap: () => onInput('7'))),
            Expanded(child: _button('8', onTap: () => onInput('8'))),
            Expanded(child: _button('9', onTap: () => onInput('9'))),
          ],
        ),
        Row(
          children: [
            Expanded(child: _button('.', onTap: () => onInput('.'))),
            Expanded(child: _button('0', onTap: () => onInput('0'))),
            Expanded(
              child: _button('⌫', color: Colors.orange, onTap: onBackspace),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(child: _button('C', color: Colors.redAccent, onTap: onClear)),
            Expanded(child: _button('00', onTap: () => onInput('00'))),
            Expanded(child: _button('000', onTap: () => onInput('000'))),
          ],
        ),
      ],
    );
  }
}
