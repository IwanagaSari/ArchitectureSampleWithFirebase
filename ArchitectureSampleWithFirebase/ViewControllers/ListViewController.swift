import UIKit
import Firebase

class ListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let db = Firestore.firestore()
    
    var contentArray: [DocumentSnapshot] = []
    var snapshot: QuerySnapshot?
    var selectedSnapshot: DocumentSnapshot?
    
    var listner: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeTableView()
        read()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == R.segue.listViewController.toPost.identifier {
            if let vc = segue.destination as? PostViewController,
                let snap = self.selectedSnapshot {
                vc.selectedPost = Post(
                    id: snap.documentID,
                    user: snap["user"] as! String,
                    content: snap["content"] as! String,
                    date: snap["date"] as! Date
                )
            }
        }
    }
    
    @IBAction func addButtonTapped() {
        selectedSnapshot = nil
        self.toPost()
    }
    
    func initializeTableView() {
        tableView.register(R.nib.listTableViewCell)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    func read()  {
        let options = QueryListenOptions()
        options.includeQueryMetadataChanges(true)
        listner = db.collection("posts")
            .addSnapshotListener(options: options) { snapshot, error in
                guard let snap = snapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                for diff in snap.documentChanges {
                    if diff.type == .added {
                        print("New data: \(diff.document.data())")
                    }
                }
                print("Current data: \(snap)")
                self.snapshot = snap
                self.reload()
        }
    }
    
    func delete(deleteIndexPath indexPath: IndexPath) {
        db.collection("posts").document(contentArray[indexPath.row].documentID).delete()
        contentArray.remove(at: indexPath.row)
    }
    
    func reload() {
        if let snap = snapshot,
            !snap.isEmpty {
            print(snap)
            contentArray.removeAll()
            for item in snap.documents {
                contentArray.append(item)
            }
            db.settings.isPersistenceEnabled = true
            self.tableView.reloadData()
        }
    }

    func toPost() {
        self.performSegue(withIdentifier: R.segue.listViewController.toPost, sender: self)
    }
}

extension ListViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contentArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.listTableViewCell.identifier) as? ListTableViewCell else { return UITableViewCell() }
        
        let content = contentArray[indexPath.row]
        let date = content["date"] as! Date
        cell.setCellData(date: date, content: String(describing: content["content"]!))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedSnapshot = contentArray[indexPath.row]
        self.toPost()
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.delete(deleteIndexPath: indexPath)
            tableView.deleteRows(at: [indexPath as IndexPath], with: .fade)
        }
    }
}
