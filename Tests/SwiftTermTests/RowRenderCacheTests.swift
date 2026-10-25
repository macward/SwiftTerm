//
//  RowRenderCacheTests.swift
//
//  The CoreGraphics path keeps each row's segments and shaped CTLines between
//  frames. These pin that an unchanged row is reused and that every input
//  feeding it invalidates the entry.
//

import Foundation
import Testing

#if os(macOS)
import AppKit

@testable import SwiftTerm

@MainActor
struct RowRenderCacheTests {

    private func makeView() -> TerminalView {
        let view = TerminalView(frame: CGRect(origin: .zero, size: .init(width: 400, height: 160)))
        view.terminal.feed(text: "first row\r\nsecond row")
        return view
    }

    private func firstLine(_ view: TerminalView, row: Int = 0) -> CTLine? {
        let buffer = view.terminal.displayBuffer
        return view.preparedRow(row: row, line: buffer.lines[row], cols: buffer.cols, buffer: buffer)
            .prepared.first?.ctLine
    }

    @Test func unchangedRowReusesItsShapedLine() {
        let view = makeView()
        let first = firstLine(view)
        let second = firstLine(view)
        #expect(first != nil)
        #expect(first === second)
    }

    @Test func editingTheRowRebuildsIt() {
        let view = makeView()
        let before = firstLine(view)
        view.terminal.feed(text: "\u{1B}[1;1Hz")
        #expect(firstLine(view) !== before)
    }

    @Test func editingAnotherRowKeepsThisOne() {
        let view = makeView()
        let before = firstLine(view)
        view.terminal.feed(text: "\u{1B}[2;1Hz")
        #expect(firstLine(view) === before)
    }

    @Test func selectingTheRowRebuildsIt() {
        let view = makeView()
        let before = firstLine(view)
        view.selection.setSelection(start: Position(col: 0, row: 0), end: Position(col: 3, row: 0))
        #expect(firstLine(view) !== before)
    }

    @Test func colorChangesRebuildEveryRow() {
        let view = makeView()
        let before = firstLine(view)
        view.nativeForegroundColor = .red
        #expect(firstLine(view) !== before)
    }

    @Test func selectionColorChangesRebuildEveryRow() {
        let view = makeView()
        let before = firstLine(view)
        view.selectedTextBackgroundColor = .red
        #expect(firstLine(view) !== before)
    }

    @Test func fontChangesRebuildEveryRow() {
        let view = makeView()
        let before = firstLine(view)
        view.font = NSFont.monospacedSystemFont(ofSize: 20, weight: .regular)
        #expect(firstLine(view) !== before)
    }

    @Test func pruningKeepsOnlyVisibleRows() {
        let view = makeView()
        _ = firstLine(view, row: 0)
        _ = firstLine(view, row: 1)
        view.pruneRowRenderCache(visible: 1...1)
        #expect(view.rowRenderCache.keys.sorted() == [1])
    }
}
#endif
