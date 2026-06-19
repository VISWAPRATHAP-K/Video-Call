import 'package:flutter_test/flutter_test.dart';
import 'package:video_call/core/models/call_state.dart';

void main() {
  test('CallState enum values verification', () {
    expect(CallState.idle.name, 'idle');
    expect(CallState.calling.name, 'calling');
    expect(CallState.ringing.name, 'ringing');
    expect(CallState.connecting.name, 'connecting');
    expect(CallState.connected.name, 'connected');
    expect(CallState.ended.name, 'ended');
    expect(CallState.failed.name, 'failed');
    
    expect(CallState.values.length, 7);
  });
}
