//
//  ViewController.swift
//  FirestoreTest
//
//  Created by 吉原飛偉 on 2024/07/19.
//

import UIKit
import Firebase
import FirebaseCore

class ViewController: UIViewController {
    @IBOutlet weak var queryDataTableView: UITableView!
    @IBOutlet weak var setTextField: UITextField!
    @IBOutlet weak var setAgeTextField: UITextField!
    @IBOutlet weak var setButton: UIButton!
    
    @IBOutlet weak var addTextField: UITextField!
    @IBOutlet weak var addAgeTextField: UITextField!
    @IBOutlet weak var addButton: UIButton!
    
    @IBOutlet weak var getButton: UIButton!
    @IBOutlet weak var realTimeQuerySwitch: UISwitch!
    
    //FireStoreデータベースへの参照を取得します
    let db = Firestore.firestore()
    //この変数は通常、クエリ結果や文字列データのリストを保存する
    var queriedDataArray = [String()]
    //Firestoreのリアルタイムリスナーを管理するための変数宣言
    var listener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        queryDataTableView.dataSource = self
        addButton.layer.cornerRadius = 15
        setButton.layer.cornerRadius = 15
        getButton.layer.cornerRadius = 15
    }
    //ビューが表示されなくなる直前に呼ばれる
    override func viewWillDisappear(_ animated: Bool) {
        super .viewWillDisappear(animated)
        listener?.remove()
    }
    
    @IBAction func didTapButton(_ sender: UIButton) {
        switch sender {
            //SetButton Acrion
        case setButton :
            guard let name = setTextField.text, let age = setAgeTextField.text else { return }
            db.collection("users").document("HiroshiTachi").setData([
                "name": name,
                "age": age,
            ]) { error in
                if let error = error {
                    print("ドキュメントの書き込みに失敗しました:", error)
                } else {
                    print("ドキュメントの書き込みに成功しました！")
                }
            }
        //AddButton Action
        case addButton :
            guard let name = addTextField.text, let age = addAgeTextField.text else { return }
            var ref: DocumentReference? = nil
            ref = db.collection("users").addDocument(data: [
                "name": name,
                "age": age,
            ]) { error in
                if let error = error {
                    print("ドキュメントの追加に失敗しました:", error)
                } else {
                    print("ドキュメントの追加に成功しました:", ref?.documentID as Any)
                }
            }
        //GetButtonAction
        default:
            queriedDataArray = []
            db.collection("users").getDocuments() { ( QuerySnapshot, error) in
                if let error = error {
                    print("ドキュメントの取得に失敗しました:", error)
                } else {
                    for document in QuerySnapshot!.documents {
                        let data = document.data()
                        guard let name = data["name"] as? String, let age = data["age"] as? String else {
                            return
                        }
                        let nameAndAge = name + " " + age + "歳"
                        self.queriedDataArray.append(nameAndAge)
                        DispatchQueue.main.async {
                            self.queryDataTableView.reloadData()
                        }
                    }
                }
            }
        }
        
    }
    
    @IBAction func didChangeRealTimeQueryState(_ sender: UISwitch) {
        if sender.isOn {
            print("リアルタイムアップデートON")
            listener = db.collection("users").addSnapshotListener { documentSnapshot, error in
                if let error = error {
                    print("ドキュメントの取得に失敗しました", error)
                } else {
                    self.queriedDataArray = []
                    if let documentSnapshots = documentSnapshot?.documents {
                        for document in documentSnapshots {
                            let data = document.data()
                            if let name = data["name"] as? String, let age = data["age"] as? String {
                                let nameAndAge = name + " " + age + "歳"
                                self.queriedDataArray.append(nameAndAge)
                                DispatchQueue.main.async {
                                    self.queryDataTableView.reloadData()
                                }
                            }
                        }
                    }
                }
            }
        } else {
            print("リアルタイムアップデートOFF")
            listener?.remove()
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return queriedDataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = queryDataTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = queriedDataArray[indexPath.row]
        return cell
    }
}
