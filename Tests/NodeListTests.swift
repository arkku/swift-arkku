//
//  NodeListTests.swift
//  SwiftArkkuTests
//
//  Created by Kimmo Kulovesi.
//  Copyright © 2019 Kimmo Kulovesi. All rights reserved.
//

import XCTest
@testable import SwiftArkku

class NodeListTests: XCTestCase {

    var nodeList: NodeList<Int>!

    override func setUp() {
        nodeList = NodeList()
    }

    override func tearDown() {
        nodeList = nil
    }

    func testEmpty() {
        XCTAssertTrue(nodeList.isEmpty)
        XCTAssertEqual(nodeList.count, 0)
    }

    func testAppend() {
        let appendCount = 10
        for i in 1...appendCount {
            let oldCount = nodeList.count
            nodeList.append(i)
            XCTAssertFalse(nodeList.isEmpty)
            XCTAssertEqual(oldCount + 1, nodeList.count)
        }
        XCTAssertEqual(nodeList.count, appendCount)
    }

    func testInsert() {
        let insertCount = 10
        for i in 1...insertCount {
            let oldCount = nodeList.count
            nodeList.insertAsFirst(i)
            XCTAssertFalse(nodeList.isEmpty)
            XCTAssertEqual(oldCount + 1, nodeList.count)
        }
        XCTAssertEqual(nodeList.count, insertCount)
    }

    func testRemoveFirst() {
        nodeList = [ 1, 2, 3, 4, 5 ]
        XCTAssertFalse(nodeList.isEmpty)
        while !nodeList.isEmpty {
            let oldCount = nodeList.count
            nodeList.removeFirst()
            XCTAssertEqual(oldCount - 1, nodeList.count)
        }
        XCTAssertEqual(nodeList.count, 0)
    }

    func testRemoveLast() {
        nodeList = [ 5, 4, 3, 2, 1 ]
        XCTAssertFalse(nodeList.isEmpty)
        while !nodeList.isEmpty {
            let oldCount = nodeList.count
            nodeList.removeLast()
            XCTAssertEqual(oldCount - 1, nodeList.count)
        }
        XCTAssertEqual(nodeList.count, 0)
    }

    func testRemoveAll() {
        nodeList = [ 1, 2, 3, 4, 5 ]
        XCTAssertFalse(nodeList.isEmpty)
        nodeList.removeAll()
        XCTAssertEqual(nodeList.count, 0)
        XCTAssertTrue(nodeList.isEmpty)
    }

    func testArrayAndReverse() {
        var array = [Int]()
        for i in 1...10 {
            XCTAssertEqual(Array(nodeList), array)
            array.append(i)
            nodeList = NodeList(array)
            XCTAssertEqual(Array(nodeList), array)
            XCTAssertEqual(nodeList.count, array.count)
            nodeList.reverse()
            array.reverse()
            XCTAssertEqual(Array(nodeList), array)
        }
    }

}
