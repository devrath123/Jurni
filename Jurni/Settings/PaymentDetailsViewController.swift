//
//  PaymentDetailsViewController.swift
//  Jurni
//
//  Created by Devrath Rathee on 08/12/22.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

class PaymentDetailsViewController: UIViewController,UITextFieldDelegate,UITableViewDelegate,
                                    UITableViewDataSource,UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var addUpdateView: UIView!
    @IBOutlet weak var addressLine1: UITextField!
    @IBOutlet weak var addressLine2: UITextField!
    @IBOutlet weak var city: UITextField!
    @IBOutlet weak var zipPostal: UITextField!
    @IBOutlet weak var creditCardNumber: UITextField!
    @IBOutlet weak var cvc: UITextField!
    @IBOutlet weak var expiryMonth: UITextField!
    @IBOutlet weak var expiryYear: UITextField!
    @IBOutlet weak var addPaymentView: UIView!
    @IBOutlet weak var updatePaymentMethodButton: UIButton!
    @IBOutlet weak var addPaymentMethodButton: UIButton!
    @IBOutlet weak var paymentPlanLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var paymentPlanTableView: UITableView!
    @IBOutlet weak var upcomingPaymentTableView: UITableView!
    @IBOutlet weak var paymentPlanTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var upcomingPaymentTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var statePickerView: UIPickerView!
    @IBOutlet weak var doneBtn: UIButton!
    
    var activityView: UIActivityIndicatorView?
    var paymentMethodsArray = [PaymentMethodBean]()
    var paymentPlanArray = [PaymentPlan]()
    var upcomingPaymentArray = [PaymentPlan]()
    var stateArray = [String]()
    var stateDict = [String:String]()
    var selectedState: String = ""
    var selectedStateId: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addressLine1.delegate = self
        addressLine2.delegate = self
        city.delegate = self
        zipPostal.delegate = self
        creditCardNumber.delegate = self
        cvc.delegate = self
        expiryMonth.delegate = self
        expiryYear.delegate = self
        statePickerView.isHidden = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(PaymentDetailsViewController.stateTapFunction))
        stateLabel.isUserInteractionEnabled = true
        stateLabel.addGestureRecognizer(tap)
        
        let paymentPlanNib = UINib(nibName: "PaymentPlanTableViewCell", bundle: nil)
        paymentPlanTableView.register(paymentPlanNib, forCellReuseIdentifier: "PaymentPlanTableViewCell")
        
        
        let upcomingPaymentNib = UINib(nibName: "UpcomingPaymentTableViewCell", bundle: nil)
        upcomingPaymentTableView.register(upcomingPaymentNib, forCellReuseIdentifier: "UpcomingPaymentTableViewCell")
        upcomingPaymentTableView.delegate = self
        upcomingPaymentTableView.dataSource = self
        upcomingPaymentTableView.backgroundColor = UIColor.white
        
        paymentPlanTableView.backgroundColor = UIColor.white
        
        statePickerView.delegate = self
        statePickerView.dataSource = self
        
        addPaymentView.isHidden = true
        doneBtn.isHidden = true

        fetchPaymentMethodData()
        fetchStudentBillDetails()
        
        addStates()
        
        let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tapGesture)
    }
    
    func addStates(){
        stateArray.append("Alabama")
        stateDict["AL"] = "Alabama"
        
        stateArray.append("Alaska")
        stateDict["AK"] = "Alaska"
        
        stateArray.append("Arizona")
        stateDict["AZ"] = "Arizona"
        
        stateArray.append("Arkansas")
        stateDict["AR"] = "Arkansas"
        
        stateArray.append("California")
        stateDict["CA"] = "California"
        
        stateArray.append("Colorado")
        stateDict["CO"] = "Colorado"
        
        stateArray.append("Connecticut")
        stateDict["CT"] = "Connecticut"
        
        stateArray.append("Delaware")
        stateDict["DE"] = "Delaware"
        
        stateArray.append("District of Columbia")
        stateDict["DC"] = "District of Columbia"
        
        stateArray.append("Florida")
        stateDict["FL"] = "Florida"
        
        stateArray.append("Georgia")
        stateDict["GA"] = "Georgia"
        
        stateArray.append("Hawaii")
        stateDict["HI"] = "Hawaii"
        
        stateArray.append("Idaho")
        stateDict["ID"] = "Idaho"
        
        stateArray.append("Illinois")
        stateDict["IL"] = "Illinois"
        
        stateArray.append("Indiana")
        stateDict["IN"] = "Indiana"
        
        stateArray.append("Iowa")
        stateDict["IA"] = "Iowa"
        
        stateArray.append("Kansas")
        stateDict["KS"] = "Kansas"
        
        stateArray.append("Kentucky")
        stateDict["KY"] = "Kentucky"
        
        stateArray.append("Louisiana")
        stateDict["LA"] = "Louisiana"
        
        stateArray.append("Maine")
        stateDict["ME"] = "Maine"
        
        stateArray.append("Maryland")
        stateDict["MD"] = "Maryland"
        
        stateArray.append("Massachusetts")
        stateDict["MA"] = "Massachusetts"
        
        stateArray.append("Michigan")
        stateDict["MI"] = "Michigan"
        
        stateArray.append("Minnesota")
        stateDict["MN"] = "Minnesota"
        
        stateArray.append("Mississippi")
        stateDict["MS"] = "Mississippi"
        
        stateArray.append("Missouri")
        stateDict["MO"] = "Missouri"
        
        stateArray.append("Montana")
        stateDict["MT"] = "Montana"
        
        stateArray.append("Nebraska")
        stateDict["NE"] = "Nebraska"
        
        stateArray.append("Nevada")
        stateDict["NV"] = "Nevada"
        
        stateArray.append("New Hampshire")
        stateDict["NH"] = "New Hampshire"
        
        stateArray.append("New Jersey")
        stateDict["NJ"] = "New Jersey"
        
        stateArray.append("New Mexico")
        stateDict["NM"] = "New Mexico"
        
        stateArray.append("New York")
        stateDict["NY"] = "New York"
        
        stateArray.append("North Carolina")
        stateDict["NC"] = "North Carolina"
        
        stateArray.append("North Dakota")
        stateDict["ND"] = "North Dakota"
        
        stateArray.append("Ohio")
        stateDict["OH"] = "Ohio"
        
        stateArray.append("Oklahoma")
        stateDict["OK"] = "Oklahoma"
        
        stateArray.append("Oregon")
        stateDict["OR"] = "Oregon"
        
        stateArray.append("Pennsylvania")
        stateDict["PA"] = "Pennsylvania"
     
        stateArray.append("Puerto Rico")
        stateDict["PR"] = "Puerto Rico"
        
        stateArray.append("Rhode Island")
        stateDict["RI"] = "Rhode Island"
        
        stateArray.append("South Carolina")
        stateDict["SC"] = "South Carolina"
        
        stateArray.append("South Dakota")
        stateDict["SD"] = "South Dakota"
        
        stateArray.append("Tennessee")
        stateDict["TN"] = "Tennessee"
        
        stateArray.append("Texas")
        stateDict["TX"] = "Texas"
        
        stateArray.append("Utah")
        stateDict["UT"] = "Utah"
        
        stateArray.append("Vermont")
        stateDict["VT"] = "Vermont"
        
        stateArray.append("Virginia")
        stateDict["VA"] = "Virginia"
        
        stateArray.append("Virgin Islands")
        stateDict["VI"] = "Virgin Islands"
        
        stateArray.append("Washington")
        stateDict["WA"] = "Washington"
        
        stateArray.append("West Virginia")
        stateDict["WV"] = "West Virginia"
        
        stateArray.append("Wisconsin")
        stateDict["WI"] = "Wisconsin"
        
        stateArray.append("Wyoming")
        stateDict["WY"] = "Wyoming"
    }

    @IBAction func doneAction(_ sender: Any) {
        doneBtn.isHidden = true
        statePickerView.isHidden = true
        stateLabel.text = selectedState
    }
    
    
    @objc func stateTapFunction(sender:UITapGestureRecognizer) {
        doneBtn.isHidden = false
        statePickerView.isHidden = false
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return stateArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return stateArray[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        selectedState = self.stateArray[row]
        
        for (key,value) in stateDict{
            if value == stateArray[row]{
                self.selectedStateId = key
            }
        }
    }
    
    func fetchPaymentMethodData(){
        let defaultStore: Firestore?
        defaultStore = Firestore.firestore()
        let userId : String = Auth.auth().currentUser!.uid
        print(userId)
        defaultStore?.collection("customerBillingDetails").whereField("uid", isEqualTo: userId)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                    self.updatePaymentMethodButton.isHidden = true
                } else {
                    self.paymentMethodsArray.removeAll()
                    var cardsArray = [String]()
                    print("Payment Method")
                    for document in querySnapshot!.documents {
                        if(document.get("status") as! String == "ACTIVE")
                        {
                            if (document.data()["payment_methods"] as? [String:Any]) != nil {
                                let paymentMethodArray : [String : Any] = document.data()["payment_methods"] as! [String : Any]
                                for payment in paymentMethodArray{
                                    let paymentMethodId = payment.key
                                    let paymentMethod = payment.value as? [String:Any]
                                    let country = paymentMethod?["country"] as! String
                                    let brand = paymentMethod?["brand"] as! String
                                    let expMonth = "\(paymentMethod?["exp_month"] ?? "")"
                                    let expYear = "\(paymentMethod?["exp_year"] ?? "")"
                                    let lastFour = paymentMethod?["last4"] as! String
                                    if(!cardsArray.contains(lastFour)){
                                        cardsArray.append(lastFour)
                                        self.paymentMethodsArray.append(PaymentMethodBean(cardBrand: brand, expiryMonth: expMonth, expiryYear: expYear, lastFour: lastFour, country: country, billId: paymentMethodId))
                                    }
                                }
                            }
                            else {
                                print("empty")
                            }
                        }
                    }
                    
                    if(self.paymentMethodsArray.isEmpty){
                        self.updatePaymentMethodButton.isHidden = true
                    }
                }
            }
    }
    
    func fetchStudentBillDetails(){
        showActivityIndicator()
        let defaultStore: Firestore?
        defaultStore = Firestore.firestore()
        let userId : String = Auth.auth().currentUser!.uid
        defaultStore?.collection("users").document(userId).collection("communitySettings").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                self.paymentPlanArray.removeAll()
                var studentIds = [String]()
                print("PAYMENT PLAN")
                for document in querySnapshot!.documents {
                    let documentData : [String : Any] = document.data()
                    print("\(document.documentID) => \(document.data())")
                    print("------------------------")
                    if(documentData["studentBillPayment"] != nil){
                       // print("\(document.documentID) => \(document.data())")
                       // print("------------------------")
                        let result: [String:Any] = documentData["studentBillPayment"] as! [String : Any]
                        for(key,value) in result{
                            if(!studentIds.contains(key))
                            {
                                studentIds.append(key)
                                let paymentDetailsArray = value as! NSArray
                                if(paymentDetailsArray.count > 0){
                                    let paymentDetailDict = paymentDetailsArray[0] as! [String : Any]
                                    let cost = paymentDetailDict["cost"] as! NSNumber
                                    let name = paymentDetailDict["name"] as! String
                                    let stamp = (paymentDetailDict["billingDate"] as! Timestamp)
                                    let date = stamp.dateValue().toString(dateFormat: "MMM dd, yyyy")
                                    let currentDate = Date()
                                    let jurniDate : Date = stamp.dateValue()
                                    
                                    var isUpcomingJurni: Bool = false
                                    if jurniDate.compare(currentDate) == .orderedAscending {
                                        isUpcomingJurni = false
                                    }else{
                                        isUpcomingJurni = true
                                    }
                                
                                    let isSameMonth = currentDate.isInSameMonth(as: stamp.dateValue())
                                    
                                    if(isSameMonth){
                                        self.paymentPlanArray.append(PaymentPlan(billId: key, billingDate: date,
                                                                                 cost: "\(cost)", name: name, status: "", isUpcoming: isUpcomingJurni, upcomingDate: jurniDate))
                                    }
                                }
                            }
                        }
                    }
                }
                if(!self.paymentPlanArray.isEmpty){
                    self.fetchStudentJurnis()
                }else{
                    self.fetchStudentJurnis()
                    self.paymentPlanTableView.isHidden = true
                    self.hideActivityIndicator()
                }
            }
        }
    }
    
    
    func fetchStudentJurnis(){
        let defaultStore: Firestore?
        defaultStore = Firestore.firestore()
        defaultStore?.collection("jurnis").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                print("Student Jurni")
                for document in querySnapshot!.documents {
                    print("\(document.documentID) ==> \(document.data())")
                    for(student) in self.paymentPlanArray{
                        if(student.billId == document.documentID){
                            print("\(document.documentID) ==> \(document.data())")
                            let billingDetails : [String : Any] = document.data()["meta"] as! [String : Any]
                            let billingType = billingDetails["billingType"] as! String
                            if(billingType == "Upfront"){
                                student.status = "One-Time"
                            }else if(billingType == "Recurring"){
                                student.status = "Monlthly Recurring"
                            }else{
                                student.status = "Free"
                            }
                        }
                    }
                }
                let count = self.paymentPlanArray.count
                if(count > 0){
                    self.paymentPlanTableViewHeight.constant = CGFloat(count * 150)
                    self.paymentPlanTableView.reloadData()
                }
                
                var totalPayment: Int = 0
                for(paymentPlan) in self.paymentPlanArray{
                    switch paymentPlan.status{
                    case "One-Time":
                        if(paymentPlan.isUpcoming){             
                            self.upcomingPaymentArray.append(paymentPlan)
                            totalPayment += Int(paymentPlan.cost)!
                        }
                    case "Monlthly Recurring":
                        let upcomingPaymentPlan:PaymentPlan = paymentPlan.withPaymentPlan(from: paymentPlan)
                        let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: upcomingPaymentPlan.upcomingDate)!
                        let date = nextMonth.toString(dateFormat: "MMMM , yyyy").replacingOccurrences(of: ",", with: "01,")
                        upcomingPaymentPlan.billingDate = date
                        totalPayment += Int(upcomingPaymentPlan.cost)!
                        self.upcomingPaymentArray.append(upcomingPaymentPlan)
                    default:
                        print("Default case")
                    }
                }
                
                self.totalLabel.text = "TOTAL - $\(totalPayment)"
                
                let upcomingCount = self.upcomingPaymentArray.count
                if(upcomingCount > 0){
                    self.upcomingPaymentTableViewHeight.constant = CGFloat(upcomingCount * 140)
                    self.upcomingPaymentTableView.reloadData()
                }
                
                self.hideActivityIndicator()
            }
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        addPaymentMethodButton.isHidden = false
        updatePaymentMethodButton.isHidden = false
        addUpdateView.isHidden = false
        addPaymentView.isHidden = true
    }
    
    @IBAction func saveAction(_ sender: Any) {
        
        let addressLineOne : String = addressLine1.text ?? ""
        let addressLineTwo : String = addressLine2.text ?? ""
        let city : String = city.text ?? ""
        let state : String =  selectedState
        let zip : String = zipPostal.text ?? ""
        let creditCard : Int = Int(creditCardNumber.text!) ?? 0
        let cvc : Int = Int(cvc.text!) ?? 0
        let expiryMonth : Int = Int(expiryMonth.text!) ?? 0
        let expiryYear : Int = Int(expiryYear.text!) ?? 0
        
        if(addressLineOne.isEmpty == true){
            showAlert(message: "Address Line 1 cannot be empty")
            return
        }
        
        if(city.isEmpty == true){
            showAlert(message: "City cannot be empty")
            return
        }
        
        if(state.isEmpty == true){
            showAlert(message: "State cannot be empty")
            return
        }
        
        if(zip.isEmpty == true){
            showAlert(message: "Zip cannot be empty")
            return
        }
        
        if(creditCard == 0){
            showAlert(message: "Credit Card cannot be empty")
            return
        }
        
        if(cvc == 0){
            showAlert(message: "CVC cannot be empty")
            return
        }
        
        if(expiryYear == 0){
            showAlert(message: "Expiry Year cannot be empty")
            return
        }
        
        if(expiryMonth == 0){
            showAlert(message: "Expiry Month cannot be empty")
            return
        }
        
        if(expiryMonth > 12){
            showAlert(message: "Please enter valid Expiry Month")
            return
        }
        
        if(expiryYear > 2040 && expiryYear < 2023){
            showAlert(message: "Please enter valid Expiry Year")
            return
        }
        
        if(cvc < 100){
            showAlert(message: "Please try to fit CVC within 4 characters")
            return
        }
      
        showActivityIndicator()
        let userId : String = Auth.auth().currentUser!.uid
        let communityId: String = UserDefaults.standard.string(forKey: Constants.COMMUNITY_ID) ?? ""
        let phoneNumber = UserDefaults.standard.string(forKey: Constants.PHONE_NUMBER) ?? "7676767676"
        let customerArray : [String: Any] = [
            "uid": userId,
            "communityId": communityId,
            "address_line_one":addressLineOne,
            "address_line_two":addressLineTwo,
            "city":city,
            "stateCode":selectedStateId,
            "zipCode":zip,
            "card_no":creditCard,
            "exp_month":expiryMonth,
            "exp_year":expiryYear,
            "cvc":cvc,
            "phone":phoneNumber,
            "studentOnboarding":false
        ]
        
        saveRequest(customerDict: customerArray)    
        
    }
    
    
    func saveRequest(customerDict: [String:Any]){
        let json: [String: Any] = ["data": ["customerInfo": customerDict]]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        let url = URL(string: "https://us-central1-jurni-dev.cloudfunctions.net/registerGiroCustomer/registerBilling")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                DispatchQueue.main.async {
                    self.hideActivityIndicator()
                    self.showAlert(message: "Error while Payment Setup")
                }
                
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
                DispatchQueue.main.async {
                    self.hideActivityIndicator()
                    self.showAlert(message: "Payment Setup Success")
                    self.addressLine1.text = ""
                    self.addressLine2.text = ""
                    self.city.text = ""
                    self.zipPostal.text = ""
                    self.creditCardNumber.text = ""
                    self.cvc.text = ""
                    self.expiryMonth.text = ""
                    self.expiryYear.text = ""
                    
                    self.addPaymentMethodButton.isHidden = false
                    self.updatePaymentMethodButton.isHidden = false
                    self.addUpdateView.isHidden = false
                    self.addPaymentView.isHidden = true
                }
            }
        }

        task.resume()
    }
    
    func showAlert(message: String){
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func updatePaymentAction(_ sender: Any) {
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! UpdatePaymentPopUpViewController
            destinationVC.updatePaymentArray = paymentMethodsArray
    }
    
    @IBAction func addPaymentAction(_ sender: Any) {
        addPaymentMethodButton.isHidden = true
        updatePaymentMethodButton.isHidden = true
        addUpdateView.isHidden = true
        addPaymentView.isHidden = false
        
    }
 
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var maxLength : Int = 0
                
        if textField == cvc{
            maxLength = 4
        } else if textField == expiryMonth{
            maxLength = 2
        } else if textField == expiryYear{
            maxLength = 4
        }else if(textField == creditCardNumber){
            maxLength = 20
        }else if(textField == zipPostal){
            maxLength = 10
        }else if(textField == addressLine1 || textField == addressLine2){
            maxLength = 45
        }else if(textField == city){
            maxLength = 30
        }
                
        let currentString: NSString = textField.text! as NSString
                
        let newString: NSString =  currentString.replacingCharacters(in: range, with: string) as NSString
        return newString.length <= maxLength
    }
    
    func showActivityIndicator() {
        activityView = UIActivityIndicatorView(style: .large)
        activityView?.center = self.view.center
        self.view.addSubview(activityView!)
        activityView?.startAnimating()
    }
    
    func hideActivityIndicator(){
        if (activityView != nil){
            activityView?.stopAnimating()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == paymentPlanTableView{
            let cell = tableView.dequeueReusableCell(withIdentifier: "PaymentPlanTableViewCell", for: indexPath)
            as! PaymentPlanTableViewCell
          
            cell.transactionName.text = paymentPlanArray[indexPath.row].name
            cell.status.text = paymentPlanArray[indexPath.row].status
            cell.cost.text = "$\(paymentPlanArray[indexPath.row].cost)"
        
            if(paymentPlanArray[indexPath.row].status == "Monlthly Recurring"){
                cell.billingDate.text = "Subscribed \(paymentPlanArray[indexPath.row].billingDate)"
                cell.action.text = "Cancel jurni"
            }else{
                cell.billingDate.text = "Paid \(paymentPlanArray[indexPath.row].billingDate)"
                cell.action.text = "N/A"
            }
            
            let cellNameTapped = UITapGestureRecognizer(target: self, action: #selector(nameTapped))
            cell.action.isUserInteractionEnabled = true
            cell.action.addGestureRecognizer(cellNameTapped)

            return cell
        }else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UpcomingPaymentTableViewCell", for: indexPath)
            as! UpcomingPaymentTableViewCell
            
            cell.tansactionName.text = upcomingPaymentArray[indexPath.row].name
            cell.cost.text = "$\(upcomingPaymentArray[indexPath.row].cost)"
            cell.upcomingBillingDate.text = upcomingPaymentArray[indexPath.row].billingDate
            return cell
        }
    }
    
    @objc func nameTapped(tapGestureRecognizer: UITapGestureRecognizer){
        let lableView = tapGestureRecognizer.view as! UILabel
        if(lableView.text == "Cancel jurni"){
            let view = tapGestureRecognizer.view
            let indexPath = paymentPlanTableView.indexPathForView(view!)
            let paymentPlan = paymentPlanArray[indexPath!.row]
            cancelJurni(jurniId: paymentPlan.billId)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == paymentPlanTableView{
            return paymentPlanArray.count
        }else {
            return upcomingPaymentArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}

    func cancelJurni(jurniId:String){
        let defaultStore: Firestore?
        defaultStore = Firestore.firestore()
        let documentRef = defaultStore?.collection("jurnis").document(jurniId)
        documentRef!.getDocument { (document, error) in
            let members : [Any] = document?.data()!["members"] as! [Any]
            let userId : String = Auth.auth().currentUser!.uid
            let userToDelete = "users/\(userId)"
            
            if let toDelete = members.first(where: { (member) -> Bool in
                        if let object = member as? DocumentReference,
                           object.path == userToDelete {
                            return true
                        } else {
                            return false
                        }
                    }) {
                
                documentRef?.updateData([
                    "members": FieldValue.arrayRemove([toDelete])
                        ]){ error in
                            if let error = error {
                                print("error: \(error)")
                            } else {
                                print("successfully deleted")
                                self.viewDidLoad()
                            }
                        }
                    }
        }
    }
}

extension Date
{
    func toString( dateFormat format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
    func isEqual(to date: Date, toGranularity component: Calendar.Component, in calendar: Calendar = .current) -> Bool {
            calendar.isDate(self, equalTo: date, toGranularity: component)
        }
    
    func isInSameMonth(as date: Date) -> Bool{ isEqual(to: date, toGranularity: .month) }
}

public extension UITableView {

  func indexPathForView(_ view: UIView) -> IndexPath? {
    let origin = view.bounds.origin
    let viewOrigin = self.convert(origin, from: view)
    let indexPath = self.indexPathForRow(at: viewOrigin)
    return indexPath
  }
}
