// ComplicationBundle.swift
// OpenClaw watchOS Client
//
// Widget bundle that registers all complications for the watch face.

import WidgetKit
import SwiftUI

@main
struct OpenClawWidgetBundle: WidgetBundle {
    var body: some Widget {
        OpenClawComplication()
    }
}
