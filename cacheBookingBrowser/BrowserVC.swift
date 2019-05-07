//
//  ViewController.swift
//  cacheBookingBrowser
//
//  Created by Kohei Masumi on 2019/03/22.
//  Copyright © 2019年 Kohei Masumi. All rights reserved.
//



import UIKit
import WebKit // WKWebViewを使うのでwebKitインポート
import CoreData
import SystemConfiguration


class BrowserVC: UIViewController, UISearchBarDelegate, WKNavigationDelegate, WKUIDelegate {
    
    //weak var delegate: AnyObject?
    //var  pageDataFolderString = String()
    
    @IBOutlet weak var progressView: UIProgressView!
    var downloadButton: UIBarButtonItem!
    var tabButton: UIBarButtonItem!
    var webView: WKWebView!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var currentURL: URL!
    var currentString = String()
    var thamnailImage = UIImage()
    var titleCd = String()
    var titleName = String()
    

    //初期表示
    func customization(){
        // ツールバー
        let toolbar = UIToolbar(frame: CGRect(x:0, y:view.bounds.size.height - 44, width:view.bounds.size.width, height:44.0))
        
        toolbar.barStyle = .default
        toolbar.tintColor = view.tintColor
        
        downloadButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(tapDownloadButton(_:)))
        
