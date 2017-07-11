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
    
    // Get the longitude and latitude
    let manager = CLLocationManager()
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        let span:MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
        let myLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        
        // THIS WORKS!
        // Work out how to append this to photo exif, or in a DB with a UID for the photo
        print(myLocation.latitude)
        
        let region:MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span)
        map.setRegion(region, animated: true)
        
        self.map.showsUserLocation = true
    }
    
    // Let a user pick an image (can only select from library)
    @IBAction func importImage(_ sender: Any) {
        let image = UIImagePickerController()
        image.delegate = self
        
        // Display from library
        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
        
        image.allowsEditing = false
        
        self.present(image, animated: true) {
            // After it is complete
        }
    }
    
    // GITHUB 
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
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

    
    
//    // Display a photo in a view (currently displays from library)
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: NSDictionary!) {
//        let metadata = info[UIImagePickerControllerReferenceURL]!
//        print(metadata)
//        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
//            myImageView.image = image
//        } else {
//            // Error message
//        }
//        
//        self.dismiss(animated: true, completion: nil)
//    }
    
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

