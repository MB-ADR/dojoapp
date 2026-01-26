// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentAdapter extends TypeAdapter<Student> {
  @override
  final int typeId = 1;

  @override
  Student read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Student(
      id: fields[0] as String,
      nombre: fields[1] as String,
      photoPath: fields[2] as String?,
      dni: fields[3] as String,
      fechaNacimiento: fields[4] as DateTime?,
      weightKg: fields[5] as double?,
      heightCm: fields[6] as int?,
      padreNombre: fields[7] as String?,
      padreTel: fields[8] as String?,
      madreNombre: fields[9] as String?,
      madreTel: fields[10] as String?,
      observaciones: fields[11] as String?,
      isArchived: fields[12] as bool,
      stars: fields[13] as int,
      attendanceByClass: (fields[14] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<String>())),
      classIds: (fields[15] as List?)?.cast<String>(),
      paymentHistory: (fields[16] as List?)?.cast<PaymentRecord>(),
      notificationHistory: (fields[17] as List?)?.cast<NotificationEvent>(),
      creationDate: fields[18] as DateTime?,
      searchableTags: (fields[19] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Student obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.photoPath)
      ..writeByte(3)
      ..write(obj.dni)
      ..writeByte(4)
      ..write(obj.fechaNacimiento)
      ..writeByte(5)
      ..write(obj.weightKg)
      ..writeByte(6)
      ..write(obj.heightCm)
      ..writeByte(7)
      ..write(obj.padreNombre)
      ..writeByte(8)
      ..write(obj.padreTel)
      ..writeByte(9)
      ..write(obj.madreNombre)
      ..writeByte(10)
      ..write(obj.madreTel)
      ..writeByte(11)
      ..write(obj.observaciones)
      ..writeByte(12)
      ..write(obj.isArchived)
      ..writeByte(13)
      ..write(obj.stars)
      ..writeByte(14)
      ..write(obj.attendanceByClass)
      ..writeByte(15)
      ..write(obj.classIds)
      ..writeByte(16)
      ..write(obj.paymentHistory)
      ..writeByte(17)
      ..write(obj.notificationHistory)
      ..writeByte(18)
      ..write(obj.creationDate)
      ..writeByte(19)
      ..write(obj.searchableTags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
