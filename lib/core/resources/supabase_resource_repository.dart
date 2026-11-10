import 'dart:io';
import 'dart:math';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/errors/supabase_guard.dart';
import 'package:proyecto_movil/core/resources/resource.dart';

/// [ResourceRepository] con Supabase: Storage (bucket `resources`, carpeta
/// del usuario) y las RPC de 045.
class SupabaseResourceRepository implements ResourceRepository {
  SupabaseResourceRepository(this._client);

  final SupabaseClient _client;

  /// Archivo local → ruta en Storage, para no subir dos veces el mismo
  /// (al pedir pasos a la IA y luego al guardar).
  final _uploaded = <String, String>{};

  static const _bucket = 'resources';

  static String _message(ServerException e) => switch (e.code) {
    'invalid_url' => 'El enlace debe empezar por http:// o https://.',
    'invalid_size' => 'El archivo pasa de 10 MB.',
    'invalid_path' || 'invalid_kind' => 'Solo fotos (JPG, PNG, WEBP) o PDF.',
    'not_found' => 'Ya no existe. Recarga e inténtalo de nuevo.',
    _ => 'No se pudo guardar el recurso. Inténtalo de nuevo.',
  };

  static String _target(ResourceTargetKind k) => k.name;

  @override
  Future<Either<Failure, List<Resource>>> list(ResourceTarget target) =>
      runGuarded(
        () => guardSupabase(() async {
          final rows = await _client.rpc<List<dynamic>>(
            'item_resources',
            params: {'p_target': _target(target.kind), 'p_target_id': target.id},
          );
          return [
            for (final r in rows.cast<Map<String, dynamic>>())
              Resource(
                id: r['id'] as String,
                kind: ResourceKind.values.byName(r['kind'] as String),
                title: r['title'] as String,
                url: r['url'] as String?,
                path: r['path'] as String?,
                note: r['note'] as String?,
              ),
          ];
        }),
        (_) => 'No se pudieron cargar los recursos.',
      );

  @override
  Future<Either<Failure, Unit>> attach(
    ResourceTarget target,
    ResourceDraft draft,
  ) => runGuarded(() async {
    if (draft.problem case final p?) throw ServerException(code: p);
    final path = draft.isFile ? await _upload(draft) : null;
    await guardSupabase(
      () => _client.rpc<String>(
        'attach_resource',
        params: {
          'p_target': _target(target.kind),
          'p_target_id': target.id,
          'p_kind': draft.kind.name,
          'p_title': draft.title,
          'p_url': draft.url,
          'p_path': path,
          'p_size': draft.size,
          'p_note': draft.note,
        },
      ),
    );
    return unit;
  }, (e) => draft.problem ?? _message(e));

  @override
  Future<Either<Failure, Unit>> delete(Resource resource) =>
      runGuarded(() async {
        final path = await guardSupabase(
          () => _client.rpc<String?>(
            'delete_resource',
            params: {'p_id': resource.id},
          ),
        );
        if (path != null) {
          // shortcut: si falla, el archivo queda huérfano (ver 045).
          await _client.storage.from(_bucket).remove([path]).catchError((_) => <FileObject>[]);
        }
        return unit;
      }, (_) => 'No se pudo borrar el recurso.');

  @override
  Future<Either<Failure, String>> openUrl(Resource resource) => runGuarded(
    () async =>
        resource.url ??
        await guardSupabase(
          () => _client.storage
              .from(_bucket)
              .createSignedUrl(resource.path!, 3600),
        ),
    (_) => 'No se pudo abrir el recurso.',
  );

  @override
  Future<Either<Failure, AiContext>> prepareForAi(
    List<ResourceDraft> drafts,
  ) => runGuarded(() async {
    final paths = <String>[];
    for (final d in drafts.where((d) => d.isFile && d.problem == null).take(3)) {
      paths.add(await _upload(d));
    }
    return AiContext(
      paths: paths,
      context: [
        for (final d in drafts)
          if (d.kind == ResourceKind.note) d.note!
          else if (d.kind == ResourceKind.link) '${d.title}: ${d.url}',
      ],
    );
  }, (_) => 'No se pudieron subir los archivos.');

  Future<String> _upload(ResourceDraft draft) async {
    final local = draft.localPath!;
    if (_uploaded[local] case final done?) return done;
    final ext = draft.extension!;
    final path = '${_client.auth.currentUser?.id}/${_uuid()}.$ext';
    final bytes = await File(local).readAsBytes();
    await guardSupabase(
      () => _client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: ext == 'pdf'
                  ? 'application/pdf'
                  : 'image/${ext == 'jpg' ? 'jpeg' : ext}',
            ),
          ),
    );
    return _uploaded[local] = path;
  }

  /// UUID v4: la RPC exige `<uid>/<uuid>.<ext>`.
  static String _uuid() {
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  }
}
