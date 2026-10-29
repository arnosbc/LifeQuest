// deno test supabase/functions/npc-context
import { assertEquals } from 'jsr:@std/assert@1';
import { strToU8, zipSync } from 'npm:fflate@0.8.2';
import { docxText, documentPart, kindOf } from './index.ts';

Deno.test('kindOf acepta PDF, Word .docx y Markdown', () => {
  assertEquals(kindOf('u/n/Plan.PDF'), 'pdf');
  assertEquals(kindOf('u/n/plan.docx'), 'docx');
  assertEquals(kindOf('u/n/notas.md'), 'text');
  assertEquals(kindOf('u/n/notas.markdown'), 'text');
  assertEquals(kindOf('u/n/viejo.doc'), null);
  assertEquals(kindOf('u/n/foto.png'), null);
});

const docx = (body: string) =>
  zipSync({
    '[Content_Types].xml': strToU8('<Types/>'),
    'word/document.xml': strToU8(`<w:document><w:body>${body}</w:body></w:document>`),
  });

Deno.test('docxText saca un párrafo por línea y decodifica entidades', () => {
  const bytes = docx(
    '<w:p><w:r><w:t>Unidad 1:</w:t></w:r><w:r><w:tab/><w:t>Flutter &amp; Dart</w:t></w:r></w:p>' +
      '<w:p><w:r><w:t xml:space="preserve">Estado &lt;Bloc&gt; </w:t></w:r></w:p>' +
      '<w:p/><w:p/><w:p><w:r><w:t>Programaci&#243;n m&#xF3;vil</w:t></w:r></w:p>',
  );
  assertEquals(docxText(bytes), 'Unidad 1:\tFlutter & Dart\nEstado <Bloc>\n\nProgramación móvil');
});

Deno.test('documentPart envía el PDF tal cual y el texto como texto', () => {
  const pdf = documentPart('pdf', new Uint8Array([37, 80, 68, 70]));
  assertEquals(pdf, { inlineData: { mimeType: 'application/pdf', data: 'JVBERg==' } });
  assertEquals(documentPart('text', new TextEncoder().encode('# Tema 1\n')), { text: 'Documento:\n# Tema 1' });
  assertEquals(documentPart('text', new TextEncoder().encode('   ')), null);
  assertEquals(documentPart('docx', docx('<w:p/>')), null);
});
