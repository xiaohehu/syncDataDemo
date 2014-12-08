@import Foundation;


void AT_dispatch_after_ms(int64_t delay_ms, dispatch_block_t block);
void AT_dispatch_after_ms_on_queue(int64_t delay_ms, dispatch_queue_t queue, dispatch_block_t block);


// 0 = not scheduled, not running
// 1 or more = scheduled or running
typedef volatile int64_t __attribute__((__aligned__(8))) ATCoalescedState;

// Done callback can be called on any queue/thread.
typedef void (^ATCoalescedBlock)(dispatch_block_t done);
typedef dispatch_block_t ATCoalescedStateChangeNotificationBlock;

// Can be called on any queue/thread. Will call the given block on the main queue (or the given serial queue).
void AT_dispatch_coalesced(ATCoalescedState *state, int64_t delay_ms, ATCoalescedBlock block);
void AT_dispatch_coalesced_with_notifications(ATCoalescedState *state, int64_t delay_ms, ATCoalescedBlock block, ATCoalescedStateChangeNotificationBlock notificationBlock);
void AT_dispatch_coalesced_on_queue(ATCoalescedState *state, int64_t delay_ms, dispatch_queue_t serial_queue, ATCoalescedBlock block);
void AT_dispatch_coalesced_on_queue_with_notifications(ATCoalescedState *state, int64_t delay_ms, dispatch_queue_t serial_queue, ATCoalescedBlock block, ATCoalescedStateChangeNotificationBlock notificationBlock);
