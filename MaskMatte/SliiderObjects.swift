//
//  SliiderObjects.swift
//  MaskMatte
//
//  Created by 永田大祐 on 2019/11/05.
//  Copyright © 2019 永田大祐. All rights reserved.
//

import UIKit

class SliiderObjects: UIView, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var sliderImageView: UIImageView!
    
    @IBOutlet weak var sliderView: UIStackView!

    @IBOutlet weak var sliderInputRVector: UISlider!{
        didSet {
            sliderInputRVector.value = 1.0
        }
    }
    @IBOutlet weak var sliderInputGVector: UISlider!{
        didSet {
            sliderInputGVector.value = 1.0
        }
    }
    @IBOutlet weak var sliderInputBVector: UISlider!{
        didSet {
            sliderInputBVector.value = 1.0
        }
    }
    @IBOutlet weak var sliderInputAVector: UISlider!{
        didSet {
            sliderInputAVector.value = 1.0
        }
    }

    private var panGesture = UIPanGestureRecognizer()
    
    private var height: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        loadNib()
        pGesture()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        loadNib()
    }

    func loadNib() {
        let bundle = Bundle(for: SliiderObjects.self)
        let view = bundle.loadNibNamed("SliiderObjects", owner: self, options: nil)?.first as? UIView
        view?.frame = UIScreen.main.bounds
        self.addSubview(view ?? UIView())
        self.subviews[0].backgroundColor = .black
    }

    func returnAnimation(tabHeight: CGFloat) {
        height = tabHeight
        guard sliderImageView.transform.a != 0.9 else {
            sliderImageView.frame.origin.y -= self.frame.height/2 - tabHeight
            sliderImageView.transform = sliderImageView.transform.scaledBy(x: 0.9, y: 1.0)
            UIView.animate(withDuration: 0.4) {
                self.sliderImageView.transform = .identity
                self.sliderImageView.frame.origin.y += self.frame.height/2 - tabHeight
                self.subviews[0].bringSubviewToFront(self.sliderImageView)
            }
            return
        }
    }

    private func pGesture() {

        panGesture = UIPanGestureRecognizer(target: self, action:#selector(panTapped(sender:)))
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)
    }

    @objc private func panTapped(sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .ended:
            UIView.animate(withDuration: 0.3) {
                self.subviews[0].bringSubviewToFront(self.sliderView)
            }
            break
        case .possible:
            break
        case .began:
            guard sliderImageView.transform.a == 0.9 else {
                self.sliderImageView.frame.origin.y -= self.frame.height/2 - height
                UIView.animate(withDuration: 0.2) {
                    self.subviews[0].bringSubviewToFront(self.sliderImageView)
                    self.sliderImageView.transform = self.sliderImageView.transform.scaledBy(x: 0.9, y: 1.0)
                }
                return
            }
            break
        case .changed:
            break
        case .cancelled:
            break
        case .failed:
            break
        @unknown default: break
        }
    }
    
    @IBAction func sliderInputRVector(_ sender: UISlider) { sliderInputRVector.value = sender.value }
    
    @IBAction func sliderInputGVector(_ sender: UISlider) { sliderInputGVector.value = sender.value }
    
    @IBAction func sliderInputBVector(_ sender: UISlider) { sliderInputBVector.value = sender.value }
    
    @IBAction func sliderInputAVector(_ sender: UISlider) { sliderInputAVector.value = sender.value }

}
