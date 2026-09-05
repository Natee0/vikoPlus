const basic = new Set(
  "@\u00a3$\u00a5\u00e8\u00e9\u00f9\u00ec\u00f2\u00c7\n\u00d8\u00f8\r\u00c5\u00e5\u0394_\u03a6\u0393\u039b\u03a9\u03a0\u03a8\u03a3\u0398\u039e\u00c6\u00e6\u00df\u00c9 !\"#\u00a4%&'()*+,-./0123456789:;<=>?\u00a1ABCDEFGHIJKLMNOPQRSTUVWXYZ\u00c4\u00d6\u00d1\u00dc\u00a7\u00bfabcdefghijklmnopqrstuvwxyz\u00e4\u00f6\u00f1\u00fc\u00e0",
);
const extended = new Set("\f^{}\\[~]|\u20ac");

export function smsSegments(content: string): number {
  let septets = 0;
  for (const character of content) {
    if (basic.has(character)) septets++;
    else if (extended.has(character)) septets += 2;
    else
      return Math.max(
        1,
        Math.ceil(content.length / (content.length <= 70 ? 70 : 67)),
      );
  }
  return Math.max(1, Math.ceil(septets / (septets <= 160 ? 160 : 153)));
}
