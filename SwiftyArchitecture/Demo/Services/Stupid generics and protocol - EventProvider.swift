//
//  EventProvider.swift
//  SAD
//
//  Created by KelanJiang on 2024/6/27.
//  Copyright © 2024 KleinMioke. All rights reserved.
//

import Foundation
import MIOSwiftyArchitecture

public protocol SAAsyncSequence<Element>: AsyncSequence {}

struct _AsyncSequenceWrapper<Base: AsyncSequence>: SAAsyncSequence {
    
    typealias Element = Base.Element
    typealias AsyncIterator = Base.AsyncIterator
    
    var base: Base
    
    func makeAsyncIterator() -> AsyncIterator {
        base.makeAsyncIterator()
    }
}

extension AsyncSequence {
    public func asOpaque() -> some SAAsyncSequence<Element> {
        _AsyncSequenceWrapper(base: self)
    }
}

struct Event {
    let id: String
    let type: Event.`Type`
    let payload: Data
    
    enum `Type` {
        case system
        case user
    }
}

protocol EventProvidable {
    associatedtype EventType
    
    func send(event: Event) async -> Void
//    func observeEvents<S: AsyncSequence>(with type: Event.`Type`) -> S where S.Element == EventType
    func observeEvents(with type: Event.`Type`) -> any AsyncSequence
    func observeEvents2(with type: Event.`Type`) -> any SAAsyncSequence<EventType>
    
    func observeEvents3(with type: Event.`Type`) -> (stream: AsyncStream<Event>, token: UnsubscribeToken)
    
    func observeEvents4(with type: Event.`Type`) -> AsyncStream<Event>
}

class EventProvider: EventProvidable {
    typealias EventType = Event
    
    var allEvents: AsyncStream<Event>
    let allEventsObserver: AsyncStream<Event>.Continuation
    
    var multicaster: AsyncMulticast<Event> = .init()
    
    var allEventsObservingTask: Task<Void, Error>?
    
    init() {
        (allEvents, allEventsObserver) = AsyncStream<Event>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let observe = allEvents.makeMulticaster()
        
        self.allEventsObservingTask = observe.task
        self.multicaster = observe.multicaster
    }
    
    deinit {
        allEventsObserver.finish()
    }
    
    func send(event: Event) {
        allEventsObserver.yield(event)
    }
    
    func observeEvents<S>(with type: Event.`Type`) -> S where S : AsyncSequence, Event == S.Element {
        let filtered = allEvents.filter { $0.type == type }
        // can't make sure what S is, so this appoarch doesn't not work.
        fatalError()
    }
    
    func observeEvents(with type: Event.`Type`) -> any AsyncSequence {
        let filtered = allEvents.filter { $0.type == type }
        return filtered
    }
    
    func observeEvents2(with type: Event.`Type`) -> any SAAsyncSequence<Event> {
        let filtered = allEvents.filter { $0.type == type }
        return filtered.asOpaque()
    }
    
    func observeEvents3(with type: Event.`Type`) -> (stream: AsyncStream<Event>, token: UnsubscribeToken) {
        return multicaster.subscribe { $0.type == type }
    }
    
    func observeEvents4(with type: Event.`Type`) -> AsyncStream<Event> {
        let filtered = allEvents.filter { $0.type == type }
        return filtered.eraseToStream()
    }
}

class EventProviderTestCases {
    
    let provider: EventProvider
    
    init(provider: EventProvider) { self.provider = provider }
    
    func case1() async throws {
        let eventStream = provider.observeEvents(with: .user)
//        eventStream erase the type, such a idiot.
        
        for try await event in eventStream {
            print(type(of: event) == Event.self)
        }
    }
    
    func case2() async throws {
        let stream = provider.observeEvents2(with: .user)
        
        var iterator = stream.makeAsyncIterator()
        while let event = try await iterator.next() {
            /// still is `Any`, lol.
            event
        }
        
        while let event = try await iterator.next() as? Event {
            /// `as? Event` here will have additional type check and conversion, bad performance.
            event
        }
    }
    
    func case3() async throws {
        let subscriber = provider.observeEvents3(with: .user)
        subscriber.token.bindLifetime(to: self)
        
        for await event in subscriber.stream {
            /// Best practice.
            print(event)
        }
    }
    
    func case4() async throws {
        let stream = provider.observeEvents4(with: .user)
        
        for await event in stream {
            /// The inconvenience issue here is we can't suspend the awaiting. So better to use the `AsyncMulticast`.
            print(event)
        }
    }
    
}
