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
}
