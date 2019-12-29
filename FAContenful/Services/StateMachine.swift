//
//  StateMachine.swift
//  
//
//  Created by Ferhat Abdullahoglu on 25.12.2019.
//

import Foundation

/// Register observations for the change of value for a given variable and trigger those observation callbacks when a change is made.
final public class StateMachine<State> {
    
    struct Transition {
        let last: State
        let next: State
    }
    
    typealias TransitionObservation = (Transition) -> Void
    
    var state: State {
        didSet {
            for (_, observe) in self.observations {
                observe(Transition(last: oldValue, next: state))
            }
        }
    }
    
    internal func triggerObservations() {
        broadcast()
    }
    
    func broadcast() {
        for (_, observer) in self.observations {
            observer(Transition(last: self.state, next: self.state))
        }
    }
    
    @discardableResult func addTransitionObservation(_ observation: @escaping TransitionObservation) -> String {
        let token = UUID().uuidString
        observations[token] = observation
        return token
    }
    
    @discardableResult func addTransitionObservationAndObserveInitialState(_ observation: @escaping TransitionObservation) -> String {
        // Trigger the initial state being set.
        observation(Transition(last: state, next: state))
        let token = addTransitionObservation(observation)
        return token
    }
    
    func stopObserving(token: String) {
        observations.removeValue(forKey: token)
    }
    
    
    private var observations: [String: TransitionObservation] = [:]
    
    init(initialState: State, observe: TransitionObservation? = nil) {
        self.state = initialState
        if let observer = observe {
            // Trigger the initial state being set.
            addTransitionObservation(observer)
        }
    }
}
