//
//  iACGEngineTests.swift
//  iACGEngineTests
//
//  Created by Martin.Ren on 16/2/7.
//  Copyright © 2016年 Martin.Ren. All rights reserved.
//

import XCTest
import iACGEngine

class iACGEngineTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
    }
    
    func testExample() {
        // This is an example of a functional test case.
        
        let audioPath = "/Users/martin/Documents/MX2/MXAudioEngine/MXAudioEngine/MXAudioEngine/psy.mp3"
        
        let sourcePosition = mr3DAudioPosition.init(x: 0, y: 0, z: 0)
        
        let testSource = mr3DAudioSource(identifier: "Source1", path:audioPath, position: sourcePosition, loopMode: true)
        
        testSource.identifier = "LLLLLL"
        
        NSLog("%s", testSource.identifier)
        
        if (testSource.status == MR3DAUDIO_ENGINE_SOURCE_STATUS.SUCCESS)
        {
            XCTAssert(true, "Source inited");
        }
        else
        {
            XCTAssert(false, "Source init faild")
        }
        
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
