import 'package:flitter/redux/actions.dart';
import 'package:flitter/redux/flitter_app_state.dart';
import 'package:flitter/services/gitter/gitter.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart' as redux;

class FlitterLoggingMiddleware
    implements redux.Middleware<FlitterAppState, FlitterAction> {
  call(redux.Store<FlitterAppState, FlitterAction> store, FlitterAction action,
      next) {
    debugPrint('${new DateTime.now()}: $action');
    next(action);
  }
}

class FlitterAppReducer extends redux.Reducer<FlitterAppState, FlitterAction> {
  final _mapper = const <Type, Function>{
    FetchRoomsAction: _fetchRooms,
    FetchGroupsAction: _fetchGroups,
    LogoutAction: _logout,
    LoginAction: _login,
    SelectRoomAction: _selectRoom,
    OnMessagesForRoom: _onMessages,
    OnSendMessage: _onSendMessage,
    FetchMessagesForRoomAction: _fetchMessages,
    JoinRoomAction: _joinRoom,
    LeaveRoomAction: _leaveRoom,
    SelectGroupAction: _selectGroup,
    FetchRoomsOfGroup: _fetchRoomsOfGroup
  };

  @override
  FlitterAppState reduce(FlitterAppState state, FlitterAction action) {
    Function reducer = _mapper[action.runtimeType];
    return reducer != null ? reducer(state, action) : state;
  }
}

FlitterAppState _fetchRooms(FlitterAppState state, FetchRoomsAction action) {
  return state.apply(rooms: action.rooms);
}

FlitterAppState _fetchGroups(FlitterAppState state, FetchGroupsAction action) {
  return state.apply(groups: action.groups);
}

FlitterAppState _logout(FlitterAppState state, LogoutAction action) {
  return state.apply(rooms: null, user: null, groups: null, messages: {});
}

FlitterAppState _login(FlitterAppState state, LoginAction action) {
  return state.apply(user: action.user);
}

FlitterAppState _selectRoom(FlitterAppState state, SelectRoomAction action) {
  CurrentRoomState current = new CurrentRoomState(
      room: action.room, messages: state.messages[action.room.id]);
  return state.apply(selectedRoom: current);
}

FlitterAppState _fetchMessages(FlitterAppState state,
    FetchMessagesForRoomAction action) {
  Map<String, List<Message>> messages = state.messages;
  messages[action.roomId] = action.messages;
  return state.apply(messages: messages);
}

FlitterAppState _onMessages(FlitterAppState state, OnMessagesForRoom action) {
  List<Message> messages = new List.from(action.messages);
  Map<String, List<Message>> messagesByRooms = new Map.from(state.messages);
  messages.addAll(state.messages[action.roomId] ?? []);
  messagesByRooms[action.roomId] = messages;
  CurrentRoomState currentRoom =
  state.selectedRoom?.apply(messages: messagesByRooms[action.roomId]);
  return state.apply(messages: messagesByRooms, selectedRoom: currentRoom);
}

FlitterAppState _joinRoom(FlitterAppState state, JoinRoomAction action) {
  List<Room> rooms = new List.from(state.rooms);
  rooms.add(action.room);
  return state.apply(rooms: rooms);
}

FlitterAppState _leaveRoom(FlitterAppState state, LeaveRoomAction action) {
  List<Room> rooms = new List.from(state.rooms);
  rooms.removeWhere((Room room) => room.id == action.room.id);
  return state.apply(rooms: rooms);
}

FlitterAppState _onSendMessage(FlitterAppState state, OnSendMessage action) {
  Map<String, List<Message>> messages = new Map.from(state.messages);
  messages[action.roomId] ??= [];
  messages[action.roomId].add(action.message);
  CurrentRoomState currentRoom =
  state.selectedRoom?.apply(messages: messages[action.roomId]);
  return state.apply(messages: messages, selectedRoom: currentRoom);
}

FlitterAppState _selectGroup(FlitterAppState state, SelectGroupAction action) {
  CurrentGroupState current = new CurrentGroupState(group: action.group);
  return state.apply(selectedGroup: current);
}

FlitterAppState _fetchRoomsOfGroup(FlitterAppState state, FetchRoomsOfGroup action) {
  CurrentGroupState current = new CurrentGroupState(group: state.selectedGroup.group, rooms: action.rooms);
  return state.apply(selectedGroup: current);
}