// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanvasViewport _$CanvasViewportFromJson(Map<String, dynamic> json) =>
    CanvasViewport(
      zoom: (json['zoom'] as num?)?.toDouble() ?? 1.0,
      offset: json['offset'] == null
          ? const Position(x: 0, y: 0)
          : Position.fromJson(json['offset'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CanvasViewportToJson(CanvasViewport instance) =>
    <String, dynamic>{
      'zoom': instance.zoom,
      'offset': instance.offset.toJson(),
    };

SelectionState _$SelectionStateFromJson(Map<String, dynamic> json) =>
    SelectionState(
      selectedBlockIds: (json['selectedBlockIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
      activeBlockId: json['activeBlockId'] as String?,
      hoveredBlockId: json['hoveredBlockId'] as String?,
    );

Map<String, dynamic> _$SelectionStateToJson(SelectionState instance) =>
    <String, dynamic>{
      'selectedBlockIds': instance.selectedBlockIds.toList(),
      'activeBlockId': instance.activeBlockId,
      'hoveredBlockId': instance.hoveredBlockId,
    };

DragState _$DragStateFromJson(Map<String, dynamic> json) => DragState(
      isDragging: json['isDragging'] as bool? ?? false,
      draggedBlockId: json['draggedBlockId'] as String?,
      dragStartPosition: json['dragStartPosition'] == null
          ? null
          : Position.fromJson(json['dragStartPosition'] as Map<String, dynamic>),
      currentDragPosition: json['currentDragPosition'] == null
          ? null
          : Position.fromJson(
              json['currentDragPosition'] as Map<String, dynamic>),
      dragType: $enumDecodeNullable(_$DragTypeEnumMap, json['dragType']),
    );

Map<String, dynamic> _$DragStateToJson(DragState instance) => <String, dynamic>{
      'isDragging': instance.isDragging,
      'draggedBlockId': instance.draggedBlockId,
      'dragStartPosition': instance.dragStartPosition?.toJson(),
      'currentDragPosition': instance.currentDragPosition?.toJson(),
      'dragType': _$DragTypeEnumMap[instance.dragType],
    };

const _$DragTypeEnumMap = {
  DragType.block: 'block',
  DragType.connection: 'connection',
  DragType.canvas: 'canvas',
};

PendingConnection _$PendingConnectionFromJson(Map<String, dynamic> json) =>
    PendingConnection(
      sourceBlockId: json['sourceBlockId'] as String,
      sourcePin: json['sourcePin'] as String,
      currentPosition:
          Position.fromJson(json['currentPosition'] as Map<String, dynamic>),
      type: $enumDecode(_$ConnectionTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$PendingConnectionToJson(PendingConnection instance) =>
    <String, dynamic>{
      'sourceBlockId': instance.sourceBlockId,
      'sourcePin': instance.sourcePin,
      'currentPosition': instance.currentPosition.toJson(),
      'type': _$ConnectionTypeEnumMap[instance.type]!,
    };

CanvasState _$CanvasStateFromJson(Map<String, dynamic> json) => CanvasState(
      workflow: ReasoningWorkflow.fromJson(
          json['workflow'] as Map<String, dynamic>),
      viewport: json['viewport'] == null
          ? const CanvasViewport()
          : CanvasViewport.fromJson(json['viewport'] as Map<String, dynamic>),
      selection: json['selection'] == null
          ? const SelectionState()
          : SelectionState.fromJson(json['selection'] as Map<String, dynamic>),
      dragState: json['dragState'] == null
          ? const DragState()
          : DragState.fromJson(json['dragState'] as Map<String, dynamic>),
      pendingConnection: json['pendingConnection'] == null
          ? null
          : PendingConnection.fromJson(
              json['pendingConnection'] as Map<String, dynamic>),
      isGridVisible: json['isGridVisible'] as bool? ?? true,
      isMinimapVisible: json['isMinimapVisible'] as bool? ?? false,
      uiState: json['uiState'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$CanvasStateToJson(CanvasState instance) =>
    <String, dynamic>{
      'workflow': instance.workflow.toJson(),
      'viewport': instance.viewport.toJson(),
      'selection': instance.selection.toJson(),
      'dragState': instance.dragState.toJson(),
      'pendingConnection': instance.pendingConnection?.toJson(),
      'isGridVisible': instance.isGridVisible,
      'isMinimapVisible': instance.isMinimapVisible,
      'uiState': instance.uiState,
    };

T? $enumDecodeNullable<T>(
  Map<T, Object> enumValues,
  Object? source, {
  T? unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return $enumDecode<T>(enumValues, source, unknownValue: unknownValue);
}