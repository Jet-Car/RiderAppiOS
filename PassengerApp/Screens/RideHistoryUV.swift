//
//  RideHistroyUV.swift
//  PassengerApp
//
//  Created by ADMIN on 13/05/17.
//  Copyright © 2017 V3Cube. All rights reserved.
//

import UIKit

class RideHistoryUV: UIViewController, UITableViewDataSource, UITableViewDelegate, MyBtnClickDelegate {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    // Surge Price OutLets
    @IBOutlet weak var surgePriceHLbl: MyLabel!
    @IBOutlet weak var surgePriceVLbl: MyLabel!
    @IBOutlet weak var surgePayAmtLbl: MyLabel!
    @IBOutlet weak var surgeAcceptBtn: MyButton!
    @IBOutlet weak var surgeLaterLbl: MyLabel!
    
    let generalFunc = GeneralFunctions()
    
    var HISTORY_TYPE:String = "PAST"
    
    var loaderView:UIView!
    
    var surgePriceView:UIView!
    var surgePriceBGView:UIView!
    
    var dataArrList = [NSDictionary]()
    var nextPage_str = 1
    var isLoadingMore:Bool = false
    var isNextPageAvail:Bool = false
    
    var APP_TYPE:String = ""
    
    var cntView:UIView!
    
    var extraHeightContainer = [CGFloat]()
    var userProfileJson:NSDictionary!
    
    var isFirstCallFinished:Bool = false
    
    var isDataLoaded:Bool = false
    
    var msgLbl:MyLabel!
    
    var isDirectPush:Bool = false
    var isSafeAreaSet:Bool = false
    
    var iCabBookingId:String = ""
    var dateStr:String = ""
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.configureRTLView()
        
        if(!isDirectPush){
            pageTabBarItem.titleColor = UIColor(hex: 0x141414)
        }
        
