// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'processing_state.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ProcessingState on _ProcessingState, Store {
  late final _$progressAtom = Atom(
    name: '_ProcessingState.progress',
    context: context,
  );

  @override
  double get progress {
    _$progressAtom.reportRead();
    return super.progress;
  }

  @override
  set progress(double value) {
    _$progressAtom.reportWrite(value, super.progress, () {
      super.progress = value;
    });
  }

  late final _$stageAtom = Atom(
    name: '_ProcessingState.stage',
    context: context,
  );

  @override
  String get stage {
    _$stageAtom.reportRead();
    return super.stage;
  }

  @override
  set stage(String value) {
    _$stageAtom.reportWrite(value, super.stage, () {
      super.stage = value;
    });
  }

  late final _$messageAtom = Atom(
    name: '_ProcessingState.message',
    context: context,
  );

  @override
  String get message {
    _$messageAtom.reportRead();
    return super.message;
  }

  @override
  set message(String value) {
    _$messageAtom.reportWrite(value, super.message, () {
      super.message = value;
    });
  }

  late final _$isErrorAtom = Atom(
    name: '_ProcessingState.isError',
    context: context,
  );

  @override
  bool get isError {
    _$isErrorAtom.reportRead();
    return super.isError;
  }

  @override
  set isError(bool value) {
    _$isErrorAtom.reportWrite(value, super.isError, () {
      super.isError = value;
    });
  }

  late final _$errorMessageAtom = Atom(
    name: '_ProcessingState.errorMessage',
    context: context,
  );

  @override
  String? get errorMessage {
    _$errorMessageAtom.reportRead();
    return super.errorMessage;
  }

  @override
  set errorMessage(String? value) {
    _$errorMessageAtom.reportWrite(value, super.errorMessage, () {
      super.errorMessage = value;
    });
  }

  late final _$isCompleteAtom = Atom(
    name: '_ProcessingState.isComplete',
    context: context,
  );

  @override
  bool get isComplete {
    _$isCompleteAtom.reportRead();
    return super.isComplete;
  }

  @override
  set isComplete(bool value) {
    _$isCompleteAtom.reportWrite(value, super.isComplete, () {
      super.isComplete = value;
    });
  }

  late final _$_ProcessingStateActionController = ActionController(
    name: '_ProcessingState',
    context: context,
  );

  @override
  void updateProgress(double value, String msg, String stg) {
    final _$actionInfo = _$_ProcessingStateActionController.startAction(
      name: '_ProcessingState.updateProgress',
    );
    try {
      return super.updateProgress(value, msg, stg);
    } finally {
      _$_ProcessingStateActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setError(String error) {
    final _$actionInfo = _$_ProcessingStateActionController.startAction(
      name: '_ProcessingState.setError',
    );
    try {
      return super.setError(error);
    } finally {
      _$_ProcessingStateActionController.endAction(_$actionInfo);
    }
  }

  @override
  void complete() {
    final _$actionInfo = _$_ProcessingStateActionController.startAction(
      name: '_ProcessingState.complete',
    );
    try {
      return super.complete();
    } finally {
      _$_ProcessingStateActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
progress: ${progress},
stage: ${stage},
message: ${message},
isError: ${isError},
errorMessage: ${errorMessage},
isComplete: ${isComplete}
    ''';
  }
}
