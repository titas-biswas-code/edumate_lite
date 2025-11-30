import 'package:mobx/mobx.dart';
import '../domain/entities/material.dart';

part 'processing_state.g.dart';

// ignore: library_private_types_in_public_api
class ProcessingState = _ProcessingState with _$ProcessingState;

abstract class _ProcessingState with Store {
  final Material material;
  final int tempId;
  
  @observable
  double progress = 0.0;
  
  @observable
  String stage = 'starting';
  
  @observable
  String message = 'Starting...';
  
  @observable
  bool isError = false;
  
  @observable
  String? errorMessage;
  
  @observable
  bool isComplete = false;
  
  _ProcessingState(this.material, this.tempId);
  
  @action
  void updateProgress(double value, String msg, String stg) {
    progress = value;
    message = msg;
    stage = stg;
  }
  
  @action
  void setError(String error) {
    isError = true;
    errorMessage = error;
  }
  
  @action
  void complete() {
    progress = 1.0;
    isComplete = true;
    message = 'Completed';
  }
}

