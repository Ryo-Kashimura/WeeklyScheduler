//
//  Task.swift
//  DiceScheduler
//
//  Created by 鹿志村諒 on 2019/07/14.
//  Copyright © 2019年 Team Time Efficiency. All rights reserved.
//

import Foundation

class Task {
    
    static var description2TaskId = [String: String]()
    var taskId: String {
        get {
            guard let _description = self.description else {
                return ""
            }
            guard let _taskId = Task.description2TaskId[_description] else {
                let newId = NSUUID().uuidString
                Task.description2TaskId[_description] = newId
                return newId
            }
            return _taskId
        }
    }
    var description: String? = nil {
        didSet {
            // taskId will be updated when the task is updated.
            guard let _description = self.description else {
                return
            }
            guard let _ = Task.description2TaskId[_description] else {
                Task.description2TaskId[_description] = NSUUID().uuidString
                return
            }
        }
    }

    init(_ description: String = "空き時間") {
        self.description = description
    }
    
}
