//
//  ViewController.swift
//  Interval Timer
//
//  Created by Ricky Loader on 24/05/19.
//  Copyright © 2019 Ricky Loader. All rights reserved.
//

import UIKit
import UserNotifications

class ViewController: UIViewController{

    
    @IBOutlet weak var secondPicker: UIPickerView!
    @IBOutlet weak var timerContainer: UILabel!
    @IBOutlet weak var minutePicker: UIPickerView!
    @IBOutlet weak var pickerGroup: UIView!
    @IBOutlet weak var stop: UIButton!
    @IBOutlet weak var start: UIButton!
    
    var running = false
    var timer = Timer()
    var userSeconds = 0
    var secValue = 0
    var minValue = 0
    var counting = 0
    var data: [String] = [String]()
    var settingUp = true
    var identifier:String!
    var backgroundTimer:Date!
    let haptic = UIImpactFeedbackGenerator(style: .heavy)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        fillPicker()
        secondPicker.dataSource = self
        secondPicker.delegate = self
        minutePicker.dataSource = self
        minutePicker.delegate = self
        
        // monitor background/foreground moves for timer to stay accurate
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)

        
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification
            , object: nil)

        notificationCenter.addObserver(self, selector: #selector(appClosed), name: UIApplication.willTerminateNotification
            , object: nil)
        
        // ask for permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound])
        {(granted,error) in
            // if user approved/denied notifications
        }
    }
    
    @objc func appMovedToBackground() {
        if(!running){
            return;
        }
        print("App moved to background!")
        backgroundTimer = Date()
    }
    
    @objc func appMovedToForeground() {
        if(!running){
            return;
        }
        print("App moved to foreground!")
        
        // gone 90 seconds
        let time = Int(Date().timeIntervalSince(backgroundTimer))
        
        // 90 seconds + (timer length 60 seconds - 50 seconds left on current interval) = 100 seconds total elapsed on current interval
        let elapsed = time+(userSeconds-counting)
        print("time elapsed: \(elapsed)")
        
        // timer length 60 seconds - (100 seconds total elapsed % timer length 60 seconds) = 20 seconds is new timer value
        counting = userSeconds-(elapsed%userSeconds)
    }
    
    func fillPicker(){
        for n in 0...59{
            var s = String(n)
            if n<10{
                s = "0"+s
            }
            data.append(s)
        }
    }
    
    @objc func appClosed(){
        print("app closed")
        cancelNotification()
    }
    
    @IBAction func startTimer(_ sender: Any) {
        haptic.impactOccurred()
        print("start button pressed")
        
        if running{
            print("already running, ignoring")
            return;
        }
        
        
        if settingUp{
            let time = getInput()
            if(time>=60){
                print("transitioning from set up to timer screen")
                showTimer()
                counting = time
                userSeconds = time
                timerContainer.text = secondsToString()
            }
        }
        else{
            print("starting timer")
            scheduleNotification()
            running = true
            initialiseTimer()
        }
    }
    
    @IBAction func stopTimer(_ sender: Any) {
        haptic.impactOccurred()
        print("Stop button pressed")
        running = false;
        print("transitioning from timer to set up screen")
        timer.invalidate()
        cancelNotification()
        showSetup()
    }

    
    func showTimer(){
        settingUp = false
        start.setTitle("Start", for: .normal)
        stop.isHidden = false
        pickerGroup.isHidden = true
        timerContainer.isHidden = false
    }
    
    func showSetup(){
        settingUp = true
        start.setTitle("Save", for: .normal)
        stop.isHidden = true
        pickerGroup.isHidden = false
        timerContainer.isHidden = true
    }
    
    
    func getInput()->Int{
        print("input = \(minValue) minutes and \(secValue) seconds totalling \((minValue*60)+secValue) seconds")
        return (minValue*60)+secValue
    }
    
    func secondsToString()->String{
        var min = String(counting/60)
        var sec = String(counting%60)
        
        if min.count==1{
            min = "0"+min
        }
        
        if sec.count==1{
            sec = "0"+sec
        }
        
        let result = "\(min):\(sec)"
        
        return result
    }
    
    @objc func updateTimer(){
        print(counting)
        counting-=1
        if counting==0{
            resetTimer()
        }
        timerContainer.text = secondsToString()
    }
    
    func resetTimer(){
        counting = userSeconds
    }
    
    func scheduleNotification(){
        let content = UNMutableNotificationContent()
        content.title = "INTERVAL TIMER"
        content.sound = UNNotificationSound.default
        
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(userSeconds), repeats: true)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { (error) in
        }
    }
    
    func cancelNotification(){
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func initialiseTimer(){
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
}

extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return data.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == secondPicker{
            secValue = Int(data[row])!
        }
        else{
            minValue = Int(data[row])!
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return data[row]
    }
}