        tabButton = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(tapTabButton(_:)))
        
        // スペーサー
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        // ツールバーに追加する.
        toolbar.items = [flexibleItem, downloadButton, flexibleItem, tabButton, flexibleItem]
        view.addSubview(toolbar)
        view.bringSubview(toFront: toolbar)
        
        progressView.progressTintColor = UIColor.blue
        progressView.trackTintColor = UIColor.white
        progressView.transform = CGAffineTransform(scaleX: 1.0, y: 2.0)
        
        
    }
    
    //CoreDataにセーブする
    func saveContextToPagesEntity(title:String, snapshot:UIImage, url:String){
        let contextBrowser = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Pages", in: contextBrowser)
        let newPage = NSManagedObject(entity: entity!, insertInto: contextBrowser) as! Pages
        //newPage.setValue(title, forKey:"pageName" )
        //newPage.setValue(snap, forKey: "snapshot")
        //newPage.setValue(url, forKey: "url")
        let imageData:NSData = UIImagePNGRepresentation(snapshot)! as NSData
        newPage.pageName = title
        newPage.snapshot = imageData
        newPage.url = url
        
        do {
            try contextBrowser.save()
        } catch {
            print("Failed saving")
        }
        contextBrowser.refreshAllObjects()
    }
    
    //CoreDataから削除する
    func deleteDataFromPagesEntity(title: String){
        
        let contextPagessEntity = appDelegate.persistentContainer.viewContext
        let fetchRequest:NSFetchRequest<Pages> = Pages.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "pageName = %@", title)
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let fetchData = try contextPagessEntity.fetch(fetchRequest)
            if(!fetchData.isEmpty){
                for i in 0..<fetchData.count{
                    //print("cの値",((fetchData[i] as AnyObject).url)!!)
                    let deleteObject = fetchData[i]
                    contextPagessEntity.delete(deleteObject)
                }
                do{
                    try contextPagessEntity.save()
                }catch{
                    print(error)
                }
            }
        } catch {
            print("Failed")
        }
        contextPagessEntity.refreshAllObjects()
    }
   
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
        //ビューのロードと同時にグローバル変数の初期化
        currentString = ""
        print("currentString最初",currentString)
        
        // WKWebView生成
         let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: CGRect(x: 0,
                                          y: 20,
                                          width: self.view.frame.size.width,
                                          height: self.view.bounds.size.height-64),
                            configuration: webConfiguration)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        customization()
        //findDataInCoreData()
    
        // WebViewの読み込み状態を監視する
        webView.addObserver(self, forKeyPath:"estimatedProgress", options:.new, context:nil)
        
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        print("viewDidLoadのオンライン判定:", CheckReachability(host_name: "google.com"))//LI-FloのIPに変更の必要あり
        if CheckReachability(host_name: "google.com") {
            print("インターネットへの接続が確認されました")
            let urlString = "https://www.google.com"
            let encodedUrlString = urlString.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!
            
            let myURL = URL(string: encodedUrlString)
            //request作成
            let request = URLRequest(url: myURL!, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
            
            view.addSubview(webView)
            webView.load(request)
            if webView.url != nil{
                currentURL = webView.url
                print("viewDidLoad時のcurrentURL:",currentURL!)
            }
        } else {
            print("インターネットに接続してください")
            displayMyAlertMessage(userTitle: "offline", userMessage: "connect to internet")
            downloadButton.isEnabled = false
            loadFileToWebView(file:"noInternet")
        }
    }
    
    
    @objc func tapDownloadButton(_ sender: UIBarButtonItem){
       
            let alert: UIAlertController = UIAlertController(title: "would you like to add this page?", message: "", preferredStyle:  UIAlertControllerStyle.alert)
            
            // OKボタン
            let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:{
                // ボタンが押された時の処理を書く（クロージャ実装）
                (action: UIAlertAction!) -> Void in
                print("OK")
                
                //処理が終わるまでボタンをUnableにする
                
                    self.downloadButton.isEnabled = false
                    self.downloadButton.tintColor = self.view.tintColor.withAlphaComponent(0.6)
                    self.tabButton.isEnabled = false
                    self.tabButton.tintColor = self.view.tintColor.withAlphaComponent(0.6)
                   
                
                
                //self.showLoading(state: true)
                if self.CheckReachability(host_name: "google.com") {
                    print("インターネットへの接続が確認されました")
                    //現在のURL取得
                    let currentURL = self.webView.url
                    self.currentString = (currentURL?.absoluteString)!
                    print("currentURL:",self.currentString)
                    //スナップショットの作成
                    self.thamnailImage = self.imageSnapshot()
                    //タイトル取得
                    
                    
                    let noSlushString = String(self.currentString.prefix(self.currentString.count - 1))
                    let fileArray = noSlushString.components(separatedBy: "/")
                    
                    if !(fileArray.isEmpty){
                        if fileArray.last! != "index"{
                            self.titleCd = fileArray.last!
                        }else{
                            let noSlushString2 = String(self.currentString.prefix(self.currentString.count - 6))
                            let fileArray2 = noSlushString2.components(separatedBy: "/")
                            self.titleCd = fileArray2.last!
                            
                        }
                        
                    }else{
                        self.titleCd = "unknown"
                    }
                    
                    let request = URLRequest(url: currentURL!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60)
                    
                    //キャッシュ
                    let memoryCapacity = 500 * 1024 * 1024
                    let diskCapacity = 500 * 1024 * 1024
                    let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first! as NSURL
                    let cachePath = cacheURL.path
                    print("cacheパス:", cachePath!)
                    let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: cachePath)
                    URLCache.shared = cache
                    
                    print("ドキュメントのURL:",self.getDocumentsURL())
                    
                    
                    let task = URLSession.shared.dataTask(with: request) {
                        data, response, error in
                        //let jsonString = String(data: data, encoding: String.Encoding.utf8),
                        
                        if error == nil {
                            print("削除直前のタイトル名:",self.titleCd)
                            self.deleteDataFromPagesEntity(title: self.titleCd)
                                self.titleName = self.titleCd
                            
                            //pagesのentityに新しいコンテキストを追加
                            self.saveContextToPagesEntity(title:self.titleName, snapshot:self.thamnailImage, url:self.currentString)
                            
                            print("セーブ完了(CoreData)！")
                            DispatchQueue.main.async {
                                self.displayMyAlertMessage(userTitle: "done", userMessage: "added \(self.titleName) to the list")
                            }
 
                        } else {
                            print("sessionでエラー",error!.localizedDescription)
                            
                            DispatchQueue.main.async {
                                self.displayMyAlertMessage(userTitle:"Error", userMessage: "try again")
                                
                            }
                        }
                    }
                    task.resume()
                    
                } else {
                    print("インターネットに接続してください")
                    let alertController = UIAlertController(title: "インターネット未接続", message: "", preferredStyle: .alert)
                    
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                    DispatchQueue.main.async {
                        
                        self.loadFileToWebView(file:"noInternet")
                    }
                }
                
                    self.downloadButton.isEnabled = true
                    self.downloadButton.tintColor = self.view.tintColor.withAlphaComponent(1.0)
                    self.tabButton.isEnabled = true
                    self.tabButton.tintColor = self.view.tintColor.withAlphaComponent(1.0)
                    
                
            })
            // 保存キャンセルボタン
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
    
    func imageSnapshot() -> UIImage
    {
        UIGraphicsBeginImageContextWithOptions(self.webView.bounds.size, true, 0)
        self.webView.drawHierarchy(in: self.webView.bounds, afterScreenUpdates: true)
        let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return snapshotImage!
    }
    func getNowTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd_HH_mm_ss"
        let now = Date()
        return formatter.string(from: now)
    }
    // DocumentディレクトリのfileURLを取得
    func getDocumentsURL() -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL
    }
    
    @objc func tapTabButton(_ sender: UIBarButtonItem) {
        
        DispatchQueue.main.async {
            self.present((self.storyboard?.instantiateViewController(withIdentifier: "tabList"))!,
                         animated: true,
                         completion: nil)
        }
        
    }
    
    //オンラインかオフラインか判定
    func CheckReachability(host_name:String)->Bool{
        
        let reachability = SCNetworkReachabilityCreateWithName(nil, host_name)!
        var flags = SCNetworkReachabilityFlags.connectionAutomatic
        if !SCNetworkReachabilityGetFlags(reachability, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
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
    
    func displayMyAlertMessage(userTitle: String, userMessage: String){
        
        let myAlert = UIAlertController(title: userTitle, message: userMessage, preferredStyle:  UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title:"OK", style: UIAlertActionStyle.default, handler:nil)
        myAlert.addAction(okAction);
        self.present(myAlert,animated:true, completion:nil)
        
    }
    func loadFileToWebView(file: String!){
        // index.htmlのパスを取得する
        let path: String = Bundle.main.path(forResource: file, ofType: "html")!
        let localHtmlUrl: URL = URL(fileURLWithPath: path, isDirectory: false)
        // ローカルのHTMLページを読み込む
        self.webView.loadFileURL(localHtmlUrl, allowingReadAccessTo: localHtmlUrl)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print("memory warning")
    }
    
    
    

    
    
}

