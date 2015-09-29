//
//  Document.swift
//  RaiseMan
//
//  Created by Stephen Skubik-Peplaski on 9/17/15.
//  Copyright © 2015 Stephen Skubik-Peplaski. All rights reserved.
//

import Cocoa

private var KVOContext: Int = 0

class Document: NSDocument, NSWindowDelegate {
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var arrayController: NSArrayController!

    var employees: [Employee] = [] {
        willSet {
            for employee in employees {
                stopObservingEmployee(employee)
            }
        }
        didSet {
            for employee in employees {
                startObservingEmployee(employee)
            }
        }
    }

    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }

    override var windowNibName: String? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return "Document"
    }

    override func dataOfType(typeName: String) throws -> NSData {
 
        // End editing
        tableView.window?.endEditingFor(nil)
        
        // Create an NSData object from the employees array
        return NSKeyedArchiver.archivedDataWithRootObject(employees)
    }

    override func readFromData(data: NSData, ofType typeName: String) throws {

        print("About to read data of type \(typeName).")
        employees = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [Employee]
    }

    // MARK: - Accessors
    
    func insertObject(employee: Employee, inEmployeesAtIndex index: Int) {
        
        print("adding \(employee) to the employees array")
        
        // Add the inverse of this operation to the undo stack
        let undo: NSUndoManager = undoManager!
        undo.prepareWithInvocationTarget(self).removeObjectFromEmployeesAtIndex(employees.count)
        if !undo.undoing {
            undo.setActionName("Add Person")
        }
        
        employees.append(employee)
    }
    
    func removeObjectFromEmployeesAtIndex(index: Int) {
        
        let employee: Employee = employees[index]
        
        print("removing \(employee) from the employees array")
        
        // Add the inverse of this operation to the undo stack
        let undo: NSUndoManager = undoManager!
        undo.prepareWithInvocationTarget(self).insertObject(employee, inEmployeesAtIndex: index)
        if !undo.undoing {
            undo.setActionName("Remove Person")
        }
        
        // Remove the Employee from the array
        employees.removeAtIndex(index)
    }
    
    // MARK: - Actions
    
    @IBAction func addEmployee(sender: NSButton) {
        let windowController = windowControllers[0]
        let window = windowController.window!
        
        let endEditing = window.makeFirstResponder(window)
        if !endEditing {
            print("Unable to end editing")
            return
        }
        
        let undo: NSUndoManager = undoManager!
        
        // Has a edit already occurred in this event?
        if undo.groupingLevel > 0 {
            // Close the last group
            undo.endUndoGrouping()
            // Open a new group
            undo.beginUndoGrouping()
        }
        
        // Create the object
        let employee = arrayController.newObject() as! Employee
        
        // Add it to the array controller's contentArray
        arrayController.addObject(employee)
        
        // Re-sort (in case the user has set a sort order)
        arrayController.rearrangeObjects()
        
        // Get the sorted array
        let sortedEmployees = arrayController.arrangedObjects as! [Employee]
        
        // Find the object just added
        let row = sortedEmployees.indexOf(employee)!
        
        // Begin edit in the first column
        print("stating edit of \(employee) in row \(row)")
        tableView.editColumn(0,
                        row: row,
                  withEvent: nil,
                     select: true)
    }
    
    @IBAction func removeEmployees(sender: NSButton) {
        let selectedPeople: [Employee] = arrayController.selectedObjects as! [Employee]
        let alert = NSAlert()
        
        alert.messageText = NSLocalizedString("REMOVE_MESSAGE", comment: "The remove alert's messageText")
            //"Do you really want to remove these people?"
        
        let informativeText = NSLocalizedString("REMOVE_INFORMATIVE %d", comment: "The remove alert's informativeText")
        alert.informativeText = String(format: informativeText, selectedPeople.count)
            //"\(selectedPeople.count) people will be removed."
        
        let removeButtonTitle = NSLocalizedString("REMOVE_DO", comment: "The remove alert's remove button")
        alert.addButtonWithTitle(removeButtonTitle)
        
        let removeCancelTitle = NSLocalizedString("REMOVE_CANCEL", comment: "The remove alert's cancel button")
        alert.addButtonWithTitle(removeCancelTitle)
        
        let window = sender.window!
        alert.beginSheetModalForWindow(window, completionHandler: {
            (response) -> Void in
            // If the user chose "Remove", tell the arrayController to delete the people
            switch response {
            case NSAlertFirstButtonReturn:
                // The arrayController will delete the selected objects
                // The argument to remove() is ignored
                self.arrayController.remove(nil)
            default: break
            }
        })
    }
    
    // MARK: - Key Value Observing
    
    func startObservingEmployee(employee: Employee) {
        
        employee.addObserver(self,
                 forKeyPath: "name",
                    options: .Old,
                    context: &KVOContext)
        employee.addObserver(self,
                 forKeyPath: "raise",
                    options: .Old,
                    context: &KVOContext)
    }
    
    func stopObservingEmployee(employee: Employee) {
        
        employee.removeObserver(self,
                    forKeyPath: "name",
                       context: &KVOContext)
        employee.removeObserver(self,
                    forKeyPath: "raise",
                       context: &KVOContext)
    }

    override func observeValueForKeyPath(keyPath: String?,
                                 ofObject object: AnyObject?,
                                          change: [String : AnyObject]?,
                                         context: UnsafeMutablePointer<Void>) {
        
            if context != &KVOContext {
            // If the context does not match, this message must be intended for our superclass
                super.observeValueForKeyPath(keyPath,
                                   ofObject: object,
                                     change: change,
                                    context: context)
                return
            }
            
            if let keyPath = keyPath, object = object, change = change {
                
                var oldValue: AnyObject? = change[NSKeyValueChangeOldKey]
                if oldValue is NSNull {
                    oldValue = nil
                }
                
                let undo: NSUndoManager = undoManager!
                print("oldValue=\(oldValue)")
                undo.prepareWithInvocationTarget(object).setValue(oldValue, forKeyPath: keyPath)
            }
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(notification: NSNotification) {
        employees = []
    }
    
    // MARK: - Printing
    
    override func printOperationWithSettings(printSettings: [String : AnyObject]) throws -> NSPrintOperation {
        let employeesPrintingView = EmployeesPrintingView(employees: employees)
        let printInfo: NSPrintInfo = self.printInfo
        let printOperation = NSPrintOperation(view: employeesPrintingView, printInfo: printInfo)
        return printOperation
    }
}

