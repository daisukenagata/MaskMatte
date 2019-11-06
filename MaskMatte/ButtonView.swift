//
//  ButtonView.swift
//  MaskMatte
//
//  Created by 永田大祐 on 2019/11/06.
//  Copyright © 2019 永田大祐. All rights reserved.
//

import UIKit

class ButtonView: UIView {

    let bt = UIButton()
    let bt2 = UIButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        btDesgin(tab: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func btDesgin(tab: CGRect) {
        print(tab)
        bt.frame = CGRect(x: (tab.width) / 2 - 75, y: (tab.height) / 2 - 25, width: 50, height: 50)
        bt.backgroundColor = .red
        bt.layer.cornerRadius = bt.frame.height/2
        
        bt2.frame = CGRect(x: (tab.width) / 2 + 25, y: (tab.height) / 2 - 25, width: 50, height: 50)
        bt2.backgroundColor = .blue
        bt2.layer.cornerRadius = bt2.frame.height/2
    }
}
