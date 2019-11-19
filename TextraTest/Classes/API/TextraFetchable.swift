//
//  TextraFetchable.swift
//  TextraTest
//
//  Created by shoshikawa on 2019/11/07.
//  Copyright © 2019 Susumu Hoshikawa. All rights reserved.
//

import Foundation
import Combine

protocol TextraFetchable {
    func textra(for text: String) -> AnyPublisher<TextraResponse, TextraError>
}
