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
import Speech

final class TopViewModel: NSObject, ObservableObject {
    
    @Published var isEnabled = false
    @Published var buttonText: String = "音声認識を開始する！"
    @Published var speechText: String = ""
    @Published var response: TextraResponse?
    
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    
    private let fetcher: TextraFetcher
    private var requestCancellable: Cancellable? {
        didSet { oldValue?.cancel() }
    }
    
    init(fetcher: TextraFetcher = TextraFetcher()) {
        self.fetcher = fetcher
        super.init()
        self.speechRecognizer.delegate = self
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

// MARK: - 音声認識関連.

extension TopViewModel: SFSpeechRecognizerDelegate {
    
    /// 音声認識の可否が変更された時に呼び出されるdelegateメソッド.
    /// - Parameters:
    ///   - speechRecognizer: speechRecognizer.
    ///   - available: 音声認識の可否.
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        print(#function)
        
        if available {
            self.isEnabled = true
            self.buttonText = "音声認識を開始する！！"
        } else {
            self.isEnabled = false
            self.buttonText = "やめる！"
        }
    }
    
    /// 音声入力の認証処理.
    func requestRecognizerAuthorization() {
        print(#function)
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            // メインスレッドで処理したい内容のため、OperationQueue.main.addOperationを使う
            OperationQueue.main.addOperation { [weak self] in
                guard let self = self else { return }
                 
                switch authStatus {
                case .authorized:
                    self.isEnabled = true
                case .denied:
                    self.isEnabled = false
                    self.speechText = "音声認識へのアクセスが拒否されています。"
                case .restricted:
                    self.isEnabled = false
                    self.speechText = "この端末で音声認識はできません。"
                case .notDetermined:
                    self.isEnabled = false
                    self.speechText = "音声認識はまだ許可されていません。"
                @unknown default:
                    fatalError()
                }
            }
        }
    }
    
    /// 音声認識の処理.
    func startRecording() throws {
        print(#function)
        
        // 既存タスクがあれば初期化.
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record)
        try audioSession.setMode(.measurement)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            if let result = result {
                self.speechText = result.bestTranscription.formattedString
                isFinal = result.isFinal
                self.test()
            }
            
            // エラーがある、もしくは最後の認識結果だった場合の処理
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                 
                self.recognitionRequest = nil
                self.recognitionTask = nil
                 
                self.isEnabled = true
                self.buttonText = "音声認識を開始する！！！"
            }
        }
        
        // マイクから取得した音声バッファをリクエストに渡す
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
         
        try startAudioEngine()
    }
    
    private func startAudioEngine() throws {
        print(#function)
        
        // startの前にリソースを確保しておく。
        audioEngine.prepare()
         
        try audioEngine.start()
         
        speechText = "(どうぞ喋ってください)"
    }
    
    func tapButton() {
        print(#function)
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            self.isEnabled = false
            self.buttonText = "停止中！！"
        } else {
            try! startRecording()
            self.buttonText = "音声認識をこの辺にしておく！"
        }
    }
}

// MARK: - 翻訳API関連.

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
            "text": self.speechText
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
