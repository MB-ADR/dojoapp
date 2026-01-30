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
      apellido: fields[2] as String,
      photoPath: fields[3] as String?,
      photoBytes: (fields[28] as List?)?.cast<int>(),
      dni: fields[4] as String,
      fechaNacimiento: fields[5] as DateTime?,
      weightKg: fields[6] as double?,
      heightCm: fields[7] as int?,
      nombrePadre: fields[8] as String?,
      apellidoPadre: fields[9] as String?,
      telefonoPadre: fields[10] as String?,
      nombreMadre: fields[11] as String?,
      apellidoMadre: fields[12] as String?,
      telefonoMadre: fields[13] as String?,
      contactoEmergenciaNombre: fields[14] as String?,
      contactoEmergenciaApellido: fields[15] as String?,
      contactoEmergenciaTelefono: fields[16] as String?,
      observaciones: fields[17] as String?,
      isArchived: fields[18] as bool,
      stars: fields[19] as int,
      attendanceByClass: (fields[20] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<String>())),
      classIds: (fields[21] as List?)?.cast<String>(),
      paymentHistory: (fields[22] as List?)?.cast<PaymentRecord>(),
      notificationHistory: (fields[23] as List?)?.cast<NotificationEvent>(),
      creationDate: fields[24] as DateTime?,
      searchableTags: (fields[25] as List?)?.cast<String>(),
      lesiones: (fields[26] as List?)?.cast<Lesion>(),
      medallas: (fields[27] as Map?)?.cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, Student obj) {
    writer
      ..writeByte(29)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(3)
      ..write(obj.photoPath)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.apellido)
      ..writeByte(4)
      ..write(obj.dni)
      ..writeByte(5)
      ..write(obj.fechaNacimiento)
      ..writeByte(6)
      ..write(obj.weightKg)
      ..writeByte(7)
      ..write(obj.heightCm)
      ..writeByte(8)
      ..write(obj.nombrePadre)
      ..writeByte(9)
      ..write(obj.apellidoPadre)
      ..writeByte(10)
      ..write(obj.telefonoPadre)
      ..writeByte(11)
      ..write(obj.nombreMadre)
      ..writeByte(12)
      ..write(obj.apellidoMadre)
      ..writeByte(13)
      ..write(obj.telefonoMadre)
      ..writeByte(14)
      ..write(obj.contactoEmergenciaNombre)
      ..writeByte(15)
      ..write(obj.contactoEmergenciaApellido)
      ..writeByte(16)
      ..write(obj.contactoEmergenciaTelefono)
      ..writeByte(17)
      ..write(obj.observaciones)
      ..writeByte(18)
      ..write(obj.isArchived)
      ..writeByte(19)
      ..write(obj.stars)
      ..writeByte(20)
      ..write(obj.attendanceByClass)
      ..writeByte(21)
      ..write(obj.classIds)
      ..writeByte(22)
      ..write(obj.paymentHistory)
      ..writeByte(23)
      ..write(obj.notificationHistory)
      ..writeByte(24)
      ..write(obj.creationDate)
      ..writeByte(25)
      ..write(obj.searchableTags)
      ..writeByte(26)
      ..write(obj.lesiones)
      ..writeByte(27)
      ..write(obj.medallas)
      ..writeByte(28)
      ..write(obj.photoBytes);
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
