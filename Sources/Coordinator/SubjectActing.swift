import Combine
import Foundation

enum SubjectActingQueue {
    case same
    case new(DispatchQueue)
}

struct SubjectActing<Action> {
    
    private let subject: PassthroughSubject<Action, Never>
    private let cancellable: AnyCancellable
    
    public init(
        queue: SubjectActingQueue = .new(.main),
        receiveValue: @escaping (Action) -> Void
    ) {
        subject = PassthroughSubject<Action, Never>()
        
        switch queue {
        case .new(let queue):
            cancellable = subject
                .receive(on: queue)
                .sink(receiveValue: receiveValue)
            
        case .same:
            cancellable = subject
                .sink(receiveValue: receiveValue)
        }
    }
    
    public func send(_ action: Action) {
        subject.send(action)
    }
}
