//
//  Bout.swift
//  FencingRefSwift
//
//  Created by Jason DuPertuis on 4/19/15.
//  Copyright (c) 2015 jdp. All rights reserved.
//

import Foundation

/** The main manager of a bout. */
public class Bout {
    
    /** Types of penalty cards */
    public enum Card {
        case None
        case Yellow
        case Red
        case Black
    }
    
    /** Data about each fencer in the bout */
    struct BoutData {
        private var m_iLeftScore:UInt8;
        private var m_iRightScore:UInt8;
        
        /** The score for the left fencer */
        var leftScore:UInt8 {
            get { return m_iLeftScore; }
            set {
                m_iLeftScore = newValue;
                
                if m_iLeftScore < 0 {
                    m_iLeftScore = 0;
                }
            }
        }
        
        /** The score for the right fencer */
        var rightScore:UInt8 {
            get { return m_iRightScore; }
            set {
                m_iRightScore = newValue;
                
                if m_iRightScore < 0 {
                    m_iRightScore = 0;
                }
            }
        }
        
        private var m_leftCard:Card;
        private var m_rightCard:Card;
        
        /** The current card of the left fencer */
        var leftCard:Card {
            get { return m_leftCard; }
            set {
                if m_leftCard != Card.None && newValue != Card.None {
                    m_leftCard = Card.Red;
                } else {
                    m_leftCard = newValue;
                }
                
                if (m_leftCard == Card.Red) {
                    m_iRightScore += 1;
                }
            }
        }
        
        /** The current card of the right fencer */
        var rightCard:Card {
            get { return m_rightCard; }
            set {
                if m_rightCard != Card.None && newValue != Card.None {
                    m_rightCard = Card.Red;
                } else {
                    m_rightCard = newValue;
                }
                
                if (m_rightCard == Card.Red) {
                    m_iLeftScore += 1;
                }
            }
        }
        
        init() {
            m_iLeftScore = 0;
            m_iRightScore = 0;
            m_leftCard = Card.None;
            m_rightCard = Card.None;
        }
    }
    
    /** Data on events that happen during the bout */
    struct BoutEvent {
        var m_time:NSTimeInterval;
        var m_leftScore:UInt8;
        var m_rightScore:UInt8;
        var m_sMessage:String;
        
        init(time:NSTimeInterval, leftScore:UInt8, rightScore:UInt8, sMessage:String) {
            m_time = time;
            m_leftScore = leftScore;
            m_rightScore = rightScore;
            m_sMessage = sMessage;
        }
    }
    
    /** Log of events that occur during the bout */
    private var m_boutEvents:[BoutEvent];
    
    var m_viewController:BoutViewController;
    
    /** Fencer data for the current bout */
    private var m_boutData:BoutData;
    
    /** The current period */
    private var m_iPeriod:UInt8;
    
    /** The current period */
    var currentPeriod:UInt8 {
        get { return m_iPeriod; }
        set { m_iPeriod = newValue; }
    }
    
    /** The maximum number of periods for the bout */
    private var m_iMaxPeriod:UInt8;
    
    /** The maximum number of periods for the bout */
    var maxPeriods:UInt8 {
        get { return m_iMaxPeriod; }
        set { m_iMaxPeriod = newValue; }
    }
    
    /** The target score for the bout */
    private var m_iPointTarget:UInt8;
    
    /** The target score for the bout */
    var pointTarget:UInt8 {
        get { return m_iPointTarget; }
        set { m_iPointTarget = newValue; }
    }
    
    /** The bout timer */
    private var m_timer:Timer?;
    
    /** The default bout time */
    private var m_fDefaultTime:NSTimeInterval;
    
    public var leftScore:UInt8 {
        return m_boutData.leftScore;
    }
    
    public var rightScore:UInt8 {
        return m_boutData.rightScore;
    }
    
    /** The current time of the bout */
    public var currentTime:NSTimeInterval {
        get { return (m_timer?.currentTime)!; }
        set {
            m_timer?.currentTime = newValue;
            m_viewController.setCurrentTime(currentTime: newValue);
        }
    }
    
    var boutViewController:BoutViewController {
        get { return m_viewController; }
        set { m_viewController = newValue; }
    }
    
    required public init (vc:BoutViewController) {
        m_viewController = vc;
        m_boutData = BoutData();
        m_fDefaultTime = 180;
        m_iPeriod = 1;
        m_iMaxPeriod = 1;
        m_iPointTarget = 5;
        m_boutEvents = [BoutEvent]();
        
        initTimer();
        setupBout();
    }
    
    /*convenience public init(vc:BoutViewController, fTime:Float, iPeriods:UInt8, iPointTarget:UInt8) {
        m_viewController = vc;
        m_boutData = BoutData();
        m_fDefaultTime = fTime;
        m_iPeriod = 1;
        m_iMaxPeriod = iPeriods;
        m_iPointTarget = iPointTarget;
        m_boutEvents = [BoutEvent]();
        
        initTimer();
        setupBout();
    }*/
    
    func initTimer() {
        m_timer = Timer(countdownFrom: m_fDefaultTime, withInterval: 0.1, tickCallback: onTimerTick, finishCallback: onTimerFinish);
    }
    
