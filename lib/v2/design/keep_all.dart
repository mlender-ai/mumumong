/// Korean editorial line breaking for display text only (word-break:
/// keep-all): syllables of one word are joined so lines break at spaces.
/// Never applied to stored text or editable fields.
String v2KeepAll(String text) => text
    .split(' ')
    .map((word) => word.runes.map(String.fromCharCode).join('⁠'))
    .join(' ');
