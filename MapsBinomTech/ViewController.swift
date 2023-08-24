import UIKit
import YandexMapsMobile


class MainViewController: UIViewController, YMKMapInputListener, YMKLayersGeoObjectTapListener, YMKUserLocationObjectListener, YMKMapObjectTapListener {
    
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var avatarIV: UIImageView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var mapView: YMKMapView!
    
    let TAG = "MainViewController: "
    lazy var mapKit = YMKMapKit.sharedInstance()
    lazy var userLocationLayer = mapKit.createUserLocationLayer(with: mapView.mapWindow)
    let LOCATION_1 = YMKPoint(latitude: 55.751574, longitude: 37.573856)   //  мск
    let LOCATION_2 = YMKPoint(latitude: 55.75612082627646, longitude: 37.577041618173354)
    let LOCATION_3 = YMKPoint(latitude: 55.74965808867371, longitude: 37.571078607496446)
    let LOCATION_4 = YMKPoint(latitude: 55.75143909462603, longitude: 37.576130776591356)
    let zoomValue = 15
    let userName = "Илья"
    
    override func viewDidLoad() {
        NSLog(TAG + "viewDidLoad: entrance")
        super.viewDidLoad()
        
        circleAvatar(avatarIV, true)
        hideBottomView()
        
        addPlacemarkOnMap(LOCATION_2)
        addPlacemarkOnMap(LOCATION_3)
        addPlacemarkOnMap(LOCATION_4)
        
        mapView.mapWindow.map.move(
            with: YMKCameraPosition(target: LOCATION_1, zoom: Float(zoomValue), azimuth: 0, tilt: 0),
            animationType: YMKAnimation(type: YMKAnimationType.smooth, duration: 0.5),
            cameraCallback: nil
        )

        mapView.mapWindow.map.addTapListener(with: self)
        mapView.mapWindow.map.addInputListener(with: self)
        NSLog(TAG + "viewDidLoad: exit")
    }
    
    // MARK: нажатие на маркер
    func onMapObjectTap(with mapObject: YMKMapObject, point: YMKPoint) -> Bool {
        guard let placemark = mapObject as? YMKPlacemarkMapObject else {
            NSLog(TAG + "onMapObjectTap: error")
            return false
        }
        showBottomView()
        self.focusOnPlacemark(placemark)
        NSLog(TAG + "onMapObjectTap: success")
        return true
    }
    
    // MARK: фокус на точке
    func focusOnPlacemark(_ placemark: YMKPlacemarkMapObject) {
        NSLog(TAG + "focusOnPlacemark: entrance")
        mapView.mapWindow.map.move(
            with: YMKCameraPosition(target: placemark.geometry, zoom: 18, azimuth: 0, tilt: 0),
            animationType: YMKAnimation(type: YMKAnimationType.smooth, duration: 0.5),
            cameraCallback: nil
        )
        NSLog(TAG + "focusOnPlacemark: exit")
    }
    
    // MARK: добавление маркера
    func addPlacemarkOnMap(_ point: YMKPoint) {
        NSLog(TAG + "addPlacemarkOnMap: entrance")
        let viewPlacemark: YMKPlacemarkMapObject = mapView.mapWindow.map.mapObjects.addPlacemark(with: point)
        
        var markerIcon = UIImage(named: "ic_mylocation")
        markerIcon = markerIcon!.roundedImageWithBorder(width: 5, color: UIColor.blue)
        
        viewPlacemark.setIconWith(
            markerIcon!,
            style: YMKIconStyle(
                anchor: CGPoint(x: 0.5, y: 0.5) as NSValue,
                rotationType: YMKRotationType.rotate.rawValue as NSNumber,
                zIndex: 0,
                flat: true,
                visible: true,
                scale: 0.7,
                tappableArea: nil
            )
        )
        viewPlacemark.addTapListener(with: self)
        NSLog(TAG + "addPlacemarkOnMap: exit")
    }

    // MARK: нажатие на объект
    func onObjectTap(with: YMKGeoObjectTapEvent) -> Bool {
        NSLog(TAG + "onObjectTap: entrance")
        let event = with
        let metadata = event.geoObject.metadataContainer.getItemOf(YMKGeoObjectSelectionMetadata.self)
        if let selectionMetadata = metadata as? YMKGeoObjectSelectionMetadata {
            mapView.mapWindow.map.selectGeoObject(withObjectId: selectionMetadata.id, layerId: selectionMetadata.layerId)
            NSLog(TAG + "onObjectTap: true")
            return true
        }
        NSLog(TAG + "onObjectTap: false")
        return false
    }
    
