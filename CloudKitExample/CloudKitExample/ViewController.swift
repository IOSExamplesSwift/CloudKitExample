//
//  ViewController.swift
//  CloudKitExample
//
//  Created by Douglas Alexander on 4/20/18.
//  Copyright © 2018 Douglas Alexander. All rights reserved.
//

import UIKit
import CloudKit
import MobileCoreServices

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var addressField: UITextField!
    @IBOutlet weak var commentsField: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    
    let container = CKContainer.default
    var privateDatabase: CKDatabase?
    var currentRecord: CKRecord?
    var photoURL: URL?
    var recordZone: CKRecordZone?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addressField.layer.borderWidth = 1
        addressField.layer.borderColor = UIColor.lightGray.cgColor
        
        commentsField.layer.borderWidth = 1
        commentsField.layer.borderColor = UIColor.lightGray.cgColor
        
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        
        performSetup()
    }

    func performSetup() {
        privateDatabase = container().privateCloudDatabase
        
        // init recordZone
        recordZone = CKRecordZone(zoneName: "HouseZone")
        
        // save the record to a private database
        if let zone = recordZone {
            privateDatabase?.save(zone, completionHandler: {(recordZone, error) in
                if (error != nil) {
                    self.notifyUser("Record Zone Error", message: "Failed to create custom record zone.")
                } else {
                    print("Saved record zone")
                }
            })
        }
    }
    
    // MARK: Tool Bar Buttons
    @IBAction func saveRecord(_ sender: Any) {
        var asset: CKAsset?
        
        // determine if a valid the photo exists
        if (photoURL == nil) {
            notifyUser("No Photo", message: "Use the Photo option to chose a photo for the record")
            return
        } else {
            // create a new asset with the URL to the photo
            asset = CKAsset(fileURL: photoURL!)
        }
        
        if let zoneID = recordZone?.zoneID {
            // create a new record and assign a record type of Houses
            let myRecord = CKRecord(recordType: "Houses", zoneID: zoneID)
            
            // add objects to the record
            myRecord.setObject(addressField.text as CKRecordValue?, forKey: "address")
            myRecord.setObject(commentsField.text as CKRecordValue?, forKey: "comment")
            myRecord.setObject(asset, forKey: "photo")
            
            // ceate a CK records operation
            let modiyRecordsOpertion = CKModifyRecordsOperation (recordsToSave: [myRecord], recordIDsToDelete: nil)
            
            // create configuration
            let configuration = CKOperationConfiguration()
            configuration.timeoutIntervalForRequest = 10
            configuration.timeoutIntervalForResource = 10
            
            modiyRecordsOpertion.configuration = configuration
            
            // create a completion handler
            modiyRecordsOpertion.modifyRecordsCompletionBlock = { records, recordIDs, error in
                if let err = error {
                    self.notifyUser("Save Error", message: err.localizedDescription)
                } else {
                    // dispatch on main que as the CK operation takes place on a separate que
                    DispatchQueue.main.async {
                        self.notifyUser("Success", message: "Record saved sucecssfully")
                    }
                    self.currentRecord = myRecord
                }
            }
            
            // start the add process
            privateDatabase?.add(modiyRecordsOpertion)
        }
    }
    
    @IBAction func queryRecord(_ sender: Any) {
    }
   
    @IBAction func selectPhoto(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        
        imagePicker.delegate = self
        
        // enable the user to select a photo from the library
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func updateRecord(_ sender: Any) {
    }
    
    @IBAction func deleteRecord(_ sender: Any) {
    }
    
    // hide the keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        addressField.endEditing(true)
        commentsField.endEditing(true)
    }
    
    // MARK: delegate method for photo selection / deletion
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.dismiss(animated: true, completion: nil)
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        imageView.image = image
        photoURL = saveImageToFile(image)
    }
    
    // dismiss the image viewer
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // save the image to file
    func saveImageToFile(_ image: UIImage) -> URL {
        
        // construct the file URL
        let fileMgr = FileManager.default
        let dirPaths = fileMgr.urls(for: .documentDirectory, in: .userDomainMask)
        let fileURL = dirPaths[0].appendingPathComponent("currentImage.jpg")
        
        // write the image to the file in JPEG format
        if let renderedJPEGData = UIImageJPEGRepresentation(image, 0.5) {
            try! renderedJPEGData.write(to: fileURL)
        }
        
        return fileURL
    }
    
    //MARK: user notification method
    func notifyUser(_ title: String, message: String) -> Void{
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

