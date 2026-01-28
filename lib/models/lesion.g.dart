// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesion.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LesionAdapter extends TypeAdapter<Lesion> {
  @override
  final int typeId = 4;

  @override
  Lesion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Lesion(
      titulo: fields[0] as String,
      fecha: fields[1] as DateTime,
      altaMedica: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Lesion obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.titulo)
      ..writeByte(1)
      ..write(obj.fecha)
      ..writeByte(2)
      ..write(obj.altaMedica);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LesionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
