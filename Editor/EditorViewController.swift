//
//  EditorViewController.swift
//  DiceScheduler
//
//  Created by 鹿志村諒 on 2019/07/14.
//  Copyright © 2019年 Team Time Efficiency. All rights reserved.
//

import UIKit

class EditorViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var selectedScheduleCellGroup = [ScheduleCell]()
    var schedule: Schedule? = nil
    var locked: Bool? = nil
    var newStartTime: Date? = Date()
    var newDay: Day? = nil
    var newScheduleCellCount: Int? = nil
    var newColor: UIColor? = nil
    var colors: [UIColor] = [#colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1), #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1), #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1), #colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1), #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1), #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1), #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1), #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1), #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1), #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)]
    
    @IBOutlet weak var lockSwitch: UISwitch!
    @IBOutlet weak var editorVariableContainerView: UIView!
    @IBOutlet weak var editorDayCollectionView: UICollectionView!
    @IBOutlet weak var timePickerView: UIPickerView!
    @IBOutlet weak var taskDetailEditField: UITextField!
    @IBOutlet weak var editCompleteButton: UIButton!
    @IBOutlet weak var unitMinutesLabel: UILabel!
    @IBOutlet weak var scheduleCellCountPickerView: UIPickerView!
    @IBOutlet weak var colorCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let _locked = self.locked else {
            return
        }
        self.lockSwitch.setOn(_locked, animated: true)
        let enabled: Bool = !self.lockSwitch.isOn
        let alpha: CGFloat = enabled ? 1: 0.5
        self.editorVariableContainerView.isUserInteractionEnabled = enabled
        self.editorVariableContainerView.alpha = alpha
        guard self.selectedScheduleCellGroup.count > 0 else {
            return
        }
        if let taskDescription = selectedScheduleCellGroup[0].assignedTask?.description {
            self.taskDetailEditField.text = taskDescription
        } else {
            self.taskDetailEditField.text = ""
        }
        self.taskDetailEditField.layer.cornerRadius = 8
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    // MARK: - UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let _unitMinutes = self.schedule?.unitMinutes, let _newDay = self.newDay else {
            return
        }
        guard let _startTime = self.schedule?.format.date(from: _newDay.rawValue.dateString) else {
            return
        }
        switch pickerView.restorationIdentifier {
        case "TimePickerView":
            guard let scheduleStartTime = Calendar.current.date(byAdding: .minute, value: (row * _unitMinutes), to: _startTime) else {
                return
            }
            self.newStartTime = scheduleStartTime
        case "ScheduleCellCountPickerView":
            self.newScheduleCellCount = row + 1
        default:
            print("default case.")
            return
        }
    }
    
    // MARK: - UIPickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        guard let _cellCount = self.schedule?.cellCountPerDay else {
            return 0
        }
        return _cellCount
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let _unitMinutes = self.schedule?.unitMinutes, let _startTime = self.schedule?.startTime else {
            return ""
        } // _startTime = 09:00 on Monday
        switch pickerView.restorationIdentifier {
        case "TimePickerView":
            guard let scheduleStartTime = Calendar.current.date(byAdding: .minute, value: (row * _unitMinutes), to: _startTime) else {
                return ""
            }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            let dateString = dateFormatter.string(from: scheduleStartTime)
            return dateString
        case "ScheduleCellCountPickerView":
            return "× \(row + 1)"
        default:
            print("default case.")
            return ""
        }
    }
    
    //MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView.restorationIdentifier {
        case "EditorDayCollectionView":
            guard let days = self.schedule?.days else {
                return
            }
            self.newDay = days[indexPath.row]
        case "ColorCollectionView":
            guard indexPath.item < self.colors.count else {
                return
            }
            self.newColor = self.colors[indexPath.item]
        default:
            print("default case.")
            return
        }
    }
    
    //MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView.restorationIdentifier {
        case "EditorDayCollectionView":
            guard let dayCount = self.schedule?.days.count else {
                return 0
            }
            return dayCount
        case "ColorCollectionView":
            return self.colors.count
        default:
            print("default case.")
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView.restorationIdentifier {
        case "EditorDayCollectionView":
            guard let days = self.schedule?.days else {
                return EditorDayCollectionViewCell()
            }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EditorDayCollectionViewCell", for: indexPath) as! EditorDayCollectionViewCell
            guard indexPath.item < days.count else {
                return cell
            }
            cell.dayLabel.text = days[indexPath.item].jaStyleSymbol
            let selectedBGView = UIView(frame: cell.frame)
            selectedBGView.backgroundColor = UIColor.lightGray
            cell.selectedBackgroundView = selectedBGView
            cell.layer.cornerRadius = 8
            return cell
        case "ColorCollectionView":
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorCollectionViewCell", for: indexPath) as! ColorCollectionViewCell
            guard indexPath.item < self.colors.count else {
                return cell
            }
            cell.colorLabel.backgroundColor = self.colors[indexPath.item]
            cell.colorLabel.alpha = 0.7
            cell.colorLabel.layer.cornerRadius = 8
            let selectedBGView = UIView(frame: cell.colorLabel.frame)
            selectedBGView.backgroundColor = self.colors[indexPath.item]
            cell.selectedBackgroundView = selectedBGView
            cell.layer.cornerRadius = 8
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
        guard let _newDay = self.newDay, let _newStartTime = self.newStartTime, let _newScheduleCellCount = self.newScheduleCellCount, let _newColor = self.newColor, let _locked = self.locked else {
            return
        }
        guard let _schedule = self.schedule, let taskDescription = self.taskDetailEditField.text else {
            return
        }
        let newTask = Task(taskDescription)
        _schedule.update(self.selectedScheduleCellGroup, with: newTask, on: _newDay, from: _newStartTime, for: _newScheduleCellCount, coloredWith: _newColor, locked: _locked)
        self.schedule = _schedule
    }

    // MARK: - IBAction
    @IBAction func toggled(_ sender: UISwitch) {
        self.locked = self.lockSwitch.isOn
        let enabled: Bool = !sender.isOn
        let alpha: CGFloat = enabled ? 1: 0.5
        self.editorVariableContainerView.isUserInteractionEnabled = enabled
        self.editorVariableContainerView.alpha = alpha
    }
    
}
