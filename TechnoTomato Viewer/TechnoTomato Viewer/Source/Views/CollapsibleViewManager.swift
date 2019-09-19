//
//  CollapsibleViewManager.swift
//  TechnoTomato Viewer
//
//  Created by DoodleBytes Development on 7/26/19.
//  Copyright © 2019 DoodleBytes Development. All rights reserved.
//

import UIKit

class CollapsibleViewManager: NSObject {
    @IBOutlet weak var viewToExpand: UIView!
    
    @IBOutlet var viewsToCollapse: [UIView] = []
    
    @IBAction func expandView( _ button: UIGestureRecognizer ) {
        for view in self.viewsToCollapse {
            view.isHidden = true 
        }
        if let viewToExpand = self.viewToExpand {
            if viewToExpand.isHidden {
                viewToExpand.isHidden = false 
            } else {
                viewToExpand.isHidden = true
            }
        }
    }
}




