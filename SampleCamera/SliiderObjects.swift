//
//  SliiderObjects.swift
//  SampleText+Navi
//
//  Created by 永田大祐 on 2019/11/05.
//  Copyright © 2019 永田大祐. All rights reserved.
//

import UIKit

class SliiderObjects: UIView {
    
    @IBOutlet weak var sliderImageView: UIImageView!
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
    @IBOutlet weak var sliderInputBiasVector: UISlider!{
        didSet {
            sliderInputBiasVector.value = 1.0
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        loadNib()
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
    }
    
    @IBAction func sliderInputRVector(_ sender: UISlider) { sliderInputRVector.value = sender.value }
    
    @IBAction func sliderInputGVector(_ sender: UISlider) { sliderInputGVector.value = sender.value }
    
    @IBAction func sliderInputBVector(_ sender: UISlider) { sliderInputBVector.value = sender.value }
    
    @IBAction func sliderInputAVector(_ sender: UISlider) { sliderInputAVector.value = sender.value }
    
    @IBAction func sliderInputBiasVector(_ sender: UISlider) { sliderInputBiasVector.value = sender.value }
}
