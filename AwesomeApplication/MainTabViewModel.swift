import Foundation

class MainTabViewModel {
    private let appVersionChecker: AppVersionCheckerProtocol

    init(
        appVersionChecker: AppVersionCheckerProtocol
    ) {
        self.appVersionChecker = appVersionChecker
    }

    func checkAppVersion() async -> Bool? {
        return await appVersionChecker.checkAppStoreVersion()
    }
}