    // MARK: текущая локация
    @IBAction func myLocationButtonClicked(_ sender: Any) {
        NSLog(TAG + "myLocationButtonClicked: entrance")
        if userLocationLayer.isVisible() {
            NSLog(TAG + "myLocationButtonClicked: userLocationLayer.isVisible = true")
            userLocationLayer.setVisibleWithOn(false)
            locationButton.setImage(UIImage(named: "ic_mylocation"), for: .normal)
            hideBottomView()
        } else {
            NSLog(TAG + "myLocationButtonClicked: userLocationLayer.isVisible = true")
            let scale = UIScreen.main.scale
            userLocationLayer.setVisibleWithOn(true)
            userLocationLayer.isHeadingEnabled = false
            userLocationLayer.setAnchorWithAnchorNormal(
                CGPoint(x: 0.5 * mapView.frame.size.width * scale, y: 0.5 * mapView.frame.size.height * scale),
                anchorCourse: CGPoint(x: 0.5 * mapView.frame.size.width * scale, y: 0.83 * mapView.frame.size.height * scale
                )
            )
            userLocationLayer.setObjectListenerWith(self)
            locationButton.setImage(UIImage(named: "ic_my_tracker"), for: .normal)
            showBottomView()
        }
        NSLog(TAG + "myLocationButtonClicked: exit")
    }
    
    // MARK: настройка маркера текущей локации
    func onObjectAdded(with view: YMKUserLocationView) {
        NSLog(TAG + "onObjectAdded: entrance")
        view.arrow.setIconWith(createTrackerIcon()!)
        
        let pinPlacemark = view.pin.useCompositeIcon()
        pinPlacemark.setIconWithName(
            "pin",
            image: createTrackerIcon()!,
            style:YMKIconStyle(
                anchor: CGPoint(x: 0.5, y: 1.0) as NSValue,
                rotationType:YMKRotationType.rotate.rawValue as NSNumber,
                zIndex: 0,
                flat: false,
                visible: true,
                scale: 1,
                tappableArea: nil
            )
        )
        
        pinPlacemark.setIconWithName(
            "icon", image: createCallout()!,
            style:YMKIconStyle(
                anchor: CGPoint(x: 0, y: 0) as NSValue,
                rotationType:YMKRotationType.rotate.rawValue as NSNumber,
                zIndex: 0,
                flat: true,
                visible: true,
                scale: 1.5,
                tappableArea: nil
            )
        )
        NSLog(TAG + "onObjectAdded: exit")
    }
    
    // MARK: создать иконку текущей локации
    func createTrackerIcon() -> UIImage? {
        NSLog(TAG + "createTrackerIcon: entrance")
        let viewTracker = UIView(frame: CGRect(x: 0, y: 0, width: 55, height: 55))
        
        let imgTracker = UIImageView()
        imgTracker.image = UIImage(named:"ic_tracker")
        viewTracker.addSubview(imgTracker)
        imgTracker.layer.cornerRadius = 10
        imgTracker.contentMode = .scaleToFill
        imgTracker.leftAnchor.constraint(equalTo: viewTracker.leftAnchor, constant: 0).isActive = true
        imgTracker.topAnchor.constraint(equalTo: viewTracker.topAnchor, constant: 0).isActive = true
        imgTracker.bottomAnchor.constraint(equalTo: viewTracker.bottomAnchor, constant: 0).isActive = true
        imgTracker.rightAnchor.constraint(equalTo: viewTracker.rightAnchor, constant: 0).isActive = true
        imgTracker.translatesAutoresizingMaskIntoConstraints = false
        
        let imgAvatar = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        imgAvatar.image = UIImage(named:"avatar")
        circleAvatar(imgAvatar, false)
        viewTracker.addSubview(imgAvatar)
        imgAvatar.widthAnchor.constraint(equalToConstant: 40).isActive = true
        imgAvatar.heightAnchor.constraint(equalToConstant: 40).isActive = true
        imgAvatar.centerXAnchor.constraint(equalTo: viewTracker.centerXAnchor).isActive = true
        imgAvatar.bottomAnchor.constraint(equalTo: viewTracker.bottomAnchor, constant: -11).isActive = true
        imgAvatar.translatesAutoresizingMaskIntoConstraints = false
        
        let img = convertViewToImage(viewTracker)
        NSLog(TAG + "createTrackerIcon: exit")
        return img
    }
    
