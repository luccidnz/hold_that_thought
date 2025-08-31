import 'package:hive/hive.dart';

class Thought {
  final String id;
  final String path;
  final DateTime createdAt;
  final int? durationMs;
  final String? transcript;
  final String? title;
  final List<String>? tags;
  final List<double>? embedding;
  final String? remoteId;
  final String? sha256;
  final DateTime? uploadedAt;

  const Thought({
    required this.id,
    required this.path,
    required this.createdAt,
    this.durationMs,
    this.transcript,
    this.title,
    this.tags,
    this.embedding,
    this.remoteId,
    this.sha256,
    this.uploadedAt,
  });

  Thought copyWith({
    String? id,
    String? path,
    DateTime? createdAt,
    int? durationMs,
    String? transcript,
    String? title,
    List<String>? tags,
    List<double>? embedding,
    String? remoteId,
    String? sha256,
    DateTime? uploadedAt,
  }) =>
      Thought(
        id: id ?? this.id,
        path: path ?? this.path,
        createdAt: createdAt ?? this.createdAt,
        durationMs: durationMs ?? this.durationMs,
        transcript: transcript ?? this.transcript,
        title: title ?? this.title,
        tags: tags ?? this.tags,
        embedding: embedding ?? this.embedding,
        remoteId: remoteId ?? this.remoteId,
        sha256: sha256 ?? this.sha256,
        uploadedAt: uploadedAt ?? this.uploadedAt,
      );
}

class ThoughtAdapter extends TypeAdapter<Thought> {
  @override
  final int typeId = 7;

  @override
  Thought read(BinaryReader r) {
    final id = r.readString();
    final path = r.readString();
    final createdAtMillis = r.readInt();

    int? dur;
    if (r.availableBytes > 0) {
      final hasDur = r.readBool();
      if (hasDur && r.availableBytes >= 4) dur = r.readInt();
    }

    String? transcript;
    if (r.availableBytes > 0) {
      final hasTranscript = r.readBool();
      if (hasTranscript && r.availableBytes > 0) transcript = r.readString();
    }

    String? title;
    if (r.availableBytes > 0) {
      final hasTitle = r.readBool();
      if (hasTitle && r.availableBytes > 0) title = r.readString();
    }

    List<String>? tags;
    if (r.availableBytes > 0) {
      final hasTags = r.readBool();
      if (hasTags && r.availableBytes >= 4) {
        final len = r.readInt();
        final out = <String>[];
        for (var i = 0; i < len && r.availableBytes > 0; i++) {
          out.add(r.readString());
        }
        tags = out;
      }
    }

    List<double>? embedding;
    if (r.availableBytes > 0) {
      final hasEmb = r.readBool();
      if (hasEmb && r.availableBytes >= 4) {
        final len = r.readInt();
        final out = <double>[];
        for (var i = 0; i < len && r.availableBytes >= 8; i++) {
          out.add(r.readDouble());
        }
        embedding = out;
      }
    }

    String? remoteId;
    if (r.availableBytes > 0) {
      final hasRemoteId = r.readBool();
      if (hasRemoteId && r.availableBytes > 0) remoteId = r.readString();
    }

    String? sha256;
    if (r.availableBytes > 0) {
      final hasSha256 = r.readBool();
      if (hasSha256 && r.availableBytes > 0) sha256 = r.readString();
    }

    DateTime? uploadedAt;
    if (r.availableBytes > 0) {
      final hasUploadedAt = r.readBool();
      if (hasUploadedAt && r.availableBytes >= 8) {
        uploadedAt = DateTime.fromMillisecondsSinceEpoch(r.readInt());
      }
    }

    return Thought(
      id: id,
      path: path,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMillis),
      durationMs: dur,
      transcript: transcript,
      title: title,
      tags: tags,
      embedding: embedding,
      remoteId: remoteId,
      sha256: sha256,
      uploadedAt: uploadedAt,
    );
  }

  @override
  void write(BinaryWriter w, Thought obj) {
    w.writeString(obj.id);
    w.writeString(obj.path);
    w.writeInt(obj.createdAt.millisecondsSinceEpoch);

    w.writeBool(obj.durationMs != null);
    if (obj.durationMs != null) w.writeInt(obj.durationMs!);

    w.writeBool(obj.transcript != null);
    if (obj.transcript != null) w.writeString(obj.transcript!);

    w.writeBool(obj.title != null);
    if (obj.title != null) w.writeString(obj.title!);

    final tags = obj.tags ?? const <String>[];
    w.writeBool(tags.isNotEmpty);
    if (tags.isNotEmpty) {
      w.writeInt(tags.length);
      for (final t in tags) {
        w.writeString(t);
      }
    }

    final emb = obj.embedding ?? const <double>[];
    w.writeBool(emb.isNotEmpty);
    if (emb.isNotEmpty) {
      w.writeInt(emb.length);
      for (final v in emb) {
        w.writeDouble(v);
      }
    }

    w.writeBool(obj.remoteId != null);
    if (obj.remoteId != null) w.writeString(obj.remoteId!);

    w.writeBool(obj.sha256 != null);
    if (obj.sha256 != null) w.writeString(obj.sha256!);

    w.writeBool(obj.uploadedAt != null);
    if (obj.uploadedAt != null) {
      w.writeInt(obj.uploadedAt!.millisecondsSinceEpoch);
    }
  }
}
