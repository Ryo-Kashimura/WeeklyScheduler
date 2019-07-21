//
//  ScheduleViewController.swift
//  DiceScheduler
//
//  Created by 鹿志村諒 on 2019/07/13.
//  Copyright © 2019年 Team Time Efficiency. All rights reserved.
//

import UIKit
import UserNotifications

class ScheduleViewController: UIViewController, UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, CustomDelegate, UICollectionViewDelegateFlowLayout, UNUserNotificationCenterDelegate {
    
    var customLayout = CustomLayout()
    var schedule: Schedule? = Schedule()
    
    @IBOutlet weak var scheduleScrollView: UIScrollView!
    @IBOutlet weak var DayCollectionView: UICollectionView!
    @IBOutlet weak var timeCollectionView: UICollectionView!
    @IBOutlet weak var scheduleCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.customLayout.delegate = self
        self.scheduleCollectionView.setCollectionViewLayout(self.customLayout, animated: true)
        self.setNotification()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - CustomDelegate
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section == 0 else {
            return 0
        }
        switch collectionView.restorationIdentifier {
        case "TimeCollectionView":
            return 128 // fixed height of a TimeCollectionViewCell
        case "ScheduleCollectionView":
            guard let _schedule = self.schedule else {
                print("schedule is nil")
                return 0
            }
            guard _schedule.days.count > 0 else {
                print("schedule.days is []")
                return 0
            }
            let day = _schedule.days[indexPath.item % _schedule.days.count]
            let scheduleCellGroups = _schedule.scheduleCellGroups(on: day)
            guard indexPath.item / _schedule.days.count < scheduleCellGroups.count else {
                return 0
            }
            return CGFloat(64 * scheduleCellGroups[indexPath.item / _schedule.days.count].count)
        case "DayCollectionView":
            return 32 // fixed height of a WorkDayCollectionViewCell
        default:
            print("default case.")
            return 0
        }
    }
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView.restorationIdentifier {
        case "TimeCollectionView":
            return
        case "ScheduleCollectionView":
            guard indexPath.section == 0, let _schedule = self.schedule else {
                return
            }
            guard _schedule.days.count > 0 else {
                return
            }
            let day = _schedule.days[indexPath.item % _schedule.days.count]
            let scheduleCellGroups = _schedule.scheduleCellGroups(on: day)
            guard indexPath.item / _schedule.days.count < scheduleCellGroups.count else {
                return
            }
            self.performSegue(withIdentifier: "PushTaskEditor", sender: scheduleCellGroups[indexPath.item / _schedule.days.count])
        case "DayCollectionView":
            return
        default:
            print("default case.")
            return
        }

    }
    
    // MARK: - UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard section == 0, let _schedule = self.schedule else {
            return 0
        }
        switch collectionView.restorationIdentifier {
        case "TimeCollectionView":
            guard let _unitMinutes = _schedule.unitMinutes else {
                return 0
            }
            guard let _startTime = _schedule.startTime else { return 0 }
            guard let _endTime = _schedule.endTime else { return 0 }
            let interval = Calendar.current.dateComponents([.hour, .minute], from: _startTime, to: _endTime)
            guard let hour = interval.hour, let minute = interval.minute else {
                return 0
            }
            return (hour * 60 + minute) / (_unitMinutes * 2) // Time stamps are supposed to be located every one hour.
        case "ScheduleCollectionView":
            return _schedule.days.count * _schedule.cellCountPerDay
        case "DayCollectionView":
            return _schedule.days.count
        default:
            print("default case.")
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let _schedule = self.schedule, indexPath.section == 0 else {
            switch collectionView.restorationIdentifier {
            case "TimeCollectionView":
                return TimeCollectionViewCell()
            case "ScheduleCollectionView":
                return ScheduleCollectionViewCell()
            case "DayCollectionView":
                return DayCollectionViewCell()
            default:
                print("default case.")
                return UICollectionViewCell()
            }
        }
        switch collectionView.restorationIdentifier {
        case "TimeCollectionView":
            guard let _startTime = _schedule.startTime else {
                return TimeCollectionViewCell()
            }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TimeCollectionViewCell", for: indexPath) as! TimeCollectionViewCell
            guard let time = Calendar.current.date(byAdding: .hour, value: indexPath.item, to: _startTime) else {
                return TimeCollectionViewCell()
            }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            cell.timeLabel.text = "\(dateFormatter.string(from: time))"
            cell.timeContainerView.layer.cornerRadius = 8
            return cell
        case "ScheduleCollectionView":
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ScheduleCollectionViewCell", for: indexPath) as! ScheduleCollectionViewCell
            let day = _schedule.days[indexPath.item % _schedule.days.count]
            let scheduleCellGroups = _schedule.scheduleCellGroups(on: day)
            guard indexPath.item / _schedule.days.count < scheduleCellGroups.count else {
                return cell
            }
            let scheduleCellGroup = scheduleCellGroups[indexPath.item / _schedule.days.count]
            guard scheduleCellGroup.count > 0 else {
                return cell
            }
            let firstScheduleCell = scheduleCellGroup[0]
            guard let _scheduleStartTime = firstScheduleCell.startTime, let _taskDescription = scheduleCellGroup[0].assignedTask?.description else {
                return cell
            }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            cell.startTimeLabel.text = dateFormatter.string(from: _scheduleStartTime)
            cell.taskDescriptionLabel.text = _taskDescription
            cell.scheduleContainerView.backgroundColor = firstScheduleCell.backgroundColor
            cell.scheduleContainerView.layer.cornerRadius = firstScheduleCell.locked ? 0: 16
            cell.lockedIcon.image = firstScheduleCell.locked ? #imageLiteral(resourceName: "lockedIcon"): nil
            return cell
        case "DayCollectionView":
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCollectionViewCell", for: indexPath) as! DayCollectionViewCell
            guard indexPath.item < _schedule.days.count else {
                return cell
            }
            cell.DayLabel.text = _schedule.days[indexPath.item].jaStyleSymbol
            cell.DayContainerView.layer.cornerRadius = 8
            return cell
        default:
            print("default case.")
            return UICollectionViewCell()
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        switch segue.identifier {
        case "PushTaskEditor":
            guard let vc = segue.destination as? EditorViewController else {
                return
            }
            let selectedScheduleCellGroup = sender as! [ScheduleCell]
            vc.selectedScheduleCellGroup = selectedScheduleCellGroup
            vc.schedule = self.schedule
            guard selectedScheduleCellGroup.count > 0 else {
                return
            }
            let firstScheduleCell = selectedScheduleCellGroup[0]
            vc.locked = firstScheduleCell.locked
            vc.newDay = firstScheduleCell.day
            vc.newStartTime = firstScheduleCell.startTime
            vc.newScheduleCellCount = selectedScheduleCellGroup.count
            vc.newColor = firstScheduleCell.backgroundColor
        default:
            print("default case.")
        }
    }
    
    // MARK: - IBAction
    @IBAction func returnFromEditorViewControllerWithSegue(segue: UIStoryboardSegue) {
        switch segue.identifier {
        case "ReturnFromEditorViewController":
            let vc = segue.source as! EditorViewController
            self.schedule = vc.schedule
            self.customLayout = CustomLayout()
            self.customLayout.delegate = self
            self.scheduleCollectionView.setCollectionViewLayout(self.customLayout, animated: true)
            self.scheduleCollectionView.reloadData()
        default:
            print("default case.")
        }
    }
    
    // MARK: - Custom Functions for Notifications
    func setNotification() {
        let startItNow = UNNotificationAction(identifier: "startItNow", title: "はじめる", options: [.foreground])
        let doItLater = UNNotificationAction(identifier: "doItLater", title: "あとで", options: [.foreground])
        let category = UNNotificationCategory(
            identifier: "message",
            actions: [startItNow, doItLater],
            intentIdentifiers: ["startItNow", "doItLater"],
            options: []
        )
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.setNotificationCategories([category])
        let content = UNMutableNotificationContent()
        content.body = "金曜日 13:00 の予定「レポート課題」を今始めますか？今終わらせると，連続する空き時間が 1 日 8 時間 30 分 から 2 日 10 時間に増えます"
        content.categoryIdentifier = "message"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(identifier: "Timer", content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }

}
