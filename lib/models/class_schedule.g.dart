// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_schedule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClassScheduleAdapter extends TypeAdapter<ClassSchedule> {
  @override
  final int typeId = 0;

  @override
  ClassSchedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClassSchedule(
      id: fields[0] as String,
      nombre: fields[1] as String,
      diasDeSemana: (fields[2] as List).cast<int>(),
      fechasCanceladas: (fields[3] as List?)?.cast<String>(),
      studentIds: (fields[4] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ClassSchedule obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.diasDeSemana)
      ..writeByte(3)
      ..write(obj.fechasCanceladas)
      ..writeByte(4)
      ..write(obj.studentIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
