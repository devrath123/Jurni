//
//  MyJurniDetailsViewController.swift
//  Jurni
//
//  Created by Devrath Rathee on 18/01/23.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class MyJurniDetailsViewController: UIViewController,UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var jurniNameLabel: UILabel!
    @IBOutlet weak var stepImageView: UIImageView!
    @IBOutlet weak var stepNumberLabel: UILabel!
    @IBOutlet weak var stepTitleLabel: UILabel!
    @IBOutlet weak var stepDescriptionLabel: UILabel!
    @IBOutlet weak var stepView: UIView!
    @IBOutlet weak var jurniDescriptionLabel: UILabel!
    @IBOutlet weak var stepTableView: UITableView!
    @IBOutlet weak var jurniProgressView: UIView!
    @IBOutlet weak var jurniProgressLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var stepTableHeightContraint: NSLayoutConstraint!
    
    var jurniDocument: QueryDocumentSnapshot? = nil
    var stepsArray = [JurniStep]()
    var tempStepsArray = [JurniStep]()
    var currentStep : JurniStep? = nil
    var totalStepsCount: Int = 0
    var selectedStepId: String = ""
    var completedSteps: Int = 0
    
    var TYPE_STEP = "step"
    var TYPE_PHASE = "phase"
    var TYPE_SPECIAL = "special"
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        if(stepsArray.count > 0){
            getJurniProgress()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let phaseNib = UINib(nibName: "PhaseTableViewCell", bundle: nil)
        stepTableView.register(phaseNib, forCellReuseIdentifier: "PhaseTableViewCell")
       
        let stepNib = UINib(nibName: "StepTableViewCell", bundle: nil)
        stepTableView.register(stepNib, forCellReuseIdentifier: "StepTableViewCell")
    
        let congratsNib = UINib(nibName: "CongratsTableViewCell", bundle: nil)
        stepTableView.register(congratsNib, forCellReuseIdentifier: "CongratsTableViewCell")
        
        stepTableView.delegate = self
        stepTableView.dataSource = self
        stepTableView.backgroundColor = UIColor.white
        
        setJurniDetails()
        addJurniProgressView()
        getGameboardDetails()
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setJurniDetails(){
        jurniNameLabel.text = jurniDocument?.get("name") as? String
        jurniDescriptionLabel.text = (jurniDocument?.get("description") as? String)?.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    func getGameboardDetails(){
      //  print("GAMEBOARD")
        let defaultStore: Firestore?
        defaultStore = Firestore.firestore()
        defaultStore?.collection("jurnis").document(jurniDocument!.documentID).collection("gameboardCards").getDocuments(){ (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                var phaseIndex = 0
                self.totalStepsCount = 0
                var tempStepsArray = [TempJurniStep]()
                for gameDocument in querySnapshot!.documents {
                  //  print("\(gameDocument.documentID) ==> \(gameDocument.data())")
                    
                    let orderId: Int =  gameDocument.get("id") as! Int
                    let jurniId : String = gameDocument.documentID
                    var type : String = gameDocument.get("type") as! String
                    let title :String = gameDocument.get("title") as! String
                    
                    var phaseId: String = ""
                    var content: String = ""
                    
                    if(type == self.TYPE_PHASE){
                        phaseId = gameDocument.documentID
                    } else if(type == self.TYPE_STEP){
                        if(gameDocument.get("phase") != nil){
                            let phaseDocument =  gameDocument.get("phase") as! DocumentReference
                            let phaseDocumentArray = phaseDocument.path.components(separatedBy: "/")
                            phaseId = phaseDocumentArray.last ?? ""
                        }
                        
                        let contentDocument = gameDocument.get("content") as! DocumentReference
                        let contentDocumentArray = contentDocument.path.components(separatedBy: "/")
                        content = contentDocumentArray.last ?? ""
                    }
                    
                    tempStepsArray.append(TempJurniStep(orderId: orderId, jurniId: jurniId, type: type, title: title, phaseId: phaseId, content: content))
                    
                }
                tempStepsArray = tempStepsArray.sorted(by: { $0.orderId < $1.orderId })
                let phaseArray = tempStepsArray.enumerated().filter {$0.element.type == self.TYPE_PHASE}.map { $0.element } as! [TempJurniStep]
                var tempSortedArray = [TempJurniStep]()
                for phase in phaseArray{
                    tempSortedArray.append(phase)
                    let steps = tempStepsArray.enumerated().filter {
                    $0.element.type == self.TYPE_STEP && $0.element.phaseId == phase.phaseId
                    }.map { $0.element } as! [TempJurniStep]
                    tempSortedArray.append(contentsOf: steps)
                }
                if let special = tempStepsArray.first(where: {$0.type == self.TYPE_SPECIAL}){
                    tempSortedArray.append(special)
                }
                
                tempStepsArray.removeAll()
                tempStepsArray.append(contentsOf: tempSortedArray)
                
               // print("TEMP ARRAY")
                var phase : String = ""
                for tempStep in tempStepsArray{
                 //   print("\(tempStep.type) \(tempStep.title) \(tempStep.phaseId)")
                    switch(tempStep.type){
                        case self.TYPE_PHASE:
                            let stepCount = tempStepsArray.enumerated().filter {
                            $0.element.type == self.TYPE_STEP && $0.element.phaseId == tempStep.phaseId
                            }.count
                            phase = tempStep.title
                            phaseIndex+=1
                            self.stepsArray.append(JurniStep(jurniId: tempStep.jurniId, type: tempStep.type, title: tempStep.title, stepCount: stepCount, phaseIndex: phaseIndex, phase: phase, phaseOpen: true))
                        
                        case self.TYPE_SPECIAL:
                            self.stepsArray.append(JurniStep(jurniId: tempStep.jurniId, type: tempStep.type, title: tempStep.title, phase: phase))
                        
                        case self.TYPE_STEP:
                        if(!tempStep.title.isEmpty){
                            self.totalStepsCount+=1
                            self.stepsArray.append(JurniStep(jurniId: tempStep.jurniId, type: self.TYPE_STEP, title: tempStep.title, phase: phase, stepContent: tempStep.content))
                        }
                    
                        default: print("Inside default case")
                    }
                }
                self.getCurrentStepDetails()
            }
        }
    }
    
    func getCurrentStepDetails(){
            let defaultStore: Firestore?
            defaultStore =  Firestore.firestore()
             defaultStore?.collection("jurnis").document(jurniDocument!.documentID).collection("steps").getDocuments(){ (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    let jurniGroup =  DispatchGroup()
                    // print("CURRENT STEPS")
                    for stepDocument in querySnapshot!.documents {
                        //  print("\(stepDocument.documentID) ==> \(stepDocument.data())")
                        var chapterFound = false
                        let description = stepDocument.get("description") as? String
                        for step in self.stepsArray{
                            if(stepDocument.documentID == step.stepContent){
                                jurniGroup.enter()
                                step.stepId = stepDocument.documentID
                                step.jurniDescription = description ?? ""
                                if(chapterFound == false){
                                    defaultStore?.collection("jurnis").document(self.jurniDocument!.documentID).collection("steps").document(stepDocument.documentID).collection("chapters").getDocuments(){ (querySnapshot, err) in
                                        for chapterDocument in querySnapshot!.documents {
                                            if(chapterFound == false){
                                                let poster = chapterDocument.get("poster") as? String
                                                step.chapterPosterUrl = poster ?? ""
                                                chapterFound = true
                                                jurniGroup.leave()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    jurniGroup.notify(queue: .main) {
                        self.getJurniProgress()
                    }
                }
            }
    }
    
    func getJurniProgress(){
        let defaultStore: Firestore?
        defaultStore = Firestore.firestore()
        let userId : String = Auth.auth().currentUser!.uid
        defaultStore?.collection("users").document(userId).collection("jurniProgress").getDocuments(){
            (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                   // print("JurniProgress")
                    for jurniDocument in querySnapshot!.documents {
                        if(self.jurniDocument?.documentID == jurniDocument.documentID){
                            
                            if(jurniDocument.data().isEmpty){
                                self.continueButton.isHidden = true
                                for step in self.stepsArray{
                                    self.tempStepsArray.append(step.withJurniStep(from: step))
                                }
                                self.stepTableView.reloadData()
                                return
                            }
                            let chaptersData = jurniDocument.data() as [String:Any]
                            self.completedSteps = 0
                         //   print("\(jurniDocument.documentID) => \(jurniDocument.data())")
                            for chapter in chaptersData{
                                for step in self.stepsArray{
                                    if(step.stepId == chapter.key){
                                        let chapterValue = chapter.value as? [String:Any]
                                        let completed = chapterValue?["completed"] as? Int
                                        let total = chapterValue?["total"] as? Int
                                        if let percent =  chapterValue!["percent"] as? Double{
                                            if (percent .isNaN == false){
                                                step.percent = Int(percent)
                                            }
                                        }
                                        else {
                                            step.percent = chapterValue?["percent"] as? Int ?? 0
                                        }
                                        step.completed = completed ?? 0
                                        step.total = total ?? 0
                                        
                                        if(completed == total){
                                            self.completedSteps += 1
                                        }
                                    }
                                }
                            }
                            
                            if(self.completedSteps > 0 && self.completedSteps == self.totalStepsCount){
                                self.animateProgress(value: Float(100))
                                self.jurniProgressLabel.text = "\(100) %"
                                self.stepTitleLabel.text = "Finished"
                                self.stepDescriptionLabel.text = "Whether these first few steps represent your free introductory program, or it reminds you of what your core offer would look like, in the end there is an opportunity to drive your students to the next experience you have in store for them. Call it an upsell or continued education regardless, the jurni is endless."
                                self.stepImageView.image = UIImage(named: "finish")
                                self.stepNumberLabel.isHidden = true
                                self.continueButton.isHidden = true
                            }else if(self.totalStepsCount == 0){
                                self.stepNumberLabel.isHidden = true
                                self.continueButton.isHidden = true
                            }
                            else{
                                let progress = self.completedSteps*100/self.totalStepsCount
                                self.animateProgress(value: Float(progress))
                                self.stepNumberLabel.text = "Step \(self.completedSteps + 1) out of \(self.totalStepsCount)"
                                self.jurniProgressLabel.text = "\(progress) %"
                            }
                                
                                var localCompletedSteps = self.completedSteps
                                for step in self.stepsArray{
                                    if(step.type == self.TYPE_PHASE && localCompletedSteps != 0){
                                        if(step.stepCount > localCompletedSteps){
                                            step.completed = localCompletedSteps
                                            localCompletedSteps = 0
                                        }else{
                                            localCompletedSteps = localCompletedSteps-step.stepCount
                                            step.completed = step.stepCount
                                        }
                                    }
                                    
                                    if(step.type == self.TYPE_STEP && step.completed != step.total){
                                        self.currentStep = step
                                        self.setCurrentStepDetails(currentStepId: step.stepId)
                                        break
                                    }
                                }
                        }
                    }
                    
                    if(self.currentStep?.stepId == nil || self.currentStep?.stepId.isEmpty == true){
                        self.animateProgress(value: Float(100))
                        self.jurniProgressLabel.text = "\(100) %"
                        self.stepTitleLabel.text = "Finished"
                        self.stepDescriptionLabel.text = "Whether these first few steps represent your free introductory program, or it reminds you of what your core offer would look like, in the end there is an opportunity to drive your students to the next experience you have in store for them. Call it an upsell or continued education regardless, the jurni is endless."
                        self.stepImageView.image = UIImage(named: "finish")
                        self.stepNumberLabel.isHidden = true
                        self.continueButton.isHidden = true
                    }
                
                    for step in self.stepsArray{
                        self.tempStepsArray.append(step.withJurniStep(from: step))
                    }
                    DispatchQueue.main.async{
                        self.stepTableView.reloadData()
                    }
                }
        }
    }
    
    func setCurrentStepDetails(currentStepId: String){
        for step in self.stepsArray{
            if(step.stepId == currentStepId){
                self.stepTitleLabel.text = step.title
                self.stepDescriptionLabel.text = step.jurniDescription
                let stepUrl = URL(string:  step.chapterPosterUrl)
                if(stepUrl != nil){
                    DispatchQueue.global().async {
                        let data = try? Data(contentsOf: stepUrl!)
                        DispatchQueue.main.async {
                            self.stepImageView.image = UIImage(data: data!)
                        }
                    }
                }
                break
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stepsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let jurniStep = stepsArray[indexPath.row]
        
        if(jurniStep.type == TYPE_PHASE){
            let cell = tableView.dequeueReusableCell(withIdentifier: "PhaseTableViewCell", for: indexPath) as! PhaseTableViewCell
            cell.phaseNumberLabel.text = "Phase \(jurniStep.phaseIndex)"
            cell.phaseDescriptionLabel.text = jurniStep.title
            cell.phaseStepCountLabel.text = "\(jurniStep.completed)/\(jurniStep.stepCount)"
            if(jurniStep.phaseOpen == true){
                cell.arrowImageView.image = UIImage(named: "arrowdown")
            }else{
                cell.arrowImageView.image = UIImage(named: "arrowup")
            }
            
            cell.phaseArrowOne.image = nil
            cell.phaseArrowTwo.image = nil
            cell.phaseArrowThree.image = nil
            cell.phaseArrowFour.image = nil
            if(indexPath.row == 0){
                let phaseCount = stepsArray.enumerated().filter {
                    $0.element.type == TYPE_PHASE
                }.count
                let stepCount = stepsArray.enumerated().filter {
                    $0.element.type == TYPE_STEP || $0.element.type == TYPE_SPECIAL
                }.count
                if(phaseCount == 1 && stepCount == 0){
                    cell.phaseArrowTwo.image = nil
                }else{
                    cell.phaseArrowTwo.image = UIImage(named: "arrowone")
                }
            }else{
                let index = indexPath.row % 2
                let isLastPhase = indexPath.row == stepsArray.count - 1
                switch(index){
                case 0 :
                    cell.phaseArrowTwo.image = UIImage(named: "arrowone")
                  //  if(jurniStep.stepCount != 0){
                        cell.phaseArrowThree.image = UIImage(named: "arrowfour")
                  //  }
                case 1 :
                    cell.phaseArrowOne.image = UIImage(named: "arrowtwo")
                    if(isLastPhase == false){
                        cell.phaseArrowFour.image = UIImage(named: "arrowthree")
                    }
                default:
                    print("Inside default")
                }
            }
            
            return cell
        } else if(jurniStep.type == TYPE_STEP){
            let cell = tableView.dequeueReusableCell(withIdentifier: "StepTableViewCell", for: indexPath) as! StepTableViewCell
            
            cell.stepTitleLabel.text = jurniStep.title
            cell.yourProgressLabel.text = "Your Progress 0%"
            cell.progressView.progress = 0
            cell.yourProgressLabel.textColor = UIColor.systemGray
            cell.progressView.tintColor = UIColor.systemGray
            cell.progressView.progressTintColor = UIColor.systemGray
            cell.lockImageView.isHidden = true
            
            if(jurniStep.percent == 0){
                cell.yourProgressLabel.text = "Your Progress \(jurniStep.percent)%"
                cell.startButton.isHidden = true
                cell.lockImageView.isHidden = false
            }else if(jurniStep.percent > 0 && jurniStep.percent < 100){
                cell.startButton.isHidden = false
                cell.startButton.setTitle("Continue", for: .normal)
                cell.yourProgressLabel.text = "Your Progress \(jurniStep.percent)%"
                cell.lockImageView.isHidden = true
                cell.progressView.progress = Float(jurniStep.percent) * 0.01
                cell.progressView.progressTintColor = UIColor.red
                cell.yourProgressLabel.textColor = UIColor.red
                cell.progressView.tintColor = UIColor.red
            }
            else if(jurniStep.percent == 100){
                cell.startButton.isHidden = false
                cell.startButton.setTitle("Review", for: .normal)
                cell.yourProgressLabel.text = "Completed \(jurniStep.percent)%"
                cell.yourProgressLabel.textColor = UIColor.systemGreen
                cell.startButton.backgroundColor = UIColor(red: 97.0/255.0, green: 157.0/255.0, blue: 206.0/255.0, alpha: 1.0)
                cell.progressView.progress = 1
                cell.progressView.progressTintColor = UIColor.systemGreen
            }
            
            if(jurniStep.stepId == currentStep?.stepId){
                cell.startButton.isHidden = false
                if(jurniStep.percent == 0){
                    cell.startButton.setTitle("Start", for: .normal)
                }
                cell.lockImageView.isHidden = true
            }
            
            let cellNameTapped = UITapGestureRecognizer(target: self, action: #selector(stepDetailsButtonTapped))
            cell.startButton.isUserInteractionEnabled = true
            cell.startButton.addGestureRecognizer(cellNameTapped)
            
            let index = indexPath.row % 2
            cell.stepArrrowOne.image = nil
            cell.stepArrowTwo.image = nil
            cell.stepArrowThree.image = nil
            cell.stepArrowFour.image = nil
            let isLastStep = indexPath.row == stepsArray.count - 1
            switch(index){
            case 0 :
                if(isLastStep == false){
                    cell.stepArrowTwo.image = UIImage(named: "arrowone")
                }
                cell.stepArrowThree.image = UIImage(named: "arrowfour")
            case 1 :
                cell.stepArrrowOne.image = UIImage(named: "arrowtwo")
                if(isLastStep == false){
                    cell.stepArrowFour.image = UIImage(named: "arrowthree")
                }
            default:
                print("Inside default")
            }
            
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "CongratsTableViewCell", for: indexPath) as! CongratsTableViewCell
            
            cell.congratsLabel.text = jurniStep.title
            
            let index = indexPath.row % 2
            cell.congratsArrowOne.image = nil
            cell.congratsArrowThree.image = nil
            switch(index){
            case 0 :
                cell.congratsArrowThree.image = UIImage(named: "arrowfour")
            case 1 :
                cell.congratsArrowOne.image = UIImage(named: "arrowtwo")
            default:
                print("Inside default")
            }
            
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = stepsArray[indexPath.row]
        if(cell.type == TYPE_PHASE){
            if(cell.phaseOpen == true){
                cell.phaseOpen = false
                let indexesToRemove = stepsArray.enumerated().filter {
                    $0.element.type != TYPE_PHASE && $0.element.phase == cell.title
                }.map{$0.offset}
                indexesToRemove.reversed().forEach{ stepsArray.remove(at: $0) }
                cell.stepCount = 0
                
            }else{
                cell.phaseOpen = true
                let indexesToAdd = tempStepsArray.enumerated().filter {
                    $0.element.type != TYPE_PHASE && $0.element.phase == cell.title
                }.map{$0.offset}
                cell.stepCount = indexesToAdd.count
                if(indexesToAdd.count > 0 && indexesToAdd[0] > indexPath.row){
                    var indexStep = indexPath.row
                    for index in indexesToAdd{
                        indexStep += 1
                        stepsArray.insert(tempStepsArray[index], at: indexStep)
                    }
                }else{
                    for index in indexesToAdd{
                        stepsArray.insert(tempStepsArray[index], at: index)
                    }
                }
            }
            stepTableView.reloadData()
        }
    }
    
    @IBAction func continueAction(_ sender: Any) {
        selectedStepId = self.currentStep?.stepId ?? ""
        self.performSegue(withIdentifier: "stepChapterDetailsSegue", sender: nil)
    }
    
    
    @objc func stepDetailsButtonTapped(tapGestureRecognizer: UITapGestureRecognizer){
        let view = tapGestureRecognizer.view
        let indexPath = stepTableView.indexPathForView(view!)
        selectedStepId = stepsArray[indexPath!.row].stepId
        self.performSegue(withIdentifier: "stepChapterDetailsSegue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! MyJurniStepChaptersViewController
        destinationVC.jurniDocument = self.jurniDocument
        destinationVC.stepId = selectedStepId
    }
    
    @objc func animateProgress(value : Float){
        let cp = self.jurniProgressView.viewWithTag(105) as! CircularProgressView
        cp.setProgressWithAnimation(duration: 1.0, value: value/100)
    }
    
    func addJurniProgressView(){
        let circularProgressView = CircularProgressView(frame: CGRect(x: 10.0, y: 10.0, width: 100.0, height: 100.0))
        circularProgressView.progressColor = UIColor(red: 97.0/255.0, green: 157.0/255.0, blue: 206.0/255.0, alpha: 1.0)
        circularProgressView.remainingColor = UIColor(red: 192.0/255.0, green: 192.0/255.0, blue: 192.0/255.0, alpha: 1.0)
        
        circularProgressView.tag = 105
        circularProgressView.center = jurniProgressView.convert(jurniProgressView.center, from:jurniProgressView.superview)
        jurniProgressView.addSubview(circularProgressView)
        
    }

}