    // MARK: создать отметку
    func createCallout() -> UIImage? {
        NSLog(TAG + "createCallout: entrance")
        let viewCallout = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 40))
        viewCallout.backgroundColor = UIColor.white
        viewCallout.layer.cornerRadius = 20
        viewCallout.alpha = 0.8
        
        let nameLabel = UILabel()
        nameLabel.text = userName
        nameLabel.textColor = .black
        nameLabel.textAlignment = .left
        nameLabel.font = nameLabel.font.withSize(10)
        viewCallout.addSubview(nameLabel)
        nameLabel.widthAnchor.constraint(equalToConstant: 30).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: 10).isActive = true
        nameLabel.topAnchor.constraint(equalTo: viewCallout.topAnchor, constant: 8).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: viewCallout.leftAnchor, constant: 10).isActive = true
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let gpsLabel = UILabel()
        gpsLabel.text = "GPS, "
        gpsLabel.textColor = .gray
        gpsLabel.textAlignment = .left
        gpsLabel.font = gpsLabel.font.withSize(10)
        viewCallout.addSubview(gpsLabel)
        gpsLabel.widthAnchor.constraint(equalToConstant: 25).isActive = true
        gpsLabel.heightAnchor.constraint(equalToConstant: 15).isActive = true
        gpsLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 1).isActive = true
        gpsLabel.leftAnchor.constraint(equalTo: viewCallout.leftAnchor, constant: 10).isActive = true
        gpsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let timeLabel = UILabel()
        timeLabel.text = getTime()
        timeLabel.textColor = .gray
        timeLabel.textAlignment = .left
        timeLabel.font = gpsLabel.font.withSize(10)
        viewCallout.addSubview(timeLabel)
        timeLabel.widthAnchor.constraint(equalToConstant: 30).isActive = true
        timeLabel.heightAnchor.constraint(equalToConstant: 15).isActive = true
        timeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 1).isActive = true
        timeLabel.leftAnchor.constraint(equalTo: gpsLabel.rightAnchor, constant: 1).isActive = true
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let img = convertViewToImage(viewCallout)
        NSLog(TAG + "createCallout: exit")
        return img
    }
 
    // MARK: круглая аватарка
    func circleAvatar(_ img: UIImageView, _ needBorder: Bool){
        NSLog(TAG + "circleAvatar: entrance")
        img.layer.masksToBounds = false
        if needBorder {
            img.layer.borderColor = UIColor.blue.cgColor
            img.layer.borderWidth = 4
        } else {
            img.layer.borderWidth = 0
        }
        img.layer.cornerRadius = img.frame.height/2
        img.clipsToBounds = true
    }
    
    // MARK: получить дату
    func getTime() -> String {
        let mytime = Date()
        let format = DateFormatter()
        format.dateFormat = "HH:mm"
        let timeText = format.string(from: mytime)
        NSLog(TAG + "getTime: timeText = " + timeText)
        return timeText
    }
    
    // MARK: получить время
    func getData() -> String {
        let mytime = Date()
        let format = DateFormatter()
        format.dateFormat = "dd.MM.yy"
        let dateText = format.string(from: mytime)
        NSLog(TAG + "getTime: getData = " + dateText)
        return dateText
    }
    
    // MARK: UIView в UIImage
    func convertViewToImage(_ view: UIView) -> UIImage? {
        NSLog(TAG + "convertViewToImage: entrance")
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        let image = renderer.image { ctx in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        NSLog(TAG + "convertViewToImage: exit")
        return image
    }
    
    func onObjectRemoved(with view: YMKUserLocationView) { }
    
    func onObjectUpdated(with view: YMKUserLocationView, event: YMKObjectEvent) { }
    
    // MARK: кнопка "+" нажата
    @IBAction func plusButtonClicked(_ sender: Any) {
        NSLog(TAG + "plusButtonClicked: entrance: zoom = " + String(mapView.mapWindow.map.cameraPosition.zoom))
        mapView.mapWindow.map.move(
            with: YMKCameraPosition(target: mapView.mapWindow.map.cameraPosition.target, zoom: mapView.mapWindow.map.cameraPosition.zoom + 1, azimuth: 0, tilt: 0),
            animationType: YMKAnimation(type: YMKAnimationType.smooth, duration: 0.5),
            cameraCallback: nil
        )
    }
    
    // MARK: кнопка "-" нажата
    @IBAction func minusButtonClicked(_ sender: Any) {
        NSLog(TAG + "minusButtonClicked: entrance: zoom = " + String(mapView.mapWindow.map.cameraPosition.zoom))
        mapView.mapWindow.map.move(
            with: YMKCameraPosition(target: mapView.mapWindow.map.cameraPosition.target, zoom: mapView.mapWindow.map.cameraPosition.zoom - 1, azimuth: 0, tilt: 0),
            animationType: YMKAnimation(type: YMKAnimationType.smooth, duration: 0.5),
            cameraCallback: nil
        )
    }
    
    // MARK: нажатие на карту
    func onMapTap(with map: YMKMap, point: YMKPoint) {
        NSLog(TAG + "onMapTap: entrance")
        mapView.mapWindow.map.deselectGeoObject()
        hideBottomView()
    }
        
    func onMapLongTap(with map: YMKMap, point: YMKPoint) {}
    
    // MARK: показать нижнее окно
    func showBottomView(){
        dateLabel.text = getData()
        timeLabel.text = getTime()
        bottomView.isHidden = false
    }
    
    // MARK: скрыть нижнее окно
    func hideBottomView(){
        bottomView.isHidden = true
    }
}



extension UIView {
   func toImage() -> UIImage {
       UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0)
       self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
       let snapshotImageFromMyView = UIGraphicsGetImageFromCurrentImageContext()
       UIGraphicsEndImageContext()
       return snapshotImageFromMyView!
   }
}

extension UIImage {
    func roundedImageWithBorder(width: CGFloat, color: UIColor) -> UIImage? {
        let square = CGSize(width: min(size.width, size.height) + width * 2, height: min(size.width, size.height) + width * 2)
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: square))
        imageView.contentMode = .center
        imageView.image = self
        imageView.layer.cornerRadius = square.width/2
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = width
        imageView.layer.borderColor = color.cgColor
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}
