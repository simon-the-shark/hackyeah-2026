import { describe, it, expect } from '@ohos/hypium';
import { isPermanentRejectionStatus } from '../main/ets/models/Delivery';

export default function deliveryTest() {
  describe('isPermanentRejectionStatus', () => {
    it('drops validation, not-found and conflict rejections', 0, () => {
      expect(isPermanentRejectionStatus(400)).assertTrue();
      expect(isPermanentRejectionStatus(403)).assertTrue();
      expect(isPermanentRejectionStatus(404)).assertTrue();
      expect(isPermanentRejectionStatus(409)).assertTrue();
    });

    it('retries expired sessions, timeouts, rate limits and server errors', 0, () => {
      expect(isPermanentRejectionStatus(401)).assertFalse();
      expect(isPermanentRejectionStatus(408)).assertFalse();
      expect(isPermanentRejectionStatus(429)).assertFalse();
      expect(isPermanentRejectionStatus(500)).assertFalse();
      expect(isPermanentRejectionStatus(503)).assertFalse();
    });
  });
}
