enum SyncEventType { queueStarted, itemUploadStarted, itemUploadSucceeded, itemUploadFailed, bulkCompleted }

class SyncEvent {
  final SyncEventType type;
  final String? thoughtId;
  final String? message;
  const SyncEvent(this.type, {this.thoughtId, this.message});
}
