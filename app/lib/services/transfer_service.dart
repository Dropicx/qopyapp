import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/peer.dart';

enum TransferStatus {
  idle,
  connecting,
  transferring,
  completed,
  failed,
  cancelled,
}

class TransferProgress {
  final String id;
  final String fileName;
  final int totalBytes;
  final int transferredBytes;
  final double speedBps;
  final Duration estimatedTimeRemaining;
  final TransferStatus status;

  TransferProgress({
    required this.id,
    required this.fileName,
    required this.totalBytes,
    required this.transferredBytes,
    required this.speedBps,
    required this.estimatedTimeRemaining,
    required this.status,
  });

  double get progress => totalBytes > 0 ? transferredBytes / totalBytes : 0;
}

class TransferService extends ChangeNotifier {
  final Map<String, TransferProgress> _activeTransfers = {};
  
  Map<String, TransferProgress> get activeTransfers => Map.unmodifiable(_activeTransfers);

  Future<String> sendFile({
    required Peer peer,
    required String filePath,
    required String fileName,
    required int fileSize,
  }) async {
    final transferId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Initialize transfer
    _activeTransfers[transferId] = TransferProgress(
      id: transferId,
      fileName: fileName,
      totalBytes: fileSize,
      transferredBytes: 0,
      speedBps: 0,
      estimatedTimeRemaining: Duration.zero,
      status: TransferStatus.connecting,
    );
    notifyListeners();

    // Simulate connection
    await Future.delayed(const Duration(seconds: 1));
    
    // Start transfer simulation
    _simulateTransfer(transferId, fileSize);
    
    return transferId;
  }

  Future<void> _simulateTransfer(String transferId, int totalBytes) async {
    const chunkSize = 1024 * 1024; // 1MB chunks
    const speed = 10 * 1024 * 1024; // 10MB/s simulated speed
    int transferred = 0;
    
    final startTime = DateTime.now();
    
    while (transferred < totalBytes) {
      // Check if cancelled
      if (!_activeTransfers.containsKey(transferId)) break;
      if (_activeTransfers[transferId]!.status == TransferStatus.cancelled) break;
      
      // Calculate next chunk
      final nextChunk = (totalBytes - transferred).clamp(0, chunkSize);
      transferred += nextChunk;
      
      // Calculate speed and time remaining
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      final currentSpeed = elapsed > 0 ? transferred / elapsed : speed.toDouble();
      final remaining = totalBytes - transferred;
      final timeRemaining = Duration(seconds: (remaining / currentSpeed).round());
      
      // Update progress
      _activeTransfers[transferId] = TransferProgress(
        id: transferId,
        fileName: _activeTransfers[transferId]!.fileName,
        totalBytes: totalBytes,
        transferredBytes: transferred,
        speedBps: currentSpeed,
        estimatedTimeRemaining: timeRemaining,
        status: TransferStatus.transferring,
      );
      notifyListeners();
      
      // Simulate transfer delay
      await Future.delayed(Duration(milliseconds: (nextChunk / speed * 1000).round()));
    }
    
    // Mark as completed
    if (_activeTransfers.containsKey(transferId)) {
      _activeTransfers[transferId] = TransferProgress(
        id: transferId,
        fileName: _activeTransfers[transferId]!.fileName,
        totalBytes: totalBytes,
        transferredBytes: totalBytes,
        speedBps: 0,
        estimatedTimeRemaining: Duration.zero,
        status: TransferStatus.completed,
      );
      notifyListeners();
    }
  }

  void cancelTransfer(String transferId) {
    if (_activeTransfers.containsKey(transferId)) {
      final transfer = _activeTransfers[transferId]!;
      _activeTransfers[transferId] = TransferProgress(
        id: transferId,
        fileName: transfer.fileName,
        totalBytes: transfer.totalBytes,
        transferredBytes: transfer.transferredBytes,
        speedBps: 0,
        estimatedTimeRemaining: Duration.zero,
        status: TransferStatus.cancelled,
      );
      notifyListeners();
    }
  }

  void removeTransfer(String transferId) {
    _activeTransfers.remove(transferId);
    notifyListeners();
  }

  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String formatSpeed(double bytesPerSecond) {
    return '${formatBytes(bytesPerSecond.round())}/s';
  }

  String formatDuration(Duration duration) {
    if (duration.inSeconds < 60) return '${duration.inSeconds}s';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    return '${duration.inHours}h ${duration.inMinutes % 60}m';
  }
}
