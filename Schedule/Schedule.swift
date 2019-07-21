//
//  Schedule.swift
//  DiceScheduler
//
//  Created by 鹿志村諒 on 2019/07/14.
//  Copyright © 2019年 Team Time Efficiency. All rights reserved.
//

import UIKit
import Foundation

class Schedule {
    
    let days: [Day] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
    
    var format: DateFormatter = DateFormatter()
    var unitMinutes: Int? = nil
    var startTime: Date? = Date()
    var endTime: Date? = Date()
    var day2ScheduleCells = [Day: [ScheduleCell]]() // A dictionary from workDay to a 1-D array of schedule cells.
    var cellCountPerDay: Int {
        get {
            guard let _unitMinutes = self.unitMinutes else {
                return 0
            }
            guard let _startTime = self.startTime else { return 0 }
            guard let _endTime = self.endTime else { return 0 }
            let interval = Calendar.current.dateComponents([.hour, .minute], from: _startTime, to: _endTime)
            guard let hour = interval.hour, let minute = interval.minute else {
                return 0
            }
            return (hour * 60 + minute) / _unitMinutes
        }
    }
    
    init(
        withUnitMinutesOf unitMinutes: Int = 30
    ) {
        // startTime must be set on the first workday (e.g. Monday)
        self.unitMinutes = unitMinutes
        self.format.dateFormat = "yyyy/MM/dd HH:mm"
        self.format.locale = Locale(identifier: "ja_JP")
        self.startTime = self.format.date(from: self.days[0].rawValue.dateString)
        guard let _startTime = self.startTime else {
            return
        }
        guard let _endTime = Calendar.current.date(byAdding: .hour, value: 8, to: _startTime) else {
            return
        }
        self.endTime = _endTime
        for day in self.days {
            var _scheduleCells = [ScheduleCell]()
            for i in 0 ..< self.cellCountPerDay {
                if i == 6 || i == 7 {
                    _scheduleCells.append(ScheduleCell(for: Task("ランチ"), coloredWith: #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1), locked: true))
                } else {
                    _scheduleCells.append(ScheduleCell())
                }
            }
            self.day2ScheduleCells[day] = _scheduleCells
        }
        guard let _unitMinutes = self.unitMinutes else {
            return
        }
        for day in self.days {
            guard let _scheduleStartTime = self.format.date(from: day.rawValue.dateString) else {
                continue
            }
            for i in 0 ..< self.day2ScheduleCells[day]!.count {
                self.day2ScheduleCells[day]![i].startTime = Calendar.current.date(byAdding: .minute, value: i * _unitMinutes, to: _scheduleStartTime)
                self.day2ScheduleCells[day]![i].endTime = Calendar.current.date(byAdding: .minute, value: (i + 1) * _unitMinutes, to: _scheduleStartTime)
            }
        }
    }
    
    func scheduleCellGroups(on day: Day) -> [[ScheduleCell]] {
        // A function of type String -> [[ScheduleCell]]
        // Returns groups of consequently same schedule cells in each day.
        // Suppose that one day we have five Tasks: A, B, C, D and E and they are assigned to 16 schedule cells like [A, A, B, C, D, D, A, A, D, D, C, C, B, E, E, E].
        // In this case, this property will returns [[A, A], [B], [C], [D, D], [A, A], [D, D], [C, C], [B], [E, E, E]].
        var sCGs = [[ScheduleCell]]()
        guard let _sCs = self.day2ScheduleCells[day] else {
            return sCGs
        }
        guard _sCs.count > 0 else {
            return sCGs
        }
        var currentTaskId: String? = _sCs[0].assignedTask?.taskId
        var sCG = [ScheduleCell]()
        for scheduleCell in _sCs {
            guard let task = scheduleCell.assignedTask else {
                sCGs.append(sCG)
                sCG = [ScheduleCell]()
                continue
            }
            if task.taskId != currentTaskId {
                sCGs.append(sCG)
                sCG = [ScheduleCell]()
                currentTaskId = task.taskId
            }
            sCG.append(scheduleCell)
        }
        if sCG.count > 0 {
            sCGs.append(sCG)
        }
        return sCGs
    }
    
    func update(_ scheduleCells: [ScheduleCell], with task: Task, on day: Day, from scheduleStartTime: Date, for scheduleCellCount: Int, coloredWith color: UIColor, locked: Bool = false) {
        guard let _unitMinutes = self.unitMinutes, let _startTime = self.startTime else {
            return
        }
        let interval = Calendar.current.dateComponents([.minute], from: _startTime, to: scheduleStartTime)
        guard let minute = interval.minute else {
            return
        }
        var idx = (minute % (60 * 24)) / _unitMinutes // interval minutes can be over different days.
        for scheduleCell in scheduleCells {
            self.initialize(scheduleCell) // Old scheduleCells should be initialized before tasks get rescheduled.
        }
        for _ in 0 ..< scheduleCellCount {
            if idx >= self.cellCountPerDay {
                break
            }
            self.updateScheduleCell(with: task, on: day, at: idx, coloredWith: color, locked: locked)
            idx += 1
        }
    }
    
    func updateScheduleCell(with task: Task, on day: Day, at scheduleCellIdx: Int, coloredWith color: UIColor, locked: Bool) {
        guard let _ = self.day2ScheduleCells[day] else {
            return
        }
        if scheduleCellIdx < self.day2ScheduleCells[day]!.count {
            self.day2ScheduleCells[day]![scheduleCellIdx].assignedTask = task
            self.day2ScheduleCells[day]![scheduleCellIdx].backgroundColor = color
            self.day2ScheduleCells[day]![scheduleCellIdx].locked = locked
        }
    }
    
    func initialize(_ scheduleCell: ScheduleCell) {
        guard let _unitMinutes = self.unitMinutes, let _startTime = self.startTime, let _scheduleStartTime = scheduleCell.startTime else {
            return
        }
        guard let day = scheduleCell.day else {
            return
        }
        let interval = Calendar.current.dateComponents([.minute], from: _startTime, to: _scheduleStartTime)
        guard let minute = interval.minute else {
            return
        }
        let idx = (minute % (60 * 24)) / _unitMinutes // interval minutes can be over different days.
        self.updateScheduleCell(with: Task(), on: day, at: idx, coloredWith: #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1), locked: false)
    }
    
}

class ScheduleCell {
    
    static let jaStyleDaySymbol2Day: [String: Day] = [
        "日": .sunday, "月": .monday, "火": .tuesday, "水": .wednesday, "木": .thursday, "金": .friday, "土": .saturday]
    
    var locked: Bool
    var assignedTask: Task? = nil
    var startTime: Date? = Date()
    var endTime: Date? = Date()
    var backgroundColor: UIColor
    var day: Day? {
        get {
            guard let jaStyleDaySymbol = self.startTime?.weekday else {
                return nil
            }
            return ScheduleCell.jaStyleDaySymbol2Day[jaStyleDaySymbol]
        }
    }
    
    init(for task: Task = Task(), coloredWith backgroundColor: UIColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1), locked: Bool = false) {
        self.assignedTask = task
        self.backgroundColor = backgroundColor
        self.locked = locked
    }
    
}
