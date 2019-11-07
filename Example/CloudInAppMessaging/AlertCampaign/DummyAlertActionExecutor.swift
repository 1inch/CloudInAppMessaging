//
//  Created by Andrew Podkovyrin
//  Copyright © 2019 Dash Core Group. All rights reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://opensource.org/licenses/MIT
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import CloudInAppMessaging
import UIKit

final class DummyAlertActionExecutor: CLMAlertActionExecutor {
    func perform(alertButtonAction action: String, in context: UIViewController) {
        let actionAlert = UIAlertController(title: "The following URL will be opened within the app",
                                            message: action,
                                            preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel)
        actionAlert.addAction(okAction)
        context.present(actionAlert, animated: true)
    }
}
