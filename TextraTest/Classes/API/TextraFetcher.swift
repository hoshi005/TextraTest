//
//  TextraFetcher.swift
//  TextraTest
//
//  Created by shoshikawa on 2019/11/07.
//  Copyright © 2019 Susumu Hoshikawa. All rights reserved.
//

import Foundation
import Combine

class TextraFetcher {
    private let session: URLSession
    init(session: URLSession = .shared) {
        self.session = session
    }
}

extension TextraFetcher: TextraFetchable {
    
    func textra(for text: String) -> AnyPublisher<TextraResponse, TextraError> {
        return fetchTextra(for: text, with: ja2EnComponents(text: text))
    }
    
    private func fetchTextra<T>(for text: String, with components: URLComponents) -> AnyPublisher<T, TextraError> where T: Decodable {
        
        guard let url = components.url else {
            let error = TextraError.network(description: "URLが不正です.")
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "key=\(Const.API.key)&name=hoshi005&type=json&text=\(text)".data(using: .utf8)
        
        return session.dataTaskPublisher(for: request)
            .mapError { TextraError.network(description: $0.localizedDescription) }
            .flatMap { decode($0.data) }
            .eraseToAnyPublisher()
    }
}

private extension TextraFetcher {
    
    struct TextraAPI {
        static let scheme = "https"
        static let host = "mt-auto-minhon-mlt.ucri.jgn-x.jp"
        static let ja_en = "/api/mt/generalNT_ja_en/"
        static let en_ja = "/api/mt/generalNT_en_ja/"
    }
    
    func ja2EnComponents(text: String) -> URLComponents {
        
        var components = URLComponents()
        components.scheme = TextraAPI.scheme
        components.host = TextraAPI.host
        components.path = TextraAPI.ja_en
        
        // TODO: リクエストパラメータ.
        
//        components.queryItems = [
//            URLQueryItem(name: "key", value: Const.API.key),
//            URLQueryItem(name: "name", value: "hoshi005"),
//            URLQueryItem(name: "type", value: "json"),
//            URLQueryItem(name: "text", value: text)
//        ]
        
        debugPrint(components.url?.absoluteURL ?? "(non value)")
        return components
    }
}

fileprivate func decode<T: Decodable>(_ data: Data) -> AnyPublisher<T, TextraError> {
    
    let decoder = JSONDecoder()
    
    return Just(data)
        .decode(type: T.self, decoder: decoder)
        .mapError { TextraError.parsing(description: $0.localizedDescription) }
        .eraseToAnyPublisher()
}
