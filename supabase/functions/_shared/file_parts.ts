import { encodeBase64 } from 'jsr:@std/encoding@1/base64';
import { strFromU8, unzipSync } from 'npm:fflate@0.8.2';

export type DocKind = 'pdf' | 'docx' | 'text';

const TEXT_MAX = 300_000;
const DOCX_XML_MAX = 1_000_000;
const ENTITIES: Record<string, string> = {
  amp: '&',
  lt: '<',
  gt: '>',
  quot: '"',
  apos: "'",
};

export function kindOf(path: string): DocKind | null {
  const ext = path.toLowerCase().split('.').pop();
  if (ext === 'pdf') return 'pdf';
  if (ext === 'docx') return 'docx';
  if (ext === 'md' || ext === 'markdown' || ext === 'txt') return 'text';
  return null;
}

export function docxText(bytes: Uint8Array): string {
  const files = unzipSync(bytes, {
    filter: (file) =>
      file.name === 'word/document.xml' &&
      typeof file.originalSize === 'number' &&
      file.originalSize <= DOCX_XML_MAX,
  });
  const xml = files['word/document.xml'];
  if (!xml) return '';
  return strFromU8(xml)
    .replace(/<w:tab\/>/g, '\t')
    .replace(/<w:br\/>|<w:p\/>|<\/w:p>/g, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&(#x[0-9a-f]+|#\d+|\w+);/gi, (match, entity: string) =>
      entity[0] === '#'
        ? String.fromCodePoint(
            parseInt(
              entity[1] === 'x' ? entity.slice(2) : entity.slice(1),
              entity[1] === 'x' ? 16 : 10,
            ),
          )
        : ENTITIES[entity] ?? match,
    )
    .replace(/[ \t]+\n/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

export function documentPart(
  kind: DocKind,
  bytes: Uint8Array,
): Record<string, unknown> | null {
  if (kind === 'pdf') {
    return {
      inlineData: { mimeType: 'application/pdf', data: encodeBase64(bytes) },
    };
  }
  const text = (
    kind === 'docx' ? docxText(bytes) : new TextDecoder().decode(bytes)
  ).trim();
  return text ? { text: `Documento:\n${text.slice(0, TEXT_MAX)}` } : null;
}

export function evidencePart(
  name: string,
  bytes: Uint8Array,
): Record<string, unknown> | null {
  const ext = name.toLowerCase().split('.').pop();
  const imageTypes: Record<string, string> = {
    jpg: 'image/jpeg',
    jpeg: 'image/jpeg',
    png: 'image/png',
    heic: 'image/heic',
    heif: 'image/heif',
  };
  const imageType = ext ? imageTypes[ext] : null;
  if (imageType) {
    return {
      inlineData: { mimeType: imageType, data: encodeBase64(bytes) },
    };
  }
  const kind = kindOf(name);
  return kind ? documentPart(kind, bytes) : null;
}