        if(HISTORY_TYPE != "PAST" && loaderView != nil && self.isFirstCallFinished == true){
            self.dataArrList.removeAll()
            self.extraHeightContainer.removeAll()
            self.isLoadingMore = false
            self.nextPage_str = 1
            self.isNextPageAvail = false
            self.tableView.reloadData()
            
            if(self.msgLbl != nil){
                self.msgLbl.isHidden = true
            }
            
            self.getDtata(isLoadingMore: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if(!isDirectPush){
            pageTabBarItem.titleColor = UIColor(hex: 0x737373)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

         cntView = self.generalFunc.loadView(nibName: "RideHistoryScreenDesign", uv: self, contentView: contentView)
        
        self.contentView.addSubview(cntView)
        
        self.tableView.delegate = self
        self.tableView.bounces = false
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView()
        self.tableView.register(UINib(nibName: "RideHistoryUFXListTVCell", bundle: nil), forCellReuseIdentifier: "RideHistoryUFXListTVCell")
        self.tableView.register(UINib(nibName: "RideHistoryListTVCell", bundle: nil), forCellReuseIdentifier: "RideHistoryTVCell")
        
        self.tableView.contentInset = UIEdgeInsetsMake(6, 0, GeneralFunctions.getSafeAreaInsets().bottom + 6, 0)

        userProfileJson = (GeneralFunctions.getValue(key: Utils.USER_PROFILE_DICT_KEY) as! String).getJsonDataDict().getObj(Utils.message_str)
        APP_TYPE = userProfileJson.get("APP_TYPE")
        
        if(isDirectPush){
            self.addBackBarBtn()
            
            if(userProfileJson.get("APP_TYPE").uppercased() == Utils.cabGeneralType_Ride.uppercased()){
                self.navigationItem.title = self.generalFunc.getLanguageLabel(origValue: "Your trips", key: "LBL_YOUR_TRIPS")
                self.title = self.generalFunc.getLanguageLabel(origValue: "Your trips", key: "LBL_YOUR_TRIPS")
            }else if(userProfileJson.get("APP_TYPE").uppercased() == "DELIVERY"){
                self.navigationItem.title = self.generalFunc.getLanguageLabel(origValue: "Your deliveries", key: "LBL_YOUR_DELIVERY")
                self.title = self.generalFunc.getLanguageLabel(origValue: "Your deliveries", key: "LBL_YOUR_DELIVERY")
            }else{
                self.navigationItem.title = self.generalFunc.getLanguageLabel(origValue: "Your bookings", key: "LBL_YOUR_BOOKING")
                self.title = self.generalFunc.getLanguageLabel(origValue: "Your bookings", key: "LBL_YOUR_BOOKING")
            }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if(isDataLoaded == false){
            
//            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
//                self.cntView.frame = self.view.frame
//                self.cntView.frame.size = CGSize(width: Application.screenSize.width, height: self.view.frame.height)
//                self.cntView.setNeedsLayout()
//
//
//            })

            self.extraHeightContainer.removeAll()
            self.dataArrList.removeAll()
            self.tableView.reloadData()
            self.getDtata(isLoadingMore: self.isLoadingMore)
            
            isDataLoaded = true
        }
    }
    
    
    override func viewDidLayoutSubviews() {
        
        if(isSafeAreaSet == false){
            
            if(cntView != nil){
                self.cntView.frame = self.view.frame
                cntView.frame.size.height = cntView.frame.size.height + GeneralFunctions.getSafeAreaInsets().bottom
            }
            
            isSafeAreaSet = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getDtata(isLoadingMore:Bool){
        if(loaderView == nil){
            loaderView =  self.generalFunc.addMDloader(contentView: self.view)
            loaderView.backgroundColor = UIColor.clear
        }else if(loaderView != nil && isLoadingMore == false){
            loaderView.isHidden = false
        }

        let parameters = ["type": HISTORY_TYPE == "PAST" ? "getRideHistory" : "checkBookings", "UserType": Utils.appUserType, "iUserId": GeneralFunctions.getMemberd(), "page": self.nextPage_str.description]
        
        let exeWebServerUrl = ExeServerUrl(dict_data: parameters, currentView: self.view, isOpenLoader: false)
        exeWebServerUrl.executePostProcess(completionHandler: { (response) -> Void in
            
            if(response != ""){
                let dataDict = response.getJsonDataDict()
                
                if(dataDict.get("Action") == "1"){
                    
                    let dataArr = dataDict.getArrObj(Utils.message_str)
                    
                    if(self.isFirstCallFinished == false){
                        self.isFirstCallFinished = true
                    }
                    
                    for i in 0 ..< dataArr.count{
                        let dataTemp = dataArr[i] as! NSDictionary
                        
                        self.dataArrList += [dataTemp]
                        
                       
                        
                        if(self.HISTORY_TYPE != "PAST"){

                            /**
                             Calculating address height. As source location address is always available, default height of source address label (20) is minus.
                             88 is minus from screen width due to left and right margins from screen. To check label's width, kindly look into design file.
                            */
                            let sourceAddHeight = dataTemp.get("vSourceAddresss").height(withConstrainedWidth: Application.screenSize.width - 88, font: UIFont(name: "Roboto-Light", size: 16)!) - 19.5
                            
                            var destAddHeight = dataTemp.get("tDestAddress").height(withConstrainedWidth: Application.screenSize.width - 88, font: UIFont(name: "Roboto-Light", size: 16)!) - 19.5

                            /**
                             If destination address is not available then set destination address height to ZERO.
                            */
                            if(dataTemp.get("tDaddress") == "" && dataTemp.get("tDestAddress") == ""){
                                destAddHeight = 0
                            }
                            

                            let vTypeNameTxt = dataTemp.get("vVehicleCategory") != "" ? "\(dataTemp.get("vVehicleCategory")) - \(dataTemp.get("vVehicleType"))" : "\(dataTemp.get("vVehicleType"))"
                            
                            /**
                             Calculate height of vehicle type value. 50 is the default left and right margins from screen.
                             */
                            var vTypeNameHeight = vTypeNameTxt.trim().height(withConstrainedWidth: Application.screenSize.width - 50, font: UIFont(name: "Roboto-Light", size: 16)!) - 19.5

                            if(vTypeNameHeight < 0){
                                vTypeNameHeight = 0 // setting default value
                            }

                            self.extraHeightContainer += [sourceAddHeight + destAddHeight + vTypeNameHeight]
                            
                        }else{
                            var packageNameHeight : CGFloat = 0
                            let topPaddingForPackageName : CGFloat = 2
                            
                            if(dataTemp.get("vPackageName") != ""){
                                packageNameHeight = dataTemp.get("vPackageName").height(withConstrainedWidth: Application.screenSize.width - 50, font: UIFont(name: "Roboto-Light", size: 14)!) + topPaddingForPackageName
                            }
                            
                            let sourceAddHeight = dataTemp.get("tSaddress").height(withConstrainedWidth: Application.screenSize.width - 88, font: UIFont(name: "Roboto-Light", size: 16)!) - 19.5
                            var destAddHeight = dataTemp.get("tDaddress").height(withConstrainedWidth: Application.screenSize.width - 88, font: UIFont(name: "Roboto-Light", size: 16)!) - 19.5
                            
                            if(dataTemp.get("tDaddress") == "" && dataTemp.get("tDestAddress") == ""){
                                destAddHeight = 0
                            }
                            
                            var vTypeNameTxt  = ""
                            
                            if(dataTemp.get("vPackageName") != ""){
                                vTypeNameTxt = "\(self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_RENTAL_CATEGORY_TXT")) - "
                            }
                            
                            vTypeNameTxt = "\(vTypeNameTxt)\(dataTemp.get("vVehicleCategory") != "" ? "\(dataTemp.get("vVehicleCategory")) - \(dataTemp.get("vVehicleType"))" : "\(dataTemp.get("vVehicleType"))")"
                            
                            var vTypeNameHeight = vTypeNameTxt.trim().height(withConstrainedWidth: Application.screenSize.width - 50, font: UIFont(name: "Roboto-Light", size: 16)!) - 19.5
                            
                            if(vTypeNameHeight < 0){
                                vTypeNameHeight = 0 // setting default value
                            }
                            
                            self.extraHeightContainer += [sourceAddHeight + destAddHeight + vTypeNameHeight + packageNameHeight]
                        }
                        
                    }
                    let NextPage = dataDict.get("NextPage")
                    
                    if(NextPage != "" && NextPage != "0"){
                        self.isNextPageAvail = true
                        self.nextPage_str = Int(NextPage)!
                        
                        self.addFooterView()
                    }else{
                        self.isNextPageAvail = false
                        self.nextPage_str = 0
                        
                        self.removeFooterView()
                    }
                    
                    self.tableView.reloadData()
                    
                }else{
                    if(isLoadingMore == false){
                        if(self.msgLbl != nil){
                            self.msgLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key: dataDict.get("message"))
                            self.msgLbl.isHidden = false
                        }else{
                            self.msgLbl = GeneralFunctions.addMsgLbl(contentView: self.view, msg: self.generalFunc.getLanguageLabel(origValue: "", key: dataDict.get("message")))
                        }
                        
                    }else{
                        self.isNextPageAvail = false
                        self.nextPage_str = 0
                        
                        self.removeFooterView()
                    }
                    
                }
                
                //                self.generalFunc.setError(uv: self, title: "", content: self.generalFunc.getLanguageLabel(origValue: "", key: dataDict.get("message")))
                
                
            }else{
                if(isLoadingMore == false){
                    self.generalFunc.setError(uv: self)

                }
            }
            
            self.isLoadingMore = false
            self.loaderView.isHidden = true
            
        })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        return self.dataArrList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let item = self.dataArrList[indexPath.item]
        var vBookingNo:String = ""
     
            let cell = tableView.dequeueReusableCell(withIdentifier: "RideHistoryTVCell", for: indexPath) as! RideHistoryTVCell
            
            var vTypeNameTxt = ""

            if(self.HISTORY_TYPE == "PAST"){
                cell.btnContainerView.isHidden = true
                cell.rideDateLbl.text = Utils.convertDateFormateInAppLocal(date: Utils.convertDateGregorianToAppLocale(date: item.get("tTripRequestDateOrig"), dateFormate: "yyyy-MM-dd HH:mm:ss"), toDateFormate: Utils.dateFormateWithTime)
                cell.pickUpLocVLbl.text = item.get("tSaddress")
                cell.destVLbl.text = item.get("tDaddress") == "" ? "----" : item.get("tDaddress")
//                cell.cancelBtn.isHidden = true
                vBookingNo = Configurations.convertNumToAppLocal(numStr: item.get("vRideNo"))
//                cell.statusAreaViewHeight.constant = 45
                
                cell.btnContainerView.isHidden = true
                
            }else{
                cell.btnContainerView.isHidden = false
                //            cell.rideDateLbl.text = item.get("dBooking_date")
                cell.rideDateLbl.text = Utils.convertDateFormateInAppLocal(date: Utils.convertDateGregorianToAppLocale(date: item.get("dBooking_dateOrig"), dateFormate: "yyyy-MM-dd HH:mm:ss"), toDateFormate: Utils.dateFormateWithTime)
                cell.pickUpLocVLbl.text = item.get("vSourceAddresss")
                cell.destVLbl.text = item.get("tDestAddress") == "" ? "----" : item.get("tDestAddress")
                //            vBookingNo = item.get("vBookingNo")
//                cell.cancelBtn.isHidden = false
                vBookingNo = Configurations.convertNumToAppLocal(numStr: item.get("vBookingNo"))
//                cell.statusAreaViewHeight.constant = 34
            }
            
            if(item.get("vVehicleCategory") != ""){
                vTypeNameTxt = "\(item.get("vVehicleCategory")) - "
            }
            
            if(item.get("vPackageName") != ""){
                vTypeNameTxt = "\(self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_RENTAL_CATEGORY_TXT")) - "
            }
            
            if(item.get("vVehicleType") != ""){
                vTypeNameTxt = "\(vTypeNameTxt)\(item.get("vVehicleType"))"
            }
            
            cell.vehicleTypeLbl.text = vTypeNameTxt
            cell.vehicleTypeLbl.textColor = UIColor.UCAColor.AppThemeColor_1
            cell.vehicleTypeLbl.textAlignment = .center
            
            cell.destVLbl.fitText()
            cell.pickUpLocVLbl.fitText()
            
            
            cell.rentalPackageNameLbl.text = item.get("vPackageName")
            cell.rentalPackageNameLbl.textColor = UIColor.UCAColor.AppThemeColor_1
            cell.rentalPackageNameLbl.textAlignment = .center
            
            if item.get("vPackageName") == "" {
                cell.rentalPackageNameLbl.text = ""
                cell.rentalPackageNameLbl.isHidden = true
            }else{
                cell.rentalPackageNameLbl.isHidden = false
            }
            
            
            let statusH_str = self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_Status") + ": "
            
            if(item.get("eCancelled") == "Yes"){
//                cell.statusVLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_CANCELED_TXT")
                if(item.get("eCancelBy") == "Admin"){
                    cell.statusVLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_CANCELLED_BY_ADMIN")
                }else if(item.get("eCancelBy") == "Driver"){
//                    cell.statusVLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_CANCELLED_BY_DRIVER")
                    cell.statusVLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key:  item.get("eType") == Utils.cabGeneralType_Ride ? "LBL_CANCELLED_BY_DRIVER" : (item.get("eType") == Utils.cabGeneralType_UberX ? "LBL_CANCELLED_BY_PROVIDER" : "LBL_CANCELLED_BY_CARRIER"))
                }else{
                    cell.statusVLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_CANCELED_TXT")
                }
            }else{
                if(item.get("iActive") == "Canceled"){
                    cell.statusVLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_CANCELED_TXT")
                }else if(item.get("iActive") == "Finished"){
                    cell.statusVLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_FINISHED_TXT")
                }else {
                    if(item.get("iActive") == ""){
                        if(item.get("eStatus") == "Pending"){
                            cell.statusVLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_PENDING")
                        }else if(item.get("eStatus") == "Cancel"){
                            if(item.get("eCancelBy") == "Admin"){
                                cell.statusVLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_CANCELLED_BY_ADMIN")
                            }else if(item.get("eCancelBy") == "Driver"){
//                                cell.statusVLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_CANCELLED_BY_DRIVER")
                                cell.statusVLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key:  item.get("eType") == Utils.cabGeneralType_Ride ? "LBL_CANCELLED_BY_DRIVER" : (item.get("eType") == Utils.cabGeneralType_UberX ? "LBL_CANCELLED_BY_PROVIDER" : "LBL_CANCELLED_BY_CARRIER"))
                            }else{
                                cell.statusVLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_CANCELED_TXT")
                            }
//                            cell.statusVLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_CANCELED_TXT")
                        }else if(item.get("eStatus") == "Assign"){
                            cell.statusVLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_ASSIGNED")
                        }else if(item.get("eStatus") == "Accepted"){
                            cell.statusVLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_ACCEPTED")
                        }else if(item.get("eStatus") == "Declined"){
                            cell.statusVLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_DECLINED")
                        }else if(item.get("eStatus") == "Failed"){
                            cell.statusVLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_FAILED_TXT")
                        }else{
                            cell.statusVLbl.text = item.get("eStatus")
                        }
                    }else{
                        cell.statusVLbl.text = item.get("iActive") == "" ? item.get("eStatus") : item.get("iActive")
                    }
                }
            }
            
            
            cell.statusVLbl.textAlignment = .center
            cell.statusVLbl.text =  statusH_str + cell.statusVLbl.text!
            cell.statusVLbl.halfTextColorChange(fullText: cell.statusVLbl.text!, changeText: statusH_str, withColor: UIColor.UCAColor.AppThemeColor)
            
            cell.reScheduleBookingBtn.tag = indexPath.item
            cell.reScheduleBookingBtn.clickDelegate = self
            
            cell.reScheduleBookingBtn.btnType = "RE_BOOKING"
            cell.reScheduleBookingBtn.setButtonTitle(buttonTitle: self.generalFunc.getLanguageLabel(origValue: item.get("eType") == Utils.cabGeneralType_UberX ? "Re Booking" : "Re Schedule", key: item.get("eType") == Utils.cabGeneralType_UberX ? "LBL_REBOOKING" : "LBL_RESCHEDULE"))
            
            cell.cancelBookingBtn.tag = indexPath.item
            cell.cancelBookingBtn.clickDelegate = self
            
            if(item.get("eStatus") == "Declined" || item.get("eStatus") == "Cancel"){
                if(item.get("eType") != Utils.cabGeneralType_UberX && item.get("eAutoAssign").uppercased() == "NO"){
                    cell.reScheduleBookingBtn.isHidden = true
                }else{
                    cell.reScheduleBookingBtn.isHidden = false
                }
                
                cell.cancelBookingBtn.btnType = "VIEW_CANCEL_REASON"
                cell.cancelBookingBtn.setButtonTitle(buttonTitle: self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_VIEW_REASON"))
            }else{
                if(item.get("eType") == Utils.cabGeneralType_UberX || item.get("eAutoAssign").uppercased() == "NO"){
                    cell.reScheduleBookingBtn.isHidden = true
                }else{
                    cell.reScheduleBookingBtn.isHidden = false
                }
                
                cell.cancelBookingBtn.btnType = "CANCEL_BOOKING"
                cell.cancelBookingBtn.setButtonTitle(buttonTitle: self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_CANCEL_BOOKING"))
            }
            
//            cell.bookingNoLbl.text = self.generalFunc.getLanguageLabel(origValue: item.get("eType") == Utils.cabGeneralType_Deliver ? "Delivery" : "Booking", key: item.get("eType") == Utils.cabGeneralType_Deliver ? "LBL_DELIVERY" : "LBL_BOOKING") + "# " + vBookingNo
            cell.bookingNoLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_BOOKING") + "# " + vBookingNo
            
//            cell.pickUpLocHLbl.text = self.generalFunc.getLanguageLabel(origValue: "Pick up location", key: "LBL_PICK_UP_LOCATION")
            
            cell.pickUpLocHLbl.text = self.generalFunc.getLanguageLabel(origValue: item.get("eType") == Utils.cabGeneralType_UberX ? "Job Location" : (item.get("eType") == Utils.cabGeneralType_Deliver ? "Sender's location" : "Pick up location"), key: item.get("eType") == Utils.cabGeneralType_UberX ? "LBL_JOB_LOCATION_TXT" : (item.get("eType") == Utils.cabGeneralType_Deliver ? "LBL_SENDER_LOCATION" : "LBL_PICK_UP_LOCATION"))
            
            
            cell.destHLbl.text = self.generalFunc.getLanguageLabel(origValue: item.get("eType") == Utils.cabGeneralType_Deliver ? "Receiver's location" : "Destination location", key: item.get("eType") == Utils.cabGeneralType_Deliver ? "LBL_RECEIVER_LOCATION" : "LBL_DEST_LOCATION")
            
//            cell.destHLbl.text = self.generalFunc.getLanguageLabel(origValue: "Destination location", key: "LBL_DEST_LOCATION")
            
            cell.rideTypeLbl.text = item.get("eType") == Utils.cabGeneralType_Deliver ? self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_DELIVERY") : (item.get("eType") == Utils.cabGeneralType_Ride ? self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_RIDE") : self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_BOOKING"))
            
            if item.get("eType") == Utils.cabGeneralType_UberX
            {
                cell.rideTypeLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_SERVICES")
            }
            if(self.APP_TYPE.uppercased() == "RIDE-DELIVERY" || self.APP_TYPE.uppercased() == "RIDE-DELIVERY-UBERX"){
                cell.rideDateLbl.isHidden = false
            }else{
                cell.rideTypeLbl.text = cell.rideDateLbl.text
                cell.rideDateLbl.isHidden = true
            }
            
            
//            if(self.userProfileJson.get("APP_DESTINATION_MODE").uppercased() == "NONE"){
//                cell.destVLbl.text = "---"
//            }
            
            cell.dataView.layer.shadowOpacity = 0.5
            cell.dataView.layer.shadowOffset = CGSize(width: 0, height: 3)
            cell.dataView.layer.shadowColor = UIColor(hex: 0xe6e6e6).cgColor
            
            
            //            cell.dashedView.addDashedBorder(strokeColor: UIColor(hex: 0xADADAD), lineWidth: 2)
            cell.dashedView.backgroundColor = UIColor.clear
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                
                cell.dashedView.addDashedLine(color: UIColor(hex: 0xADADAD), lineWidth: 2)
            })
            
            
            GeneralFunctions.setImgTintColor(imgView: cell.locPinImgView, color: UIColor(hex: 0xd73030))
            
            cell.selectionStyle = .none
            cell.backgroundColor = UIColor.clear
            return cell
        
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if(self.HISTORY_TYPE == "PAST"){
            let rideDetailUV = GeneralFunctions.instantiateViewController(pageName: "RideDetailUV") as! RideDetailUV
            rideDetailUV.tripDetailDict = self.dataArrList[indexPath.item]
            self.pushToNavController(uv: rideDetailUV)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        //Rental package name related height is managed in extraHeightContainer arr
        
        if(indexPath.item < self.extraHeightContainer.count){
//            return self.extraHeightContainer[indexPath.item] + 295
            let item = dataArrList[indexPath.item]
            
            if(item.get("tDaddress") == "" && item.get("tDestAddress") == ""){
                return self.extraHeightContainer[indexPath.item] + (self.HISTORY_TYPE == "PAST" ? 225 : 280)
            }else{
                return self.extraHeightContainer[indexPath.item] + (self.HISTORY_TYPE == "PAST" ? 298 : 350)
            }
        }
        
        return (self.HISTORY_TYPE == "PAST" ? 298 : 350)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y;
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height;
        
        
        if (maximumOffset - currentOffset <= 15) {
            
            if(isNextPageAvail==true && isLoadingMore==false){
                
                isLoadingMore=true
                
                getDtata(isLoadingMore: isLoadingMore)
            }
        }
    }
    
    func addFooterView(){
        let loaderView =  self.generalFunc.addMDloader(contentView: self.tableView, isAddToParent: false)
        loaderView.backgroundColor = UIColor.clear
        loaderView.frame = CGRect(x:0, y:0, width: Application.screenSize.width, height: 80)
        self.tableView.tableFooterView  = loaderView
        self.tableView.tableFooterView?.isHidden = false
    }
    
    func removeFooterView(){
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.tableFooterView?.isHidden = true
    }
    
    func myBtnTapped(sender: MyButton) {
        
        if(sender.btnType == "RE_BOOKING"){
            
            let item = self.dataArrList[sender.tag]

            if(item.get("eType") == Utils.cabGeneralType_UberX){
                
                var customDataDict = [String:String]()
                
                customDataDict["iVehicleCategoryId"] = item.get("SelectedCategoryId")
                customDataDict["vCategory"] = item.get("SelectedCategory")
                customDataDict["ePriceType"] = item.get("SelectedPriceType")
                customDataDict["vVehicleType"] = item.get("SelectedVehicle")
                customDataDict["eFareType"] = item.get("SelectedFareType")
                customDataDict["fFixedFare"] = "\(item.get("SelectedCurrencySymbol"))\(item.get("SelectedPrice"))"
                customDataDict["fPricePerHour"] = "\(item.get("SelectedCurrencySymbol"))\(item.get("SelectedPrice"))"
                customDataDict["fPricePerKM"] = "\(item.get("SelectedCurrencySymbol"))\(item.get("SelectedPricePerKM"))"
                customDataDict["fPricePerMin"] = "\(item.get("SelectedCurrencySymbol"))\(item.get("SelectedPricePerMin"))"
                customDataDict["iBaseFare"] = "\(item.get("SelectedCurrencySymbol"))\(item.get("SelectedBaseFare"))"
                customDataDict["fCommision"] = "\(item.get("SelectedCurrencySymbol"))\(item.get("SelectedCommision"))"
                customDataDict["iMinFare"] = "\(item.get("SelectedCurrencySymbol"))\(item.get("SelectedMinFare"))"
                customDataDict["iPersonSize"] = "\(item.get("SelectedCurrencySymbol"))\(item.get("SelectedPersonSize"))"
                customDataDict["vVehicleTypeImage"] = item.get("SelectedVehicleTypeImage")
                customDataDict["eType"] = item.get("SelectedeType")
                customDataDict["eIconType"] = item.get("SelectedeIconType")
                customDataDict["eAllowQty"] = item.get("SelectedAllowQty")
                customDataDict["iMaxQty"] = item.get("SelectediMaxQty")
                customDataDict["iVehicleTypeId"] = item.get("iVehicleTypeId")
                customDataDict["fFixedFare_value"] = item.get("SelectedPrice")
                customDataDict["fPricePerHour_value"] = item.get("SelectedPrice")
                customDataDict["ALLOW_SERVICE_PROVIDER_AMOUNT"] = item.get("ALLOW_SERVICE_PROVIDER_AMOUNT")
                customDataDict["vCategoryTitle"] = item.get("SelectedCategoryTitle")
                customDataDict["vCategoryDesc"] = item.get("SelectedCategoryDesc")
                customDataDict["vSymbol"] = item.get("SelectedCurrencySymbol")
                
                let ufxServiceItemDict = customDataDict as NSDictionary
                
                let chooseServiceDateUv = GeneralFunctions.instantiateViewController(pageName: "ChooseServiceDateUV") as! ChooseServiceDateUV
                chooseServiceDateUv.ufxSelectedVehicleTypeId = item.get("iVehicleTypeId")
                chooseServiceDateUv.ufxSelectedVehicleTypeName = item.get("SelectedVehicle")
                chooseServiceDateUv.ufxSelectedQty = item.get("SelectedQty")
                chooseServiceDateUv.ufxAddressId = item.get("iUserAddressId")
                chooseServiceDateUv.ufxSelectedLatitude = item.get("vSourceLatitude")
                chooseServiceDateUv.ufxSelectedLongitude = item.get("vSourceLongitude")
                chooseServiceDateUv.serviceAreaAddress = item.get("vSourceAddresss")
                chooseServiceDateUv.ufxCabBookingId = item.get("iCabBookingId")
                chooseServiceDateUv.ufxServiceItemDict = ufxServiceItemDict
                self.pushToNavController(uv: chooseServiceDateUv)
            }else{
                
                let minDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
                let maxDate = Calendar.current.date(byAdding: .month, value: Utils.MAX_DATE_SELECTION_MONTH_FROM_CURRENT, to: Date())
                
                DatePickerDialog().show(self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_BOOKING_DATE"), doneButtonTitle: self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_SELECT_TXT"), cancelButtonTitle: self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_CANCEL_TXT"), minimumDate: minDate, maximumDate: maxDate, datePickerMode: .dateAndTime) {
                    (date) -> Void in
                    
                    if(date != nil){
                        let dateFormatter = DateFormatter()
                        dateFormatter.locale = Locale(identifier: "en_GB")
                        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm"
                        let dateString = dateFormatter.string(from: date!)
                        
                        self.changeBookingDate(iCabBookingId: item.get("iCabBookingId"), dateStr: dateString, eConfirmByUser: "No")
                        
//                        self.selectedDate = dateString
//                        self.selectedTimeZone = dateFormatter.timeZone.identifier
//
//                        self.checkSurgePrice(selectedTime: dateString, isRideLater:true, ufxSelectedDriverIndex: -1)
                    }
                }
            }
        }else if(self.surgeAcceptBtn != nil && self.surgeAcceptBtn == sender){
            self.cancelSurgeView()
            self.changeBookingDate(iCabBookingId: self.iCabBookingId, dateStr: self.dateStr, eConfirmByUser: "Yes")
        }else if(sender.btnType == "CANCEL_BOOKING"){
            cancelBooking(position: sender.tag)
        }else if(sender.btnType == "VIEW_CANCEL_REASON"){
            
            let item = self.dataArrList[sender.tag]

            self.generalFunc.setError(uv: self, title: self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_BOOKING_CANCEL_REASON"), content: item.get("vCancelReason"))
        }
        
    }
    
    func cancelBooking(position:Int){
        
        var superView:UIView!
        
        if(self.pageTabBarController != nil){
            superView = self.pageTabBarController!.view
        }else{
            superView = self.view
        }
        
        let bgView = UIView()
        bgView.backgroundColor = UIColor.black
        bgView.alpha = 0.4
        bgView.frame = superView.frame
        
        bgView.center = CGPoint(x: superView.bounds.midX, y: superView.bounds.midY)
        
        let cancelBookingView = CancelBookingView(frame: CGRect(x: superView.frame.width / 2, y: superView.frame.height / 2, width: (Application.screenSize.width > 390 ? 375 : (Application.screenSize.width - 50)), height: 200))
        cancelBookingView.center = CGPoint(x: superView.bounds.midX, y: superView.bounds.midY)
        cancelBookingView.setViewHandler { (isViewClose, view, isPositiveBtnClicked, reason) in
            
            cancelBookingView.frame.origin.y = Application.screenSize.height + 1000
            
            bgView.removeFromSuperview()
            
           superView.layoutIfNeeded()
            
            if(isPositiveBtnClicked){
                self.continueCancelBooking(iCabBookingId: self.dataArrList[position].get("iCabBookingId"), reason: reason)
            }
        }
        
        Utils.createRoundedView(view: cancelBookingView, borderColor: UIColor.clear, borderWidth: 0, cornerRadius: 10)
        
        cancelBookingView.layer.shadowOpacity = 0.5
        cancelBookingView.layer.shadowOffset = CGSize(width: 0, height: 3)
        cancelBookingView.layer.shadowColor = UIColor.black.cgColor
        
        superView.addSubview(bgView)
        superView.addSubview(cancelBookingView)
        
    }
    
    func changeBookingDate(iCabBookingId: String, dateStr:String, eConfirmByUser:String){
        let parameters = ["type":"UpdateBookingDateRideDelivery", "iUserId": GeneralFunctions.getMemberd(), "UserType": Utils.appUserType, "iCabBookingId": iCabBookingId, "scheduleDate": dateStr, "eConfirmByUser": eConfirmByUser]
        
        let exeWebServerUrl = ExeServerUrl(dict_data: parameters, currentView: self.view, isOpenLoader: true)
        exeWebServerUrl.executePostProcess(completionHandler: { (response) -> Void in
            
            if(response != ""){
                let dataDict = response.getJsonDataDict()
                
                if(dataDict.get("Action") == "1"){
                    self.isLoadingMore = false
                    self.dataArrList.removeAll()
                    self.tableView.reloadData()
                    self.nextPage_str = 1
                    
                    if(self.msgLbl != nil){
                        self.msgLbl.isHidden = true
                    }
                    
                    self.getDtata(isLoadingMore: false)
                    
                    self.generalFunc.setError(uv: self, title: "", content: self.generalFunc.getLanguageLabel(origValue: "", key: dataDict.get(Utils.message_str)))
                    
                }else{
                    if(dataDict.get("SurgePrice") != ""){
                        self.iCabBookingId = iCabBookingId
                        self.dateStr = dateStr
                        self.openSurgeConfirmDialog(isSurgeFromAddDestination: false, isRideLater: false, dataDict: dataDict)
                        return
                    }
                    self.generalFunc.setError(uv: self, title: "", content: self.generalFunc.getLanguageLabel(origValue: "", key: dataDict.get("message")))
                }
                
            }else{
                self.generalFunc.setError(uv: self)
            }
        })
    }
    
    /**
     This function is used to show surge charge view on screen.
     - parameters:
     - isSurgeFromAddDestination: By passing value true, This indicates whether a view opens while adding/change a destination. This will be called if trip will falled into flate trip after adding destination. User needs to confirm first for flate fare.
     - isRideLater: Pass true value if view is opening from booking later functionality (User is going to book an schedule trip/job).
     - dataDict: server response.
     */
    func openSurgeConfirmDialog(isSurgeFromAddDestination:Bool, isRideLater:Bool, dataDict:NSDictionary){
        var superView:UIView!
        
        if(self.pageTabBarController != nil){
            superView = self.pageTabBarController!.view
        }else{
            superView = self.view
        }
        
        surgePriceView = self.generalFunc.loadView(nibName: "SurgePriceView", uv: self, isWithOutSize: true)
        
        let width = Application.screenSize.width  > 390 ? 375 : Application.screenSize.width - 50
        
        var defaultHeight:CGFloat = 154
        surgePriceView.frame.size = CGSize(width: width, height: defaultHeight)
        
        surgePriceView.center = CGPoint(x: superView.bounds.midX, y: superView.bounds.midY)
        
        surgePriceBGView = UIView()
        surgePriceBGView.backgroundColor = UIColor.black
        self.surgePriceBGView.alpha = 0
        surgePriceBGView.isUserInteractionEnabled = true
        
        let bgViewTapGue = UITapGestureRecognizer()
        surgePriceBGView.frame = superView.frame
        
        surgePriceBGView.center = CGPoint(x: superView.bounds.midX, y: superView.bounds.midY)
        
        bgViewTapGue.addTarget(self, action: #selector(self.cancelSurgeView))
        
        surgePriceBGView.addGestureRecognizer(bgViewTapGue)
        
        surgePriceView.layer.shadowOpacity = 0.5
        surgePriceView.layer.shadowOffset = CGSize(width: 0, height: 3)
        surgePriceView.layer.shadowColor = UIColor.black.cgColor
        
        surgePriceView.alpha = 0
        superView.addSubview(surgePriceBGView)
        superView.addSubview(surgePriceView)
        
        UIView.animate(withDuration: 0.5,
                       animations: {
                        self.surgePriceBGView.alpha = 0.4
                        self.surgePriceView.alpha = 1
        },  completion: { finished in
            self.surgePriceBGView.alpha = 0.4
            self.surgePriceView.alpha = 1
        })
        
        let cancelSurgeTapGue = UITapGestureRecognizer()
        cancelSurgeTapGue.addTarget(self, action: #selector(self.cancelSurgeView))
        
        surgeLaterLbl.isUserInteractionEnabled = true
        surgeLaterLbl.addGestureRecognizer(cancelSurgeTapGue)
      
        self.surgePayAmtLbl.text = ""
        self.surgeLaterLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_TRY_LATER")
        
        self.surgePriceVLbl.text = Configurations.convertNumToAppLocal(numStr: dataDict.get("SurgePrice"))
        self.surgePriceHLbl.text = self.generalFunc.getLanguageLabel(origValue: "", key: dataDict.get(Utils.message_str))
        self.surgeAcceptBtn.setButtonTitle(buttonTitle: self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_ACCEPT_SURGE"))
        
        let headerTxtHeight = self.surgePriceHLbl.text!.height(withConstrainedWidth: width - 20, font: UIFont(name: "Roboto-Light", size: 17)!)
        let priceTxtHeight = self.surgePriceVLbl.text!.height(withConstrainedWidth: width - 20, font: UIFont(name: "Roboto-Light", size: 26)!)
        let payAmtTxtHeight = self.surgePayAmtLbl.text!.height(withConstrainedWidth: width - 20, font: UIFont(name: "Roboto-Light", size: 16)!)
        
        self.surgePriceHLbl.fitText()
        self.surgePayAmtLbl.fitText()
        self.surgePriceVLbl.fitText()
        
        defaultHeight = defaultHeight + headerTxtHeight + priceTxtHeight + payAmtTxtHeight
        surgePriceView.frame.size = CGSize(width: width, height: defaultHeight)
        surgePriceView.center = CGPoint(x: self.cntView.bounds.midX, y: self.cntView.bounds.midY)
        
        self.surgeAcceptBtn.clickDelegate = self
        
    }
    
    /**
     This function is used to close or remove surge charge view from screen.
     */
    func cancelSurgeView(){
        surgePriceView.removeFromSuperview()
        surgePriceBGView.removeFromSuperview()
    }
    
    func continueCancelBooking(iCabBookingId: String, reason:String){
        let parameters = ["type":"cancelBooking", "iUserId": GeneralFunctions.getMemberd(), "UserType": Utils.appUserType, "iCabBookingId": iCabBookingId, "Reason": reason]
        
        let exeWebServerUrl = ExeServerUrl(dict_data: parameters, currentView: self.view, isOpenLoader: true)
        exeWebServerUrl.executePostProcess(completionHandler: { (response) -> Void in
            
            if(response != ""){
                let dataDict = response.getJsonDataDict()
                
                if(dataDict.get("Action") == "1"){
                    
                    self.generalFunc.setAlertMessage(uv: self, title: "", content: self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_BOOKING_CANCELED"), positiveBtn: self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_BTN_OK_TXT"), nagativeBtn: "", completionHandler: { (btnClickedIndex) in
                        
                        self.isLoadingMore = false
                        self.dataArrList.removeAll()
                        self.tableView.reloadData()
                        self.nextPage_str = 1
                        self.getDtata(isLoadingMore: false)
                    })
                    
                    
                }else{
                    if(dataDict.get(Utils.message_str) == "DO_RESTART"){
                        let window = Application.window
                        
                        let getUserData = GetUserData(uv: self, window: window!)
                        getUserData.getdata()
                        
                        return
                    }
                    
                    self.generalFunc.setError(uv: self, title: "", content: self.generalFunc.getLanguageLabel(origValue: "", key: dataDict.get("message")))
                }
                
            }else{
                self.generalFunc.setError(uv: self)
            }
        })
    }

    @IBAction func unwindToRideHistoryScreen(_ segue:UIStoryboardSegue) {
        
        if(segue.source.isKind(of: RideDetailUV.self))
        {
            if(self.HISTORY_TYPE == "PAST"){
                let iTripId = (segue.source as! RideDetailUV).tripDetailDict.get("iTripId")
                var dataList = [NSDictionary]()
                dataList.append(contentsOf: dataArrList)
                
                self.dataArrList.removeAll()
                
                for i in 0..<dataList.count{
                    
                    let item = dataList[i]
                    let tripId = item.get("iTripId")
                    
                    if(iTripId == tripId){
                        item.setValue("Yes", forKey: "is_rating")
                    }
                    
//                    self.dataArrList += [item]
                    self.dataArrList.append(item)
                }
                
                self.tableView.reloadData()
            }
           
        }else if(segue.source.isKind(of: MainScreenUV.self)){
            // Called when booking is successfully finished
            
            let mainScreenUv = segue.source as! MainScreenUV
            
            if(mainScreenUv.ufxCabBookingId != ""){
                self.generalFunc.setAlertMessage(uv: self, title: "", content: self.generalFunc.getLanguageLabel(origValue: "Your selected booking has been updated.", key: "LBL_BOOKING_UPDATED"), positiveBtn: self.generalFunc.getLanguageLabel(origValue: "", key: "LBL_BTN_OK_TXT"), nagativeBtn: "", completionHandler: { (btnClickedIndex) in
                    
                    self.isLoadingMore = false
                    self.dataArrList.removeAll()
                    self.tableView.reloadData()
                    self.nextPage_str = 1
                    
                    if(self.msgLbl != nil){
                        self.msgLbl.isHidden = true
                    }
                    
                    self.getDtata(isLoadingMore: false)
                })
            }
        }
        
    }
    
}
