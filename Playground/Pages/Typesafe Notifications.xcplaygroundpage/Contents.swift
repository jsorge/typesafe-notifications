import UIKit

public protocol NotificationDescriptor {
    associatedtype Payload
    var noteName: Notification.Name { get }
    func encode(payload: Payload) -> Notification
    func decode(_ note: Notification) -> Payload
}

public extension NotificationDescriptor {
    private var _modelKey: String {
        return "ModelKey"
    }
    
    public func encode(payload: Payload) -> Notification {
        let info = [_modelKey: payload]
        let note = Notification(name: noteName, object: nil, userInfo: info)
        return note
    }
    
    public func decode(_ note: Notification) -> Payload {
        let model = note.userInfo![_modelKey] as! Payload
        return model
    }
}

public class NotificationToken {
    let token: NSObjectProtocol
    let center: NotificationCenter
    init(token: NSObjectProtocol, center: NotificationCenter) {
        self.token = token
        self.center = center
    }
    
    deinit {
        center.removeObserver(token)
    }
}

public extension NotificationCenter {
    public func addObserver<A: NotificationDescriptor>(descriptor: A, queue: OperationQueue? = nil, using block: @escaping (A.Payload) -> ()) -> NotificationToken {
        let token = addObserver(forName: descriptor.noteName, object: nil, queue: queue, using: { note in
            block(descriptor.decode(note))
        })
        return NotificationToken(token: token, center: self)
    }
}

/* ====================== CUSTOM NOTIFICATIONS ========================*/
struct CustomNotification: NotificationDescriptor {
    typealias Payload = (name: String, type: String)
    let noteName = Notification.Name(rawValue: "CustomNotificationPosted")
}

class Foo {
    let token: NotificationToken
    init() {
        let custom = CustomNotification()
        token = NotificationCenter.default.addObserver(descriptor: custom) { output in
            print("got the custom")
            print("received a \(output.name) of type \(output.type)")
        }
    }
}

var myFoo: Foo? = Foo()
let sample = (name: "Notification", type: "Custom")
let note = CustomNotification().encode(payload: sample)
NotificationCenter.default.post(note)
myFoo = nil

/* ====================== COCOA TOUCH NOTIFICATIONS ========================*/
struct UIKeyboardDidDisplay: NotificationDescriptor {
    typealias Payload = (begin: CGRect, end: CGRect)
    let noteName: Notification.Name = .UIKeyboardDidShow

    /// Required to interperet system notifications
    func decode(_ note: Notification) -> Payload {
        let begin = note.userInfo![UIKeyboardFrameBeginUserInfoKey] as! CGRect
        let end = note.userInfo![UIKeyboardFrameEndUserInfoKey] as! CGRect
        return (begin, end)
    }

    /// Not required in production, helpful in testing
    func encode(payload: Payload) -> Notification {
        var userInfo = [String: Any]()
        userInfo[UIKeyboardFrameBeginUserInfoKey] = payload.begin
        userInfo[UIKeyboardFrameEndUserInfoKey] = payload.end     
        let note = Notification(name: .UIKeyboardDidShow, object: nil, userInfo: userInfo)
        return note
    }
}

class Bar {
    let token: NotificationToken
    init() {
        let system = UIKeyboardDidDisplay()
        token = NotificationCenter.default.addObserver(descriptor: system) { output in
print("yo")
            print("keyboard starts at \(output.begin), and ends at \(output.end)")
        }
    }
}

var myBar: Bar? = Bar()
let payload = (begin: CGRect.zero, end: CGRect.zero)
let systemNote = UIKeyboardDidDisplay().encode(payload: payload)
NotificationCenter.default.post(systemNote)
myBar = nil




