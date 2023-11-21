//
//  DKStoreInfo.swift
//  ABank24
//
//  Created by Anton Vovk on 17.01.2023.
//  Copyright © 2023 ABank. All rights reserved.
//

import Foundation

class DKStoreInfo: Info {
    
    // MARK: - Initialization

    init(viewModel: DKStoreViewModel) {
        super.init()
        sectionInfo.removeAll()
        sectionInfo.append(spacer(height: 20))
        sectionInfo.append(infoSection(objects: viewModel.shopInfo?.mAccessories, title: ABLocalizedString("accessories_title")))
        sectionInfo.append(spacer(height: 30))
        sectionInfo.append(infoSection(objects: viewModel.shopInfo?.mClothes, title: ABLocalizedString("cloth_title")))
    }
    
    
    // MARK: - Private Methods

    private func infoSection(objects: [DKShopItem]?, title: String) -> HFSuperClass {
        var section = HFSuperClass()
        let header = HeaderFooter(text: title, size: CGSize(width: UIScreen.main.bounds.width, height: 30), id: .titled)
        header.font = .medium16
        section.header = header
        let width = (UIScreen.main.bounds.width - 8 - 32) / 2
        section.data = objects?.compactMap { item in
            return CellSuperClass(id: .dynamoItem, object: item, cellSize: CGSize(width: width, height: width + 82))
        } ?? []

        section.sideSpace = kDefaultSideSpace / 2
        return section
    }
    
    private func spacer(height: CGFloat) -> HFSuperClass {
        var section = HFSuperClass()
        let header = HeaderFooter(size: CGSize(width: UIScreen.main.bounds.width, height: height), id: .titled)
        section.header = header
        return section
    }
}
