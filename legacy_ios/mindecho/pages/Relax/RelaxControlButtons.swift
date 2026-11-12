//
//  RelaxControlButtons.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/10/21.
//

import SwiftUI

struct RelaxControlButtons: View {
    @ObservedObject var viewModel: RelaxTimerViewModel
    
    var body: some View {
        EmptyView()
    }
}

#Preview {
    RelaxControlButtons(viewModel: RelaxTimerViewModel())
}
