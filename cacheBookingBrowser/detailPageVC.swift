//
//  detailPageVC.swift
//  cacheBookingBrowser
//
//  Created by Kohei Masumi on 2019/03/22.
//  Copyright © 2019年 Kohei Masumi. All rights reserved.
//

import UIKit
import WebKit
import CoreData


class detailPageVC: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    var webView: WKWebView!
    var selectedURL: String!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var json : String!
    var jsonData: NSData!
    var dataBox: NSData!
    @IBOutlet weak var progressView: UIProgressView!
    // MARK: - プログレスバーの更新(KVO)
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if(keyPath == "estimatedProgress"){
            let progress : Float = Float(webView.estimatedProgress)
            if(progressView != nil){
                // プログレスバーの更新
                if(progress < 1.0){
                    progressView.setProgress(progress, animated: true)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                    
                }else{
                    // 読み込み完了
                    progressView.setProgress(0.0, animated: false)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            }
        }
    }
    override func loadView(){
        super.loadView()
       
        let webConfiguration = WKWebViewConfiguration()
        
        // WKWebView生成
        webView = WKWebView(frame: CGRect(x: 0,
                                          y: 20,
                                          width: self.view.frame.size.width,
                                          height: self.view.bounds.size.height-64),
                            configuration: webConfiguration)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        customization()
        // WebViewの読み込み状態を監視する
        webView.addObserver(self, forKeyPath:"estimatedProgress", options:.new, context:nil)
    
        let encodedUrlString = selectedURL.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!
        
        let myUrl = URL(string: encodedUrlString)
        print("myUrl:",encodedUrlString)
        let request = URLRequest(url: myUrl!, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
        
        view.addSubview(webView)
        webView.load(request)
        print("リク成功")
        
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
    }
    
    //初期表示
    func customization(){
        // ツールバー
        let toolbar = UIToolbar(frame: CGRect(x:0, y:self.view.bounds.size.height - 44, width:self.view.bounds.size.width, height:44.0))
        
        toolbar.barStyle = .default
        toolbar.tintColor = self.view.tintColor
        
        
        let  backBtn = UIBarButtonItem(barButtonSystemItem: .reply, target: self, action: #selector(onClickBackBarButton(_:)))
        
        // スペーサー
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        // ツールバーに追加する.
        toolbar.items = [flexibleItem, backBtn, flexibleItem,]
        self.view.addSubview(toolbar)
        self.view.bringSubview(toFront: toolbar)
        
        progressView.progressTintColor = UIColor.blue
        progressView.trackTintColor = UIColor.white
        progressView.transform = CGAffineTransform(scaleX: 1.0, y: 2.0)
        
    }
    
    //戻るボタンを押した時のアクション
    @objc func onClickBackBarButton(_ sender:UIBarButtonItem){
        let alert: UIAlertController = UIAlertController(title: "Going back TabList-page", message: "It'll be initialized if you have written something on the form", preferredStyle:  UIAlertControllerStyle.alert)
        
        // OKボタン
        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            print("OK")
            self.present((self.storyboard?.instantiateViewController(withIdentifier: "tabList"))!,
                         animated: true,
                         completion: nil)
            
        })
        // キャンセルボタン
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            print("Cancel")
        })
        
        // ③ UIAlertControllerにActionを追加
        alert.addAction(cancelAction)
        alert.addAction(defaultAction)
        
        // ④ Alertを表示
        present(alert, animated: true, completion: nil)
        
    }
    // target="_blank"を開けるようにWKUIDelegate を継承して、viewDidLoad() に self.webView!.UIDelegate = self を追加
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    // display alert dialog
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let otherAction = UIAlertAction(title: "OK", style: .default) {
            action in completionHandler()
        }
        alertController.addAction(otherAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // display confirm dialog
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {
            action in completionHandler(false)
        }
        let okAction = UIAlertAction(title: "OK", style: .default) {
            action in completionHandler(true)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print("memory warnig")
    }
}



