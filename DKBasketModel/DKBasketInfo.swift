//
//  DKBasketInfo.swift
//  ABank24
//
//  Created by Anton Vovk on 19.01.2023.
//  Copyright © 2023 ABank. All rights reserved.
//

import Foundation

class DKBasketInfo: Info {
    
    // MARK: - Initialization

    init(viewModel: DKBasketViewModel) {
        super.init()
        sectionInfo.removeAll()
        sectionInfo.append(cardInfo(viewModel: viewModel))
        sectionInfo.append(NPInfo(viewModel: viewModel))
        sectionInfo.append(itemsInfo(viewModel: viewModel))
    }
    
    
    // MARK: - Private Methods

    private func infoSection(objects: [DKShopItem]?, title: String) -> HFSuperClass {
        var section = HFSuperClass()
        let header = HeaderFooter(text: title, size: CGSize(width: UIScreen.main.bounds.width, height: 30), id: .titled)
        header.font = .medium16
        section.header = header
        let width = (UIScreen.main.bounds.width - 8 - 32) / 2
        section.data = objects?.compactMap { CellSuperClass(id: .dynamoItem, object: $0, cellSize: CGSize(width: width, height: width * 1.4)) } ?? []
        section.sideSpace = kDefaultSideSpace / 2
        return section
    }
    
    private func cardInfo(viewModel: DKBasketViewModel) -> HFSuperClass {
        var section = HFSuperClass()
        section.header = HeaderFooter(height: kDefaultSideSpace / 2)
        let cardView = SelectCardView.configure(card: viewModel.selectCard,
                                                title: ABLocalizedString("pay_with_card_title"),
                                                insets: UIEdgeInsets(top: 0, left: kDefaultSideSpace, bottom: 0, right: kDefaultSideSpace))
       
        viewModel.subscribeCardRx(cardView.selectedCardRx)
        section.data = [CellSuperClass(id: .newStack, object: [cardView])]
        return section
    }
    
    private func NPInfo(viewModel: DKBasketViewModel) -> HFSuperClass {
        var section = HFSuperClass()
        let object: [String: AnyObject] = [kObject: viewModel.updateNPPlace]
        section.data = [CellSuperClass(id: .selectNPOfficeCell, object: object)]
        return section
    }
    
    private func itemsInfo(viewModel: DKBasketViewModel) -> HFSuperClass {
        var section = HFSuperClass()
        section.header = HeaderFooter(height: 20)
        section.data = viewModel.basketInfo?.mBasket.compactMap({ item in
            let cell = CellSuperClass(id: .dKBasketCell, object: item)
            cell.isEditable = true
            return cell
        }) ?? []
        return section
    }
}
