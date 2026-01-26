// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationEventAdapter extends TypeAdapter<NotificationEvent> {
  @override
  final int typeId = 3;

  @override
  NotificationEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationEvent(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime?,
      type: fields[2] as String,
      messageContent: fields[3] as String,
      isDelivered: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationEvent obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.messageContent)
      ..writeByte(4)
      ..write(obj.isDelivered);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
