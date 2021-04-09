#if canImport(UIKit)
import UIKit
public typealias ViewControllerType = UIViewController
#else
public typealias ViewControllerType = AnyObject
#endif
