import { PairingView } from '../components/PairingView';
import { WatchHome } from '../components/WatchHome';

@Entry
@Component
struct WatchIndex {
  @StorageProp('watchPaired') paired: boolean = false;

  build() {
    Stack() {
      if (this.paired) {
        WatchHome()
      } else {
        PairingView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.watch_background'))
  }
}
