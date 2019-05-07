//
//  TabVC.swift
//  cacheBookingBrowser
//
//  Created by Kohei Masumi on 2019/03/22.
//  Copyright © 2019年 Kohei Masumi. All rights reserved.
//


import WebKit
import UIKit
import CoreData


// MARK: - タブを保持するコンテナクラス
protocol CustomCollectionViewCellDelegate: class {
    func onClickDelete(_ tag:Int)
}

class TabVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, CustomCollectionViewCellDelegate {
    
    var backBtn: UIBarButtonItem!
    var cellImage: UIImage!
    
    var tabDataList: [TabData] = []
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var collectionView: UICollectionView!
    var selectedUrl: String!
    
    private var cache = NSCache<AnyObject, AnyObject>()
    
    deinit{
        collectionView.delegate = nil
        collectionView.dataSource = nil
        print("deinit!!!")
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        customization()
        collectionView?.isPrefetchingEnabled = true
        let contextTab = self.appDelegate.persistentContainer.viewContext
        let fetchRequest:NSFetchRequest<Pages> = Pages.fetchRequest()
        //var pageList:Array<Pages> = []
        do{
            let fetchData = try! contextTab.fetch(fetchRequest)
            if(!fetchData.isEmpty){
                for i in 0..<fetchData.count{
                    print("bの値:",fetchData[i].pageName!)
                    
                    let nameOfPage = fetchData[i].pageName
                    let snap = fetchData[i].snapshot
                    let pageImage:UIImage = UIImage(data:snap! as Data)!
                    let urlOfPage = fetchData[i].url
                    //pageList.append(page)
                    let thisData = TabData(dataListTitle: nameOfPage, dataListUrl: urlOfPage, dataListImage: pageImage)
                    
                    self.tabDataList.append(thisData)
                    print("aの値:", nameOfPage!)
                }
                
            }else{
                print("コアデータは空です")
            }
        }catch{
            print("failed")
        }
        contextTab.refreshAllObjects()
        cache.removeAllObjects()
        
        
        collectionView.register(UINib(nibName: "CustomCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        collectionView.backgroundColor = UIColor.white
        collectionView.delegate = self
        collectionView.dataSource = self
        
        /*
         collectionView.isPagingEnabled = true
         collectionView.clipsToBounds = true
         */
        
    }
    
    //colectionViewの設定
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell : CustomCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath as IndexPath) as! CustomCollectionViewCell
        /*
         //Cellの再利用
         for subview in cell.contentView.subviews {
         subview.removeFromSuperview()
         }
         */
        cell.delegate = self
        cell.tag = indexPath.row
        
        
        cell.configure(with: tabDataList[indexPath.row])
        
        cell.textView.textAlignment = NSTextAlignment.center
        cell.textView.isEditable = false
        
        // 画像配列の番号で指定された要素の名前の画像をUIImageとする
        cellImage = tabDataList[indexPath.row].dataListImage
        // UIImageをUIImageViewのimageとして設定
        cell.imageView?.image = cellImage
        var cellTitle = String()
        let cellTitleCd = tabDataList[indexPath.row].dataListTitle
        
            cellTitle = cellTitleCd!
        
        cell.textView.text = cellTitle
        print("CellTitle", cellTitle)
        
        let cellUrl = tabDataList[indexPath.row].dataListUrl
        cell.urlStr = cellUrl
        
        return cell
        
    }
    
    // MARK: - TableViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedUrl = tabDataList[indexPath.row].dataListUrl
        if selectedUrl != nil {
            // SubViewController へ遷移するために Segue を呼び出す
            performSegue(withIdentifier: "toDetailPage",sender: nil)
        }
        
        
    }
    func customization(){
        // ツールバー
        let toolbar = UIToolbar(frame: CGRect(x:0, y:view.bounds.size.height - 44, width:view.bounds.size.width, height:44.0))
        
        toolbar.barStyle = .default
        toolbar.tintColor = view.tintColor
        
        
        let backBtn = UIBarButtonItem(barButtonSystemItem: .reply, target: self, action: #selector(onClickBackBarButton(_:)))
        
        // スペーサー
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        // ツールバーに追加する.
        toolbar.items = [flexibleItem, backBtn, flexibleItem]
        view.addSubview(toolbar)
        view.bringSubview(toFront: toolbar)
        
        
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // DataSourceの件数を返す
        print("データソースの件数:",tabDataList.count)
        return tabDataList.count
    }
    // Segue 準備
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if (segue.identifier == "toDetailPage") {
            
            let detail: detailPageVC = (segue.destination as? detailPageVC)!
            // SubViewController のselectedImgに選択された画像を設定する
            detail.selectedURL = selectedUrl
        }
    }
    
    //CoreDataから削除する
    func deleteDataFromCoreData(title: String){
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pages")
        fetchRequest.predicate = NSPredicate(format: "pageName = %@", title)
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let fetchData = try context.fetch(fetchRequest)
            if(!fetchData.isEmpty){
                for i in 0..<fetchData.count{
                    //print("cの値",(fetchData[i] as AnyObject).url)
                    let deleteObject = fetchData[i] as! Pages
                    context.delete(deleteObject)
                }
                do{
                    try context.save()
                }catch{
                    print(error)
                }
            }
        } catch {
            print("Failed")
        }
    }
    
    //戻る
    @IBAction func tapkBackButton(_ sender: Any){
        DispatchQueue.main.async {
            self.present((self.storyboard?.instantiateViewController(withIdentifier: "browser"))!,
                         animated: true,
                         completion: nil)
        }
    }
    // タブを閉じる
    func onClickDelete(_ tag:Int){
        //先にCoreDataのデータを削除してからタブリムーブをしないとindexOutOfRangeエラーが起こる
        let pageTitle = tabDataList[tag].dataListTitle
        print("削除ボタンで削除するページのタイトル:",pageTitle!)
        //ファイル削除処理
        deleteDataFromCoreData(title: pageTitle!)
        tabDataList.remove(at: tag)
        collectionView.reloadData()
        
    }
    //戻るボタンを押した時のアクション
    @objc func onClickBackBarButton(_ sender:UIBarButtonItem){
        self.present((self.storyboard?.instantiateViewController(withIdentifier: "browser"))!,
                         animated: true,
                         completion: nil)
            
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("viewWillDisappear")
        
    }
    override func viewWillAppear(_ animated:Bool){
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print("メモリーワーニング")
    }
    
}


let margin: CGFloat = 20.0
extension TabVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 例えば端末サイズを 3 列にする場合
        let width: CGFloat = UIScreen.main.bounds.width/2  - margin*2
        let height = width*1.775
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return margin
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return margin
    }
}

