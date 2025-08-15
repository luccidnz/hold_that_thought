// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thought.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ThoughtAdapter extends TypeAdapter<Thought> {
  @override
  final int typeId = 0;

  @override
  Thought read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Thought(
      id: fields[0] as String,
      text: fields[1] as String,
      createdAt: fields[2] as DateTime,
      updatedAt: fields[3] as DateTime?,
      pinned: fields[4] as bool,
      archived: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Thought obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.pinned)
      ..writeByte(5)
      ..write(obj.archived);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThoughtAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
