// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmarked_competition_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookmarkedCompetitionModelAdapter
    extends TypeAdapter<BookmarkedCompetitionModel> {
  @override
  final typeId = 0;

  @override
  BookmarkedCompetitionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookmarkedCompetitionModel(
      id: fields[0] as String,
      title: fields[1] as String,
      soaringspotUrl: fields[2] as String,
      bookmarkedAt: fields[3] as DateTime,
      selectedClass: fields[4] as String?,
      description: fields[5] as String?,
      startDate: fields[6] as DateTime?,
      endDate: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BookmarkedCompetitionModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.soaringspotUrl)
      ..writeByte(3)
      ..write(obj.bookmarkedAt)
      ..writeByte(4)
      ..write(obj.selectedClass)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.startDate)
      ..writeByte(7)
      ..write(obj.endDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookmarkedCompetitionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
