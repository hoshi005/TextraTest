//
//  TopView.swift
//  TextraTest
//
//  Created by shoshikawa on 2019/11/07.
//  Copyright © 2019 Susumu Hoshikawa. All rights reserved.
//

import SwiftUI
import Combine

struct TopView: View {
    
    @State var text: String = ""
    @ObservedObject(initialValue: TopViewModel()) var viewModel
    
    var body: some View {
        VStack {
            
            Text(viewModel.speechText)
                .padding()
            
//            TextField("翻訳したい文字", text: $viewModel.text)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .border(Color.gray, width: 2)
            
            Button(action: {
//                self.viewModel.fetchTextra(for: "おはようございます")
//                self.viewModel.test()
                self.viewModel.tapButton()
            }) {
                Text(self.viewModel.buttonText)
            }
            .disabled(!viewModel.isEnabled)
            .padding()
            
            if viewModel.response != nil {
                Text(viewModel.response!.resultset.result.text)
                    .font(.body)
                    .padding()
            }
        }
        .onAppear() { self.viewModel.requestRecognizerAuthorization() }
    }
}

struct TopView_Previews: PreviewProvider {
    static var previews: some View {
        TopView()
    }
}
