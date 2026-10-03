import { common } from '@kit.AbilityKit';
import { ArcDotIndicator, ArcSwiper, ArcSwiperController } from '@kit.ArkUI';
import { watchMonitor } from '../services/WatchMonitor';
import { HeartRateView } from './HeartRateView';
import { SosView } from './SosView';
import { StatusView } from './StatusView';

/** Three round screens, swiped sideways: SOS first, then heart rate, then status. */
@Component
export struct WatchHome {
  private readonly controller: ArcSwiperController = new ArcSwiperController();

  aboutToAppear(): void {
    watchMonitor.start(this.getUIContext().getHostContext() as common.UIAbilityContext);
  }

  build() {
    ArcSwiper(this.controller) {
      SosView()
      HeartRateView()
      StatusView()
    }
    .indicator(new ArcDotIndicator())
    .width('100%')
    .height('100%')
  }
}
