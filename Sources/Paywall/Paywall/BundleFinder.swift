//
//  BundleFinder.swift
//  Paywall
//
//  Created by Brian Anglin on 9/13/21.
//


import Foundation
//import class Foundation.Bundle

private class BundleFinder {}
#if !SPM

extension Foundation.Bundle {
    /// Returns the resource bundle associated with the current Swift module.
    static var module: Bundle = {
        let bundleName = "PaywallAssets"

        let candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,

            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: BundleFinder.self).resourceURL,

            // For command-line tools.
            Bundle.main.bundleURL,
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            print("bundle path", bundlePath)
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        print("Bundles!")
        print(allBundles)
        print("frameworks", allFrameworks)
        var i = 0;
        while(i < allFrameworks.count) {
            
//        let url =allFrameworks[i].bundleURL
//        for (var i = 0; i < allFrameworks.length; i++) {
            print(allFrameworks[i].bundleURL)
//        }
            i += 1;
        }
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: URL(string:  main.bundleURL.absoluteString + "/Frameworks/Paywall.framework")!, includingPropertiesForKeys: nil)
            print(directoryContents)

            // if you want to filter the directory contents you can do like this:
            let mp3Files = directoryContents.filter{ $0.pathExtension == "mp3" }
            print("mp3 urls:",mp3Files)
            let mp3FileNames = mp3Files.map{ $0.deletingPathExtension().lastPathComponent }
            print("mp3 list:", mp3FileNames)

        } catch {
            print(error)
        }
        
        fatalError("unable to find bundle named Paywall_Paywall")
    }()
}

#endif