    func setupBout() {
        m_boutData = BoutData();
        m_timer?.currentTime = m_fDefaultTime;
        m_iPeriod = 1;
        
        m_viewController.setLeftScore(score: m_boutData.leftScore);
        m_viewController.setRightScore(score: m_boutData.rightScore);
        m_viewController.setCurrentTime(currentTime: m_fDefaultTime);
        m_viewController.setPeriodLabel(labelText: "");
        m_viewController.clearPriority();
        m_viewController.setFencingToScore(score: m_iPointTarget);
    }
    
    // MARK: - Bout actions
    
    /** Begin running the timer */
    public func start() {
        m_timer?.start();
    }
    
    /** Stop the timer */
    public func halt() {
        m_timer?.stop();
    }
    
    public func toggleTimer() {
        m_timer?.toggle();
    }
    
    /** 
    Score touch for fencer on the left
    */
    public func touchLeft() {
        m_boutData.leftScore += 1;
        m_viewController.setLeftScore(score: m_boutData.leftScore);
        
        recordBoutEvent("Left scores");
        
        scoreUpdated();
    }
    
    public func reverseTouchLeft() {
        m_boutData.leftScore -= 1;
        m_viewController.setLeftScore(score: m_boutData.leftScore);
    }
    
    /** 
    Score touch for fencer on the right 
    */
    public func touchRight() {
        m_boutData.rightScore += 1;
        m_viewController.setRightScore(score: m_boutData.rightScore);
        
        recordBoutEvent("Right scores");
        
        scoreUpdated();
    }
    
    public func reverseTouchRight() {
        m_boutData.rightScore -= 1;
        m_viewController.setRightScore(score: m_boutData.rightScore);
    }
    
    /** 
    Score a double touch, if allowed by the bout type 
    */
    public func touchDouble() {
        m_boutData.leftScore += 1;
        m_boutData.rightScore += 1;
        
        m_viewController.setLeftScore(score: m_boutData.leftScore);
        m_viewController.setRightScore(score: m_boutData.rightScore);
        
        scoreUpdated();
        
        recordBoutEvent("Double-touch");
    }
    
    public func cardLeft(card:Card) {
        m_boutData.leftCard = card;
        m_viewController.setLeftCard(m_boutData.leftCard);
        m_viewController.setRightScore(score: m_boutData.rightScore);
        
        scoreUpdated();
    }
    
    public func cardRight(card:Card) {
        m_boutData.rightCard = card;
        m_viewController.setRightCard(m_boutData.rightCard);
        m_viewController.setLeftScore(score: m_boutData.leftScore);
        
        scoreUpdated();
    }
    
    /** Called by the view controller when the user closes the period break vc */
    public func periodBreakComplete() {
        m_timer?.currentTime = m_fDefaultTime;
        m_viewController.setCurrentTime(currentTime: m_fDefaultTime);
        m_viewController.wantPeriodBreak(false);
    }
    
    /** Select the priority */
    public func selectPriority() {
        m_viewController.setPriority(forLeft: rand() % 2 == 1);
        
        m_timer?.currentTime = 60;
        m_viewController.setCurrentTime(currentTime: 60);
        
        m_viewController.setPeriodLabel(labelText: "Priority Minute");
        m_viewController.wantPriority(false);
    }
    
    // MARK: - Bout management
    
    /** Reset the bout to its default state */
    func resetToDefault() {
        m_boutData = BoutData();
        m_timer?.currentTime = m_fDefaultTime;
        
        m_viewController.setLeftScore(score: m_boutData.leftScore);
        m_viewController.setRightScore(score: m_boutData.rightScore);
        m_viewController.setLeftCard(Card.None);
        m_viewController.setRightCard(Card.None);
        m_viewController.setCurrentTime(currentTime: m_fDefaultTime);
        m_viewController.clearPriority();
        
        m_viewController.setPeriodLabel(labelText: "");
        
        m_viewController.wantPeriodBreak(false);
        m_viewController.wantPriority(false);
    }
    
    // MARK: - Internals
    
    /**
    Record a message into the bout history
    
    :sMessage: The message to record. Timestamp and scores are automatically added.
    */
    private func recordBoutEvent(sMessage:String) {
        let time:NSTimeInterval? = m_timer?.currentTime;
        let event:BoutEvent = BoutEvent(time: time!, leftScore: m_boutData.leftScore, rightScore: m_boutData.rightScore, sMessage: sMessage);
        m_boutEvents.append(event);
    }
    
    /** Called at the end of the period. Handle switching to the next. */
    func endOfPeriod() {
        if (m_iPeriod == m_iMaxPeriod && m_boutData.leftScore == m_boutData.rightScore) {
            m_viewController.wantPriority(true);
        } else if m_iMaxPeriod > 1 && m_iPeriod < m_iMaxPeriod {
            m_viewController.wantPeriodBreak(true);
        }
    }
    
    /** Called whenever the score is changed */
    func scoreUpdated() {
        if m_boutData.leftScore >= m_iPointTarget || m_boutData.rightScore >= m_iPointTarget {
            m_viewController.alert();
        }
    }
    
    // MARK: - Timer handling
    
    /** 
    Called on each tick of the timer.
    
    :fTimerValue: The value of the timer after the tick
    */
    func onTimerTick(fTimerValue:NSTimeInterval) {
        m_viewController.setCurrentTime(currentTime: fTimerValue);
    }
    
    /** Called by the timer when completed. */
    func onTimerFinish() {
        m_viewController.setCurrentTime(currentTime: 0);
        m_viewController.stopTimer();
        
        endOfPeriod();
    }
}