// swift-tools-version:3.1

import PackageDescription

let package = Package(
   name: "Mockr"
   , dependencies: [
      .Package(url: "https://github.com/oarrabi/FileUtils.git", majorVersion: 0)
      , .Package(url: "git@bitbucket.org:bigfrancoag/swiftprotocolparser.git", majorVersion: 0)
   ]
)
