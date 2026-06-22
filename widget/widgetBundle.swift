import WidgetKit
import SwiftUI

@main
struct HyuabotWidgetBundle: WidgetBundle {
    var body: some Widget {
        CafeteriaWidget()
        ShuttleWidget()
        TransferWidget()
        if #available(iOSApplicationExtension 16.1, *) {
            ShuttleBoardingLiveActivity()
        }
    }
}
