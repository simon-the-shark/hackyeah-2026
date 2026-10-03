import { sensor } from '@kit.SensorServiceKit';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { runningOnEmulator } from './DeviceEnvironment';

/** Error code of `getSingleSensorSync` when the device has no such sensor. */
const SENSOR_NOT_SUPPORTED = 14500102;
/** `Sensor.isMockSensor` exists from API 23. */
const MOCK_FLAG_API = 23;

export enum SensorAvailability {
  Available,
  Missing,
  Failed
}

/** Called with a whole-number bpm, or 0 when the reading was unreliable (e.g. the watch is not worn). */
export type HeartRateListener = (bpm: number) => void;

/** Thin wrapper over Sensor Service Kit, so the rest of the app can be tested without a sensor. */
export class HeartRateSensor {
  /** True when readings come from a virtual or emulated sensor and must be labelled as simulated. */
  simulated: boolean = false;
  private callback: ((data: sensor.HeartRateResponse) => void) | undefined = undefined;

  probe(): SensorAvailability {
    try {
      const info = sensor.getSingleSensorSync(sensor.SensorId.HEART_RATE);
      const mock = deviceInfo.sdkApiVersion >= MOCK_FLAG_API && info.isMockSensor === true;
      this.simulated = mock || runningOnEmulator();
      return SensorAvailability.Available;
    } catch (error) {
      const code = (error as BusinessError).code;
      console.error(`[HeartRateSensor] probe failed: ${code}`);
      return code === SENSOR_NOT_SUPPORTED ? SensorAvailability.Missing : SensorAvailability.Failed;
    }
  }

  /** Subscribes at the 'normal' rate; the lowest one that still gives a live value. */
  start(listener: HeartRateListener): boolean {
    this.stop();
    const callback = (data: sensor.HeartRateResponse): void => {
      const reliable = data.accuracy !== sensor.SensorAccuracy.ACCURACY_UNRELIABLE;
      listener(reliable ? Math.round(data.heartRate) : 0);
    };
    try {
      sensor.on(sensor.SensorId.HEART_RATE, callback, { interval: 'normal' });
      this.callback = callback;
      return true;
    } catch (error) {
      console.error(`[HeartRateSensor] subscribe failed: ${(error as BusinessError).code}`);
      return false;
    }
  }

  /** Sensors must not run in the background, so this is called whenever the app leaves the foreground. */
  stop(): void {
    if (this.callback === undefined) {
      return;
    }
    try {
      sensor.off(sensor.SensorId.HEART_RATE, this.callback);
    } catch (error) {
      console.error(`[HeartRateSensor] unsubscribe failed: ${(error as BusinessError).code}`);
    }
    this.callback = undefined;
  }
}
