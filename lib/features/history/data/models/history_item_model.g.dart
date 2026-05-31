// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HistoryItemModelAdapter extends TypeAdapter<HistoryItemModel> {
  @override
  final int typeId = 1;

  @override
  HistoryItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryItemModel(
      id: fields[0] as String,
      imagePath: fields[1] as String,
      diseaseName: fields[2] as String,
      confidence: fields[3] as double,
      createdAt: fields[4] as DateTime,
      shortDescription: fields[5] as String,
      recommendedMedicines: (fields[6] as List).cast<String>(),
      dosageGuide: fields[7] as String,
      precautions: (fields[8] as List).cast<String>(),
      preventionTips: (fields[9] as List).cast<String>(),
      boxLeft: fields[10] as double,
      boxTop: fields[11] as double,
      boxRight: fields[12] as double,
      boxBottom: fields[13] as double,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryItemModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.diseaseName)
      ..writeByte(3)
      ..write(obj.confidence)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.shortDescription)
      ..writeByte(6)
      ..write(obj.recommendedMedicines)
      ..writeByte(7)
      ..write(obj.dosageGuide)
      ..writeByte(8)
      ..write(obj.precautions)
      ..writeByte(9)
      ..write(obj.preventionTips)
      ..writeByte(10)
      ..write(obj.boxLeft)
      ..writeByte(11)
      ..write(obj.boxTop)
      ..writeByte(12)
      ..write(obj.boxRight)
      ..writeByte(13)
      ..write(obj.boxBottom);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
