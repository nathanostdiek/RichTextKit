//
//  RichTextFormatSheet.swift
//  RichTextKit
//
//  Created by Daniel Saidi on 2022-12-13.
//  Copyright © 2022-2024 Daniel Saidi. All rights reserved.
//

import SwiftUI

/**
 This toolbar provides different text format options, and is
 meant to be used on iOS, where space is limited.
 
 Consider presenting this view from the bottom in a way that
 doesn't cause the underlying text view to dim.
 
 You can provide a custom configuration to adjust the format
 options that are presented. When presented, the font picker
 will take up the available vertical height.
 
 You can style this view by applying a style anywhere in the
 view hierarchy, using `.richTextFormatToolbarStyle`.
 */
public struct RichTextFormatToolbar: View {

    /**
     Create a rich text format sheet.

     - Parameters:
       - context: The context to apply changes to.
       - config: The configuration to use, by default `.standard`.
     */
    public init(
        context: RichTextContext,
        config: Configuration = .standard
    ) {
        self._context = ObservedObject(wrappedValue: context)
        self.config = config
    }

    @ObservedObject
    private var context: RichTextContext
    
    @Environment(\.richTextFormatToolbarStyle)
    private var style

    /// The configuration to use.
    private let config: Configuration

    public var body: some View {
        VStack(spacing: 0) {
            fontPicker
            toolbar
        }
    }
}

public extension RichTextFormatToolbar {
    
    /// Convert the toolbar to a sheet, with a close button.
    func asSheet(
        dismiss: @escaping () -> Void
    ) -> some View {
        NavigationView {
            self
                .padding(.top, -35)
                .withAutomaticToolbarRole()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(RTKL10n.done.text, action: dismiss)
                    }
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}

public extension RichTextFormatToolbar {
    
    /// This struct can be used to configure a format sheet.
    struct Configuration {
        
        public init(
            colorPickers: [RichTextColor] = [.foreground],
            fontPicker: Bool = true
        ) {
            self.colorPickers = colorPickers
            self.fontPicker = fontPicker
        }
        
        public var colorPickers: [RichTextColor]
        public var fontPicker: Bool
    }
}

public extension RichTextFormatToolbar.Configuration {
    
    /// The standard rich text format toolbar configuration.
    static var standard = Self.init()
}

public extension RichTextFormatToolbar {
    
    /// This struct can be used to style a format sheet.
    struct Style {
        
        public init(
            padding: Double = 10,
            spacing: Double = 10
        ) {
            self.padding = padding
            self.spacing = spacing
        }
        
        public var padding: Double
        public var spacing: Double
    }
    
    /// This environment key defines a format toolbar style.
    struct StyleKey: EnvironmentKey {
        
        public static let defaultValue = RichTextFormatToolbar.Style()
    }
}

public extension View {
    
    /// Apply a rich text format toolbar style.
    func richTextFormatToolbarStyle(
        _ style: RichTextFormatToolbar.Style
    ) -> some View {
        self.environment(\.richTextFormatToolbarStyle, style)
    }
}

public extension EnvironmentValues {
    
    /// This environment value defines format toolbar styles.
    var richTextFormatToolbarStyle: RichTextFormatToolbar.Style {
        get { self [RichTextFormatToolbar.StyleKey.self] }
        set { self [RichTextFormatToolbar.StyleKey.self] = newValue }
    }
}

private extension RichTextFormatToolbar {
    
    @ViewBuilder
    var fontPicker: some View {
        if config.fontPicker {
            RichTextFont.ListPicker(selection: $context.fontName)
            Divider()
        }
    }
    
    var toolbar: some View {
        VStack(spacing: style.spacing) {
            controls
            colorPickers
        }
        .padding(.vertical, style.padding)
        .environment(\.sizeCategory, .medium)
        .background(background)
    }
}

private extension RichTextFormatToolbar {
    
    var background: some View {
        Color.clear
            .overlay(Color.primary.opacity(0.1))
            .shadow(color: .black.opacity(0.1), radius: 5)
            .edgesIgnoringSafeArea(.all)
    }
    
    var controls: some View {
        VStack(spacing: style.spacing) {
            fontRow
            paragraphRow
        }
        .padding(.horizontal, style.padding)
    }
    
    @ViewBuilder
    var colorPickers: some View {
        if !config.colorPickers.isEmpty {
            VStack(spacing: style.spacing) {
                Divider()
                ForEach(config.colorPickers) {
                    RichTextColor.Picker(
                        type: $0,
                        value: context.binding(for: $0),
                        quickColors: .quickPickerColors
                    )
                }
            }
            .padding(.leading, style.padding)
        }
    }
    
    var fontRow: some View {
        HStack {
            styleButtons
            Spacer()
            RichTextFont.SizePickerStack(context: context)
                .buttonStyle(.bordered)
        }
    }
    
    @ViewBuilder
    var indentButtons: some View {
        RichTextAction.ButtonGroup(
            context: context,
            actions: [.decreaseIndent(), .increaseIndent()],
            greedy: false
        )
    }

    var paragraphRow: some View {
        HStack {
            RichTextAlignment.Picker(selection: $context.textAlignment)
                .pickerStyle(.segmented)
            Spacer()
            indentButtons
        }
    }
    
    @ViewBuilder
    var styleButtons: some View {
        RichTextStyle.ToggleGroup(
            context: context
        )
    }
}

private extension View {

    @ViewBuilder
    func withAutomaticToolbarRole() -> some View {
        if #available(iOS 16.0, *) {
            self.toolbarRole(.automatic)
        } else {
            self
        }
    }
}

struct RichTextFormatToolbar_Previews: PreviewProvider {

    struct Preview: View {
        
        @StateObject
        private var context = RichTextContext()

        @State
        private var isSheetPresented = false

        var body: some View {
            Button("Toggle sheet") {
                isSheetPresented.toggle()
            }
            .sheet(isPresented: $isSheetPresented) {
                RichTextFormatToolbar(
                    context: context,
                    config: .init(
                        colorPickers: [.foreground],
                        fontPicker: true
                    )
                )
                .asSheet { isSheetPresented = false }
                .richTextFormatToolbarStyle(.init(
                    padding: 10,
                    spacing: 10
                ))
            }
        }
    }

    static var previews: some View {
        Preview()
    }
}
