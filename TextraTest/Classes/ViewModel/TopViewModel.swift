//
//  TopViewModel.swift
//  TextraTest
//
//  Created by shoshikawa on 2019/11/07.
//  Copyright © 2019 Susumu Hoshikawa. All rights reserved.
//

import Foundation
import Combine
import OAuthSwift

final class TopViewModel: ObservableObject {
    
    @Published var text: String = ""
    @Published var response: TextraResponse?
    
    private let fetcher: TextraFetcher
    private var requestCancellable: Cancellable? {
        didSet { oldValue?.cancel() }
    }
    
    init(fetcher: TextraFetcher = TextraFetcher()) {
        self.fetcher = fetcher
    }
    
    deinit {
        requestCancellable?.cancel()
    }
    
    func fetchTextra(for text: String) {
        print(#function)
        
        response = nil
        
        requestCancellable = fetcher.textra(for: text)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] value in
                guard let self = self else { return }
                switch value {
                case .failure(let error):
                    self.response = nil
                    print("error = \(error.localizedDescription)")
                case .finished:
                    print("finished")
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.response = response
            })
    }
}

extension TopViewModel {
    func test() {
        
        let oauthswift = OAuth1Swift(
            consumerKey: Const.API.key,
            consumerSecret: Const.API.secret
        )

        let params = [
            "key": Const.API.key,
            "name": Const.API.name,
            "type": "json",
            "text": self.text
        ]
        
        oauthswift.client.post(
            "https://mt-auto-minhon-mlt.ucri.jgn-x.jp/api/mt/generalNT_ja_en/",
            parameters: params,
            headers: nil,
            body: nil) { result in
                switch result {
                case .success(let response):
                    
                    print("*** success ***")

                    if let response = try? JSONDecoder().decode(TextraResponse.self, from: response.data) {
                        print(response)
                        self.response = response
                    } else {
                        print("パースに失敗しました")
                    }
                    
//                if let string = response.dataString() {
//                    print(string)
//                }
                
                case .failure(let error):
                    print("*** error ***")
                    print(error)
                }
            }
    }
}
