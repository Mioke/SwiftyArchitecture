//
//  NSDate+Extentsions.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 5/16/16.
//  Copyright © 2016 KleinMioke. All rights reserved.
//

import Foundation

extension NSDate {
    
    var year: Int {
        get {
            return NSCalendar.currentCalendar().component(NSCalendarUnit.Year, fromDate: self)
        }
    }
    var month: Int {
        get {
            return NSCalendar.currentCalendar().component(NSCalendarUnit.Month, fromDate: self)
        }
    }
    var day: Int {
        get {
            return NSCalendar.currentCalendar().component(NSCalendarUnit.Day, fromDate: self)
        }
    }
    
    var weekday: Int {
        get {
            return NSCalendar.currentCalendar().ordinalityOfUnit(NSCalendarUnit.Weekday, inUnit: NSCalendarUnit.WeekOfYear, forDate: self)
        }
    }
    
    var weekOfMonth: Int {
        get {
            return NSCalendar.currentCalendar().component(NSCalendarUnit.WeekOfMonth, fromDate: self)
        }
    }
    
    func offsetMonth(offset: Int) -> NSDate {
        guard offset != 0 else { return self }
        let comps = NSDateComponents()
        comps.month = offset
        return NSCalendar.currentCalendar().dateByAddingComponents(comps, toDate: self, options: NSCalendarOptions.WrapComponents)!
    }
    
    func offsetDay(offset: Int) -> NSDate {
        guard offset != 0 else { return self }
        let comps = NSDateComponents()
        comps.day = offset
        return NSCalendar.currentCalendar().dateByAddingComponents(comps, toDate: self, options: NSCalendarOptions.WrapComponents)!
    }
    
    func offsetWeek(offset: Int) -> NSDate {
        guard offset != 0 else { return self }
        let comps = NSDateComponents()
        comps.weekOfYear = offset
        return NSCalendar.currentCalendar().dateByAddingComponents(comps, toDate: self, options: NSCalendarOptions.WrapComponents)!
    }
    
    class func numberOfDaysInMonth(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().rangeOfUnit(NSCalendarUnit.Day, inUnit: NSCalendarUnit.Month, forDate: date).length
    }
    
    var firstWeekdayInMonth: Int {
        get {
            let comps = NSCalendar.currentCalendar().components([NSCalendarUnit.Year, NSCalendarUnit.Month], fromDate: self)
            comps.day = 1
            if let newDate = NSCalendar.currentCalendar().dateFromComponents(comps) {
                return newDate.weekday
            }
            assert(false, "NSDate.firstWeekdayInMonth error, can't generate the first day in month")
            return 0
        }
    }
    
    func isMonthEqualToDate(date: NSDate) -> Bool {
        let cal = NSCalendar.currentCalendar()
        let selfComps = cal.components([NSCalendarUnit.Year, .Month], fromDate: self)
        let other = cal.components([.Year, .Month], fromDate: date)
        
        return selfComps.year == other.year && selfComps.month == other.month
    }
    
    func isDayEqualToDate(date: NSDate) -> Bool {
        let cal = NSCalendar.currentCalendar()
        let selfComps = cal.components([NSCalendarUnit.Year, .Month, .Day], fromDate: self)
        let other = cal.components([.Year, .Month, .Day], fromDate: date)
        
        return selfComps.year == other.year && selfComps.month == other.month && selfComps.day == other.day
    }
    
    func isWeekEqualToDate(date: NSDate) -> Bool {
        let cal = NSCalendar.currentCalendar()
        let selfComps = cal.components([NSCalendarUnit.Year, .WeekOfYear, .YearForWeekOfYear], fromDate: self)
        let other = cal.components([.Year, .Month, .YearForWeekOfYear], fromDate: date)
        
        return selfComps.yearForWeekOfYear == other.yearForWeekOfYear && selfComps.weekOfYear == other.weekOfYear
    }
    
    var originTimeOfDay: NSTimeInterval {
        get {
            let comps = NSCalendar.currentCalendar().components([.Year, .Month, .Day], fromDate: self)
            return NSCalendar.currentCalendar().dateFromComponents(comps)!.timeIntervalSince1970
        }
    }
    
}