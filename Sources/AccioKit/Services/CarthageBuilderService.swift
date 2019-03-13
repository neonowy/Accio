import Foundation

enum CarthageBuilderError: Error {
    case buildProductsMissing
}

final class CarthageBuilderService {
    private let frameworkCachingService: FrameworkCachingService

    init(frameworkCachingService: FrameworkCachingService) {
        self.frameworkCachingService = frameworkCachingService
    }

    func build(framework: Framework, platform: Platform) throws -> FrameworkProduct {
        print("Building scheme \(framework.libraryName) with Carthage ...", level: .info)

        // TODO: subdependencies are currently not supported, should be built up front and copied to "\(framwork.directory)/Carthage/Build/\(platform.rawValue)"
        try bash("carthage build --project-directory \(framework.projectDirectory) --platform \(platform.rawValue) --no-skip-current")

        let platformBuildDir = "\(framework.projectDirectory)/Carthage/Build/\(platform)"
        let frameworkProduct = FrameworkProduct(
            frameworkDirPath: "\(platformBuildDir)/\(framework.libraryName).framework",
            symbolsFilePath: "\(platformBuildDir)/\(framework.libraryName).framework.dSYM"
        )

        guard FileManager.default.fileExists(atPath: frameworkProduct.frameworkDirPath) && FileManager.default.fileExists(atPath: frameworkProduct.symbolsFilePath) else {
            print("Failed to build products to \(platformBuildDir)/\(framework.libraryName).framework(.dSYM).", level: .error)
            throw CarthageBuilderError.buildProductsMissing
        }

        print("Completed building scheme \(framework.libraryName) with Carthage.", level: .info)
        try frameworkCachingService.cache(product: frameworkProduct, framework: framework, platform: platform)

        return frameworkProduct
    }
}
