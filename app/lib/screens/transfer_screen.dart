import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/peer.dart';
import '../services/transfer_service.dart';

class TransferScreen extends StatefulWidget {
  final Peer peer;
  final String filePath;
  final String fileName;
  final int fileSize;

  const TransferScreen({
    super.key,
    required this.peer,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
  });

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  String? _transferId;

  @override
  void initState() {
    super.initState();
    _startTransfer();
  }

  Future<void> _startTransfer() async {
    final transferService = context.read<TransferService>();
    final id = await transferService.sendFile(
      peer: widget.peer,
      filePath: widget.filePath,
      fileName: widget.fileName,
      fileSize: widget.fileSize,
    );
    
    if (mounted) {
      setState(() {
        _transferId = id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Transfer'),
        centerTitle: true,
      ),
      body: Consumer<TransferService>(
        builder: (context, transferService, child) {
          if (_transferId == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final transfer = transferService.activeTransfers[_transferId];
          if (transfer == null) {
            return const Center(child: Text('Transfer not found'));
          }
          
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Progress Indicator
                CircularPercentIndicator(
                  radius: 120.0,
                  lineWidth: 12.0,
                  animation: true,
                  percent: transfer.progress,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(transfer.progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 32.0,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (transfer.status == TransferStatus.transferring)
                        Text(
                          transferService.formatSpeed(transfer.speedBps),
                          style: TextStyle(
                            fontSize: 14.0,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: _getStatusColor(transfer.status, theme),
                  backgroundColor: theme.colorScheme.surfaceVariant,
                ),
                
                const SizedBox(height: 40),
                
                // File Info
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.insert_drive_file,
                              color: theme.colorScheme.primary,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.fileName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    transferService.formatBytes(widget.fileSize),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const Divider(height: 32),
                        
                        // Transfer Info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'To',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.peer.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Status',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getStatusText(transfer.status),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _getStatusColor(transfer.status, theme),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        if (transfer.status == TransferStatus.transferring) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${transferService.formatBytes(transfer.transferredBytes)} / ${transferService.formatBytes(transfer.totalBytes)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              Text(
                                'ETA: ${transferService.formatDuration(transfer.estimatedTimeRemaining)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Action Buttons
                if (transfer.status == TransferStatus.transferring)
                  ElevatedButton.icon(
                    onPressed: () {
                      transferService.cancelTransfer(_transferId!);
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel Transfer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                      minimumSize: const Size(200, 48),
                    ),
                  )
                else if (transfer.status == TransferStatus.completed)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Done'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 48),
                    ),
                  )
                else if (transfer.status == TransferStatus.failed || 
                         transfer.status == TransferStatus.cancelled)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 48),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getStatusText(TransferStatus status) {
    switch (status) {
      case TransferStatus.idle:
        return 'Idle';
      case TransferStatus.connecting:
        return 'Connecting...';
      case TransferStatus.transferring:
        return 'Transferring';
      case TransferStatus.completed:
        return 'Completed';
      case TransferStatus.failed:
        return 'Failed';
      case TransferStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor(TransferStatus status, ThemeData theme) {
    switch (status) {
      case TransferStatus.idle:
      case TransferStatus.connecting:
        return theme.colorScheme.secondary;
      case TransferStatus.transferring:
        return theme.colorScheme.primary;
      case TransferStatus.completed:
        return Colors.green;
      case TransferStatus.failed:
        return theme.colorScheme.error;
      case TransferStatus.cancelled:
        return Colors.orange;
    }
  }
}
