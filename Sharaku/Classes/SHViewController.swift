//
//  SHViewController.swift
//  Pods
//
//  Created by 母利 睦人 on 2017/01/04.
//
//

import UIKit

public protocol SHViewControllerDelegate {
    func shViewControllerImageDidFilter(image: UIImage)
    func shViewControllerDidCancel()
}

public class SHViewController: UIViewController {
    public var delegate: SHViewControllerDelegate?
    fileprivate let filterNameList = [
        "No Filter",
        "CIPhotoEffectChrome",
        "CIPhotoEffectFade",
        "CIPhotoEffectInstant",
        "CIPhotoEffectMono",
        "CIPhotoEffectNoir",
        "CIPhotoEffectProcess",
        "CIPhotoEffectTonal",
        "CIPhotoEffectTransfer",
        "CILinearToSRGBToneCurve",
        "CISRGBToneCurveToLinear",
        
        "CIColorInvert",
        "CISepiaTone",
        "CIColorMonochrome",
        "CIColorPosterize",
        "CICrystallize",
        "CIPixellate",
        "CIDiscBlur"
    ]
    
    fileprivate let filterDisplayNameList = [
        "Normal",
        "Chrome",
        "Fade",
        "Instant",
        "Mono",
        "Noir",
        "Process",
        "Tonal",
        "Transfer",
        "Tone",
        "Linear",
        
        "Color Invert",
        "Sepia",
        "Monochrome",
        "Posterize",
        "Crystallize",
        "Pixellate",
        "Blur"
    ]
    
    fileprivate var filterIndex = 0
    fileprivate let context = CIContext(options: nil)
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var topBarView: UIView!
    fileprivate var image: UIImage?
    fileprivate var smallImage: UIImage?
    fileprivate var hidden = false

    public init(image: UIImage) {
        super.init(nibName: nil, bundle: nil)
        self.image = image
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        if let view = UINib(nibName: "SHViewController", bundle: Bundle(for: self.classForCoder)).instantiate(withOwner: self, options: nil).first as? UIView {
            self.view = view
            if let image = self.image {
                imageView?.image = image
                smallImage = resizeImage(image: image)
            }
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: "SHCollectionViewCell", bundle: Bundle(for: self.classForCoder))
        collectionView?.register(nib, forCellWithReuseIdentifier: "cell")
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func imageViewDidSwipeLeft() {
        if filterIndex == filterNameList.count - 1 {
            filterIndex = 0
            imageView?.image = image
        } else {
            filterIndex += 1
        }
        if filterIndex != 0 {
            applyFilter()
        }
        updateCellFont()
    }

    @IBAction func imageViewDidSwipeRight() {
        if filterIndex == 0 {
            filterIndex = filterNameList.count - 1
        } else {
            filterIndex -= 1
        }
        if filterIndex != 0 {
            applyFilter()
        } else {
            imageView?.image = image
        }
        updateCellFont()
    }
    
    @IBAction func imageViewDidTap() {
        if !hidden {
            let hideCollectionTransform = collectionView.transform.translatedBy(x: 0, y: collectionView.frame.size.height)
            let hideTopBarTransform = topBarView.transform.translatedBy(x: 0, y: -topBarView.frame.size.height)
            
            UIView.animate(withDuration: TimeInterval(0.3), animations:
                {
                    self.collectionView.transform = hideCollectionTransform
                    self.topBarView.transform = hideTopBarTransform
                    self.hidden = true
            })
        } else {
            UIView.animate(withDuration: TimeInterval(0.3), animations:
                {
                    self.collectionView.transform = .identity
                      self.topBarView.transform = .identity
                    self.hidden = false
            })
        }
    }

    func applyFilter() {
        let filterName = filterNameList[filterIndex]
        if let image = self.image {
            let filteredImage = createFilteredImage(filterName: filterName, image: image)
            imageView?.image = filteredImage
        }
    }

    func createFilteredImage(filterName: String, image: UIImage) -> UIImage {
        // 1 - create source image
        let sourceImage = CIImage(image: image)

        // 2 - create filter using name
        let filter = CIFilter(name: filterName)
        filter?.setDefaults()

        // 3 - set source image
        filter?.setValue(sourceImage, forKey: kCIInputImageKey)

        // 4 - output filtered image as cgImage with dimension.
        let outputCGImage = context.createCGImage((filter?.outputImage!)!, from: (filter?.outputImage!.extent)!)

        // 5 - convert filtered CGImage to UIImage
        let filteredImage = UIImage(cgImage: outputCGImage!)

        return filteredImage
    }

    func resizeImage(image: UIImage) -> UIImage {
        let ratio: CGFloat = 0.3
        let resizedSize = CGSize(width: Int(image.size.width * ratio), height: Int(image.size.height * ratio))
        UIGraphicsBeginImageContext(resizedSize)
        image.draw(in: CGRect(x: 0, y: 0, width: resizedSize.width, height: resizedSize.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage!
    }

    @IBAction func closeButtonTapped() {
        if let delegate = self.delegate {
            delegate.shViewControllerDidCancel()
        }
        dismiss(animated: true, completion: nil)
    }

    @IBAction func doneButtontapped() {
        if let delegate = self.delegate {
            delegate.shViewControllerImageDidFilter(image: (imageView?.image)!)
        }
        dismiss(animated: true, completion: nil)
    }
}

extension  SHViewController: UICollectionViewDataSource, UICollectionViewDelegate
{
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! SHCollectionViewCell
        var filteredImage = smallImage
        if indexPath.row != 0 {
            filteredImage = createFilteredImage(filterName: filterNameList[indexPath.row], image: smallImage!)
        }

        cell.imageView.image = filteredImage
        cell.filterNameLabel.text = filterDisplayNameList[indexPath.row]
        updateCellFont()
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filterNameList.count
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        filterIndex = indexPath.row
        if filterIndex != 0 {
            applyFilter()
        } else {
            imageView?.image = image
        }
        updateCellFont()
    }

    func updateCellFont() {
        // update font of selected cell
        if let selectedCell = collectionView?.cellForItem(at: IndexPath(row: filterIndex, section: 0)) {
            let cell = selectedCell as! SHCollectionViewCell
            cell.filterNameLabel.font = UIFont.boldSystemFont(ofSize: 14)
        }

        for i in 0...filterNameList.count - 1 {
            if i != filterIndex {
                // update nonselected cell font
                if let unselectedCell = collectionView?.cellForItem(at: IndexPath(row: i, section: 0)) {
                    let cell = unselectedCell as! SHCollectionViewCell
                    if #available(iOS 8.2, *) {
                        cell.filterNameLabel.font = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightThin)
                    } else {
                        // Fallback on earlier versions
                        cell.filterNameLabel.font = UIFont.systemFont(ofSize: 14.0)
                    }
                }
            }
        }
    }
}
