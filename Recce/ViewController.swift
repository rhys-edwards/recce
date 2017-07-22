//
//  ViewController.swift
//  Recce
//
//  Created by Rhys Edwards on 8/7/17.
//  Copyright © 2017 Rhys Edwards. All rights reserved.
//

import UIKit
import MapKit
import Photos

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var geoLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    
    let UIImagePickerControllerImageURL: String = ""
    let UIImagePickerControllerPHAsset: String = ""
    
    // Get the longitude and latitude
    let manager = CLLocationManager()
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        let span:MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
        let myLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        
        // THIS WORKS!
        // Work out how to append this to photo exif, or in a DB with a UID for the photo
        //print(myLocation.latitude)
        
        let region:MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span)
        map.setRegion(region, animated: true)
        
        self.map.showsUserLocation = true
    }
    
    // Let a user pick an image (can only select from library)
    @IBAction func importImage(_ sender: Any) {
        let image = UIImagePickerController()

        image.delegate = self
        
        // Display from library
        image.sourceType = UIImagePickerControllerSourceType.camera

        image.allowsEditing = false
        
        self.present(image, animated: true) {
            print("hello me")
        }
    }
    
    // SAVE IMAGE TO PHOTO LIBRARY
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        func addAsset(image: UIImage, location: CLLocation? = nil) {
            PHPhotoLibrary.shared().performChanges({
                // Request creating an asset from the image.
                let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                // Set metadata location
                if let location = location {
                    creationRequest.location = location
                }
            }, completionHandler: { success, error in
                if !success { NSLog("error creating asset: \(String(describing: error))") }
            })
        }
        
        addAsset(image: image, location: manager.location)
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        print(manager.location!)
        print(info[UIImagePickerControllerMediaMetadata]!)

        
        var chosenImage:UIImage?
        var location = "Not known"
        var timeTaken = "Not known"
        
        if let URL = info[UIImagePickerControllerReferenceURL] as? URL {
            print("We got the URL as \(URL)")
            let opts = PHFetchOptions()
            opts.fetchLimit = 1
            let assets = PHAsset.fetchAssets(withALAssetURLs: [URL], options: opts)
            for assetIndex in 0..<assets.count {
                let asset = assets[assetIndex]
                location = String(describing: asset.location)
                timeTaken = asset.creationDate!.description
                
                CLGeocoder().reverseGeocodeLocation(asset.location!, completionHandler: {(placemarks, error) -> Void in
                    print(location)
                    
                    if let error = error {
                        print("Reverse geocoder failed with error" + error.localizedDescription)
                        return
                    }
                    
                    if placemarks != nil && placemarks!.count > 0 {
                        DispatchQueue.main.async {
                            self.geoLabel.text = placemarks![0].locality!
                        }
                    } else {
                        print("There's a problem with the data, motherfucker")
                    }
                })
            }
        }
        
        if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            chosenImage = editedImage
        } else if let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            chosenImage = selectedImage
        }
        
        dismiss(animated: true) {
            DispatchQueue.main.async {
                self.myImageView.image = chosenImage
                self.locationLabel.text = location
                self.timeLabel.text = timeTaken
            }
        }
    }
    
    func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the location manager
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

