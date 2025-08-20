// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_service.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteChangeAdapter extends TypeAdapter<NoteChange> {
  @override
  final int typeId = 2;

  @override
  NoteChange read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteChange(
      type: fields[0] as ChangeType,
      note: fields[1] as Note,
      ts: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, NoteChange obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.note)
      ..writeByte(2)
      ..write(obj.ts);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteChangeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChangeTypeAdapter extends TypeAdapter<ChangeType> {
  @override
  final int typeId = 1;

  @override
  ChangeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ChangeType.create;
      case 1:
        return ChangeType.update;
      case 2:
        return ChangeType.delete;
      default:
        return ChangeType.create;
    }
  }

  @override
  void write(BinaryWriter writer, ChangeType obj) {
    switch (obj) {
      case ChangeType.create:
        writer.writeByte(0);
        break;
      case ChangeType.update:
        writer.writeByte(1);
        break;
      case ChangeType.delete:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
