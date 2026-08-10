// swift-tools-version: 6.2
// Package.swift
// ApinCore
//
// Local Swift package shared by the Apin app target and the ApinWidget extension
// target. Houses AI, persistence, and App Intents code that must stay free of
// SwiftUI/UIKit imports so it can be reused from extension targets without pulling
// in app-target UI code. See tasks/task-graph.md T1.

import PackageDescription

let package = Package(
    name: "ApinCore",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "ApinCore",
            targets: ["ApinCore"]
        )
    ],
    targets: [
        .target(
            name: "ApinCore",
            path: "Sources"
        ),
        .testTarget(
            name: "ApinCoreTests",
            dependencies: ["ApinCore"],
            path: "Tests/ApinCoreTests"
        )
    ]
)
